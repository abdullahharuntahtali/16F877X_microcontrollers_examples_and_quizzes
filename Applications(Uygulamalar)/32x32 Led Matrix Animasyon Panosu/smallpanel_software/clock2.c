#include <inttypes.h>
#include <avr/io.h>
//#include <avr/pgmspace.h>

#include "ks0108.h"
//#include "font12x16.h"
//#include "font6x8.h"

//const char pgmString[] PROGMEM = "http://www.apeTech.de\n\nme@apetech.de";

//void wait(unsigned int d) 
//	{
//	volatile unsigned int s;
//	for (s=0;s<d;s++) asm ("nop");
//	}

void wait(unsigned int d) 
{
	volatile unsigned int s;
	for (s=0;s<d;s++) asm("nop");
}

/*
 * define endpoints of clock-pointers
 */
__attribute__ ((progmem)) char number[]=
  {
       0,-15,
       7,-13,
      13, -7,
      15,  0,
      13,  7,
       7, 13,
       0, 15,
      -7, 13,
     -13,  7,
     -15,  0,
     -13, -7,
      -7,-13 
  };

/*
 * define endpoints of clock-pointers
 */
__attribute__ ((progmem)) char pointer[]=
  {
        0,-14,  0,-10 ,
        1,-14,  1,-10 ,
        3,-14,  2,-10 ,
        4,-13,  3, -9 ,
        5,-13,  4, -9 ,
        7,-12,  5, -9 ,
        8,-11,  6, -8 ,
        9,-10,  7, -7 ,
       10, -9,  7, -7 ,
       11, -8,  8, -6 ,
       12, -7,  9, -5 ,
       13, -5,  9, -4 ,
       13, -4,  9, -3 ,
       14, -3, 10, -2 ,
       14, -1, 10, -1 ,
       14,  0, 10,  0 ,
       14,  1, 10,  1 ,
       14,  3, 10,  2 ,
       13,  4,  9,  3 ,
       13,  5,  9,  4 ,
       12,  7,  9,  5 ,
       11,  8,  8,  6 ,
       10,  9,  7,  7 ,
        9, 10,  7,  7 ,
        8, 11,  6,  8 ,
        7, 12,  5,  9 ,
        5, 13,  4,  9 ,
        4, 13,  3,  9 ,
        3, 14,  2, 10 ,
        1, 14,  1, 10 ,
        0, 14,  0, 10 ,
       -1, 14, -1, 10 ,
       -3, 14, -2, 10 ,
       -4, 13, -3,  9 ,
       -5, 13, -4,  9 ,
       -7, 12, -5,  9 ,
       -8, 11, -6,  8 ,
       -9, 10, -7,  7 ,
      -10,  9, -7,  7 ,
      -11,  8, -8,  6 ,
      -12,  7, -9,  5 ,
      -13,  5, -9,  4 ,
      -13,  4, -9,  3 ,
      -14,  3,-10,  2 ,
      -14,  1,-10,  1 ,
      -14,  0,-10,  0 ,
      -14, -1,-10, -1 ,
      -14, -3,-10, -2 ,
      -13, -4, -9, -3 ,
      -13, -5, -9, -4 ,
      -12, -7, -9, -5 ,
      -11, -8, -8, -6 ,
      -10, -9, -7, -7 ,
       -9,-10, -7, -7 ,
       -8,-11, -6, -8 ,
       -7,-12, -5, -9 ,
       -5,-13, -4, -9 ,
       -4,-13, -3, -9 ,
       -3,-14, -2,-10 ,
       -1,-14, -1,-10  
  };

  int  i;
  int  hh,mm,ss;

  hh=2;
  mm=15;
  ss=0;

  do
  {
  	ks0108DrawRect(122,0,127,5);
	  PORTD ^= _BV(PD4);
    /* Ziffernblatt */
    for (i=0;i<24;i+=2)
      ks0108SetDot(15+PRG_RDB(number+i),15+PRG_RDB(number+i+1), 3);
  
    /* Minutenzeiger */
  	PORTD ^= _BV(PD5);
    ks0108DrawLine(15,15,15+PRG_RDB(pointer+mm*4),15+PRG_RDB(pointer+mm*4+1);
  
    /* Stundenzeiger */
  	PORTD ^= _BV(PD6);
  	ks0108DrawLine(15,15,15+PRG_RDB(pointer+(hh*5+mm/12)*4+2),15+PRG_RDB(pointer+(hh*5+mm/12)*4+3));
  
    /* Sekundenzeiger */
  	PORTD ^= _BV(PD7);
    ks0108DrawLine(15,15,15+PRG_RDB(pointer+ss*4+2),15+PRG_RDB(pointer+ss*4+3));
  	PORTD ^= _BV(PD0);
  
    ss++;
    if (ss>59)
    {
      ss=0;
      mm++;
      if (mm>59)
      {
        mm=0;
        hh++;
        if (hh>12)
          hh=0;
      }
    }
    delay(100);
  }
  while (1);
}



int main(void) 
{
	volatile uint16_t i;
//	struct font largeFont, smallFont;
	
	for(i=0; i<30000; i++);
	
/*	
	largeFont.width = FONT12X16_WIDTH;
	largeFont.height = FONT12X16_HEIGHT;
	largeFont.charData = Font12x16;
	
	smallFont.width = FONT6X8_WIDTH;
	smallFont.height = FONT6X8_HEIGHT;
	smallFont.charData = Font6x8;
*/	
	DDRD=0xFF;
	LCD_CMD_DIR = 0xFF;								// command port is output
	LCD_CMD_PORT |= 0x20;			// Set RESET-Pin HIGH

	ks0108Init();
	
	// Invertiert das Display
	/*
	ks0108SetInverted(1);
	ks0108Fill(CLEAR);
	
	
	ks0108GotoXY(0,4);
	ks0108PutString("Hallo Welt", largeFont);
	ks0108GotoXY(0,28);
	ks0108PutStringP(pgmString, smallFont);
*/	
	// Malt ein Nikolaus-Haus :)
		
	ks0108DrawLine(10,60,10,30);			//links
	ks0108DrawLine(60,60,60,30);			//rechts
	ks0108DrawLine(10,60,60,60);			//unten
	ks0108DrawLine(10,30,60,30);			//oben
	ks0108DrawLine(10,30,35,5);				//dach links
	ks0108DrawLine(35,5,60,30);				//dach rechts
	ks0108DrawLine(10,60,60,30);			//schräge1
	ks0108DrawLine(10,30,60,60);			//schräge2
	for(i=0; i<60000; i++);
	PORTD ^= _BV(PD0);
	ks0108Fill(CLEAR);
	PORTD ^= _BV(PD1);
	ks0108DrawRect(1,1,32,32);
	PORTD ^= _BV(PD2);
	wait(65535);
	wait(65535);
	wait(65535);
	wait(65535);
	
	PORTD ^= _BV(PD3);
	
//	AnalogClock();

	while(1);
}
