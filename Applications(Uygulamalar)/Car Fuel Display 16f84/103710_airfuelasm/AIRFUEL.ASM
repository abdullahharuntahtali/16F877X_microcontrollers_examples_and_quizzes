; File O2DISP.ASM
; Uses assembly code for PIC16F84 microcontroller
; A 3-digit oxygen sensor display plus 7-segment bar graph for cars.
; Displays air/fuel ratio on three digit display and also on bargraph. 
;
; Processor pin allocations are as follows:
; RA0 Output disp3 driving transistor for common anode display
; RA1 Output disp2
; RA2 Output disp1
; RA3 Output for PWM to comparator 
; RA4 Output 7-seg bar disp4

; RB0 Input from comparator
; RB1 c segment drive LED7
; RB2 d segment drive LED6
; RB3 e segment drive LED5
; RB4 f segment drive LED3
; RB5 a segment drive LED2	
; RB6 b segment drive LED1
; RB7 g segment drive LED4

; CPU configuration
; 	
	list P=16F84
	#include "p16f84.inc"
	__config _XT_OSC & _WDT_OFF & _PWRTE_ON

; Define variables at memory locations

; RAM

DISP1		equ	H'0C'	; working storage for Display1 
DISP2		equ	H'0D'	; working storage for Display2 
DISP3		equ	H'0E'	; working storage for Display3 
DISP4		equ	H'0F'	; working storage for Display4
STATUS_TMP 	equ 	H'10'	; temp storage for status during interrupt
W_TMP		equ	H'11'	; temporary storage for w during interrupt
FLAG_1		equ	H'12'	; bit 0 is multiplex or PWM flag, bit1 is for interrupt count
PWM_CNT		equ	H'13'	; counter for PWM output
LOW_TME		equ	H'14'	; PWM low time
BIN_0		equ	H'15'	; binary value
BCD_1		equ	H'16'	; display value MS
BCD_2		equ	H'17'	; display value LS
TEMP		equ	H'18'	; temporary register
CNT_8		equ	H'19'	; counter for BCD conversion
TEMP_2		equ	H'1A'	; temporary register
TEMP_3		equ	H'1B'	; temporary storage of BIN_0
EXTN		equ	H'1C'	; delay extension value
MODE		equ	H'1D'	; dot or bar selection
PCHBUF		equ	H'1E'	; program counter High byte buffer
OFFST		equ	H'1F'	; offset value for lookup table
DISP_UP		equ	H'20'	; digit display update counter
TEMP_4		equ     H'21'	; temp register

; define reset and interrupt vector start addresses

	org	0	  	; start at address 0000h
	goto	MAIN		; normal service routines from Reset vector
	org     4		; interrupt vector 0004h, start interrupt routine here
	goto	INTRUPT		; go to start of interrupt routine, bypass subroutines

;***************************************************************************************
; led bargraph lookup table (DOT display)each count represents 5mV from 0V to 1V in 200 steps
	
LEDDOT  addwf	PCL,f		; add value to program counter
	retlw	B'11111100'	; 0 bit 1 LED7 on
	retlw	B'11111100'	; 1 bit 1 LED7 on
	retlw	B'11111100'	; 2 bit 1 LED7 on
	retlw	B'11111100'	; 3 bit 1 LED7 on
	retlw	B'11111100'	; 4 bit 1 LED7 on
	retlw	B'11111100'	; 5 bit 1 LED7 on
	retlw	B'11111100'	; 6 bit 1 LED7 on
	retlw	B'11111100'	; 7 bit 1 LED7 on
	retlw	B'11111000'	; 8 bit 1,2 LED6&7 
	retlw	B'11111000'	; 9 
	retlw	B'11111000'	; 10 
 	retlw	B'11111000'	; 11 
	retlw	B'11111000'	; 12 
 	retlw	B'11111010'	; 13 bit 2 LED6 on
	retlw	B'11111010'	; 14 bit 2 LED6 on
 	retlw	B'11111010'	; 15 bit 2 LED6 on
	retlw	B'11111010'	; 16 bit 2 LED6 on
 	retlw	B'11111010'	; 17 bit 2 LED6 on
	retlw	B'11111010'	; 18 bit 2 LED6 on
 	retlw	B'11111010'	; 19 bit 2 LED6 on
	retlw	B'11111010'	; 20 bit 2 LED6 on
 	retlw	B'11111010'	; 21 bit 2 LED6 on
	retlw	B'11111010'	; 22 bit 2 LED6 on
 	retlw	B'11111010'	; 23 
	retlw	B'11111010'	; 24 
	retlw	B'11111010'	; 25 
	retlw	B'11111010'	; 26 
	retlw	B'11111010'	; 27 
	retlw	B'11111010'	; 28 
	retlw	B'11110010'	; 29 bit 3,2 LED5&6 on
	retlw	B'11110010'	; 30 bit 3,2 LED5&6 on
	retlw	B'11110010'	; 31 bit 3,2 LED5&6 on
	retlw	B'11110010'	; 32 
	retlw	B'11110010'	; 33
	retlw	B'11110010'	; 34 
	retlw	B'11110010'	; 35 
	retlw	B'11110010'	; 36 
	retlw	B'11110010'	; 37 
	retlw	B'11110010'	; 38 
	retlw	B'11110010'	; 39 
	retlw	B'11110010'	; 40 
	retlw	B'11110110'	; 41 bit 3 LED5 on
	retlw	B'11110110'	; 42 bit 3 LED5 on
	retlw	B'11110110'	; 43 bit 3 LED5 on
	retlw	B'11110110'	; 44 bit 3 LED5 on
	retlw	B'11110110'	; 45 bit 3 LED5 on
	retlw	B'11110110'	; 46 bit 3 LED5 on
	retlw	B'11110110'	; 47 bit 3 LED5 on
	retlw	B'11110110'	; 48 bit 3 LED5 on
	retlw	B'11110110'	; 49 bit 3 LED5 on
	retlw	B'11110110'	; 50 bit 3 LED5 on
	retlw	B'11110110'	; 51 bit 3 LED5 on
	retlw	B'11110110'	; 52 bit 3 LED5 on
	retlw	B'11110110'	; 53 bit 3 LED5 on
	retlw	B'11110110'	; 54 bit 3 LED5 on
	retlw	B'11110110'	; 55 bit 3 LED5 on
	retlw	B'11110110'	; 56 
	retlw	B'11110110'	; 57 
	retlw	B'11110110'	; 58 
	retlw	B'11110110'	; 59 
	retlw	B'11110110'	; 60 
	retlw	B'11110110'	; 61 
	retlw	B'11110110'	; 62 
	retlw	B'11110110'	; 63 
	retlw	B'11110110'	; 64 
	retlw	B'11110110'	; 65 
	retlw	B'11110110'	; 66 
	retlw	B'11110110'	; 67 
	retlw	B'11110110'	; 68 
	retlw	B'01110110'	; 69 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 70 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 71 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 72 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 73 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 74 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 75 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 76 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 77 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 78 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 79 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 80 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 81 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 82 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 83 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 84 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 85 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 86 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 87 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 88 bit 7,3 LED4&5 on
	retlw	B'01110110'	; 89 
	retlw	B'01110110'	; 90 
	retlw	B'01110110'	; 91 
	retlw	B'01110110'	; 92 
	retlw	B'01110110'	; 93 
	retlw	B'01110110'	; 94
	retlw	B'01110110'	; 95 
	retlw	B'01110110'	; 96 
	retlw	B'01110110'	; 97 
	retlw	B'01110110'	; 98 
	retlw	B'01110110'	; 99 
	retlw	B'01110110'	; 100 
	retlw	B'01110110'	; 101 
	retlw	B'01110110'	; 102 
	retlw	B'01110110'	; 103 
	retlw	B'01110110'	; 104 
	retlw	B'01110110'	; 105 
	retlw	B'01110110'	; 106 
	retlw	B'01110110'	; 107 
	retlw	B'01111110'	; 108 bit 7 LED4 on
	retlw	B'01111110'	; 109 bit 7 LED4 on
	retlw	B'01111110'	; 110 bit 7 LED4 on
	retlw	B'01111110'	; 111 bit 7 LED4 on
	retlw	B'01111110'	; 112 bit 7 LED4 on
	retlw	B'01111110'	; 113 bit 7 LED4 on
	retlw	B'01111110'	; 114 bit 7 LED4 on
	retlw	B'01111110'	; 115 bit 7 LED4 on
	retlw	B'01111110'	; 116 bit 7 LED4 on
	retlw	B'01111110'	; 117 bit 7 LED4 on
	retlw	B'01111110'	; 118 bit 7 LED4 on
	retlw	B'01111110'	; 119 bit 7 LED4 on
	retlw	B'01111110'	; 120 bit 7 LED4 on
	retlw	B'01111110'	; 121 bit 7 LED4 on
	retlw	B'01111110'	; 122 bit 7 LED4 on
	retlw	B'01111110'	; 123 bit 7 LED4 on
	retlw	B'01111110'	; 124 bit 7 LED4 on
	retlw	B'01111110'	; 125 bit 7 LED4 on
	retlw	B'01111110'	; 126 bit 7 LED4 on
	retlw	B'01111110'	; 127 bit 7 LED4 on
	retlw	B'01111110'	; 128 bit 7 LED4 on
	retlw	B'01111110'	; 129 bit 7 LED4 on
	retlw	B'01111110'	; 130 bit 7 LED4 on
	retlw	B'01101110'	; 131 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 132 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 133 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 134 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 135 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 136 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 137 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 138 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 139 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 140 bit 4,7 LED3,4 on
	retlw	B'11101110'	; 141 bit 4 LED3 on
	retlw	B'11101110'	; 142 bit 4 LED3 on
	retlw	B'11101110'	; 143 bit 4 LED3 on
	retlw	B'11101110'	; 144 bit 4 LED3 on
	retlw	B'11101110'	; 145 bit 4 LED3 on
	retlw	B'11101110'	; 146 bit 4 LED3 on
	retlw	B'11101110'	; 147 bit 4 LED3 on
	retlw	B'11101110'	; 148 bit 4 LED3 on
	retlw	B'11101110'	; 149 bit 4 LED3 on
	retlw	B'11101110'	; 150 bit 4 LED3 on
	retlw	B'11101110'	; 151 bit 4 LED3 on
	retlw	B'11101110'	; 152 bit 4 LED3 on
	retlw	B'11001110'	; 153 bit 5,4 LED2&3 on
	retlw	B'11001110'	; 154 bit 5,4 LED2&3 on
	retlw	B'11001110'	; 155 bit 5,4 LED2&3 on
	retlw	B'11001110'	; 156 bit 5,4 LED2&3 on
	retlw	B'11001110'	; 157 bit 5,4 LED2&3 on
	retlw	B'11001110'	; 158 bit 5,4 LED2&3 on
	retlw	B'11001110'	; 159 bit 5,4 LED2&3 on
	retlw	B'11001110'	; 160 bit 5,4 LED2&3 on
	retlw	B'11001110'	; 161 bit 5,4 LED2&3 on
	retlw	B'11001110'	; 162 bit 5,4 LED2&3 on
	retlw	B'11001110'	; 163 bit 5,4 LED2&3 on
	retlw	B'11001110'	; 164 bit 5,4 LED2&3 on
	retlw	B'11011110'	; 165 bit 5 LED2 on
	retlw	B'11011110'	; 166 bit 5 LED2 on
	retlw	B'11011110'	; 167 bit 5 LED2 on
	retlw	B'11011110'	; 168 bit 5 LED2 on
	retlw	B'11011110'	; 169 bit 5 LED2 on
	retlw	B'11011110'	; 170 bit 5 LED2 on
	retlw	B'11011110'	; 171 bit 5 LED2 on
	retlw	B'11011110'	; 172 bit 5 LED2 on
	retlw	B'11011110'	; 173 bit 5 LED2 on
	retlw	B'11011110'	; 174 bit 5 LED2 on
	retlw	B'10011110'	; 175 bit 6,5 LED1&2 on
	retlw	B'10011110'	; 176 bit 6,5 LED1&2 on
	retlw	B'10011110'	; 177 bit 6,5 LED1&2 on
	retlw	B'10011110'	; 178 bit 6,5 LED1&2 on
	retlw	B'10111110'	; 179 bit 6 LED1 on
	retlw	B'10111110'	; 180 bit 6 LED1 on
	retlw	B'10111110'	; 181 bit 6 LED1 on
	retlw	B'10111110'	; 182 bit 6 LED1 on
	retlw	B'10111110'	; 183 bit 6 LED1 on
	retlw	B'10111110'	; 184 bit 6 LED1 on
	retlw	B'10111110'	; 185 bit 6 LED1 on
	retlw	B'10111110'	; 186 bit 6 LED1 on
	retlw	B'10111110'	; 187 bit 6 LED1 on
	retlw	B'10111110'	; 188 bit 6 LED1 on
	retlw	B'10111110'	; 189 bit 6 LED1 on
	retlw	B'10111110'	; 190 bit 6 LED1 on
	retlw	B'10111110'	; 191 bit 6 LED1 on
	retlw	B'10111110'	; 192 bit 6 LED1 on
	retlw	B'10111110'	; 193 bit 6 LED1 on
	retlw	B'10111110'	; 194 bit 6 LED1 on
	retlw	B'10111110'	; 195 bit 6 LED1 on
	retlw	B'10111110'	; 196 bit 6 LED1 on
	retlw	B'10111110'	; 197 bit 6 LED1 on
	retlw	B'10111110'	; 198 bit 6 LED1 on
	retlw	B'10111110'	; 199 bit 6 LED1 on
	retlw	B'10111110'	; 200 bit 6 LED1 on
	retlw	B'10111110'	; 201 bit 6 LED1 on
	
; ************************************************************

; airfuel ratio lookup table 5mV per count

AIRFUEL movf	PCHBUF,w	; high offset address
	movwf	PCLATH		; this table crosses PCLATH page boundary
	movf	OFFST,w
	movwf	PCL		; value to program counter
	retlw	D'000'		; pwm count of 0
	retlw	D'000'		; pwm count of 1 or 5mV
	retlw	D'235'
	retlw	D'206'
	retlw	D'191'
	retlw	D'184'
	retlw	D'176'		; count 6
	retlw	D'175'
	retlw	D'171'		; 8
	retlw	D'168'
	retlw	D'163'
	retlw	D'162'
	retlw	D'160'
	retlw	D'159'
	retlw	D'157'
	retlw	D'156'		; 15
	retlw	D'156'
	retlw	D'155'
	retlw	D'154'
	retlw	D'154'
	retlw	D'153'
	retlw	D'152'
	retlw	D'152'		;  22
	retlw	D'151'
	retlw	D'151'
	retlw	D'151'
	retlw	D'150'
	retlw	D'150'
	retlw	D'150'	
	retlw	D'150'		; 29
	retlw	D'150'
	retlw	D'149'
	retlw	D'149'
	retlw	D'149'
	retlw	D'149'
	retlw	D'149'
	retlw	D'149'		; 36
	retlw	D'149'
	retlw	D'149'
	retlw	D'149'
	retlw	D'149'
	retlw	D'149'
	retlw	D'149'
	retlw	D'149'		; 43
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'		; 50
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'	
	retlw	D'148'
	retlw	D'148'		; 58
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'		; 65
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'		; 72
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'	
	retlw	D'148'		; 80
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'
	retlw	D'148'		; 87
	retlw	D'148'
	retlw	D'148'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'		;94
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'		; 101
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'	
	retlw	D'147'		; 108
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'		; 115
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'		; 122
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'	
	retlw	D'147'		; 130
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'147'
	retlw	D'146'
	retlw	D'146'		; 137
	retlw	D'146'
	retlw	D'146'
	retlw	D'146'
	retlw	D'146'
	retlw	D'146'
	retlw	D'146'
	retlw	D'146'		; 144
	retlw	D'146'
	retlw	D'146'
	retlw	D'146'
	retlw	D'146'
	retlw	D'146'
	retlw	D'146'
	retlw	D'146'		; 151
	retlw	D'145'
	retlw	D'145'
	retlw	D'145'
	retlw	D'145'
	retlw	D'145'
	retlw	D'144'	
	retlw	D'144'		; 158
	retlw	D'144'
	retlw	D'143'
	retlw	D'143'
	retlw	D'142'
	retlw	D'142'
	retlw	D'142'
	retlw	D'141'		; 165
	retlw	D'140'
	retlw	D'140'
	retlw	D'139'
	retlw	D'139'
	retlw	D'138'
	retlw	D'138'
	retlw	D'137'		; 172
	retlw	D'136'
	retlw	D'135'
	retlw	D'133'
	retlw	D'132'
	retlw	D'130'
	retlw	D'128'	
	retlw	D'125'		; 179
	retlw	D'119'
	retlw	D'118'
	retlw	D'118'
	retlw	D'0'
	retlw	D'0'
	retlw	D'0'
	retlw	D'0'		; 186
	retlw	D'0'
	retlw	D'0'
	retlw	D'0'
	retlw	D'0'
	retlw	D'0'
	retlw	D'0'
	retlw	D'0'		; 193
	retlw	D'0'
	retlw	D'0'
	retlw	D'0'
	retlw	D'0'
	retlw	D'0'
	retlw	D'0'	
	retlw	D'0'		; 200
	retlw	D'0'		; 201
		
; **************************************************************************
; subroutine to get seven segment display data. 

SVNSEG	andlw	0x0F		; remove most significant bits if present prevents value >16h
	addwf	PCL,f		; add value of display to program counter
	retlw 	B'10000000'	; 7-segment code 0 
	retlw 	B'10111100'	; 7-segment code 1
	retlw 	B'00010010'	; 7-segment code 2
	retlw 	B'00011000'	; 7-segment code 3
	retlw 	B'00101100'	; 7-segment code 4
	retlw 	B'01001000'	; 7-segment code 5
	retlw 	B'01000000'	; 7-segment code 6
	retlw 	B'10011100'	; 7-segment code 7
	retlw 	B'00000000'	; 7-segment code 8
	retlw 	B'00001000'	; 7-segment code 9
; ******************************************************************************
; Subroutines

; delay period 

DELMOR	movlw 	D'255'		; delay period
	movwf	TEMP_2
SMALER	decfsz	TEMP_2,f	; reduce temp_2
	goto	SMALER		; temp_2 smaller by 1
	return			; end delay

; Subroutine for PWM cycle period for successive approximation A-D converter
	
SAR	movlw	0x38		; number of interrupts between PWM changes
	movwf	PWM_CNT
CNT_AGN	bcf	FLAG_1,1	; bit set in interrupt at multiplex rate
CNT_NOW	btfss	FLAG_1,1	; look at flag
	goto	CNT_NOW		; wait till flag set at multiplex interrupt 
	decfsz 	PWM_CNT,f	; reduce this value 
	goto	CNT_AGN		; cycle 
	return

; Subroutine to convert from 8-bit binary to 2-digit BCD (packed)
; Binary value is in BIN0  
; Result in BCD is in BCD1 & BCD2.  
; BCD1 is MSB, BCD2 is LSB

BCD	bcf	STATUS,c	; clear carry bit
	movlw	D'8'
	movwf	CNT_8		; 8 in count
	clrf	BCD_1
	clrf	BCD_2		; set BCD registers to 0 
LOOPBCD	rlf	BIN_0,f		; shift left binary registers
	rlf	BCD_2,f		; MSB shift left
	rlf	BCD_1,f		; LSB shift left BCD registers
	decfsz	CNT_8,f		; reduce count value return when 0
	goto	DECADJ		; continue decimal adjust
	return			; completed decimal to BCD operation

; subroutine decimal adjust

DECADJ	movlw	BCD_2		; BCD LSB address
	movwf	FSR		; pointer for BCD2
	call	ADJBCD		; subroutine to adjust BCD
	movlw	BCD_1		; BCD MS address
	movwf	FSR		; pointer for BCD1
	call	ADJBCD
	goto	LOOPBCD

; subroutine adjust BCD

ADJBCD	movlw	0x03		; w has 03 
	addwf	INDF,w		; add 03 to BCDx register (x is 0-1)
	movwf	TEMP		; store w
	btfsc	TEMP,3		; test if >7
	movwf	INDF		; save as LS digit
	movlw	0x30		; 3 for MSbyte
	addwf	INDF,w		; add 30 to BCDx register
	movwf	TEMP		; store w in temp
	btfsc	TEMP,7		; test if >7
	movwf	INDF		; save as MS digit
	return			; end subroutine

;****************************************************************************
; LED bargraph display bar mode
	
	org	0x0200		; PCLATH page 2
LEDBAR	addwf	PCL,f		; add value to program counter
	retlw	B'01110000'	; 0 LED4-7 on
	retlw	B'01110000'	; 1 
	retlw	B'01110000'	; 2 
	retlw	B'01110000'	; 3 
	retlw	B'01110000'	; 4 
	retlw	B'01110000'	; 5 
	retlw	B'01110000'	; 6 
	retlw	B'01110000'	; 7 
	retlw	B'01110000'	; 8 
	retlw	B'01110010'	; 9 LED4-6
 	retlw	B'01110010'	; 10 
	retlw	B'01110010'	; 11 
 	retlw	B'01110010'	; 12 
	retlw	B'01110010'	; 13 
 	retlw	B'01110010'	; 14 
	retlw	B'01110010'	; 15 
 	retlw	B'01110010'	; 16 
	retlw	B'01110010'	; 17 
 	retlw	B'01110010'	; 18 
	retlw	B'01110010'	; 19 
 	retlw	B'01110010'	; 20 
	retlw	B'01110010'	; 21 
 	retlw	B'01110010'	; 22 
	retlw	B'01110010'	; 23 
 	retlw	B'01110010'	; 24 
	retlw	B'01110010'	; 25 
 	retlw	B'01110010'	; 26 
	retlw	B'01110010'	; 27 
	retlw	B'01110110'	; 28 LED 4 & 5
	retlw	B'01110110'	; 29 
 	retlw	B'01110110'	; 30 
	retlw	B'01110110'	; 31 
 	retlw	B'01110110'	; 32 
	retlw	B'01110110'	; 33
	retlw	B'01110110'	; 34 
 	retlw	B'01110110'	; 35 
	retlw	B'01110110'	; 36 
 	retlw	B'01110110'	; 37 
	retlw	B'01110110'	; 38 
	retlw	B'01110110'	; 39 
	retlw	B'01110110'	; 40 
	retlw	B'01110110'	; 41 
	retlw	B'01110110'	; 42 
	retlw	B'01110110'	; 43 
	retlw	B'01110110'	; 44 
	retlw	B'01110110'	; 45 
	retlw	B'01110110'	; 46 
	retlw	B'01110110'	; 47 
	retlw	B'01110110'	; 48 
	retlw	B'01110110'	; 49 
	retlw	B'01110110'	; 50 
	retlw	B'01110110'	; 51 
	retlw	B'01110110'	; 52 
	retlw	B'01110110'	; 53 
	retlw	B'01110110'	; 54 
	retlw	B'01110110'	; 55 
	retlw	B'01110110'	; 56 
	retlw	B'01110110'	; 57 
	retlw	B'01110110'	; 58
	retlw	B'01110110'	; 59 
	retlw	B'01110110'	; 60 
	retlw	B'01110110'	; 61 
	retlw	B'01110110'	; 62 
	retlw	B'01110110'	; 63
	retlw	B'01110110'	; 64 
	retlw	B'01110110'	; 65 
	retlw	B'01110110'	; 66 
	retlw	B'01110110'	; 67 
	retlw	B'01111110'	; 68 LED4
	retlw	B'01111110'	; 69 
	retlw	B'01111110'	; 70
	retlw	B'01111110'	; 71 LED4
	retlw	B'01111110'	; 72 
	retlw	B'01111110'	; 73 
	retlw	B'01111110'	; 74 
	retlw	B'01111110'	; 75 
	retlw	B'01111110'	; 76 
	retlw	B'01111110'	; 77
	retlw	B'01111110'	; 78
	retlw	B'01111110'	; 79 LED4
	retlw	B'01111110'	; 80 
	retlw	B'01111110'	; 81 
	retlw	B'01111110'	; 82 
	retlw	B'01111110'	; 83 
	retlw	B'01111110'	; 84 
	retlw	B'01111110'	; 85
	retlw	B'01111110'	; 87 LED4
	retlw	B'01111110'	; 88 
	retlw	B'01111110'	; 89 
	retlw	B'01111110'	; 90 
	retlw	B'01111110'	; 91 
	retlw	B'01111110'	; 92 
	retlw	B'01111110'	; 93
	retlw	B'01111110'	; 94 LED4
	retlw	B'01111110'	; 95 
	retlw	B'01111110'	; 96 
	retlw	B'01111110'	; 97 
	retlw	B'01111110'	; 98 
	retlw	B'01111110'	; 99 
	retlw	B'01111110'	; 100
	retlw	B'01111110'	; 101 LED4
	retlw	B'01111110'	; 102 
	retlw	B'01111110'	; 103 
	retlw	B'01111110'	; 104 
	retlw	B'01111110'	; 105 
	retlw	B'01111110'	; 106 
	retlw	B'01111110'	; 107
	retlw	B'01111110'	; 108 LED4
	retlw	B'01111110'	; 109 
	retlw	B'01111110'	; 110 
	retlw	B'01111110'	; 111 
	retlw	B'01111110'	; 112 
	retlw	B'01111110'	; 113 
	retlw	B'01111110'	; 114 
	retlw	B'01111110'	; 115 
	retlw	B'01111110'	; 116 
	retlw	B'01111110'	; 117 
	retlw	B'01111110'	; 118 
	retlw	B'01111110'	; 119 
	retlw	B'01111110'	; 120 
	retlw	B'01111110'	; 121 
	retlw	B'01111110'	; 122 
	retlw	B'01111110'	; 123 
	retlw	B'01111110'	; 124 
	retlw	B'01111110'	; 125 
	retlw	B'01111110'	; 126 
	retlw	B'01111110'	; 127 
	retlw	B'01111110'	; 128 
	retlw	B'01111110'	; 129 
	retlw	B'01111110'	; 130 
	retlw	B'01111110'	; 131 
	retlw	B'01111110'	; 132 
	retlw	B'01111110'	; 133 
	retlw	B'01111110'	; 134 
	retlw	B'01111110'	; 135 
	retlw	B'01111110'	; 136
	retlw	B'01111110'	; 137 
	retlw	B'01111110'	; 138 
	retlw	B'01111110'	; 139 
	retlw	B'01101110'	; 140 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 141 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 142 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 143 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 144 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 145 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 146 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 147 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 148 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 149 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 150 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 151 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 152 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 153 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 154 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 155 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 156 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 157 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 168 bit 4,7 LED3,4 on
	retlw	B'01101110'	; 159 bit 4,7 LED3,4 on
	retlw	B'01001110'	; 160 LED2,3,4 on
	retlw	B'01001110'	; 161 
	retlw	B'01001110'	; 162
	retlw	B'01001110'	; 163 
	retlw	B'01001110'	; 164 
	retlw	B'01001110'	; 165 
	retlw	B'01001110'	; 166 
	retlw	B'01001110'	; 167 
	retlw	B'01001110'	; 168 
	retlw	B'01001110'	; 169 
	retlw	B'01001110'	; 170 
	retlw	B'01001110'	; 171 
	retlw	B'01001110'	; 172 
	retlw	B'01001110'	; 173 
	retlw	B'01001110'	; 174
	retlw	B'01001110'	; 165 
	retlw	B'01001110'	; 166 
	retlw	B'01001110'	; 167  
	retlw	B'00001110'	; 168 LED 1-4 on
	retlw	B'00001110'	; 169 
	retlw	B'00001110'	; 170 
	retlw	B'00001110'	; 171 
	retlw	B'00001110'	; 172 
	retlw	B'00001110'	; 173 
	retlw	B'00001110'	; 174 
	retlw	B'00001110'	; 175 
	retlw	B'00001110'	; 176 
	retlw	B'00001110'	; 177 
	retlw	B'00001110'	; 178 
	retlw	B'00001110'	; 179 
	retlw	B'00001110'	; 180
	retlw	B'00001110'	; 181 
	retlw	B'00001110'	; 182 
	retlw	B'00001110'	; 183 
	retlw	B'00001110'	; 184 
	retlw	B'00001110'	; 185 
	retlw	B'00001110'	; 186
	retlw	B'00001110'	; 187 
	retlw	B'00001110'	; 188 
	retlw	B'00001110'	; 189 
	retlw	B'00001110'	; 190 
	retlw	B'00001110'	; 191 
	retlw	B'00001110'	; 192
	retlw	B'00001110'	; 193 
	retlw	B'00001110'	; 194 
	retlw	B'00001110'	; 195 
	retlw	B'00001110'	; 196 
	retlw	B'00001110'	; 197 
	retlw	B'00001110'	; 198
	retlw	B'00001110'	; 199 
	retlw	B'00001110'	; 200 
	retlw	B'00001110'	; 201 

; **************************************************************************

; INTERRUPT
; interrupt from counter used to multiplex display
; this sucessively switches on Disp1, Disp2, Disp3, Disp4 in sequence plus 
; uses internal timer to initiate display update
; produces PWM output with duty set by LOW_TME register
; start interrupt by saving w and status registers before altered by interrupt routine

INTRUPT	movwf	W_TMP		; w to w_tmp storage
	swapf	STATUS,w	; status to w
	movwf	STATUS_TMP	; status in status_tmp  

; PWM output routine

PWM_MPX	movf	LOW_TME,w	; PWM low time to w
	btfsc	FLAG_1,0	; check bit 0
	goto	LOW_OUT
	bsf	FLAG_1,0	; clear if set
	nop			; output cycle time adjust
	bcf	PORTA,3		; RA3 low
	sublw	0x02		; PWM low time
	nop			; align timer with cycles of instruction
	addwf	TMR0,f		; 4MHz so low time is inverse of 4MHz/4/2/256  
	bcf	INTCON,T0IF	; clear TMRO interrupt flag
	goto	LITCHK		; multiplex
LOW_OUT	nop			; set equal time between high out and low out
	bsf	PORTA,3		; RA3 high
	addlw	0x02		; align timer
	addwf	TMR0,f		; 4MHz so high time is inverse of 4MHz/4/2/256  
	bcf	FLAG_1,0	; set if clear
	bcf	INTCON,T0IF
	goto	RECLAIM

; multiplex display routine

LITCHK	bsf	FLAG_1,1	; set flag for interrupt count
	btfss	PORTA,2		; skip if display 1 not lit
	goto	LIT1		; display 1 lit
	btfss	PORTA,1		; skip if display 2 not lit
	goto	LIT2		; display 2 lit
	btfss	PORTA,0		; skip if display 3 not lit				
	goto	LIT3		; display 3 lit
	bsf	PORTA,4		; disp4 off
	movf	DISP1,w		; disp1	to w
	movwf	PORTB
	bcf	PORTA,2		; disp1 powered
	goto 	RECLAIM
LIT1	bsf	PORTA,2		; disp1 off
	movf	DISP2,w		; disp2 to w
	movwf	PORTB		; seven segment value to portB
	bcf	PORTA,1		; disp2 powered
	goto	RECLAIM		; end of multiplex
LIT2	bsf	PORTA,1		; disp2 off
	movf	DISP3,w		; disp3 to w
	movwf	PORTB		; portB has seven-segment code 
	bcf	PORTA,0		; disp3 powered
	goto	RECLAIM		; end of multiplex
LIT3	bsf	PORTA,0		; disp3 off
	movf	DISP4,w		; disp4 to w
	movwf 	PORTB
	bcf	PORTA,4		; disp4 powered

; end of interrupt reclaim w and status 

RECLAIM	swapf	STATUS_TMP,w	; status temp storage to w
	movwf	STATUS		; w to status register
	swapf	W_TMP,f		; swap upper and lower 4-bits in w_tmp
	swapf   W_TMP,w		; swap bits and into w register
	retfie			; return from interrupt

;********************************************************************************************** 
  
; RESET		
; Set ports A & B

MAIN	clrf	MODE		; dot or bar mode flag
	movlw	B'11111110'	; code for 7-segment display off
	movwf 	DISP1		; display values
	movwf	DISP2		; initial display value
	movwf	DISP3		; initial display value
	movwf	DISP4		; bar graph initial value
	bsf	STATUS,RP0	; select memory bank 1
	movlw	B'00011011'	; w = 00000011 binary (RB0 input, RB1-RB7 output)(RB1,
				; RB3,4 initially an input)
	movwf	TRISB		; port B data direction register
	movlw	B'00000000'	; w = 10000000 binary
	movwf	OPTION_REG	; TMRO prescaler, PORTB pullups enabled
	movlw   B'00000000'	; w = 10000 binary (RA0-RA4 outputs)
	movwf   TRISA		; A port data direction register
	bcf	STATUS,RP0	; select memory bank 0
	movlw	B'11111110'	; w is all 1's for RB7-RB1, 0 for RB0
	movwf	PORTB		; portB outputs high
	movlw	B'00010111'
	movwf	PORTA		; portA RA0,RA1,RA2,RA4 outputs high, RA3 low
	btfsc	PORTB,1		; check if RB1 low or high
	bsf	MODE,0		; set mode for bar style
	btfsc	PORTB,3		; RB3 high or low?
	bsf	MODE,1		; set for volts or air fuel mode, high = airfuel
	btfss	PORTB,4		; RB4 high or low?
	bsf	MODE,2		; set petrol or LPG mode, high = petrol
	bsf	STATUS,RP0	; select memory bank 1
	bcf	TRISB,1		; set RB1 as an output
	bcf	TRISB,3		; set RB3 as an output
	bcf	TRISB,4		; set RB4 as an output
	bcf	STATUS,RP0	; select memory bank 0

; interrupt enable and program now runs

NO_OPEN	bsf	INTCON,T0IE	; set interrupt enable for TMR0 
	bsf	INTCON,GIE	; set global interrupt enable for above

; delay for input voltage to settle

	movlw	0x20		; delay extension
	movwf	EXTN
WAIT	call	DELMOR		; delay
	decfsz	EXTN,f		; out from delay when zero
	goto	WAIT
	
; Successive Approximation for A-D converter
	
NEWVAL	clrf	LOW_TME
	bsf	LOW_TME,7	; bit 7 set
	call	SAR
	btfss 	PORTB,0		; comparator out. if RB0 high then value below 128 (high bit 7)
	bcf	LOW_TME,7	; bit 7 cleared
	bsf	LOW_TME,6	; next LS bit test
	call 	SAR
	btfss 	PORTB,0		; if RB0 high then value below (high bit 6)
	bcf	LOW_TME,6
	bsf	LOW_TME,5
	call 	SAR
	btfss 	PORTB,0		; if RB0 high then value below (high bit 5)
	bcf	LOW_TME,5
	bsf	LOW_TME,4
	call 	SAR
	btfss 	PORTB,0		; if RB0 high then value below (high bit 4)
	bcf	LOW_TME,4
	bsf	LOW_TME,3
	call 	SAR
	btfss 	PORTB,0		; if RB0 high then value below (high bit 3)
	bcf	LOW_TME,3
	bsf	LOW_TME,2
	call 	SAR
	btfss	PORTB,0		; if RB0 high then value below (high bit 2)
	bcf	LOW_TME,2
	bsf	LOW_TME,1
	call 	SAR
	btfss 	PORTB,0		; if RB0 high then value below (high bit 1)
	bcf	LOW_TME,1
	bsf	LOW_TME,0
	call 	SAR
	btfss	PORTB,0		; bit 0 test
	bcf	LOW_TME,0


	movf	LOW_TME,w	; store 255 minus lowtime value into binary0 register
	sublw	D'255'		; get reverse value ie high output time
	movwf	TEMP_3		; temporary storage for pwm value
	incf	DISP_UP,f	; increment display update counter

; check display update (slower for digit display)
	
	movf	DISP_UP,w	; check update counter value
	sublw	0x02		; 2-disp_up
	btfsc	STATUS,c	; if larger then update 
	goto	MODE_DB		; just update bargraph
	clrf	DISP_UP		; clear for recount

; check if airfuel ratio or volts

	btfsc	MODE,1		; airfuel or volts
	goto	NO_LOW		; airfuel display
	movf	TEMP_3,w
	sublw	D'230'		; check if more than 1.05V
	btfsc	STATUS,c	; more than so load OL into disp	
	goto	VOLT		; value is within range	
	movlw	B'10000000'	; "O" as in Overload
	movwf	DISP3	
	movlw	B'11100010'	; "L" as overLoad
	movwf	DISP2
	movlw	B'11111110'	; blank display
	movwf	DISP1
	btfsc	MODE,0		; dot or bar
	goto 	HI_RICH
	movlw	B'00001110'	; high LEDs on (RIch)
	movwf	DISP4
	goto	NEWVAL
HI_RICH	movlw	B'10111110'	; high rich LED
	movwf	DISP4
	goto	NEWVAL	
NEGTIVE	movlw	B'01111110'	; (-) for negative
	movwf	DISP3
	movlw	B'11111110'
	movwf	DISP2
	movwf	DISP1		; displays off
	goto	MODE_DB
VOLT	movlw	D'19'		; minimum value of 19 to w register 
	subwf	TEMP_3,w	; reduce by 19	
	btfss	STATUS,c	; if 0 or positive continue
	goto 	NEGTIVE		; if negative clear value add - sign
	movwf	TEMP_4		; temp storage
	bcf	STATUS,c	; clear carry bit
	rrf	TEMP_4,w	; divide by 2
	goto	B_BCD		; w has 0-1V value in binary
 
; check if overrange or under range

NO_LOW	movf	TEMP_3,w	; binary value to w
	sublw	D'21'		; check if less than 10mV  
	btfsc	STATUS,c	; if c is 0 then larger
	goto	SMALLR		; smaller so load lean into disp
	movf	TEMP_3,w
	sublw	D'201'		; check if more 0.8 lambda
	btfsc	STATUS,c	; more than so load rich into disp	
	goto	INRNGE		; value in range	
	movlw	B'10000110'	; "r" as in rich
	movwf	DISP2	
	movlw	B'11111110'	; blank display
	movwf	DISP3
	movlw	B'11111110'	; blank display
	movwf	DISP1
	btfsc	MODE,0		; dot or bar
	goto 	MAX_DOT
	movlw	B'00001110'	; high LEDs on (RIch)
	movwf	DISP4
	goto	NEWVAL
MAX_DOT	movlw	B'10111110'	; high rich LED
	movwf	DISP4
	goto	NEWVAL
SMALLR	movlw	B'11100010'	; "L" into display as in Lean
	movwf	DISP2	
	movlw	B'11111110'	; blank display
	movwf	DISP3
	movlw	B'11111110'	; blank display
	movwf	DISP1
	btfsc	MODE,0		; if clear then bar mode
	goto	LN_DOT
	movlw	B'01110000'	; lowest lean LEDs
	movwf	DISP4
	goto	NEWVAL
LN_DOT	movlw	B'11111100'	; lowest. LED7
	movwf	DISP4
	goto 	NEWVAL
INRNGE	clrf	PCHBUF		; set to zero
	movlw	D'19'		; min value to W
	subwf	TEMP_3,w	; reduce by 19
	btfss	STATUS,c	; if 0 or plus continue
	clrw			; negative so clear value
	movwf	OFFST		; temp offset storage
	movlw	0xD4		; low byte of AIRFUEL lookup table
	addwf	OFFST,f		; offset has lookup table offset (check if boundary crossed)
	movlw	0x00		; high address of table for AIRFUEL
	btfsc	STATUS,c	; has table crossed 0 to 1 page boundary (256 bytes)
	addlw	0x01		; yes so increment page
	movwf	PCHBUF		; temporary location 
	call	AIRFUEL		; obtain value from lookup table
	btfsc	MODE,2		; if bit 2 high then add 9 to display for LPG
	addlw	0x9		; add 9 to w
B_BCD	movwf	BIN_0		; register value for bcd conversion 
	call	BCD		; convert binary number to BCD
	movlw	0x01		; page 2 PCLATH address
	movwf	PCLATH
	movf	BCD_1,w		; BCD1 value to w
	xorlw	0x00		; compare with 0
	btfss	STATUS,z	; skip if zero
	goto 	SHOW		; show digit on disp3
	movlw	B'11111110'	; 7-segment display off
	goto	BLNK		; value to blank display
SHOW	movf	BCD_1,w	
	call 	SVNSEG		; convert to 7-segment value for display
BLNK	movwf	DISP3		; transfer BCD MSD to DISPlay 3
	movf	BCD_2,w		; contains packed BCD value
	andlw	0x0F		; extract LS bits
	call	SVNSEG
	movwf	DISP1		; place in display 1
	swapf	BCD_2,w		; swap upper and lower 4-bits
	andlw	0x0F		; extract bits
	call	SVNSEG
	movwf	DISP2		; place in middle digit register
	
; bar display (MODE bit 0 has dot or bar flag)
	
MODE_DB	movf	TEMP_3,w	; binary value to w
	sublw	D'21'		; check if less than 10mV count 2 plus 19
	btfsc	STATUS,c	; if c is 0 then larger
	goto	SMAL		; smaller so load lean into disp
	movf	TEMP_3,w
	sublw	D'201'		; check if more than .8 lambda (182 plus 19)
	btfsc	STATUS,c	; more than so load rich into disp	
	goto	INRGE		; value in range	
	btfsc	MODE,0		; dot or bar
	goto 	HI_DOT
	movlw	B'00001110'	; high LEDs on (RIch)
	movwf	DISP4
	goto	NEWVAL
HI_DOT	movlw	B'10111110'	; high rich LED
	movwf	DISP4
	goto	NEWVAL
SMAL	btfsc	MODE,0		; if clear then bar mode
	goto	LN_DOT
	movlw	B'01110000'	; lowest lean LEDs
	movwf	DISP4
	goto 	NEWVAL

INRGE	btfsc	MODE,0		; dot or bar flag
	goto 	DOT	
	movlw	0x02		; page 2 PCLATH address
	goto	BAR
DOT	movlw	0x00		; page 0 address
BAR	movwf	PCLATH
	movlw	D'19'		; min value to W
	subwf	TEMP_3,w	; reduce pwm count value by 19
	btfss	STATUS,c	; if 0 or plus continue
	clrw			; negative so clear value
	btfss	MODE,0		; dot or bar flag
	goto	BAR_1
	call	LEDDOT		; lookup table for bargraph
LD_DISP	movwf	DISP4		; display 
	goto 	NEWVAL		; read input voltage again
BAR_1	call	LEDBAR
	goto 	LD_DISP		; load display


	end

	
	
