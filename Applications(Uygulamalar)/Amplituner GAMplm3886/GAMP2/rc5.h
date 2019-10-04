/* funkcje obs³ugi pilota RC-5 MAK2002 Maxi */

#include <avr/timer.h>

//======================================================================================
// pilot zaprogramowany kodem 4055

#define IR_POWER		  61   		   // adres 95
#define IR_SLEEP		  38           // adres 95
#define IR_MUTE		  	  13           // adres 87
#define IR_PROG_PLUS	  32           // adres 81
#define IR_PROG_MINUS	  33           // adres 81
#define IR_CD		  	  81           // komenda IR_INPUT_SELECT
#define IR_TUNER	  	  85           // komenda IR_INPUT_SELECT
#define IR_DVD		  	  84           // komenda IR_INPUT_SELECT
#define IR_PC		  	  83           // komenda IR_INPUT_SELECT            		
#define IR_VOL_UP		  26           // adres 87
#define IR_VOL_DOWN	  	  27           // adres 87
#define IR_BASS_UP		  22           // adres 87
#define IR_BASS_DOWN	  23           // adres 87
#define IR_TREBLE_UP	  24           // adres 87
#define IR_TREBLE_DOWN	  25           // adres 87
#define IR_INPUT_SELECT	  63           // komenda 63      
#define IR_DIGIT		  81		   // adres przyciskow klawiatury numerycznej i programow 

//======================================================================================

unsigned char get_ir(void);            // odbiera kod RC5

