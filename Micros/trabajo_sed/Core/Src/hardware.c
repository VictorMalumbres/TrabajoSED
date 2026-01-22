#include "hardware.h"
#include <math.h> // Para abs()

extern ADC_HandleTypeDef hadc1;

// Arrays de configuración de pines (Verifica que coinciden con tus conexiones)
GPIO_TypeDef* PUERTOS_LED[4][2] = {
    {GPIOC, GPIOC}, // Digito 1 (Verde, Rojo)
    {GPIOC, GPIOC}, // Digito 2
    {GPIOC, GPIOC}, // Digito 3
    {GPIOC, GPIOC}  // Digito 4
};

uint16_t PINES_LED[4][2] = {
    {GPIO_PIN_0, GPIO_PIN_1}, // Digito 1: PC0(Verde), PC1(Rojo)
    {GPIO_PIN_2, GPIO_PIN_3}, // Digito 2: PC2, PC3
    {GPIO_PIN_4, GPIO_PIN_5}, // Digito 3: PC4, PC5
    {GPIO_PIN_6, GPIO_PIN_7}  // Digito 4: PC6, PC7
};

// --- FUNCIÓN ZUMBADOR (UNIVERSAL) ---
void Zumbador_Tono(int duracion_ms, int tipo) {
    // TIPO 1: VICTORIA (Agudo) | TIPO 0: ERROR/DERROTA (Grave/Roto)
    if (tipo == 1) {
        HAL_GPIO_WritePin(GPIOB, GPIO_PIN_5, GPIO_PIN_SET);
        HAL_Delay(duracion_ms);
        HAL_GPIO_WritePin(GPIOB, GPIO_PIN_5, GPIO_PIN_RESET);
    }
    else {
        for(int i=0; i<3; i++) {
            HAL_GPIO_WritePin(GPIOB, GPIO_PIN_5, GPIO_PIN_SET);
            HAL_Delay(duracion_ms / 3);
            HAL_GPIO_WritePin(GPIOB, GPIO_PIN_5, GPIO_PIN_RESET);
            HAL_Delay(50);
        }
    }
}

// --- FUNCIÓN POTENCIÓMETROS (MODO DISCONTINUO) ---
void Leer_Potenciometros(int* valores_0_9) {
    for(int i=0; i<4; i++) {
        HAL_ADC_Start(&hadc1); // Dispara una lectura
        if (HAL_ADC_PollForConversion(&hadc1, 50) == HAL_OK) {
            uint32_t val = HAL_ADC_GetValue(&hadc1);
            valores_0_9[i] = (val * 10) / 4100; // Escala 0-9
        } else {
            valores_0_9[i] = 0; // Error
        }
    }
}

// --- FUNCIÓN LEDS (CON AMARILLO) ---
void Actualizar_LED_Digito(int index, ColorLED color) {
    // 1. Apagar todo
    HAL_GPIO_WritePin(PUERTOS_LED[index][0], PINES_LED[index][0], GPIO_PIN_RESET);
    HAL_GPIO_WritePin(PUERTOS_LED[index][1], PINES_LED[index][1], GPIO_PIN_RESET);

    // 2. Encender según color
    if (color == VERDE) {
        HAL_GPIO_WritePin(PUERTOS_LED[index][0], PINES_LED[index][0], GPIO_PIN_SET);
    }
    else if (color == ROJO) {
        HAL_GPIO_WritePin(PUERTOS_LED[index][1], PINES_LED[index][1], GPIO_PIN_SET);
    }
    else if (color == AMARILLO) {
        // Mezcla: Rojo + Verde
        HAL_GPIO_WritePin(PUERTOS_LED[index][0], PINES_LED[index][0], GPIO_PIN_SET);
        HAL_GPIO_WritePin(PUERTOS_LED[index][1], PINES_LED[index][1], GPIO_PIN_SET);
    }
}

void Apagar_Todos_LEDs() {
    for(int i=0; i<4; i++) {
        Actualizar_LED_Digito(i, 99); // Color invalido apaga todo
    }
}

void Hardware_Init(ADC_HandleTypeDef* adc, I2C_HandleTypeDef* i2c) {
    lcd_init();
    Apagar_Todos_LEDs();
}
