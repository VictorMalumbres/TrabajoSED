#include "logica_juego.h"
#include "hardware.h"
#include "i2c-lcd.h"
#include <stdlib.h>
#include <stdio.h>
#include "main.h"

// --- VARIABLE EXTERNA DEL TIMER (Para arreglar el error de compilación) ---
extern TIM_HandleTypeDef htim2;

// Variables Globales del Juego
EstadoJuego estado_actual = ESTADO_ESPERA;
int clave_secreta[4];
int intento_actual[4];
bool digito_bloqueado[4];

// Variables de Juego
int intentos_restantes = 6;
int tiempo_restante = 120; // 120 segundos

// VARIABLES PARA LOGICA NO BLOQUEANTE (El sustituto de HAL_Delay)
uint32_t t_inicio_estado = 0;   // Guarda la hora a la que entramos al estado
bool es_inicio_estado = true;   // Indica si acabamos de entrar (para ejecutar cosas 1 sola vez)
uint32_t ultimo_refresco_lcd = 0;

// Variables Botones
volatile uint32_t t_btn_val = 0;
volatile uint32_t t_btn_ini = 0;
volatile bool flag_validar = false;
volatile bool flag_inicio = false;

// Función para cambiar de estado de forma segura y marcar el tiempo
void Cambiar_Estado(EstadoJuego nuevo_estado) {
    estado_actual = nuevo_estado;
    es_inicio_estado = true; // Marcamos que acabamos de llegar
    t_inicio_estado = HAL_GetTick(); // Guardamos la hora de llegada
}

// --- TIMER HARDWARE (Cuenta atrás 120s) ---
void Logica_Timer_Callback() {
    if (estado_actual == ESTADO_JUGANDO) {
        if (tiempo_restante > 0) {
            tiempo_restante--;
        } else {
            // Cambio directo si se acaba el tiempo
            Cambiar_Estado(ESTADO_DERROTA);
        }
    }
}

void Logica_Inicializar() {
    Apagar_Todos_LEDs();
    lcd_clear();
    lcd_put_cur(0,0);
    lcd_send_string("PROYECTO CERROJO");
    // Aquí sí podemos dejar un delay pequeño al arrancar,
    // pero si es estricto, mejor quítalo. Dejamos 1s.
    HAL_Delay(1000);

    tiempo_restante = 120;
    lcd_clear();
    lcd_put_cur(0,0);
    lcd_send_string("PULSA INICIO");

    Cambiar_Estado(ESTADO_ESPERA);
}

void Logica_Ejecutar_Ciclo() {
    char buffer[20];
    int lecturas_raw[4];
    uint32_t t_actual = HAL_GetTick(); // Hora actual del sistema

    switch (estado_actual) {

        // --- 1. ESPERA ---
        case ESTADO_ESPERA:
            if (es_inicio_estado) {
                // Cosas que se hacen solo al entrar en ESPERA
                es_inicio_estado = false;
            }

            if (flag_inicio) {
                flag_inicio = false;
                Cambiar_Estado(ESTADO_GENERAR);
            }
            break;

        // --- 2. GENERAR ---
        case ESTADO_GENERAR:
            if (es_inicio_estado) {
                srand(HAL_GetTick());
                for(int i=0; i<4; i++) {
                    clave_secreta[i] = rand() % 10;
                    digito_bloqueado[i] = false;
                }
                intentos_restantes = 6;
                tiempo_restante = 120;

                lcd_clear();
                lcd_send_string("NUEVA PARTIDA");
                es_inicio_estado = false;
            }

            // SUSTITUTO DEL HAL_DELAY(1000):
            // Si han pasado 1000ms desde que entramos, cambiamos.
            if (t_actual - t_inicio_estado >= 1000) {
                lcd_clear();
                Cambiar_Estado(ESTADO_JUGANDO);
            }
            break;

        // --- 3. JUGANDO ---
        case ESTADO_JUGANDO:
            // Aquí no había delays, así que se queda casi igual
            if (es_inicio_estado) es_inicio_estado = false;

            // Leer Hardware
            Leer_Potenciometros(lecturas_raw);
            for(int i=0; i<4; i++) {
                if(!digito_bloqueado[i]) intento_actual[i] = lecturas_raw[i];
            }

            // Refrescar LCD
            if (t_actual - ultimo_refresco_lcd > 200) {
                sprintf(buffer, "T:%03d Vid:%d", tiempo_restante, intentos_restantes);
                lcd_put_cur(0, 0); lcd_send_string(buffer);

                sprintf(buffer, " %d  %d  %d  %d ",
                        intento_actual[0], intento_actual[1],
                        intento_actual[2], intento_actual[3]);
                lcd_put_cur(1, 0); lcd_send_string(buffer);

                ultimo_refresco_lcd = t_actual;
            }

            // Verificar tiempo agotado (por si el Timer se adelantó)
            if (tiempo_restante <= 0) Cambiar_Estado(ESTADO_DERROTA);

            // Botones
            if (flag_validar) { flag_validar = false; Cambiar_Estado(ESTADO_VERIFICAR); }
            if (flag_inicio) { flag_inicio = false; Cambiar_Estado(ESTADO_GENERAR); }
            break;

        // --- 4. VERIFICAR ---
        case ESTADO_VERIFICAR:
            if (es_inicio_estado) {
                lcd_clear();
                lcd_send_string("VERIFICANDO...");

                intentos_restantes--;

                // Lógica de colores
                for(int i=0; i<4; i++) {
                    int dif = abs(intento_actual[i] - clave_secreta[i]);
                    if (dif == 0) { Actualizar_LED_Digito(i, VERDE); digito_bloqueado[i] = true; }
                    else if (dif == 1) { Actualizar_LED_Digito(i, AMARILLO); }
                    else { Actualizar_LED_Digito(i, ROJO); }
                }
                es_inicio_estado = false;
            }

            // SUSTITUTO DE HAL_DELAY(1500) para ver los LEDs:
            if (t_actual - t_inicio_estado >= 1500) {
                // Decidir destino
                int aciertos = 0;
                for(int i=0; i<4; i++) if(intento_actual[i] == clave_secreta[i]) aciertos++;

                if (aciertos == 4) {
                    Cambiar_Estado(ESTADO_VICTORIA);
                } else if (intentos_restantes <= 0 || tiempo_restante <= 0) {
                    Cambiar_Estado(ESTADO_DERROTA);
                } else {
                    lcd_clear();
                    Zumbador_Tono(100, 0); // Pitido corto
                    Cambiar_Estado(ESTADO_JUGANDO);
                }
            }
            break;

        // --- 5. VICTORIA ---
        case ESTADO_VICTORIA:
            if (es_inicio_estado) {
                lcd_clear();
                lcd_send_string("GANASTE!!");
                lcd_put_cur(1,0);
                sprintf(buffer, "Clave: %d%d%d%d", clave_secreta[0], clave_secreta[1], clave_secreta[2], clave_secreta[3]);
                lcd_send_string(buffer);
                Zumbador_Tono(100, 1);
                es_inicio_estado = false;
            }

            // SUSTITUTO DE HAL_DELAY(4000): Esperamos 4s y reiniciamos
            if (t_actual - t_inicio_estado >= 4000) {
                Logica_Inicializar(); // Reinicia y va a ESPERA
            }
            break;

        // --- 6. DERROTA ---
        case ESTADO_DERROTA:
            if (es_inicio_estado) {
                lcd_clear();
                if (tiempo_restante <= 0) lcd_send_string("TIEMPO AGOTADO");
                else lcd_send_string("FIN DE JUEGO");

                lcd_put_cur(1,0);
                sprintf(buffer, "Era: %d%d%d%d", clave_secreta[0], clave_secreta[1], clave_secreta[2], clave_secreta[3]);
                lcd_send_string(buffer);
                Zumbador_Tono(500, 0);
                es_inicio_estado = false;
            }

            // SUSTITUTO DE HAL_DELAY(4000)
            if (t_actual - t_inicio_estado >= 4000) {
                Logica_Inicializar();
            }
            break;
    }
}

// Callbacks Botones
void Callback_Boton_Validar() {
    if (HAL_GetTick() - t_btn_val > 500) { flag_validar = true; t_btn_val = HAL_GetTick(); }
}
void Callback_Boton_Inicio() {
    if (HAL_GetTick() - t_btn_ini > 500) { flag_inicio = true; t_btn_ini = HAL_GetTick(); }
}
