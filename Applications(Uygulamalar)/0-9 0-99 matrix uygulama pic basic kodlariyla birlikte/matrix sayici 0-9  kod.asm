
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
_p               		EQU	RAM_START + 054h
_i               		EQU	RAM_START + 056h
_sayac           		EQU	RAM_START + 057h
_sayi            		EQU	RAM_START + 058h
_PORTL           		EQU	PORTB
_PORTH           		EQU	PORTC
_TRISL           		EQU	TRISB
_TRISH           		EQU	TRISC

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
	INCLUDE	"MAA6F1~1.MAC"
	INCLUDE	"PBPPIC14.LIB"

	MOVE?CB	000h, TRISA
	MOVE?CB	000h, TRISB
	MOVE?CB	000h, TRISC
	MOVE?CB	000h, TRISD
	MOVE?CB	000h, PORTA
	MOVE?CB	000h, PORTB
	MOVE?CB	0FFh, PORTC
	MOVE?CB	000h, PORTD
	MOVE?CB	000h, _i
	MOVE?CB	000h, _sayac
	MOVE?CB	00Fh, _ekran + 00001h
	MOVE?CB	009h, _ekran + 00002h
	MOVE?CB	00Fh, _ekran + 00003h
	MOVE?CB	001h, _ekran + 00004h
	MOVE?CB	00Fh, _ekran + 00005h
	MOVE?CB	00Fh, _ekran + 00006h
	MOVE?CB	009h, _ekran + 00007h
	MOVE?CB	00Fh, _ekran + 00008h
	MOVE?CB	009h, _ekran + 00009h
	MOVE?CB	00Fh, _ekran + 0000Ah
	MOVE?CB	00Fh, _ekran + 0000Bh
	MOVE?CB	001h, _ekran + 0000Ch
	MOVE?CB	002h, _ekran + 0000Dh
	MOVE?CB	004h, _ekran + 0000Eh
	MOVE?CB	004h, _ekran + 0000Fh
	MOVE?CB	00Fh, _ekran + 00010h
	MOVE?CB	008h, _ekran + 00011h
	MOVE?CB	00Fh, _ekran + 00012h
	MOVE?CB	009h, _ekran + 00013h
	MOVE?CB	00Fh, _ekran + 00014h
	MOVE?CB	00Fh, _ekran + 00015h
	MOVE?CB	008h, _ekran + 00016h
	MOVE?CB	00Fh, _ekran + 00017h
	MOVE?CB	001h, _ekran + 00018h
	MOVE?CB	00Fh, _ekran + 00019h
	MOVE?CB	009h, _ekran + 0001Ah
	MOVE?CB	009h, _ekran + 0001Bh
	MOVE?CB	00Fh, _ekran + 0001Ch
	MOVE?CB	001h, _ekran + 0001Dh
	MOVE?CB	001h, _ekran + 0001Eh
	MOVE?CB	00Fh, _ekran + 0001Fh
	MOVE?CB	001h, _ekran + 00020h
	MOVE?CB	00Fh, _ekran + 00021h
	MOVE?CB	001h, _ekran + 00022h
	MOVE?CB	00Fh, _ekran + 00023h
	MOVE?CB	00Fh, _ekran + 00024h
	MOVE?CB	001h, _ekran + 00025h
	MOVE?CB	00Fh, _ekran + 00026h
	MOVE?CB	008h, _ekran + 00027h
	MOVE?CB	00Fh, _ekran + 00028h
	MOVE?CB	001h, _ekran + 00029h
	MOVE?CB	003h, _ekran + 0002Ah
	MOVE?CB	001h, _ekran + 0002Bh
	MOVE?CB	001h, _ekran + 0002Ch
	MOVE?CB	001h, _ekran + 0002Dh
	MOVE?CB	00Fh, _ekran + 0002Eh
	MOVE?CB	009h, _ekran + 0002Fh
	MOVE?CB	009h, _ekran + 00030h
	MOVE?CB	009h, _ekran + 00031h
	MOVE?CB	00Fh, _ekran + 00032h
	MOVE?CW	004h, _p
	MOVE?CB	000h, _sayi

	LABEL?L	_basla	
	ADD?BCB	_sayi, 001h, _sayi
	CMPLE?BCL	_sayi, 009h, L00002
	MOVE?CB	000h, _sayi
	LABEL?L	L00002	
	BRANCHL?BCL	_sayi, 00Ah, L00001
	BRLGOTO?L	_sifir
	BRLGOTO?L	_bir
	BRLGOTO?L	_iki
	BRLGOTO?L	_uc
	BRLGOTO?L	_dort
	BRLGOTO?L	_bes
	BRLGOTO?L	_alti
	BRLGOTO?L	_yedi
	BRLGOTO?L	_sekiz
	BRLGOTO?L	_dokuz

	LABEL?L	L00001	
	GOTO?L	_basla

	LABEL?L	_sayac1	
	ADD?BCB	_sayac, 001h, _sayac
	RETURN?	

	LABEL?L	_sifir	
	GOSUB?L	_sayac1
	MOVE?BB	_ekran + 0002Eh, PORTB
	MOVE?CB	01Eh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 0002Fh, PORTB
	MOVE?CB	01Dh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00030h, PORTB
	MOVE?CB	01Bh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00031h, PORTB
	MOVE?CB	017h, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00032h, PORTB
	MOVE?CB	00Fh, PORTC
	PAUSE?W	_p
	CMPGE?BCL	_sayac, 032h, L00004
	GOTO?L	_sifir
	LABEL?L	L00004	
	MOVE?CB	000h, _sayac
	GOTO?L	_basla

	LABEL?L	_bir	
	GOSUB?L	_sayac1
	MOVE?BB	_ekran + 00029h, PORTB
	MOVE?CB	01Eh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 0002Ah, PORTB
	MOVE?CB	01Dh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 0002Bh, PORTB
	MOVE?CB	01Bh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 0002Ch, PORTB
	MOVE?CB	017h, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 0002Dh, PORTB
	MOVE?CB	00Fh, PORTC
	PAUSE?W	_p
	CMPGE?BCL	_sayac, 032h, L00006
	GOTO?L	_bir
	LABEL?L	L00006	
	MOVE?CB	000h, _sayac
	GOTO?L	_basla

	LABEL?L	_iki	
	GOSUB?L	_sayac1
	MOVE?BB	_ekran + 00024h, PORTB
	MOVE?CB	01Eh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00025h, PORTB
	MOVE?CB	01Dh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00026h, PORTB
	MOVE?CB	01Bh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00027h, PORTB
	MOVE?CB	017h, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00028h, PORTB
	MOVE?CB	00Fh, PORTC
	PAUSE?W	_p
	CMPGE?BCL	_sayac, 032h, L00008
	GOTO?L	_iki
	LABEL?L	L00008	
	MOVE?CB	000h, _sayac
	GOTO?L	_basla

	LABEL?L	_uc	
	GOSUB?L	_sayac1
	MOVE?BB	_ekran + 0001Fh, PORTB
	MOVE?CB	01Eh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00020h, PORTB
	MOVE?CB	01Dh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00021h, PORTB
	MOVE?CB	01Bh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00022h, PORTB
	MOVE?CB	017h, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00023h, PORTB
	MOVE?CB	00Fh, PORTC
	PAUSE?W	_p
	CMPGE?BCL	_sayac, 032h, L00010
	GOTO?L	_uc
	LABEL?L	L00010	
	MOVE?CB	000h, _sayac
	GOTO?L	_basla

	LABEL?L	_dort	
	GOSUB?L	_sayac1
	MOVE?BB	_ekran + 0001Ah, PORTB
	MOVE?CB	01Eh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 0001Bh, PORTB
	MOVE?CB	01Dh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 0001Ch, PORTB
	MOVE?CB	01Bh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 0001Dh, PORTB
	MOVE?CB	017h, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 0001Eh, PORTB
	MOVE?CB	00Fh, PORTC
	PAUSE?W	_p
	CMPGE?BCL	_sayac, 032h, L00012
	GOTO?L	_dort
	LABEL?L	L00012	
	MOVE?CB	000h, _sayac
	GOTO?L	_basla

	LABEL?L	_bes	
	GOSUB?L	_sayac1
	MOVE?BB	_ekran + 00015h, PORTB
	MOVE?CB	01Eh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00016h, PORTB
	MOVE?CB	01Dh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00017h, PORTB
	MOVE?CB	01Bh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00018h, PORTB
	MOVE?CB	017h, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00019h, PORTB
	MOVE?CB	00Fh, PORTC
	PAUSE?W	_p
	CMPGE?BCL	_sayac, 032h, L00014
	GOTO?L	_bes
	LABEL?L	L00014	
	MOVE?CB	000h, _sayac
	GOTO?L	_basla

	LABEL?L	_alti	
	GOSUB?L	_sayac1
	MOVE?BB	_ekran + 00010h, PORTB
	MOVE?CB	01Eh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00011h, PORTB
	MOVE?CB	01Dh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00012h, PORTB
	MOVE?CB	01Bh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00013h, PORTB
	MOVE?CB	017h, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00014h, PORTB
	MOVE?CB	00Fh, PORTC
	PAUSE?W	_p
	CMPGE?BCL	_sayac, 032h, L00016
	GOTO?L	_alti
	LABEL?L	L00016	
	MOVE?CB	000h, _sayac
	GOTO?L	_basla

	LABEL?L	_yedi	
	GOSUB?L	_sayac1
	MOVE?BB	_ekran + 0000Bh, PORTB
	MOVE?CB	01Eh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 0000Ch, PORTB
	MOVE?CB	01Dh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 0000Dh, PORTB
	MOVE?CB	01Bh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 0000Eh, PORTB
	MOVE?CB	017h, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 0000Fh, PORTB
	MOVE?CB	00Fh, PORTC
	PAUSE?W	_p
	CMPGE?BCL	_sayac, 032h, L00018
	GOTO?L	_yedi
	LABEL?L	L00018	
	MOVE?CB	000h, _sayac
	GOTO?L	_basla

	LABEL?L	_sekiz	
	GOSUB?L	_sayac1
	MOVE?BB	_ekran + 00006h, PORTB
	MOVE?CB	01Eh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00007h, PORTB
	MOVE?CB	01Dh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00008h, PORTB
	MOVE?CB	01Bh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00009h, PORTB
	MOVE?CB	017h, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 0000Ah, PORTB
	MOVE?CB	00Fh, PORTC
	PAUSE?W	_p
	CMPGE?BCL	_sayac, 032h, L00020
	GOTO?L	_sekiz
	LABEL?L	L00020	
	MOVE?CB	000h, _sayac
	GOTO?L	_basla

	LABEL?L	_dokuz	
	GOSUB?L	_sayac1
	MOVE?BB	_ekran + 00001h, PORTB
	MOVE?CB	01Eh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00002h, PORTB
	MOVE?CB	01Dh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00003h, PORTB
	MOVE?CB	01Bh, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00004h, PORTB
	MOVE?CB	017h, PORTC
	PAUSE?W	_p
	MOVE?BB	_ekran + 00005h, PORTB
	MOVE?CB	00Fh, PORTC
	PAUSE?W	_p
	CMPGE?BCL	_sayac, 032h, L00022
	GOTO?L	_dokuz
	LABEL?L	L00022	
	MOVE?CB	000h, _sayac
	GOTO?L	_basla
	END?	

	END
