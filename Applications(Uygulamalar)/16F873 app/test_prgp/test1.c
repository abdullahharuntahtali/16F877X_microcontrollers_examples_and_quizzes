// Let's play PIC test program ver. 1.10  //
//  coded by Kiyoshi Sasano ( onchan@mm.neweb.ne.jp )  //

// 	ra5	in	switch 2
// 	ra4	in	switch 1
// 	ra3-0	in/out	LCD data bus

// 	rb7-0	out	LED

//	rc7	in	RxD
//	rc6	out	TxD
//	rc5	out	relay
//	rc4	out	NC
//	rc3	out	buzzer
//	rc2	out	LCD E
//	rc1	out	LCD R/W
//	rc0	out	LCD RS

#include "test1.h"

#org 0x0f00, 0xfff {} 	//for the 4k 16F873/4
  
#byte port_a = 5
#byte port_b = 6
#byte port_c = 7

#byte db = 5

#define timer_data 0x3d

#define Amode	0x30
#define rs 	PIN_C0
#define rw 	PIN_C1
#define stb 	PIN_C2

#include "lcd_lib.c"

int 	main_count, ten_count;

byte const table[16] = {0x01, 0x03, 0x06, 0x0c, 0x18, 0x30, 0x60, 0xc0, 0x80, 0xc0, 0x60, 0x30, 0x18, 0x0c, 0x06, 0x03};

#int_RTCC
RTCC_isr() {
	set_timer0(timer_data);		// set TIMER0 about 10ms
	
	if(!bit_test(port_a,4))
		bit_set(port_c,3);	// buzzer ON
	else
		bit_clear(port_c,3);	// buzzer OFF
	
	if(!bit_test(port_a,5))
		bit_set(port_c,5);	// relay ON
	else
		bit_clear(port_c,5);	// relay OFF

	ten_count++;
	
	if(ten_count == 6){
		ten_count = 0;
		main_count++;
		
		if(main_count == 16){
			main_count = 0;
		}
	}
}


void main() {

	setup_adc_ports(NO_ANALOGS);
	setup_counters(RTCC_INTERNAL,RTCC_DIV_128);
	enable_interrupts(INT_RTCC);
	enable_interrupts(global);

	set_tris_a(Amode);
	set_tris_b(0);		// rb7-0 output
	set_tris_c(0x80);
	
	set_timer0(timer_data);	// set TIMER0 about 10ms

	ten_count = 0;
	main_count = 0;
	
	lcd_init();
	lcd_clear();
	lcd_data("Welcome to");
	lcd_cmd(0xc0);
	lcd_data("'Let's play PIC'");

	while(1){
		port_b = table[main_count];
	}
}
