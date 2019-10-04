/* Obs³uga potencjometru cyfrowego DALLAS DS1267 */

#include "ds.h"

//======================================================================================
// inicjalizacja DS1267  	
void ds1267_init(void)
{
	sbi(DS_DDR,DS_RST);	            // piny jako wyjscia
	sbi(DS_DDR,DS_CLK);
	sbi(DS_DDR,DS_DATA);
	DS_RST_0
	DS_CLK_0
	DS_DATA_0
}

//======================================================================================
// zapis do uk³adu DS1267
void ds1267_write(unsigned char pot_0, unsigned char pot_1)
{
	unsigned char i;
		
	DS_RST_1        	      	
	DS_CLOCK                   // impuls zegarowy dla 'Stack Select Bit'

	// treble
	for(i=0;i<8;i++)
	{
	    if(bit_is_set(pot_0,7))
	     DS_DATA_1
	    else
	     DS_DATA_0

	    DS_CLOCK
	    pot_0 <<= 1;		   // nastepny bit
	}
	
	// bass
	for(i=0;i<8;i++)
	{
	    if(bit_is_set(pot_1,7))
	     DS_DATA_1
	    else
	     DS_DATA_0

	    DS_CLOCK
	    pot_1 <<= 1;		   // nastepny bit
	}
			
	DS_RST_0					
}

//======================================================================================



