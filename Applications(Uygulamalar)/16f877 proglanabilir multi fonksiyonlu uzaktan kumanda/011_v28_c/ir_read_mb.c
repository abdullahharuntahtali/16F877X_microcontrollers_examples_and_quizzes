

void ir_read(void);	// IR routines
void ir_get_rise(void);
void ir_get_fall(void);
void ir_build_bytes(void);


////////////////////////////////////////////////////////////////////////////////////////////
void ir_read(void)
{
ir_tempbyte_hi=0;
ir_tempbyte_lo=0;
protocol=0;
rx_status=0;			// reset rx_status to error code 0

while(CP1);				// wait for minimal pre which stays low
// ir_seek_sequence_start();	
ir_get_rise();			// get headp & heads to see what protocol it is
headp=rise;
ir_get_fall();
heads=fall;


			
if ((headp>8800)&&(headp<9090)&&(heads>4200)&&(heads<4570)){protocol=2;}			// NEC
		
else if ((headp>2340)&&(headp<2480)&&(heads>470)&&(heads<575)){protocol=4;}			// SIRCS

else if ((headp>680)&&(headp<970)&&(heads>680)&&(heads<885)){protocol=5;}			// RC5

else if ((headp>3300)&&(headp<3590)&&(heads>1500)&&(heads<1695)){protocol=7;}		// JAPAN
	
else if ((headp>4305)&&(headp<4695)&&(heads>4200)&&(heads<4550)){protocol=8;}		// SAMSUNG

// end if;

if (protocol>0){rx_status=2;ir_build_bytes();} // got sequence_start, now trying to read data bits
	
else if (protocol==0){rx_status=1;}	// check: return if no prtocol recognized, set rx_status to error code 1


// else return;

delay_ms(100);	// only for test
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void ir_get_rise(void){

setup_counters(RTCC_INTERNAL,RTCC_DIV_1); 	// get high
setup_timer_1(T1_INTERNAL|T1_DIV_BY_1);
set_timer1(0);
while(!CP1);       	// wait for signal to go high 	// RC2, CCP1, pin 17
rise = get_timer1();

}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void ir_get_fall(void){

setup_counters(RTCC_INTERNAL,RTCC_DIV_1);	// get low
setup_timer_1(T1_INTERNAL|T1_DIV_BY_1);
set_timer1(0);
while(CP1);       	// wait for signal to go low 
fall = get_timer1();

}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void ir_build_bytes(void)
{

if (protocol==2){				// if NEC protocol	************************************************************

		
	for (bitcount=0;bitcount!=32;bitcount++){

		ir_get_rise();
		ir_get_fall();
		if ((rise>450)&&(rise<650)&&(fall>1400)&&(fall<1655)){ir_tempbyte_hi|=1;}	// bit=1
		else if	((rise>450)&&(rise<650)&&(fall>390)&&(fall<600)){;}					// bit=0
		else return;																// error detection		

		if (bitcount<31){ir_tempbyte_hi<<=1;}		// don't shift last bit
														}

	if (bitcount==32)rx_status=3;	// reception is valid

				}



if (protocol==4){				// if SIRCS protocol	************************************************************

		
	for (bitcount=0;bitcount!=11;bitcount++){

		ir_get_rise();
		ir_get_fall();
		if ((rise>1050)&&(rise<1250)&&(fall>400)&&(fall<620)){ir_tempbyte_hi|=1;}	// bit=1
		else if	((rise>400)&&(rise<620)&&(fall>400)&&(fall<620)){;}					// bit=0
		else return;																// error detection

		ir_tempbyte_hi<<=1;		
														}


	ir_get_rise();
		if ((rise>1050)&&(rise<1250)&&(fall>400)&&(fall<620)){ir_tempbyte_hi|=1;bitcount++;}		// last bit=1
		else if	((rise>400)&&(rise<620)&&(fall>400)&&(fall<620)){bitcount++;}					// last bit=0

	if (bitcount==12)rx_status=3;	// reception is valid

				}




else if (protocol==5){			// if RC5 protocol	************************************************************


	bit_prev=1;		// start bit was 1	
	sample_RC5=0;
	
	for (bitcount=0;bitcount!=12;){
	

		if (!CP1){
		ir_get_rise();
		if ((rise>600)&&(rise<970)){sample_RC5=1;}
		else if ((rise>1500)&&(rise<1720)){sample_RC5=3;}
		else return; 	// error detection
					}


		else if (CP1){
		ir_get_fall();
		if ((fall>600)&&(fall<970)){sample_RC5=0;}
		else if ((fall>1500)&&(fall<1720)){sample_RC5=2;}
		else return; 	// error detection
					}
		

		if (sample_RC5>1){bit_RC5^=bit_prev; ir_tempbyte_hi|=bit_RC5; bitcount++; bit_prev=bit_RC5;}
		else if (sample_RC5==1){bit_RC5=bit_prev; ir_tempbyte_hi|=bit_RC5; bitcount++; bit_prev=bit_RC5;}
		else if (sample_RC5==0);

			
		if ((sample_RC5>0)&&(bitcount<12)){ir_tempbyte_hi<<=1;}

										}

	rx_status=3;	// reception is valid

				}


else if (protocol==7){				// if JAPAN protocol	************************************************************

		
	for (bitcount=0;bitcount!=32;bitcount++){

		ir_get_rise();
		ir_get_fall();
		if ((rise>300)&&(rise<500)&&(fall>1000)&&(fall<1450)){ir_tempbyte_hi|=1;}	// bit=1
		else if	((rise>300)&&(rise<500)&&(fall>250)&&(fall<450)){;}					// bit=0
		else return;																// error detection

		if (bitcount<31){ir_tempbyte_hi<<=1;}		// don't shift last bit
														}

	for (bitcount=32;bitcount!=48;bitcount++){

		ir_get_rise();
		ir_get_fall();
		if ((rise>300)&&(rise<500)&&(fall>1000)&&(fall<1450)){ir_tempbyte_lo|=1;}	// bit=1
		else if	((rise>300)&&(rise<500)&&(fall>250)&&(fall<450)){;}					// bit=0
		else return;																// error detection

		if (bitcount<47){ir_tempbyte_lo<<=1;}		// don't shift last bit
														}




	if (bitcount==48)rx_status=3;	// reception is valid

				}


else if (protocol==8){			// if SAMSUNG protocol	************************************************************

		
	for (bitcount=0;bitcount!=32;bitcount++){

		ir_get_rise();
		ir_get_fall();
		if ((rise>380)&&(rise<670)&&(fall>1250)&&(fall<1750)){ir_tempbyte_hi|=1;}	// bit=1
		else if	((rise>380)&&(rise<670)&&(fall>300)&&(fall<650)){;}					// bit=0
		else return;																// error detection

		if (bitcount<31){ir_tempbyte_hi<<=1;}		// don't shift last bit
														}

	if (bitcount==32)rx_status=3;	// reception is valid

				}




}	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
