#ifndef INC_LOGICA_JUEGO_H_
#define INC_LOGICA_JUEGO_H_

#include "main.h"
#include <stdbool.h>

// Estados de la máquina
typedef enum {
    ESTADO_ESPERA,
    ESTADO_GENERAR,
    ESTADO_JUGANDO,
    ESTADO_VERIFICAR,
    ESTADO_VICTORIA,
    ESTADO_DERROTA
} EstadoJuego;

// Declaramos 'extern' para que main.c pueda ver el estado si quiere
extern EstadoJuego estado_actual;

// Funciones principales
void Logica_Inicializar(void);
void Logica_Ejecutar_Ciclo(void);

// Función llamada por la interrupción del Timer
void Logica_Timer_Callback(void);

#endif /* INC_LOGICA_JUEGO_H_ */
