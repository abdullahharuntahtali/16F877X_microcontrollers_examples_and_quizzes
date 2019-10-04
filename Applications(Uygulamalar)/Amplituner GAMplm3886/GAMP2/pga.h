/* Obs³uga regulatora wzmocnienia Burr-Brown PGA2310 */

#include <avr/io.h>
#include "delay.h"

//======================================================================================

#define PGA_PORT   PORTC
#define PGA_DDR	   DDRC
#define	PGA_CS	   5
#define	PGA_DATA   4
#define	PGA_CLK	   3
#define	PGA_MUTE   2

#define	PGA_CS_1       sbi(PGA_PORT,PGA_CS);
#define	PGA_CS_0       cbi(PGA_PORT,PGA_CS);
#define	PGA_DATA_1	   sbi(PGA_PORT,PGA_DATA);
#define	PGA_DATA_0	   cbi(PGA_PORT,PGA_DATA);
#define	PGA_CLK_1	   sbi(PGA_PORT,PGA_CLK);
#define	PGA_CLK_0	   cbi(PGA_PORT,PGA_CLK);
#define PGA_CLOCK	   PGA_CLK_1; PGA_CLK_0;	      			  	    // impuls zegarowy

//======================================================================================

void pga2310_init(void);                                                // inicjalizacja PGA2310
void pga2310_write(unsigned char left, unsigned char right); 			// zapis do PGA2310
