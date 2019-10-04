////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
Project 016 - interface for 4 digit LCD module
CCS compiler
		
by Michel Bavin (c) September , 2004. --- bavin@skynet.be --- http://users.skynet.be/bk317494/ ---  

... enjoy !

Open source for personal or educational use only.
*/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include <18f452.h>			// device selection  
#device adc=10  *=16 

#fuses XT,NOWDT,NOPROTECT,NOLVP,PUT,NOBROWNOUT,NOOSCSEN,CCP2C1,NOSTVREN,NODEBUG  

#use delay(clock=4000000) 	// 4 MhZ  ! ADC is not optimal at 20 MhZ + power consumption doubles

#use rs232(baud=19200, xmit=PIN_C6, rcv=PIN_C7)
#use i2c(master, sda=PIN_C4, scl=PIN_C3, fast) 

#zero_ram 

// #PRIORITY  

#use fast_io(A)
#use fast_io(B)
#use fast_io(C)
#use fast_io(D)
#use fast_io(E)

#define NOP #asm nop #endasm

#byte pa	=0xF80	//port a	// analog
#byte pb	=0xF81	//b			// 
#byte pc	=0xF82	//c			// 
#byte pd	=0xF83	//d			// LCD 
#byte pe	=0xF84	//port e	// 

// *********************************
// PORT A
// analog inputs 



// *********************************
// PORT B: 

#bit led 		=pb.7			// RB7 pin40

// *********************************
// PORT C 
// i²c 


// RC3 pin18 = SCL i²c 			// already defined (hardware)
// RC4 pin23 = SDA i²c

// RC6 pin25 = RS232 TX			// already defined (hardware)
// RC7 pin26 = RS232 RX

// *********************************
// PORT D
// 

#bit lcd_d0		=pd.0			// RD0 pin19
#bit lcd_d1		=pd.1			// RD1 pin20 (d one)
#bit lcd_d2		=pd.2			// RD2 pin21
#bit lcd_d3		=pd.3			// RD3 pin22
#bit lcd_dp1	=pd.4			// RD4 pin27 (dp one)
#bit lcd_dp2	=pd.5			// RD5 pin28
#bit lcd_min	=pd.6			// RD6 pin29 (el)
#bit lcd_bat	=pd.7			// RD7 pin30


// *********************************
// PORT E

#bit lcd_cs 	=pe.0			// RE0 pin8
#bit lcd_dg1 	=pe.1			// RE1 pin9
#bit lcd_dg2 	=pe.2			// RE2 pin10

// *********************************


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



//
void lcd_4digit(signed int16 lcd_value);
char llsb, ulsb, lmsb,umsb;
int16 lcd_bcd;

//


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//-------------------------------------------

void main(){


SET_TRIS_A(0x00);		// oooo oooo
SET_TRIS_B(0x00);		// oooo oooo	
SET_TRIS_C(0x02);		// oooo ooio
SET_TRIS_D(0x00);		// oooo oooo
SET_TRIS_E(0x00);		// oooo oooo	

printf("4 digit LCD interface\n\r");		// RS232 test

//
//

led=1;
delay_ms(10);		// test
led=0;


lcd_dp1=0;	// (dp one)
lcd_dp2=0;
lcd_min=0; 	// 
lcd_bat=0;


/////////////////////////////////////////////
while(1) 
{ 
signed int16 d;



for (d=1000;d>-9999;d--){
			if (d<0){lcd_min=TRUE;}
			else {lcd_min=FALSE;}
			lcd_4digit(d);
			delay_ms(50);
						}




// sleep();

} //end while 

		} //end main 


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void lcd_4digit(signed int16 lcd_value)
{
char pd_hi;

// signed int16 lcd_value to int16 lcd_bcd (BCD) conversion
// signed int16 lcd_value;
// int16 lcd_bcd;
// MSB 0xffff LSB
// 0 to 15

pd_hi=0;

if (lcd_dp1==1){bit_set(pd_hi,4);}
if (lcd_dp2==1){bit_set(pd_hi,5);}
if (lcd_min==1){bit_set(pd_hi,6);}
if (lcd_bat==1){bit_set(pd_hi,7);}

lcd_min=1; 	// 
lcd_bat=0;


lcd_bcd=0;


if (bit_test(lcd_value,15)){			// if negative 
		
		lcd_value=~lcd_value;		// invert bits (from signed int16)
		lcd_value+=1;				// correction
							}
else {lcd_min=0;}



while(lcd_value>=10000){lcd_value-=10000;}
while(lcd_value>=1000){lcd_value-=1000;lcd_bcd+=0x1000;}		// convert to BCD
while(lcd_value>=100){lcd_value-=100;lcd_bcd+=0x0100;}
while(lcd_value>=10){lcd_value-=10;lcd_bcd+=0x0010;}
while(lcd_value>=1){lcd_value-=1;lcd_bcd+=0x0001;}
//


llsb=lcd_bcd&0x000f;
lcd_bcd>>=4;
ulsb=lcd_bcd&0x000f;
lcd_bcd>>=4;
lmsb=lcd_bcd&0x000f;
lcd_bcd>>=4;
umsb=lcd_bcd&0x000f;

//
lcd_dg1=1;
lcd_dg2=1;
pd=(llsb&0x0f)|pd_hi;
lcd_cs=0;
lcd_cs=1;

lcd_dg1=0;
lcd_dg2=1;
pd=(ulsb&0x0f)|pd_hi;
lcd_cs=0;
lcd_cs=1;

lcd_dg1=1;
lcd_dg2=0;
pd=(lmsb&0x0f)|pd_hi;
lcd_cs=0;
lcd_cs=1;

lcd_dg1=0;
lcd_dg2=0;
pd=(umsb&0x0f)|pd_hi;
lcd_cs=0;
lcd_cs=1;
//

}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//												The End !!!!
