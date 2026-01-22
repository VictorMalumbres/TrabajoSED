#ifndef INC_LOGICA_JUEGO_H_
#define INC_LOGICA_JUEGO_H_

#include "main.h"
#include <stdbool.h>

typedef enum {
    ESTADO_ESPERA,
    ESTADO_GENERAR,
    ESTADO_JUGANDO,
    ESTADO_VERIFICAR,
    ESTADO_VICTORIA,
    ESTADO_DERROTA
} EstadoJuego;

extern EstadoJuego estado_actual;

// Funciones
void Logica_Inicializar(void);
void Logica_Ejecutar_Ciclo(void);
void Logica_Timer_Callback(void);

#endif /* INC_LOGICA_JUEGO_H_ */
