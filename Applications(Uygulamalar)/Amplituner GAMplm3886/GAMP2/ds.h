/* Obs³uga potencjometru cyfrowego DALLAS DS1267 */

#include <avr/io.h>
#include "delay.h"

//======================================================================================

#define	 DS_PORT	 PORTD
#define	 DS_DDR 	 DDRD 	
#define	 DS_DATA	 4	
#define	 DS_CLK    	 6
#define	 DS_RST    	 5

#define	 DS_RST_0	 cbi(DS_PORT,DS_RST);
#define	 DS_CLK_0	 cbi(DS_PORT,DS_CLK);
#define	 DS_DATA_0   cbi(DS_PORT,DS_DATA);
#define	 DS_RST_1    sbi(DS_PORT,DS_RST);
#define	 DS_CLK_1    sbi(DS_PORT,DS_CLK);
#define	 DS_DATA_1   sbi(DS_PORT,DS_DATA);
#define  DS_CLOCK	 DS_CLK_1; DS_CLK_0;        //impuls zegarowy

//======================================================================================

void ds1267_init(void);												// inicjalizacja DS1267 
void ds1267_write(unsigned char pot_0, unsigned char pot_1);        // zapis do uk³adu DS1267

