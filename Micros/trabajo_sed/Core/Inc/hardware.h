#ifndef INC_HARDWARE_H_
#define INC_HARDWARE_H_

#include "stm32f4xx_hal.h"

// Definición de Colores para facilitar la lectura
typedef enum {
    APAGADO,
    ROJO,
    VERDE,
    AMARILLO
} ColorLED;

// Prototipos de funciones
void Hardware_Init(ADC_HandleTypeDef* hadc, I2C_HandleTypeDef* hi2c);
void Leer_Potenciometros(int* valores_0_9);
void Actualizar_LED_Digito(int digito_index, ColorLED color);
void Apagar_Todos_LEDs(void);
void Zumbador_Tono(int duracion_ms, int tipo);

#endif
