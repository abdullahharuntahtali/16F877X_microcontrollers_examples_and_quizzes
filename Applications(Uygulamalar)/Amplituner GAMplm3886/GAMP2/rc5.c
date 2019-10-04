/* funkcje obs³ugi pilota RC-5 MAK2002 Maxi */

#include "types.h"
#include "rc5.h"

//======================================================================================
// odbiera kod RC5
unsigned char get_ir(void)				
{
	unsigned char i, T2, time, tmp = 0;

	timer0_source(CK256);							// prescaler timera 0 na ok. 32us
	timer0_start();									// uruchom timer
	loop_until_bit_is_set(IR_PIN,IR_BIT);			// pomiñ nag³ówek

	for(i=0; i<13; i++)				 				// pozosta³o 13 bitów
	{
 	    if(bit_is_clear(IR_PIN,IR_BIT))
  		 T2 = 0;				   		   			// aktualnie jest 1
        else
		 T2 = 1;									// aktualnie jest 0

        timer0_start();								// uruchom timer
		while(1)
		{
  		    time = inp(TCNT0);
			if(time>0x21)							// przekroczenie czasu bitu ?
			return 0;								// b³¹d
			
			// narastaj¹ce zbocze w po³owie bitu ?
			if(bit_is_clear(IR_PIN,IR_BIT) && (T2==1))
			{
			    tmp<<=1;				   // tak - przesuñ wynik
			    tmp++;					   // i zapisz "1"
			    break;
			}
			// opadaj¹ce zbocze w po³owie bitu ?
			else if(bit_is_set(IR_PIN,IR_BIT) && (T2==0))
			{
			    tmp<<=1;				  // tak - przesun wynik
			    break;					  // i zapisz "0"
			}
		}

		// zapamiêtanie adresu urz¹dzenia
		if(i==6)
		{					   			 // zapisz adres i
			rc5.adres = (tmp & 0x5f); 	 // obetnij troggle bit
			tmp = 0;				   	 // zeruj bajt odbioru
		}

		timer0_start();					 // opóŸnienie o 3 czasu bitu
		while(1)
		{
			time = inp(TCNT0);
			if(time>0x21)
	  		 break;
		}
    }
		
    rc5.komenda = tmp;					// zapamiêtanie kodu komendy
	return 1;	  						// poprawne odebranie kodu pilota					
}

//======================================================================================

