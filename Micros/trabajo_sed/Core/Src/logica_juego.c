#include "logica_juego.h"
#include "hardware.h"
#include "i2c-lcd.h"
#include <stdlib.h>
#include <stdio.h>
#include "main.h"

// --- IMPORTANTE: Usamos 'extern' para no duplicar la variable htim2 ---
extern TIM_HandleTypeDef htim2;

// Variables Globales del Juego
EstadoJuego estado_actual = ESTADO_ESPERA;
int clave_secreta[4];
int intento_actual[4];
bool digito_bloqueado[4];

// Variables de Juego y Tiempo
int intentos_restantes = 6;
int tiempo_restante = 120; // 120 segundos totales

// Variables auxiliares
uint32_t ultimo_refresco_lcd = 0;

// Variables Anti-Rebote para botones
volatile uint32_t t_btn_val = 0;
volatile uint32_t t_btn_ini = 0;
volatile bool flag_validar = false;
volatile bool flag_inicio = false;

// --- FUNCIÓN DEL TIMER (Se ejecuta cada segundo automáticamente) ---
void Logica_Timer_Callback() {
    if (estado_actual == ESTADO_JUGANDO) {
        if (tiempo_restante > 0) {
            tiempo_restante--;
        } else {
            // Si el tiempo llega a 0, cambiamos a derrota inmediatamente
            estado_actual = ESTADO_DERROTA;
        }
    }
}

void Logica_Inicializar() {
    Apagar_Todos_LEDs();
    lcd_clear();
    lcd_put_cur(0,0);
    lcd_send_string("PROYECTO CERROJO");
    HAL_Delay(2000);

    tiempo_restante = 120; // Reiniciamos reloj

    lcd_clear();
    lcd_put_cur(0,0);
    lcd_send_string("PULSA INICIO");
}

void Logica_Ejecutar_Ciclo() {
    char buffer[20];
    int lecturas_raw[4];

    switch (estado_actual) {
        case ESTADO_ESPERA:
            if (flag_inicio) {
                flag_inicio = false;
                estado_actual = ESTADO_GENERAR;
            }
            break;

        case ESTADO_GENERAR:
            srand(HAL_GetTick());
            for(int i=0; i<4; i++) {
                clave_secreta[i] = rand() % 10;
                digito_bloqueado[i] = false;
            }
            intentos_restantes = 6;
            tiempo_restante = 120; // 2 minutos

            lcd_clear();
            lcd_send_string("NUEVA PARTIDA");
            HAL_Delay(1000);
            lcd_clear();
            estado_actual = ESTADO_JUGANDO;
            break;

        case ESTADO_JUGANDO:
            // 1. Leer Hardware
            Leer_Potenciometros(lecturas_raw);
            for(int i=0; i<4; i++) {
                if(!digito_bloqueado[i]) intento_actual[i] = lecturas_raw[i];
            }

            // 2. Refrescar Pantalla (Muestra Tiempo T:xxx)
            if (HAL_GetTick() - ultimo_refresco_lcd > 200) {
                sprintf(buffer, "T:%03d Vid:%d", tiempo_restante, intentos_restantes);
                lcd_put_cur(0, 0); lcd_send_string(buffer);

                sprintf(buffer, " %d  %d  %d  %d ",
                        intento_actual[0], intento_actual[1],
                        intento_actual[2], intento_actual[3]);
                lcd_put_cur(1, 0); lcd_send_string(buffer);

                ultimo_refresco_lcd = HAL_GetTick();
            }

            // 3. Verificar derrota por tiempo
            if (tiempo_restante <= 0) estado_actual = ESTADO_DERROTA;

            // 4. Botones
            if (flag_validar) { flag_validar = false; estado_actual = ESTADO_VERIFICAR; }
            if (flag_inicio) { flag_inicio = false; estado_actual = ESTADO_GENERAR; }
            break;

        case ESTADO_VERIFICAR:
            lcd_clear();
            lcd_send_string("VERIFICANDO...");
            HAL_Delay(500);

            intentos_restantes--;
            int aciertos = 0;

            for(int i=0; i<4; i++) {
                int dif = abs(intento_actual[i] - clave_secreta[i]);
                if (dif == 0) {
                    Actualizar_LED_Digito(i, VERDE);
                    digito_bloqueado[i] = true;
                    aciertos++;
                } else if (dif == 1) {
                    Actualizar_LED_Digito(i, AMARILLO);
                } else {
                    Actualizar_LED_Digito(i, ROJO);
                }
            }
            HAL_Delay(1500); // Pausa visual

            if (aciertos == 4) {
                estado_actual = ESTADO_VICTORIA;
            } else if (intentos_restantes <= 0 || tiempo_restante <= 0) {
                estado_actual = ESTADO_DERROTA;
            } else {
                // Sigue jugando
                lcd_clear();
                Zumbador_Tono(100, 0);
                estado_actual = ESTADO_JUGANDO;
            }
            break;

        case ESTADO_VICTORIA:
            lcd_clear();
            lcd_send_string("GANASTE!!");
            lcd_put_cur(1,0);
            sprintf(buffer, "Clave: %d%d%d%d", clave_secreta[0], clave_secreta[1], clave_secreta[2], clave_secreta[3]);
            lcd_send_string(buffer);
            Zumbador_Tono(100, 1);
            HAL_Delay(4000);
            Logica_Inicializar();
            estado_actual = ESTADO_ESPERA;
            break;

        case ESTADO_DERROTA:
            lcd_clear();
            if (tiempo_restante <= 0) lcd_send_string("TIEMPO AGOTADO");
            else lcd_send_string("FIN DE JUEGO");

            lcd_put_cur(1,0);
            sprintf(buffer, "Era: %d%d%d%d", clave_secreta[0], clave_secreta[1], clave_secreta[2], clave_secreta[3]);
            lcd_send_string(buffer);
            Zumbador_Tono(500, 0);
            HAL_Delay(4000);
            Logica_Inicializar();
            estado_actual = ESTADO_ESPERA;
            break;
    }
}

// Callbacks botones
void Callback_Boton_Validar() {
    if (HAL_GetTick() - t_btn_val > 500) { flag_validar = true; t_btn_val = HAL_GetTick(); }
}
void Callback_Boton_Inicio() {
    if (HAL_GetTick() - t_btn_ini > 500) { flag_inicio = true; t_btn_ini = HAL_GetTick(); }
}
