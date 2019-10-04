/* Obs³uga regulatora wzmocnienia Burr-Brown PGA2310 */

#include "types.h"
#include "pga.h"
#include "audio.h"

//======================================================================================
// inicjalizacja PGA2310
void pga2310_init(void)
{
	sbi(PGA_DDR,PGA_CS); 					// piny jako wyjscia
	sbi(PGA_DDR,PGA_CLK);
	sbi(PGA_DDR,PGA_DATA);
	sbi(PGA_DDR,PGA_MUTE);
	mute_on();
	PGA_CS_1
}

//======================================================================================
// zapis do PGA2310
void pga2310_write(unsigned char left, unsigned char right)
{
	unsigned char i;
	
	PGA_CS_0
	
	for(i=0;i<8;i++) 	  		 	  		// zapis bajtu kana³u prawego
	{
	    if(bit_is_set(right,7))
		 PGA_DATA_1
        else
		 PGA_DATA_0
		 
		 PGA_CLOCK
		 right <<= 1;
	}
	
	for(i=0;i<8;i++) 		   				// zapis bajtu kana³u lewego
	{
	    if(bit_is_set(left,7))
		 PGA_DATA_1
        else
		 PGA_DATA_0
		
		 PGA_CLOCK
		 left <<= 1;
	}
		
	PGA_CS_1 	
}

//======================================================================================


