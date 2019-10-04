/*
 * LED Matrix display driver (main function and tcpip routines)
 *
 * Controlling several LED Matrix Modules Samsung SLM1606M/SLM1608M
 * connected to port B/D of Ethernut:
 *
 * Printer   Module
 * -----------------
 * D0 (2)    SELECT (CN2-2)
 * D1 (3)    RED    (CN3-2)
 * D2 (4)    GREEN  (CN3-4)
 * D3 (6)    CLOCK  (CN3-6)
 * D4 (8)    BRIGHT (CN3-8)
 * D5 (9)    RESET  (CN3-10)
 * GND (20)  GND    (CN3-3)
 *
 * Written by Thorsten Erdmann 06/2003 (thorsten.erdmann@gmx.de)
 */

/**************************************************************
 **** CAUTION: The module can be destroyed if applied      ****
 ****          static signals, so NEVER interrupt the      ****
 ****          program without switching off module's      ****
 ****          power source first !!!                      ****
 **************************************************************/
 
#include <inttypes.h>
#include <avr/pgmspace.h>
#include <avr/interrupt.h>
#include <string.h>
#include <stdio.h>
#include <avr/io.h>

//#include <uart.h>
#include "serial.h"

#include "led.h" 
#include "led_asm.h"
#include "parser.h"
#include "dataflash.h"
#include "be_happy.c"
#include "matrix.c"
#include "application.h"

const char vbanner_P[] PROGMEM="\r\nLED Matrix Display - FW 1.0 %s\r\n";
const char banner_P[] PROGMEM="\r\nLED Matrix Display\r\nType 'help' for a list of available commands\r\n";
const char init0[] PROGMEM ="Initialize LED Panel...\r\n";
const char init1[] PROGMEM ="Checking Dataflash: %s\r\n";

#define BTN_ACTION 0x04
#define BTN_UP     0x10
#define BTN_DOWN   0x80
#define BTN_LEFT   0x40
#define BTN_RIGHT  0x08

int cx=0;
int cy=0;

  
/*
 * read a line from a stream with echo and BS support
 */
void readln(char *line, u_char len, FILE *stream)
{
	u_char x=0;
  u_char ch;
  *line=0;
  do
  {
//  	if (stream==stdin)
//  	  ch=UartGetChar();
//  	else  
      ch=fgetc(stream);
    switch (ch)
    {
      case 0x08:
      case 0x7f:
        if (x>0)
        {
          line[--x]=0;
          fputc(ch,stream);
          fputc(' ',stream);
          fputc(ch,stream);
//          fflush(stream);
        }
        break;
      default:
        if (ch>=' ')
        {
          if (x<len)
          {
            fputc(ch,stream);
//            fflush(stream);
            line[x++]=ch;
            line[x]=0;
          }
        }
    }
  } while ((ch!='\n')&&(ch!='\r'));
}

void delay(u_char t)
{
	u_char x,y;
	t++;
	do
	{
		for (y=0;y<0x50;y++)
		  for (x=0;x<0xff;x++);
		t--;
	} while (t>0);
}

/*******************************************************************************
 *
 ******************************************************************************/
void ioinit(void)
{
	// set 38400 baud rate for 14,7Mhz CPU clock 
	UartInit(38400,HANDSHAKE_HARDWARE,0);
	sei();
}
	 

void move_cursor(void)
{
	static u_char oldcolor=BLACK;
	
	u_char key=~inp(PINE);
	if (key&BTN_ACTION) 
	{
	  if (oldcolor<YELLOW)
	    oldcolor++;
	  else
	    oldcolor=BLACK;
	    
		LEDPixel(cx,cy,oldcolor);
		LEDDraw();
	}
	else
	{    
	  if (key&(BTN_LEFT+BTN_RIGHT+BTN_UP+BTN_DOWN)) 
	  {
		  LEDPixel(cx,cy,oldcolor);
	    if (key&BTN_UP)
	    {
	      if (cy>0)
	        cy--;
	      else
	        cy=MAXY-1;  
	    }
	        
	    if (key&BTN_DOWN)
	    {
	      if (cy<MAXY-1)
	        cy++;
	      else
	        cy=0;
	    }
	          
	    if (key&BTN_LEFT)
	    {
	      if (cx>0)
	        cx--;
	      else
	        cx=MAXX-1;  
	    }
	        
	    if (key&BTN_RIGHT)
	    {
	      if (cx<MAXX-1)
	        cx++;
	      else
	        cx=0;  
	    }
	        
	    oldcolor=LEDGetPixel(cx,cy);
		  LEDPixel(cx,cy,YELLOW);
		  LEDDraw();
	  }
  }
}

void ShowScreen(void)
{
	u_char x,y;
	putchar('\n');
	for (y=0;y<MAXY;y++)
	{
		for (x=0;x<MAXX;x++) putchar('0'+LEDGetPixel(x,y));
		putchar('\n');
	}
}

/*
 * Main application routine. 
 */
int main(void)
{
  
	char  line[200];
	int x;
	PGM_P bm;

	// set 115200 baud rate for 14,7Mhz CPU clock 
	UartInit(38400,HANDSHAKE_HARDWARE,0);

	// we don't need store returned stream because first call
	// to the fdevopen will assign them to stdin and stdout
	//fdevopen(uart_putchar, UART_get, 0);
  
  puts_P(init0);
  LEDInit();
  sei();
  
  LEDClear();
//  outp(0x00,EIMSK);
//  outp(0x80,ACSR);
  DF_get_type(line);
  printf_P(init1,line);
  
  /* Port E is input. */
  //outp(0x00, DDRE);
  /* Port E pullup on */
  //outp(0xff, );
/*  
  do
  {
  	move_cursor();
    delay(1);
  } while (1);
*/  

/*
  LEDHLine(0,0,5,1);
  LEDHLine(MAXX-5,0,5,1);
  LEDHLine(0,MAXY-1,5,1);
  LEDHLine(MAXX-5,MAXY-1,5,1);
  LEDVLine(0,0,5,2);
  LEDVLine(0,MAXY-5,5,2);
  LEDVLine(MAXX-1,0,5,2);
  LEDVLine(MAXX-1,MAXY-5,5,2);
 	LEDLine(0,0,MAXX-1,MAXY-1,YELLOW);
 	LEDLine(0,MAXY-1,MAXX-1,0,YELLOW);
 	LEDDraw();
 	while(1);
*/
  LEDRectangle(0,0,20,18,YELLOW);
  LEDRectangle(20,0,MAXX-20,18,YELLOW);
  LEDRectangle(0,20,MAXX,12,GREEN);
  LEDDraw();
  LEDSStr(1,21,MAXX-2,0x10+TE_LEFT,RED,"LED Matrix Display \x01Red \x02Green \x03Yellow");
  LEDABitmap(1,5,GREEN,matrix_P);
  LEDABitmap(21,5,RED,be_happy_P);
/*
  while (1)
  {
    delay(100);
    LEDCircle(16,16,15,YELLOW);
    LEDCircle(16,16,13,RED);
    LEDCircle(16,16,11,GREEN);
    LEDDraw();
    delay(100);
    LEDClear();
    LEDDraw();
  }
*/
  
  x=0;
  for (;;)
  {
  	LEDNumout(x,6);
  	printf("\n>");
  	readln(line,sizeof(line),stdin);
//  	printf("\n=%s",line);
  	Processline(line,stdin);
  	x++; if (x>9999) x=0;
  }
}
