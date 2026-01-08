#include "logica_juego.h"
#include "hardware.h"
#include "i2c-lcd.h"
#include <stdlib.h>
#include <stdio.h>

// Variables del Juego
EstadoJuego estado_actual = ESTADO_ESPERA;
int clave_secreta[4];
int intento_actual[4];
bool digito_bloqueado[4];
int intentos_restantes = 6;
uint32_t ultimo_refresco_lcd = 0;

// Variables Anti-Rebote (Debounce)
volatile uint32_t t_btn_val = 0;
volatile uint32_t t_btn_ini = 0;
volatile bool flag_validar = false;
volatile bool flag_inicio = false;

void Logica_Inicializar() {
    Apagar_Todos_LEDs();
    lcd_clear();
    lcd_put_cur(0,0);
    lcd_send_string("PROYECTO CERROJO");
    HAL_Delay(1000);
    lcd_clear();
    lcd_put_cur(0,0);
    lcd_send_string("PULSA INICIO");
}

void Logica_Ejecutar_Ciclo() {
    char buffer[20];
    int lecturas_raw[4];

    // MÁQUINA DE ESTADOS FINITOS
    switch (estado_actual) {

        // --- 1. MODO ESPERA ---
        case ESTADO_ESPERA:
            if (flag_inicio) {
                flag_inicio = false;
                estado_actual = ESTADO_GENERAR;
            }
            break;

        // --- 2. GENERACIÓN DE CLAVE ---
        case ESTADO_GENERAR:
            srand(HAL_GetTick()); // Semilla aleatoria
            for(int i=0; i<4; i++) {
                clave_secreta[i] = rand() % 10;
                digito_bloqueado[i] = false;
            }
            intentos_restantes = 6;

            lcd_clear();
            lcd_send_string("NUEVA PARTIDA");
            HAL_Delay(1000);
            lcd_clear();
            estado_actual = ESTADO_JUGANDO;
            break;

        // --- 3. JUEGO ACTIVO ---
        case ESTADO_JUGANDO:
            // A. Leer Sensores (ADC)
            Leer_Potenciometros(lecturas_raw);

            // B. Actualizar Lógica (Bloquear acertados)
            for(int i=0; i<4; i++) {
                if(!digito_bloqueado[i]) {
                    intento_actual[i] = lecturas_raw[i];
                }
            }

            // C. Salida: Refresco LCD (Frecuencia controlada)
            if (HAL_GetTick() - ultimo_refresco_lcd > 200) {
                sprintf(buffer, "Vidas:%d Clave:??", intentos_restantes);
                lcd_put_cur(0, 0);
                lcd_send_string(buffer);

                sprintf(buffer, " %d  %d  %d  %d ",
                        intento_actual[0], intento_actual[1],
                        intento_actual[2], intento_actual[3]);
                lcd_put_cur(1, 0);
                lcd_send_string(buffer);

                ultimo_refresco_lcd = HAL_GetTick();
            }

            // D. Transiciones
            if (flag_validar) {
                flag_validar = false;
                estado_actual = ESTADO_VERIFICAR;
            }
            if (flag_inicio) { // Reinicio rápido
                flag_inicio = false;
                estado_actual = ESTADO_GENERAR;
            }
            break;

        // --- 4. VALIDACIÓN ---
        case ESTADO_VERIFICAR:
            lcd_clear();
            lcd_send_string("VERIFICANDO...");
            HAL_Delay(500);

            intentos_restantes--;
            int aciertos = 0;

            for(int i=0; i<4; i++) {
                            // Calculamos la distancia positiva
                            int diferencia = abs(intento_actual[i] - clave_secreta[i]);

                            if (diferencia == 0) {
                                // EXACTO -> VERDE
                                Actualizar_LED_Digito(i, VERDE);
                                digito_bloqueado[i] = true;
                                aciertos++;
                            }
                            else if (diferencia == 1) {
                                // CAMBIO AQUÍ: Solo si la diferencia es EXACTAMENTE 1
                                // (Ejemplo: Si la clave es 5, solo se enciende con 4 o 6)
                                Actualizar_LED_Digito(i, AMARILLO);
                            }
                            else {
                                // Si fallas por 2 o más -> ROJO
                                Actualizar_LED_Digito(i, ROJO);
                            }
                        }

            HAL_Delay(1000); // Pausa para ver los LEDs

            if (aciertos == 4) {
                estado_actual = ESTADO_VICTORIA;
            } else if (intentos_restantes <= 0) {
                estado_actual = ESTADO_DERROTA;
            } else {
                // Sigue jugando
                lcd_clear();
                Zumbador_Tono(100, 0); // Feedback Sonoro (Error)
                estado_actual = ESTADO_JUGANDO;
            }
            break;

        // --- 5. RESULTADOS ---
        case ESTADO_VICTORIA:
            lcd_clear();
            lcd_send_string("GANASTE!!");
            lcd_put_cur(1,0);
            sprintf(buffer, "Clave: %d%d%d%d", clave_secreta[0], clave_secreta[1], clave_secreta[2], clave_secreta[3]);
            lcd_send_string(buffer);

            Zumbador_Tono(100, 1); HAL_Delay(100);
            Zumbador_Tono(100, 1); HAL_Delay(100);
            Zumbador_Tono(400, 1); // Melodía Victoria

            HAL_Delay(3000);
            Logica_Inicializar();
            estado_actual = ESTADO_ESPERA;
            break;

        case ESTADO_DERROTA:
            lcd_clear();
            lcd_send_string("PERDISTE...");
            lcd_put_cur(1,0);
            sprintf(buffer, "Era: %d%d%d%d", clave_secreta[0], clave_secreta[1], clave_secreta[2], clave_secreta[3]);
            lcd_send_string(buffer);

            Zumbador_Tono(1000, 0); // Tono Triste
            HAL_Delay(3000);
            Logica_Inicializar();
            estado_actual = ESTADO_ESPERA;
            break;
    }
}

// Funciones Callback con Anti-Rebote
void Callback_Boton_Validar() {
    if (HAL_GetTick() - t_btn_val > 500) {
        flag_validar = true;
        t_btn_val = HAL_GetTick();
    }
}

void Callback_Boton_Inicio() {
    if (HAL_GetTick() - t_btn_ini > 500) {
        flag_inicio = true;
        t_btn_ini = HAL_GetTick();
    }
}
