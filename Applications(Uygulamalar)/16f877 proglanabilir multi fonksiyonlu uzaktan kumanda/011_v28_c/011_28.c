////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*

Project 011 v28
Infrared remote control --- Multi-protocol: NEC, SIRCS, RC5, JAPAN, SAMSUNG.

CCS compiler

		
by Michel Bavin (c) february 26, 2004.



... enjoy !


Open source for personal or educational use only.

*/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include <16f877_mb.h>		// device selection  
	
#fuses XT,NOWDT,NOPROTECT,NOLVP,NOBROWNOUT,PUT
#use delay(clock=4000000) 	// 4 MhZ

#use fast_io(A)
#use fast_io(B)
#use fast_io(C)
#use fast_io(D)

#use rs232(baud=9600, invert, xmit=PIN_E0,rcv=PIN_E1)	// *************************************************************
// #zero_ram 

#byte analog	=0x05	//port a	// LED control
#byte keys		=0x06	//b
#byte ir		=0x07	//c			// IR control
#byte lcd		=0x08	//d
#byte reserved	=0x09	//port e	// reserved for rs232 interface

#byte tris_analog 		=0x85	//port a direction
#byte tris_keys			=0x86	//b
#byte tris_ir 			=0x87	//c
#byte tris_lcd			=0x88	//d
#byte tris_reserved 	=0x89	//port e	"


// LED bits
#bit LED_PROGR		=analog.0	// RA0	// LED 0
#bit LED_SPEC		=analog.1	// RA1	// LED 1
#bit LED_ADDR0		=analog.2	// RA2	// LED 2
#bit LED_ADDR1		=analog.3	// RA3	// LED 3
#bit LED_ADDR2		=analog.5	// RA5	// LED 5

// keys bits
#bit ROWKEYPRESS 	=keys.0	// RB0
#bit ROWMX0 		=keys.1
#bit ROWMX1			=keys.2
#bit ROWMX2  		=keys.3	// RB3

#bit COL0			=keys.4	// RB4
#bit COL1			=keys.5
#bit COL2			=keys.6
#bit COL3 			=keys.7	// RB7

// IR bits
#bit IR_RX_EN	=ir.0	// RC0 **** power for IR RX module
#bit CP2		=ir.1	// RC1 **** IR TX 37,1 kHz
#bit CP1		=ir.2	// RC2 **** IR RX 

//	RC3= SCL i²c
//	RC4= SDA i²c



// NOKIA_LCD bits
#bit nok_sclk 	=lcd.6	// RD6	
#bit nok_sda 	=lcd.7	// RD7
#bit nok_dc 	=lcd.0	// RD0
#bit nok_cs 	=lcd.3	// RD3
#bit nok_res 	=lcd.1	// RD1


unsigned char bitcount;
char speedtest;
//
#include <24256_mb.c>	// for ext eeprom
EEPROM_ADDRESS address;
//
#SEPARATE void ir_to_nokia(void);	
//
#SEPARATE void key_enc(void);
char key;
int16 key16;
int32 temp3;
//
#SEPARATE void keys_init_mode(void);
char device_0_key,device_1_key,device_2_key,device_3_key,device_4_key,device_5_key; // 7ff0 to 7ff7 
char current_device;	// 7ff8
char program_key;		// 7ff9	
char enter_key;		// 7ffa	
char keys_init_valid;	// 7ffb	: valid is 0xaa else unvalid
#SEPARATE void keys_init_sub();
//
#SEPARATE void menu(void);
//
#SEPARATE void program_mode(void);
//
#SEPARATE void transmit_mode(void);
int32 MSB3,MSB2,MSB1,MSB0,LSB1,LSB0;
int16 current_device16;
char y;
//

//
#SEPARATE void ir_tx(void);
byte tx_bit;
unsigned char tx_c;
//
char char_row,charsel,charpos,chardata; // for nokia_3310
int16 ddram;
#include <nokia_3310_mb.c>
short analyze;
//



//
void sleep_routine(void);	// for sleep mode
short sleep_mode;
char counter;
#INT_EXT 
void ext_isr(void);		   
//

//
unsigned char rx_status;	// for IR read routines
short bit_RC5,bit_prev;		
char sample_RC5;		
int32 ir_tempbyte_hi;
int16 ir_tempbyte_lo;
int16 headp,heads,rise,fall;
char protocol;
#include <ir_read_mb.c>
//

//
char temp2,value2;
int16 percent2;
int32 address2;
#SEPARATE void backup(void);
#SEPARATE void restore(void);

void show_led_addr(void);
//

////////////////////////////////////////////////////////////////////////////////////////////////// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//-------------------------------------------

void main(){

setup_adc_ports( NO_ANALOGS);	// portA is digital
tris_analog=0x00;	// portA is output (for LEDs)
analog=0x00;		// 
    
tris_ir=0xfe; 	// iiii iiio CP1, RC2 to input mode, disable TX
IR_RX_EN=0;		// disable RC0 **** power for IR RX module
output_low(PIN_C1); // Set CCP2 output low 
setup_ccp2(CCP_PWM);
setup_timer_2(T2_DIV_BY_1,26,1); 	// 37,1 kHz square wave on CCP1
set_pwm2_duty(13);

tris_ir=0xfe; 	// iiii iiio CP1, RC2 to input mode, disable TX



tris_keys=0x0f;	// oooo iiii

init_ext_eeprom();



sleep_mode=FALSE;          // init sleep flag
ext_int_edge(H_TO_L);      // init interrupt triggering for button press
enable_interrupts(INT_EXT);// turn on interrupts
enable_interrupts(GLOBAL);
counter=0;

speedtest=0;

nokia_init();				// nokia 3310 lcd init.

// analyze
analyze=read_ext_eeprom(0x7ffc);		// read analyze setting


keys_init_mode();


// **********************************

while(TRUE) 
  { 



menu();
sleep_routine();


      

	
 	} //end while 

} //end main 
/////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#INT_EXT 
void ext_isr(void){				// external interrupt definition for sleep mode
static short button_pressed=FALSE;	

	if(button_pressed){        // 
   	
		sleep_mode=FALSE;
		counter=0;
			
						}

	else{sleep_mode=TRUE;}
    
	if(!input(PIN_B0)){button_pressed=TRUE;}		
				

					}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void sleep_routine(void)
{

if (counter>4){sleep_mode=TRUE;}
   

if(sleep_mode){          // if sleep flag set

		nokia_gotoxy(0,2);
		printf(nokia_printchar,"Sleeping...   ");
		delay_ms(100);
        output_high(EEPROM_SCL); // eeprom forced to stand-by
		output_high(EEPROM_SDA);
		delay_ms(200);
		nokia_write_command(0x24);	// LCD power-off
		delay_ms(200);
		sleep();}             // make processor sleep

if(!sleep_mode){ 
		
		counter++;}              // sleep counter increment


}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#SEPARATE void ir_to_nokia(void)
{
// display all details

nokia_gotoxy(0,4);
if (protocol<10){printf(nokia_printchar,"%1u",protocol);} else {printf(nokia_printchar,"-");}

nokia_gotoxy(10,4);
printf(nokia_printchar,"b%03u",bitcount);

nokia_gotoxy(38,4);
printf(nokia_printchar,"%03u",speedtest);

if (key!=0){
	nokia_gotoxy(60,4);	
	printf(nokia_printchar,"k%03u",key);
			}


nokia_gotoxy(0,5);
printf(nokia_printchar,"%Lx",ir_tempbyte_hi);
nokia_gotoxy(54,5);
printf(nokia_printchar,"%lx",ir_tempbyte_lo);


}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#SEPARATE void key_enc(void)
{
/*
#bit ROWKEYPRESS 	=keys.0	// RB0
#bit ROWMX0 		=keys.1
#bit ROWMX1			=keys.2
#bit ROWMX2  		=keys.3	// RB7

#bit COL0			=keys.4	
#bit COL1			=keys.5
#bit COL2			=keys.6
#bit COL3 			=keys.7
*/

key=0;

for (temp3=0;temp3!=100000;temp3++){

 	

	keys=0xe0;	// col=1;
		if (!ROWKEYPRESS){key=((keys&0x0e)|0xe0); counter=0; break;}
	

	keys=0xd0;	// col=2;
		if (!ROWKEYPRESS){key=((keys&0x0e)|0xd0); counter=0; break;}

	
	keys=0xb0;	// col=3;
		if (!ROWKEYPRESS){key=((keys&0x0e)|0xb0); counter=0; break;}


	keys=0x70;	// col=4;
		if (!ROWKEYPRESS){key=((keys&0x0e)|0x70); counter=0; break;}					

									}



keys=0x00;	// select all columns (for wake-up from sleep)


}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#SEPARATE void keys_init_mode(void)
{
analog=0x00;		// LEDs off

keys_init_valid=read_ext_eeprom(0x7ffb);	// location in ext.eeprom for keys_init_valid

if (keys_init_valid!=0xaa){

	analog=0x02;
	nokia_gotoxy(0,0);
	printf(nokia_printchar,"Keys init:    ");
	nokia_gotoxy(0,2);
	printf(nokia_printchar,"Progam key?   ");
	address=0x7ff9;
	keys_init_sub();

	analog=0x2e;
	printf(nokia_printchar,"Enter key ?   ");
	address=0x7ffa;
	keys_init_sub();

	analog=0x06;
	printf(nokia_printchar,"Aux key   ?   ");
	address=0x7ff0;
	keys_init_sub();
	
	analog=0x0a;
	printf(nokia_printchar,"TV  key   ?   ");
	address=0x7ff1;
	keys_init_sub();
	
	analog=0x0e;
	printf(nokia_printchar,"HiFi key  ?   ");
	address=0x7ff2;
	keys_init_sub();

	analog=0x22;
	printf(nokia_printchar,"CD key    ?   ");
	address=0x7ff3;
	keys_init_sub();

	analog=0x26;
	printf(nokia_printchar,"DVD key   ?   ");
	address=0x7ff4;
	keys_init_sub();

	analog=0x2a;
	printf(nokia_printchar,"Video key ?   ");
	address=0x7ff5;
	keys_init_sub();

						
analog=0x00;		// LEDs off
printf(nokia_printchar,"init success !");
write_ext_eeprom(0x7ffb, 0xaa);	// validate keys_init_valid

delay_ms(2000);
nokia_erase_y(0);
nokia_erase_y(2);


							}	// end  "if (keys_init_valid!=0xaa)"


device_0_key= read_ext_eeprom(0x7ff0);	// Aux (mixed)
device_1_key= read_ext_eeprom(0x7ff1);	// TV
device_2_key= read_ext_eeprom(0x7ff2);	// HiFi
device_3_key= read_ext_eeprom(0x7ff3);	// CD
device_4_key= read_ext_eeprom(0x7ff4);	// DVD
device_5_key= read_ext_eeprom(0x7ff5);	// Video

current_device= read_ext_eeprom(0x7ff8);
program_key= read_ext_eeprom(0x7ff9);
enter_key= read_ext_eeprom(0x7ffa);

}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#SEPARATE void keys_init_sub()
{
key_enc();
	nokia_gotoxy(60,2);
	if (key!=0){
			write_ext_eeprom(address, key);
			printf(nokia_printchar,"=%03u",key);
				}
	else {printf(nokia_printchar,"_err");delay_ms(1500);reset_cpu();}
	delay_ms(1500);
	nokia_gotoxy(0,2);



}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#SEPARATE void menu(void)
{
speedtest+=1;
nokia_write_command(0x20);	// LCD power-on


// nokia_gotoxy(0,2);
if (current_device>5){current_device=0;}	//		check if there is a current_device selected
	

nokia_gotoxy(30,0);
// if (current_device>5){printf(nokia_printchar,"err-1");}
if (current_device==0){printf(nokia_printchar," Aux ");}
else if (current_device==1){printf(nokia_printchar," TV  ");}
else if (current_device==2){printf(nokia_printchar,"HiFi ");}
else if (current_device==3){printf(nokia_printchar," CD  ");}
else if (current_device==4){printf(nokia_printchar," DVD ");}
else if (current_device==5){printf(nokia_printchar,"Video");}

write_ext_eeprom(0x7ff8, current_device);
//

// 						transmit mode, program mode, backup or restore ?
nokia_gotoxy(0,2);
printf(nokia_printchar,"Select Task   ");

key_enc();


	if (key==program_key){program_mode();}
	else if (key==device_0_key){current_device=0;show_led_addr();delay_ms(10);}
	else if (key==device_1_key){current_device=1;show_led_addr();delay_ms(10);}
	else if (key==device_2_key){current_device=2;show_led_addr();delay_ms(10);}
	else if (key==device_3_key){current_device=3;show_led_addr();delay_ms(10);}
	else if (key==device_4_key){current_device=4;show_led_addr();delay_ms(10);}
	else if (key==device_5_key){current_device=5;show_led_addr();delay_ms(10);}
	else if (key==enter_key){if (analyze==0){analyze=1; write_ext_eeprom(0x7ffc, 0xff);
												nokia_gotoxy(0,2);	
												printf(nokia_printchar,"Details on    ");

												} else {
															analyze=0; write_ext_eeprom(0x7ffc, 0x00);
															nokia_gotoxy(0,2);
															printf(nokia_printchar,"Details off   ");
															// nokia_erase_y(3);
															nokia_erase_y(4);
															nokia_erase_y(5);
															}
								delay_ms(500);
									}
	else if (key!=0){transmit_mode();}


analog=0x00;		// LEDs off
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#SEPARATE void program_mode(void)
{


show_led_addr();

nokia_erase_y(4);
nokia_erase_y(5);



tris_ir=0xfe;	// disable TX
IR_RX_EN=1;		// enable RC0 = power on for IR RX module 


nokia_gotoxy(0,2);
printf(nokia_printchar,"Program Key ? ");
delay_ms(400);             // debounce button
key_enc();




if (key==program_key){
		analog=0x00;		// LEDs off
		LED_SPEC=1;
		nokia_gotoxy(0,2);
		printf(nokia_printchar,"Soft Reset  ? ");
		delay_ms(400);             // debounce button
		key_enc();
			if (key==enter_key){reset_cpu();}
			else if (key==program_key){
				LED_PROGR=1;
				nokia_gotoxy(0,2);
				printf(nokia_printchar,"Backup data ? ");
				delay_ms(400);             // debounce button
				key_enc();
					if (key==enter_key){backup();}
					else if (key==program_key){
						LED_SPEC=0;
						nokia_gotoxy(0,2);
						printf(nokia_printchar,"Restore data ?");
						delay_ms(400);             // debounce button
						key_enc();
							if (key==enter_key){restore();}	
							else if (key==program_key){
								LED_ADDR0=1;
								LED_ADDR1=1;
								LED_ADDR2=1;
								nokia_gotoxy(0,2);
								printf(nokia_printchar,"Reset init ?  ");
								delay_ms(400);             // debounce button
								key_enc();
								if (key==enter_key){write_ext_eeprom(0x7ffb, 0xff);reset_cpu();}	// unvalidate keys_init_valid


														}
												}
										}
					}

else if (key!=0){

	LED_PROGR=1;
	LED_SPEC=1;

	nokia_gotoxy(0,2);
	printf(nokia_printchar,"Waiting for IR");
	nokia_gotoxy(60,4);	
	printf(nokia_printchar,"k%03u",key);


	ir_read();		// ********************************************************************************************



	if (rx_status==3){
		LED_PROGR=0;
		LED_SPEC=1;

		nokia_gotoxy(0,2);
		printf(nokia_printchar,"OK,  RX valid ");

		if (analyze){ir_to_nokia();}



		key16=key;
		current_device16=current_device;
		address=(0x0000|(key16<<4)|(current_device16<<12));



		write_ext_eeprom(address, protocol);						// address + 0  // protocol
		write_ext_eeprom(address+1, bitcount);						// address + 1  // rx_bitcount

		write_ext_eeprom(address+7, (ir_tempbyte_lo)&0xff);			// address + 7  // LSB data
		write_ext_eeprom(address+6, ((ir_tempbyte_lo>>8)&0xff));	// address + 6  // 
		write_ext_eeprom(address+5, (ir_tempbyte_hi)&0xff);			// address + 5  // 
		write_ext_eeprom(address+4, ((ir_tempbyte_hi>>8)&0xff));	// address + 4  //
		write_ext_eeprom(address+3, ((ir_tempbyte_hi>>16)&0xff));	// address + 3  // 
		write_ext_eeprom(address+2, ((ir_tempbyte_hi>>24)&0xff));	// address + 2  // MSB data

						}


	else {
		LED_PROGR=1;
		LED_SPEC=0;		
		nokia_gotoxy(0,2);
		printf(nokia_printchar,"Try again !!! ");

			}


	


	delay_ms(1000); 
	nokia_erase_y(2);
	if (!analyze){nokia_erase_y(4);nokia_erase_y(5);}
	
	

				}	// end "else if (key!=0)"


delay_ms(1); // 
IR_RX_EN=0;		// disable RC0 = power off for IR RX module
delay_ms(1); // 

analog=0x00;		// LEDs off

}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#SEPARATE void transmit_mode(void)
{

show_led_addr();

nokia_gotoxy(0,2);
printf(nokia_printchar,"Transmit Mode ");

if (key!=0){

key16=key;
current_device16=current_device;
address=(0x0000|(key16<<4)|(current_device16<<12));

protocol= read_ext_eeprom(address);
bitcount= read_ext_eeprom(address+1);

MSB3= read_ext_eeprom(address+2);
MSB2= read_ext_eeprom(address+3);
MSB1= read_ext_eeprom(address+4);
MSB0= read_ext_eeprom(address+5);
LSB1= read_ext_eeprom(address+6);
LSB0= read_ext_eeprom(address+7);

ir_tempbyte_hi=0x00000000;
ir_tempbyte_hi=((MSB3<<24)|(MSB2<<16)|(MSB1<<8)|MSB0);
ir_tempbyte_lo=0x0000;
ir_tempbyte_lo=((LSB1<<8)|LSB0);


if (analyze){ir_to_nokia();}

			

ir_tx();

analog=0x00;		// LEDs off
			}			


}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#SEPARATE void ir_tx(void)
{

setup_ccp2(CCP_PWM);
setup_timer_2(T2_DIV_BY_1,26,1); 	// 37,1 kHz square wave on CCP1
set_pwm2_duty(13);


/////////////////////////////////////////////////////
if (protocol==2){				// if NEC protocol	************************************************************

tris_ir=0xfc;	// enable TX	// start bit *****
delay_us(9000);
tris_ir=0xfe; 	// disable TX
delay_us(4500);


	for (tx_c=32;tx_c!=0;tx_c--){	// data bits *****
				
		tx_bit=bit_test(ir_tempbyte_hi,tx_c-1);
		
		if (tx_bit==0){
			tris_ir=0xfc;	// enable TX
			delay_us(525);
			tris_ir=0xfe; 	// disable TX
			delay_us(525);
						}
		
		else if (tx_bit==1){
			tris_ir=0xfc;	// enable TX
			delay_us(525);
			tris_ir=0xfe; 	// disable TX
			delay_us(1650);
							}

								}

								
tris_ir=0xfc;	// enable TX	// stop bit *****
delay_us(525);
tris_ir=0xfe; 	// disable TX
delay_us(1650);

				}

/////////////////////////////////////////////////////
else if (protocol==4){				// if SIRCS protocol	************************************************************



setup_ccp2(CCP_PWM); 
setup_timer_2(T2_DIV_BY_1,24,1); 	// 40 kHz square wave on CCP1
set_pwm2_duty(12); 


for (y=0;y!=3;y++){		// SIRCS needs at least 3 identical bursts separated with a pause of approx. 24 mS


tris_ir=0xfc;	// enable TX	// start bit *****
delay_us(2200);
tris_ir=0xfe; 	// disable TX
delay_us(500);



	for (tx_c=12;tx_c!=0;tx_c--){	// data bits *****
				
		tx_bit=bit_test(ir_tempbyte_hi,tx_c-1);
		
		if (tx_bit==0){
			tris_ir=0xfc;	// enable TX
			delay_us(560);
			tris_ir=0xfe; 	// disable TX
			delay_us(500);
						}
		
		else if (tx_bit==1){
			tris_ir=0xfc;	// enable TX
			delay_us(1120);
			tris_ir=0xfe; 	// disable TX
			delay_us(500);
							}

								}

delay_ms(24);
							} // end for y


				}

////////////////////////////////////////////////////////////
else if (protocol==7){				// if PANASONIC protocol	************************************************************

tris_ir=0xfc;	// enable TX	// start bit *****
delay_us(3380);
tris_ir=0xfe; 	// disable TX
delay_us(1690);


	for (tx_c=32;tx_c!=0;tx_c--){	// data bits *****
				
		tx_bit=bit_test(ir_tempbyte_hi,tx_c-1);
		
		if (tx_bit==0){
			tris_ir=0xfc;	// enable TX
			delay_us(420);
			tris_ir=0xfe; 	// disable TX
			delay_us(420);
	
						}
		
		else if (tx_bit==1){
			tris_ir=0xfc;	// enable TX
			delay_us(420);
			tris_ir=0xfe; 	// disable TX
			delay_us(1270);
	
							}

												}

	for (tx_c=16;tx_c!=0;tx_c--){	// data bits *****
				
		tx_bit=bit_test(ir_tempbyte_lo,tx_c-1);
		
		if (tx_bit==0){
			tris_ir=0xfc;	// enable TX
			delay_us(420);
			tris_ir=0xfe; 	// disable TX
			delay_us(420);
						}
		
		else if (tx_bit==1){
			tris_ir=0xfc;	// enable TX
			delay_us(420);
			tris_ir=0xfe; 	// disable TX
			delay_us(1270);
							}

												}


								
tris_ir=0xfc;	// enable TX	// stop bit *****
delay_us(420);
tris_ir=0xfe; 	// disable TX
delay_us(420);

				}
/////////////////////////////////////////////////////
else if (protocol==8){				// if SAMSUNG protocol	************************************************************

tris_ir=0xfc;	// enable TX	// start bit *****
delay_us(4500);
tris_ir=0xfe; 	// disable TX
delay_us(4500);


	for (tx_c=32;tx_c!=0;tx_c--){	// data bits *****
				
		tx_bit=bit_test(ir_tempbyte_hi,tx_c-1);
		
		if (tx_bit==0){
			tris_ir=0xfc;	// enable TX
			delay_us(525);
			tris_ir=0xfe; 	// disable TX
			delay_us(525);
						}
		
		else if (tx_bit==1){
			tris_ir=0xfc;	// enable TX
			delay_us(525);
			tris_ir=0xfe; 	// disable TX
			delay_us(1650);
							}

								}

								// stop bit *****
tris_ir=0xfc;	// enable TX
delay_us(525);
tris_ir=0xfe; 	// disable TX
delay_us(1650);

				}




// tris_ir=0xff;	// disable TX

// delay_ms(100); // test
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#SEPARATE void backup(void)
{
analog=0x00;		// LEDs off
LED_PROGR=1;

nokia_erase_y(0);
nokia_gotoxy(24,0);
printf(nokia_printchar,"Backup");

nokia_erase_y(2);
nokia_gotoxy(0,2);
printf(nokia_printchar,"Saving....");

for (address2=0;address2!=0x07ff;address2++){		// backup all except keys init (0x7ffx)
			for (temp2=0;temp2!=8;temp2++){
				address=(0x0000|temp2|(address2<<4));
				value2=read_ext_eeprom(address);
				write_ext_eeprom(address+8, value2);
											}	
				percent2=100-((address2*100)/0x07ff);
				nokia_gotoxy(66,2);
				printf(nokia_printchar,"%03lu",percent2);
											
				
												}


nokia_gotoxy(0,2);
printf(nokia_printchar,"Backup done.  ");
delay_ms(2000);
nokia_erase_y(0);
nokia_erase_y(2);

analog=0x00;		// LEDs off
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#SEPARATE void restore(void)
{
analog=0x00;		// LEDs off
LED_SPEC=1;

nokia_erase_y(0);
nokia_gotoxy(24,0);
printf(nokia_printchar,"Restore");

nokia_erase_y(2);
nokia_gotoxy(0,2);
printf(nokia_printchar,"Loading...");

for (address2=0;address2!=0x07ff;address2++){		// backup all except keys init (0x7ffx)
			for (temp2=0;temp2!=8;temp2++){
				address=(0x0000|temp2|(address2<<4));
				value2=read_ext_eeprom(address+8);
				write_ext_eeprom(address, value2);
											}	
				percent2=100-((address2*100)/0x07ff);
				nokia_gotoxy(66,2);
				printf(nokia_printchar,"%03lu",percent2);
											
				
												}


nokia_gotoxy(0,2);
printf(nokia_printchar,"Restore done. ");
delay_ms(2000);
nokia_erase_y(0);
nokia_erase_y(2);


analog=0x00;		// LEDs off
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void show_led_addr(void)
{

LED_ADDR0=((current_device+1)&0x01);
LED_ADDR1=((current_device+1)&0x02);
LED_ADDR2=((current_device+1)&0x04);

}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
