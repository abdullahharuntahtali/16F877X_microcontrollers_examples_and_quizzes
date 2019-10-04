/**
* @file serial.h
*
* Copyright (c) 2005 Atmel.
*
* @brief This module provide function's prototypes for AT90PWM3 Only
* @version 1.0 (CVS revision : $Revision: 1.4 $)      
* @date $Date: 2005/05/02 14:48:01 $    
* @author $Author: gallain $ 
*****************************************************************************/

void init_uart(void);
void initbootuart();
void sendchar( char );
char recchar( void );
char tstrx(void);
void putstring(char *str);
void putint(int number);
void putU8(U8 number);
void putS16(S16 number);
