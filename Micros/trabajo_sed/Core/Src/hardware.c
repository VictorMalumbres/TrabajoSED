#include "hardware.h"
#include "i2c-lcd.h"

extern ADC_HandleTypeDef hadc1; // Referencia al ADC del main

// PINES DE LEDS - CONFIGURACIÓN FÍSICA
// Matriz: [Digito 0-3][0=Verde, 1=Rojo] -> {Puerto, Pin}
// Ajusta estos pines si has usado otros en la protoboard
GPIO_TypeDef* PUERTOS_LED[4][2] = {
    {GPIOC, GPIOC}, {GPIOC, GPIOC}, {GPIOC, GPIOC}, {GPIOC, GPIOC}
};
uint16_t PINES_LED[4][2] = {
    {GPIO_PIN_0, GPIO_PIN_1}, // Digito 1: Verde PC0, Rojo PC1
    {GPIO_PIN_2, GPIO_PIN_3}, // Digito 2: Verde PC2, Rojo PC3
    {GPIO_PIN_4, GPIO_PIN_5}, // Digito 3: Verde PC4, Rojo PC5
    {GPIO_PIN_6, GPIO_PIN_7}  // Digito 4: Verde PC6, Rojo PC7
};

void Hardware_Init(ADC_HandleTypeDef* hadc, I2C_HandleTypeDef* hi2c) {
    lcd_init();
    lcd_clear();
    // Reiniciamos ADC para sincronizar
    HAL_ADC_Stop(hadc);
    HAL_Delay(10);
    HAL_ADC_Start(hadc);
}

void Leer_Potenciometros(int* valores_0_9) {
    // Modo DISCONTINUO (Paso a paso):
    // El ADC sabe que tiene una lista de 4 canales (Ranks 1, 2, 3, 4).
    // Cada vez que llamamos a START, lee EL SIGUIENTE de la lista y se para solo.

    for(int i=0; i<4; i++) {
        // 1. "¡Dispara!" -> Lee un solo potenciómetro (el que toque ahora)
        HAL_ADC_Start(&hadc1);

        // 2. Esperamos a que termine (Timeout generoso de 100ms)
        if (HAL_ADC_PollForConversion(&hadc1, 100) == HAL_OK) {

            // 3. Cogemos el dato
            uint32_t lectura = HAL_ADC_GetValue(&hadc1);

            // 4. Convertimos a 0-9
            // Usamos 4100 en vez de 4095 para evitar que salga un 10 por error
            valores_0_9[i] = (lectura * 10) / 4100;

        } else {
            // Si falla la lectura, ponemos un 0 (para detectar errores)
            valores_0_9[i] = 0;
        }

        // No hace falta HAL_ADC_Stop() porque en modo Discontinuo se para solo.
    }
}

void Actualizar_LED_Digito(int index, ColorLED color) {
    // 1. APAGAR TODO PRIMERO (Reset)
    // Esto es lo que se ejecuta siempre. Si no entra en los 'if' de abajo, se queda apagado.
    HAL_GPIO_WritePin(PUERTOS_LED[index][0], PINES_LED[index][0], GPIO_PIN_RESET); // Apaga Verde
    HAL_GPIO_WritePin(PUERTOS_LED[index][1], PINES_LED[index][1], GPIO_PIN_RESET); // Apaga Rojo

    // 2. ENCENDER SEGÚN EL COLOR
    if (color == VERDE) {
        // Solo encendemos el pin Verde
        HAL_GPIO_WritePin(PUERTOS_LED[index][0], PINES_LED[index][0], GPIO_PIN_SET);
    }
    else if (color == ROJO) {
        // Solo encendemos el pin Rojo
        HAL_GPIO_WritePin(PUERTOS_LED[index][1], PINES_LED[index][1], GPIO_PIN_SET);
    }
    else if (color == AMARILLO) {
        // --- AQUÍ ESTABA EL FALLO ---
        // Para hacer amarillo en un LED RGB, encendemos ROJO y VERDE a la vez
        HAL_GPIO_WritePin(PUERTOS_LED[index][0], PINES_LED[index][0], GPIO_PIN_SET); // Verde ON
        HAL_GPIO_WritePin(PUERTOS_LED[index][1], PINES_LED[index][1], GPIO_PIN_SET); // Rojo ON
    }
}

void Apagar_Todos_LEDs() {
    for(int i=0; i<4; i++) Actualizar_LED_Digito(i, APAGADO);
}

void Zumbador_Tono(int duracion_ms, int tipo) {
    // Generación de tono simple bloqueante
    // tipo 0 = Error (Grave), tipo 1 = Acierto (Agudo)
    for(int i=0; i<(duracion_ms/2); i++) {
        HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_5); // Pin PB5
        HAL_Delay(tipo == 0 ? 2 : 1);
    }
    HAL_GPIO_WritePin(GPIOB, GPIO_PIN_5, GPIO_PIN_RESET);
}
