#ifndef INC_I2C_LCD_H_
#define INC_I2C_LCD_H_

#include "stm32f4xx_hal.h"

void lcd_init (void);   // Inicializar pantalla
void lcd_send_cmd (char cmd);  // Enviar comando interno
void lcd_send_data (char data);  // Enviar letra/número
void lcd_send_string (char *str);  // Enviar frase completa
void lcd_put_cur(int row, int col);  // Mover cursor
void lcd_clear (void);  // Borrar pantalla

#endif
