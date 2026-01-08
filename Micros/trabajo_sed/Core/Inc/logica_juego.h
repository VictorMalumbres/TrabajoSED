#ifndef INC_LOGICA_JUEGO_H_
#define INC_LOGICA_JUEGO_H_

#include <stdbool.h>

// Estados de la Máquina (FSM) - Requisito Obligatorio
typedef enum {
    ESTADO_ESPERA,
    ESTADO_GENERAR,
    ESTADO_JUGANDO,
    ESTADO_VERIFICAR,
    ESTADO_VICTORIA,
    ESTADO_DERROTA
} EstadoJuego;

void Logica_Inicializar(void);
void Logica_Ejecutar_Ciclo(void);
void Callback_Boton_Validar(void);
void Callback_Boton_Inicio(void);

#endif
