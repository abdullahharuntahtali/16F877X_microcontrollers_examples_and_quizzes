
; PicBasic Pro Compiler 2.41, (c) 1998, 2002 microEngineering Labs, Inc. All Rights Reserved. 
PM_USED			EQU	1

	INCLUDE	"16F877.INC"


; Define statements.
#define		CODE_SIZE		 8

RAM_START       		EQU	00020h
RAM_END         		EQU	001EFh
RAM_BANKS       		EQU	00004h
BANK0_START     		EQU	00020h
BANK0_END       		EQU	0007Fh
BANK1_START     		EQU	000A0h
BANK1_END       		EQU	000EFh
BANK2_START     		EQU	00110h
BANK2_END       		EQU	0016Fh
BANK3_START     		EQU	00190h
BANK3_END       		EQU	001EFh
EEPROM_START    		EQU	02100h
EEPROM_END      		EQU	021FFh

R0              		EQU	RAM_START + 000h
R1              		EQU	RAM_START + 002h
R2              		EQU	RAM_START + 004h
R3              		EQU	RAM_START + 006h
R4              		EQU	RAM_START + 008h
R5              		EQU	RAM_START + 00Ah
R6              		EQU	RAM_START + 00Ch
R7              		EQU	RAM_START + 00Eh
R8              		EQU	RAM_START + 010h
FLAGS           		EQU	RAM_START + 012h
GOP             		EQU	RAM_START + 013h
RM1             		EQU	RAM_START + 014h
RM2             		EQU	RAM_START + 015h
RR1             		EQU	RAM_START + 016h
RR2             		EQU	RAM_START + 017h
_ekran           		EQU	RAM_START + 018h
_b0              		EQU	RAM_START + 036h
_PORTL           		EQU	PORTB
_PORTH           		EQU	PORTC
_TRISL           		EQU	TRISB
_TRISH           		EQU	TRISC
#define _PORTB_2         	PORTB, 002h
#define _PORTB_1         	PORTB, 001h
#define _PORTB_0         	PORTB, 000h
#define _PORTA_3         	PORTA, 003h
#define _PORTA_2         	PORTA, 002h
#define _PORTA_1         	PORTA, 001h
#define _PORTA_0         	PORTA, 000h

; Constants.
_T2400           		EQU	00000h
_T1200           		EQU	00001h
_T9600           		EQU	00002h
_T300            		EQU	00003h
_N2400           		EQU	00004h
_N1200           		EQU	00005h
_N9600           		EQU	00006h
_N300            		EQU	00007h
_OT2400          		EQU	00008h
_OT1200          		EQU	00009h
_OT9600          		EQU	0000Ah
_OT300           		EQU	0000Bh
_ON2400          		EQU	0000Ch
_ON1200          		EQU	0000Dh
_ON9600          		EQU	0000Eh
_ON300           		EQU	0000Fh
_MSBPRE          		EQU	00000h
_LSBPRE          		EQU	00001h
_MSBPOST         		EQU	00002h
_LSBPOST         		EQU	00003h
_LSBFIRST        		EQU	00000h
_MSBFIRST        		EQU	00001h
_CLS             		EQU	00000h
_HOME            		EQU	00001h
_BELL            		EQU	00007h
_BKSP            		EQU	00008h
_TAB             		EQU	00009h
_CR              		EQU	0000Dh
_UnitOn          		EQU	00012h
_UnitOff         		EQU	0001Ah
_UnitsOff        		EQU	0001Ch
_LightsOn        		EQU	00014h
_LightsOff       		EQU	00010h
_Dim             		EQU	0001Eh
_Bright          		EQU	00016h
	INCLUDE	"MATRIX~2.MAC"
	INCLUDE	"PBPPIC14.LIB"

	MOVE?CB	000h, TRISA
	MOVE?CB	000h, TRISB
	MOVE?CB	0FFh, PORTA
	MOVE?CB	001h, _b0
	MOVE?CB	0FFh, _ekran
	MOVE?CB	08Fh, _ekran + 00001h
	MOVE?CB	0FFh, _ekran + 00002h
	MOVE?CB	04Fh, _ekran + 00003h
	MOVE?CB	0FFh, _ekran + 00004h
	MOVE?CB	00Fh, _ekran + 00005h
	MOVE?CB	0BFh, _ekran + 00006h
	MOVE?CB	0AFh, _ekran + 00007h
	MOVE?CB	0EFh, _ekran + 00008h

	LABEL?L	_basla	
	GOSUB?L	_ekran1
	GOTO?L	_basla

	LABEL?L	_ekran1	
	MOVE?BB	_ekran + 00006h, PORTB
	LOW?T	_PORTB_2
	PAUSE?C	019h
	HIGH?T	_PORTB_2
	MOVE?BB	_ekran + 00007h, PORTB
	LOW?T	_PORTB_1
	PAUSE?C	019h
	HIGH?T	_PORTB_1
	MOVE?BB	_ekran + 00008h, PORTB
	LOW?T	_PORTB_0
	PAUSE?C	019h
	HIGH?T	_PORTB_0
	MOVE?CB	000h, PORTB
	LOW?T	_PORTA_3
	PAUSE?C	019h
	HIGH?T	_PORTA_3
	MOVE?BB	_ekran + 00003h, PORTB
	LOW?T	_PORTA_2
	PAUSE?C	019h
	HIGH?T	_PORTA_2
	MOVE?BB	_ekran + 00004h, PORTB
	LOW?T	_PORTA_1
	PAUSE?C	019h
	HIGH?T	_PORTA_1
	MOVE?BB	_ekran + 00005h, PORTB
	LOW?T	_PORTA_0
	PAUSE?C	019h
	HIGH?T	_PORTA_0
	RETURN?	
	END?	

	END
