
; PicBasic Pro Compiler 2.46, (c) 1998, 2005 microEngineering Labs, Inc. All Rights Reserved.  
_USED			EQU	1

	INCLUDE	"C:\PROGRA~1\MECANI~1\MCSP\PBP2.46\18F452.INC"


; Define statements.
#define		OSC		 20

RAM_START       		EQU	00000h
RAM_END         		EQU	005FFh
RAM_BANKS       		EQU	00006h
BANK0_START     		EQU	00080h
BANK0_END       		EQU	000FFh
BANK1_START     		EQU	00100h
BANK1_END       		EQU	001FFh
BANK2_START     		EQU	00200h
BANK2_END       		EQU	002FFh
BANK3_START     		EQU	00300h
BANK3_END       		EQU	003FFh
BANK4_START     		EQU	00400h
BANK4_END       		EQU	004FFh
BANK5_START     		EQU	00500h
BANK5_END       		EQU	005FFh
BANKA_START     		EQU	00000h
BANKA_END       		EQU	0007Fh

R0              		EQU	RAM_START + 000h
R1              		EQU	RAM_START + 002h
R2              		EQU	RAM_START + 004h
R3              		EQU	RAM_START + 006h
R4              		EQU	RAM_START + 008h
R5              		EQU	RAM_START + 00Ah
R6              		EQU	RAM_START + 00Ch
R7              		EQU	RAM_START + 00Eh
R8              		EQU	RAM_START + 010h
T1              		EQU	RAM_START + 012h
FLAGS           		EQU	RAM_START + 014h
GOP             		EQU	RAM_START + 015h
RM1             		EQU	RAM_START + 016h
RM2             		EQU	RAM_START + 017h
RR1             		EQU	RAM_START + 018h
RR2             		EQU	RAM_START + 019h
RS1             		EQU	RAM_START + 01Ah
RS2             		EQU	RAM_START + 01Bh
PB01            		EQU	RAM_START + 01Ch
_a               		EQU	RAM_START + 01Dh
_animasyon_reg   		EQU	RAM_START + 01Eh
_b               		EQU	RAM_START + 01Fh
_c               		EQU	RAM_START + 020h
_i               		EQU	RAM_START + 021h
_k               		EQU	RAM_START + 022h
_lcd_reg         		EQU	RAM_START + 023h
_repat           		EQU	RAM_START + 024h
_tasma           		EQU	RAM_START + 025h
_tekrar_reg      		EQU	RAM_START + 026h
_vezne_bul       		EQU	RAM_START + 027h
_vezne_no        		EQU	RAM_START + 028h
_vezne_no_birler 		EQU	RAM_START + 029h
_vezne_no_onlar  		EQU	RAM_START + 02Ah
_x               		EQU	RAM_START + 02Bh
_y               		EQU	RAM_START + 02Ch
_yinele          		EQU	RAM_START + 02Dh
_z               		EQU	RAM_START + 02Eh
_numara_reg      		EQU	RAM_START + 02Fh
_sayac_reg       		EQU	RAM_START + 032h
_vezne_reg       		EQU	RAM_START + 035h
_PORTL           		EQU	 PORTB
_PORTH           		EQU	 PORTC
_TRISL           		EQU	 TRISB
_TRISH           		EQU	 TRISC
#define _sda             	_PORTA_4
#define _scl             	_PORTA_5
#define _izin            	_PORTA_3
#define _en1             	_PORTE_0
#define _en2             	_PORTE_1
#define _vezne_enable    	 PB01, 001h
#define _sira_enable     	 PB01, 000h
#define _vezne1_b        	_PORTC_0
#define _vezne2_b        	_PORTC_1
#define _vezne3_b        	_PORTC_2
#define _vezne4_b        	_PORTC_3
#define _vezne5_b        	_PORTC_4
#define _vezne6_b        	_PORTC_5
#define _vezne7_b        	_PORTC_6
#define _vezne8_b        	_PORTC_7
#define _vezne9_b        	_PORTA_3
#define _vezne10_b       	_PORTA_5
#define _buzzer          	_PORTE_2
#define _reset_b         	_PORTA_4
#define _PORTA_4         	 PORTA, 004h
#define _PORTA_5         	 PORTA, 005h
#define _PORTA_3         	 PORTA, 003h
#define _PORTE_0         	 PORTE, 000h
#define _PORTE_1         	 PORTE, 001h
#define _PORTC_0         	 PORTC, 000h
#define _PORTC_1         	 PORTC, 001h
#define _PORTC_2         	 PORTC, 002h
#define _PORTC_3         	 PORTC, 003h
#define _PORTC_4         	 PORTC, 004h
#define _PORTC_5         	 PORTC, 005h
#define _PORTC_6         	 PORTC, 006h
#define _PORTC_7         	 PORTC, 007h
#define _PORTE_2         	 PORTE, 002h
#define _INTCON_2        	 INTCON, 002h
	INCLUDE	"BANKA_~1.MAC"
	INCLUDE	"C:\PROGRA~1\MECANI~1\MCSP\PBP2.46\PBPPIC18.LIB"

	MOVE?CB	007h, ADCON1
	MOVE?CB	038h, TRISA
	MOVE?CB	000h, PORTA
	MOVE?CB	0C0h, TRISB
	MOVE?CB	030h, PORTB
	MOVE?CB	0FFh, TRISC
	MOVE?CB	000h, PORTC
	MOVE?CB	000h, TRISE
	MOVE?CB	003h, PORTE
	MOVE?CB	000h, TRISD
	MOVE?CB	000h, PORTD
	GOTO?L	_animation_devam

	LABEL?L	_animation	
	MOVE?CB	001h, _repat
	LABEL?L	L00002	
	CMPGT?BCL	_repat, 004h, L00003
	CALL?L	_shape1
	CALL?L	_goster1
	CALL?L	_shape2
	CALL?L	_goster1
	CALL?L	_shape3
	CALL?L	_goster1
	CALL?L	_shape4
	CALL?L	_goster1
	CALL?L	_shape5
	CALL?L	_goster1
	CALL?L	_shape6
	CALL?L	_goster1
	NEXT?BCL	_repat, 001h, L00002
	LABEL?L	L00003	

	LABEL?L	_animation_1	
	MOVE?CB	001h, _c
	LABEL?L	L00004	
	CMPGT?BCL	_c, 00Fh, L00005
	MOVE?CB	001h, _a
	LABEL?L	L00006	
	CMPGT?BCL	_a, 006h, L00007
	CALL?L	_sec
	CALL?L	_sec1
	CALL?L	_goster1
	NEXT?BCL	_a, 001h, L00006
	LABEL?L	L00007	
	NEXT?BCL	_c, 001h, L00004
	LABEL?L	L00005	
	MOVE?CB	001h, _z
	LABEL?L	L00008	
	CMPGT?BCL	_z, 028h, L00009
	CALL?L	_goster1
	NEXT?BCL	_z, 001h, L00008
	LABEL?L	L00009	
	RETURN?	

	LABEL?L	_sec	
	CMPNE?BCL	_a, 001h, L00012
	CALL?L	_shape1
	RETURN?	
	GOTO?L	L00011
	LABEL?L	L00012	
	CMPNE?BCL	_a, 002h, L00013
	CALL?L	_shape2
	RETURN?	
	GOTO?L	L00011
	LABEL?L	L00013	
	CMPNE?BCL	_a, 003h, L00014
	CALL?L	_shape3
	RETURN?	
	GOTO?L	L00011
	LABEL?L	L00014	
	CMPNE?BCL	_a, 004h, L00015
	CALL?L	_shape4
	RETURN?	
	GOTO?L	L00011
	LABEL?L	L00015	
	CMPNE?BCL	_a, 005h, L00016
	CALL?L	_shape5
	RETURN?	
	GOTO?L	L00011
	LABEL?L	L00016	
	CMPNE?BCL	_a, 006h, L00017
	CALL?L	_shape6
	RETURN?	
	LABEL?L	L00017	
	LABEL?L	L00011	

	LABEL?L	_sec1	
	CMPNE?BCL	_c, 001h, L00020
	CALL?L	_shape_1
	RETURN?	
	GOTO?L	L00019
	LABEL?L	L00020	
	CMPNE?BCL	_c, 002h, L00021
	CALL?L	_shape_1
	CALL?L	_shape_2
	RETURN?	
	GOTO?L	L00019
	LABEL?L	L00021	
	CMPNE?BCL	_c, 003h, L00022
	CALL?L	_shape_1
	CALL?L	_shape_2
	CALL?L	_shape_3
	RETURN?	
	GOTO?L	L00019
	LABEL?L	L00022	
	CMPNE?BCL	_c, 004h, L00023
	CALL?L	_shape_1
	CALL?L	_shape_2
	CALL?L	_shape_3
	CALL?L	_shape_4
	RETURN?	
	GOTO?L	L00019
	LABEL?L	L00023	
	CMPNE?BCL	_c, 005h, L00024
	CALL?L	_shape_1
	CALL?L	_shape_2
	CALL?L	_shape_3
	CALL?L	_shape_4
	CALL?L	_shape_5
	RETURN?	
	GOTO?L	L00019
	LABEL?L	L00024	
	CMPNE?BCL	_c, 006h, L00025
	CALL?L	_shape_1
	CALL?L	_shape_2
	CALL?L	_shape_3
	CALL?L	_shape_4
	CALL?L	_shape_5
	CALL?L	_shape_6
	RETURN?	
	GOTO?L	L00019
	LABEL?L	L00025	
	CMPNE?BCL	_c, 007h, L00026
	CALL?L	_shape_1
	CALL?L	_shape_2
	CALL?L	_shape_3
	CALL?L	_shape_4
	CALL?L	_shape_5
	CALL?L	_shape_6
	CALL?L	_shape_7
	RETURN?	
	GOTO?L	L00019
	LABEL?L	L00026	
	CMPNE?BCL	_c, 008h, L00027
	CALL?L	_shape_1
	CALL?L	_shape_2
	CALL?L	_shape_3
	CALL?L	_shape_4
	CALL?L	_shape_5
	CALL?L	_shape_6
	CALL?L	_shape_7
	CALL?L	_shape_8
	RETURN?	
	GOTO?L	L00019
	LABEL?L	L00027	
	CMPNE?BCL	_c, 009h, L00028
	CALL?L	_shape_1
	CALL?L	_shape_2
	CALL?L	_shape_3
	CALL?L	_shape_4
	CALL?L	_shape_5
	CALL?L	_shape_6
	CALL?L	_shape_7
	CALL?L	_shape_8
	CALL?L	_shape_9
	RETURN?	
	GOTO?L	L00019
	LABEL?L	L00028	
	CMPNE?BCL	_c, 00Ah, L00029
	CALL?L	_shape_1
	CALL?L	_shape_2
	CALL?L	_shape_3
	CALL?L	_shape_4
	CALL?L	_shape_5
	CALL?L	_shape_6
	CALL?L	_shape_7
	CALL?L	_shape_8
	CALL?L	_shape_9
	CALL?L	_shape_10
	RETURN?	
	GOTO?L	L00019
	LABEL?L	L00029	
	CMPNE?BCL	_c, 00Bh, L00030
	CALL?L	_shape_1
	CALL?L	_shape_2
	CALL?L	_shape_3
	CALL?L	_shape_4
	CALL?L	_shape_5
	CALL?L	_shape_6
	CALL?L	_shape_7
	CALL?L	_shape_8
	CALL?L	_shape_9
	CALL?L	_shape_10
	CALL?L	_shape_11
	RETURN?	
	GOTO?L	L00019
	LABEL?L	L00030	
	CMPNE?BCL	_c, 00Ch, L00031
	CALL?L	_shape_1
	CALL?L	_shape_2
	CALL?L	_shape_3
	CALL?L	_shape_4
	CALL?L	_shape_5
	CALL?L	_shape_6
	CALL?L	_shape_7
	CALL?L	_shape_8
	CALL?L	_shape_9
	CALL?L	_shape_10
	CALL?L	_shape_11
	CALL?L	_shape_12
	RETURN?	
	GOTO?L	L00019
	LABEL?L	L00031	
	CMPNE?BCL	_c, 00Dh, L00032
	CALL?L	_shape_1
	CALL?L	_shape_2
	CALL?L	_shape_3
	CALL?L	_shape_4
	CALL?L	_shape_5
	CALL?L	_shape_6
	CALL?L	_shape_7
	CALL?L	_shape_8
	CALL?L	_shape_9
	CALL?L	_shape_10
	CALL?L	_shape_11
	CALL?L	_shape_12
	CALL?L	_shape_13
	RETURN?	
	GOTO?L	L00019
	LABEL?L	L00032	
	CMPNE?BCL	_c, 00Eh, L00033
	CALL?L	_shape_1
	CALL?L	_shape_2
	CALL?L	_shape_3
	CALL?L	_shape_4
	CALL?L	_shape_5
	CALL?L	_shape_6
	CALL?L	_shape_7
	CALL?L	_shape_8
	CALL?L	_shape_9
	CALL?L	_shape_10
	CALL?L	_shape_11
	CALL?L	_shape_12
	CALL?L	_shape_13
	CALL?L	_shape_14
	RETURN?	
	GOTO?L	L00019
	LABEL?L	L00033	
	CMPNE?BCL	_c, 00Fh, L00034
	CALL?L	_shape_1
	CALL?L	_shape_2
	CALL?L	_shape_3
	CALL?L	_shape_4
	CALL?L	_shape_5
	CALL?L	_shape_6
	CALL?L	_shape_7
	CALL?L	_shape_8
	CALL?L	_shape_9
	CALL?L	_shape_10
	CALL?L	_shape_11
	CALL?L	_shape_12
	CALL?L	_shape_13
	CALL?L	_shape_14
	CALL?L	_shape_15
	RETURN?	
	LABEL?L	L00034	
	LABEL?L	L00019	

	LABEL?L	_shape_1	
	MOVE?CB	073h, _animasyon_reg
	MOVE?BB	_animasyon_reg, _vezne_reg + 0001Dh
	MOVE?BB	_animasyon_reg, _vezne_reg + 0000Eh
	RETURN?	

	LABEL?L	_shape_2	
	MOVE?CB	006h, _animasyon_reg
	MOVE?BB	_animasyon_reg, _vezne_reg + 0001Ch
	MOVE?BB	_animasyon_reg, _vezne_reg + 0000Dh
	RETURN?	

	LABEL?L	_shape_3	
	MOVE?CB	039h, _animasyon_reg
	MOVE?BB	_animasyon_reg, _vezne_reg + 0001Bh
	MOVE?BB	_animasyon_reg, _vezne_reg + 0000Ch
	RETURN?	

	LABEL?L	_shape_4	
	MOVE?CB	008h, _animasyon_reg
	MOVE?BB	_animasyon_reg, _vezne_reg + 0001Ah
	MOVE?BB	_animasyon_reg, _vezne_reg + 0000Bh
	RETURN?	

	LABEL?L	_shape_5	
	MOVE?CB	073h, _animasyon_reg
	MOVE?BB	_animasyon_reg, _vezne_reg + 00019h
	MOVE?BB	_animasyon_reg, _vezne_reg + 0000Ah
	RETURN?	

	LABEL?L	_shape_6	
	MOVE?CB	050h, _animasyon_reg
	MOVE?BB	_animasyon_reg, _vezne_reg + 00018h
	MOVE?BB	_animasyon_reg, _vezne_reg + 00009h
	RETURN?	

	LABEL?L	_shape_7	
	MOVE?CB	03Fh, _animasyon_reg
	MOVE?BB	_animasyon_reg, _vezne_reg + 00017h
	MOVE?BB	_animasyon_reg, _vezne_reg + 00008h
	RETURN?	

	LABEL?L	_shape_8	
	MOVE?CB	00Eh, _animasyon_reg
	MOVE?BB	_animasyon_reg, _vezne_reg + 00016h
	MOVE?BB	_animasyon_reg, _vezne_reg + 00007h
	RETURN?	

	LABEL?L	_shape_9	
	MOVE?CB	079h, _animasyon_reg
	MOVE?BB	_animasyon_reg, _vezne_reg + 00015h
	MOVE?BB	_animasyon_reg, _vezne_reg + 00006h
	RETURN?	

	LABEL?L	_shape_10	
	MOVE?CB	008h, _animasyon_reg
	MOVE?BB	_animasyon_reg, _vezne_reg + 00014h
	MOVE?BB	_animasyon_reg, _vezne_reg + 00005h
	RETURN?	

	LABEL?L	_shape_11	
	MOVE?CB	03Fh, _animasyon_reg
	MOVE?BB	_animasyon_reg, _vezne_reg + 00013h
	MOVE?BB	_animasyon_reg, _vezne_reg + 00004h
	RETURN?	

	LABEL?L	_shape_12	
	MOVE?CB	050h, _animasyon_reg
	MOVE?BB	_animasyon_reg, _vezne_reg + 00012h
	MOVE?BB	_animasyon_reg, _vezne_reg + 00003h
	RETURN?	

	LABEL?L	_shape_13	
	MOVE?CB	07Dh, _animasyon_reg
	MOVE?BB	_animasyon_reg, _vezne_reg + 00011h
	MOVE?BB	_animasyon_reg, _vezne_reg + 00002h
	RETURN?	

	LABEL?L	_shape_14	
	MOVE?CB	000h, _animasyon_reg
	MOVE?BB	_animasyon_reg, _vezne_reg + 00010h
	MOVE?BB	_animasyon_reg, _vezne_reg + 00001h
	RETURN?	

	LABEL?L	_shape_15	
	MOVE?CB	000h, _animasyon_reg
	MOVE?BB	_animasyon_reg, _vezne_reg + 0000Fh
	MOVE?BB	_animasyon_reg, _vezne_reg
	RETURN?	

	LABEL?L	_shape1	
	MOVE?CB	001h, _animasyon_reg
	MOVE?CB	000h, _z
	LABEL?L	L00035	
	CMPGT?BCL	_z, 01Dh, L00036
	AIN?BBB	_animasyon_reg, _vezne_reg, _y
	ADD?BCB	_y, 001h, _y
	NEXT?BCL	_z, 001h, L00035
	LABEL?L	L00036	
	RETURN?	

	LABEL?L	_shape2	
	MOVE?CB	002h, _animasyon_reg
	MOVE?CB	000h, _z
	LABEL?L	L00037	
	CMPGT?BCL	_z, 01Dh, L00038
	AIN?BBB	_animasyon_reg, _vezne_reg, _y
	ADD?BCB	_y, 001h, _y
	NEXT?BCL	_z, 001h, L00037
	LABEL?L	L00038	
	RETURN?	

	LABEL?L	_shape3	
	MOVE?CB	004h, _animasyon_reg
	MOVE?CB	000h, _z
	LABEL?L	L00039	
	CMPGT?BCL	_z, 01Dh, L00040
	AIN?BBB	_animasyon_reg, _vezne_reg, _y
	ADD?BCB	_y, 001h, _y
	NEXT?BCL	_z, 001h, L00039
	LABEL?L	L00040	
	RETURN?	

	LABEL?L	_shape4	
	MOVE?CB	008h, _animasyon_reg
	MOVE?CB	000h, _z
	LABEL?L	L00041	
	CMPGT?BCL	_z, 01Dh, L00042
	AIN?BBB	_animasyon_reg, _vezne_reg, _y
	ADD?BCB	_y, 001h, _y
	NEXT?BCL	_z, 001h, L00041
	LABEL?L	L00042	
	RETURN?	

	LABEL?L	_shape5	
	MOVE?CB	010h, _animasyon_reg
	MOVE?CB	000h, _z
	LABEL?L	L00043	
	CMPGT?BCL	_z, 01Dh, L00044
	AIN?BBB	_animasyon_reg, _vezne_reg, _y
	ADD?BCB	_y, 001h, _y
	NEXT?BCL	_z, 001h, L00043
	LABEL?L	L00044	
	RETURN?	

	LABEL?L	_shape6	
	MOVE?CB	020h, _animasyon_reg
	MOVE?CB	000h, _z
	LABEL?L	L00045	
	CMPGT?BCL	_z, 01Dh, L00046
	AIN?BBB	_animasyon_reg, _vezne_reg, _y
	ADD?BCB	_y, 001h, _y
	NEXT?BCL	_z, 001h, L00045
	LABEL?L	L00046	
	RETURN?	

	LABEL?L	_animation_devam	
	MOVE?CB	000h, _y
	CALL?L	_animation
	MOVE?CB	000h, _y
	MOVE?CB	000h, _vezne_no
	MOVE?CB	000h, _tekrar_reg
	MOVE?CB	000h, _vezne_no_birler
	MOVE?CB	000h, _vezne_no_onlar
	MOVE?CB	000h, _sayac_reg
	MOVE?CB	000h, _sayac_reg + 00001h
	MOVE?CB	000h, _sayac_reg + 00002h
	MOVE?CB	000h, _numara_reg
	MOVE?CB	000h, _numara_reg + 00001h
	MOVE?CB	000h, _numara_reg + 00002h
	MOVE?CT	001h, _vezne_enable
	MOVE?CT	001h, _sira_enable
	MOVE?CB	000h, _z
	LABEL?L	L00047	
	CMPGT?BCL	_z, 01Dh, L00048
	AIN?CBB	000h, _vezne_reg, _y
	ADD?BCB	_y, 001h, _y
	NEXT?BCL	_z, 001h, L00047
	LABEL?L	L00048	
	MOVE?CB	0A0h, INTCON
	MOVE?CB	0C6h, T0CON
	GOTO?L	_loop
	ONINT?LL	_myint, L00001

	LABEL?L	_myint	
	DISABLE?	
	CMPNE?BCL	_tasma, 04Bh, L00049
	MOVE?CB	000h, _tasma
	CMPNE?BCL	_tekrar_reg, 000h, L00051
	MOVE?CT	000h, _INTCON_2
	GOTO?L	_myint_go
	LABEL?L	L00051	
	TOGGLE?T	_vezne_enable
	TOGGLE?T	_sira_enable
	SUB?BCB	_tekrar_reg, 001h, _tekrar_reg
	MOVE?CT	000h, _INTCON_2
	GOTO?L	_myint_go
	LABEL?L	L00049	
	ADD?BCB	_tasma, 001h, _tasma
	MOVE?CT	000h, _INTCON_2

	LABEL?L	_myint_go	
	RESUME?	
	ENABLE?	

	LABEL?L	_loop	
	ICALL?L	L00001
	CALL?L	_goster
	ICALL?L	L00001
	CMPNE?TCL	_reset_b, 001h, L00053
	ICALL?L	L00001
	CALL?L	_reset_at
	ICALL?L	L00001
	CALL?L	_buzer1
	ICALL?L	L00001
	CALL?L	_buzer2
	ICALL?L	L00001
	CALL?L	_buzer1
	ICALL?L	L00001
	CALL?L	_buzer2
	ICALL?L	L00001
	CALL?L	_buzer1
	ICALL?L	L00001
	CALL?L	_buzer2
	ICALL?L	L00001
	GOTO?L	_loop
	ICALL?L	L00001
	LABEL?L	L00053	
	ICALL?L	L00001
	CMPNE?TCL	_vezne1_b, 001h, L00055
	ICALL?L	L00001
	MOVE?CB	000h, _vezne_bul
	ICALL?L	L00001
	MOVE?CB	001h, _vezne_no
	ICALL?L	L00001
	MOVE?CB	00Ah, _tekrar_reg
	ICALL?L	L00001
	MOVE?CT	001h, _vezne_enable
	ICALL?L	L00001
	MOVE?CT	001h, _sira_enable
	ICALL?L	L00001
	CALL?L	_vezne_art
	ICALL?L	L00001
	CALL?L	_buzer
	ICALL?L	L00001
	GOTO?L	_loop
	ICALL?L	L00001
	LABEL?L	L00055	
	ICALL?L	L00001
	CMPNE?TCL	_vezne2_b, 001h, L00057
	ICALL?L	L00001
	MOVE?CB	003h, _vezne_bul
	ICALL?L	L00001
	MOVE?CB	002h, _vezne_no
	ICALL?L	L00001
	MOVE?CB	00Ah, _tekrar_reg
	ICALL?L	L00001
	MOVE?CT	001h, _vezne_enable
	ICALL?L	L00001
	MOVE?CT	001h, _sira_enable
	ICALL?L	L00001
	CALL?L	_vezne_art
	ICALL?L	L00001
	CALL?L	_buzer
	ICALL?L	L00001
	GOTO?L	_loop
	ICALL?L	L00001
	LABEL?L	L00057	
	ICALL?L	L00001
	CMPNE?TCL	_vezne3_b, 001h, L00059
	ICALL?L	L00001
	MOVE?CB	006h, _vezne_bul
	ICALL?L	L00001
	MOVE?CB	003h, _vezne_no
	ICALL?L	L00001
	MOVE?CB	00Ah, _tekrar_reg
	ICALL?L	L00001
	MOVE?CT	001h, _vezne_enable
	ICALL?L	L00001
	MOVE?CT	001h, _sira_enable
	ICALL?L	L00001
	CALL?L	_vezne_art
	ICALL?L	L00001
	CALL?L	_buzer
	ICALL?L	L00001
	GOTO?L	_loop
	ICALL?L	L00001
	LABEL?L	L00059	
	ICALL?L	L00001
	CMPNE?TCL	_vezne4_b, 001h, L00061
	ICALL?L	L00001
	MOVE?CB	009h, _vezne_bul
	ICALL?L	L00001
	MOVE?CB	004h, _vezne_no
	ICALL?L	L00001
	MOVE?CB	00Ah, _tekrar_reg
	ICALL?L	L00001
	MOVE?CT	001h, _vezne_enable
	ICALL?L	L00001
	MOVE?CT	001h, _sira_enable
	ICALL?L	L00001
	CALL?L	_vezne_art
	ICALL?L	L00001
	CALL?L	_buzer
	ICALL?L	L00001
	GOTO?L	_loop
	ICALL?L	L00001
	LABEL?L	L00061	
	ICALL?L	L00001
	CMPNE?TCL	_vezne5_b, 001h, L00063
	ICALL?L	L00001
	MOVE?CB	00Ch, _vezne_bul
	ICALL?L	L00001
	MOVE?CB	005h, _vezne_no
	ICALL?L	L00001
	MOVE?CB	00Ah, _tekrar_reg
	ICALL?L	L00001
	MOVE?CT	001h, _vezne_enable
	ICALL?L	L00001
	MOVE?CT	001h, _sira_enable
	ICALL?L	L00001
	CALL?L	_vezne_art
	ICALL?L	L00001
	CALL?L	_buzer
	ICALL?L	L00001
	GOTO?L	_loop
	ICALL?L	L00001
	LABEL?L	L00063	
	ICALL?L	L00001
	CMPNE?TCL	_vezne6_b, 001h, L00065
	ICALL?L	L00001
	MOVE?CB	00Fh, _vezne_bul
	ICALL?L	L00001
	MOVE?CB	006h, _vezne_no
	ICALL?L	L00001
	MOVE?CB	00Ah, _tekrar_reg
	ICALL?L	L00001
	MOVE?CT	001h, _vezne_enable
	ICALL?L	L00001
	MOVE?CT	001h, _sira_enable
	ICALL?L	L00001
	CALL?L	_vezne_art
	ICALL?L	L00001
	CALL?L	_buzer
	ICALL?L	L00001
	GOTO?L	_loop
	ICALL?L	L00001
	LABEL?L	L00065	
	ICALL?L	L00001
	CMPNE?TCL	_vezne7_b, 001h, L00067
	ICALL?L	L00001
	MOVE?CB	012h, _vezne_bul
	ICALL?L	L00001
	MOVE?CB	007h, _vezne_no
	ICALL?L	L00001
	MOVE?CB	00Ah, _tekrar_reg
	ICALL?L	L00001
	MOVE?CT	001h, _vezne_enable
	ICALL?L	L00001
	MOVE?CT	001h, _sira_enable
	ICALL?L	L00001
	CALL?L	_vezne_art
	ICALL?L	L00001
	CALL?L	_buzer
	ICALL?L	L00001
	GOTO?L	_loop
	ICALL?L	L00001
	LABEL?L	L00067	
	ICALL?L	L00001
	CMPNE?TCL	_vezne8_b, 001h, L00069
	ICALL?L	L00001
	MOVE?CB	015h, _vezne_bul
	ICALL?L	L00001
	MOVE?CB	008h, _vezne_no
	ICALL?L	L00001
	MOVE?CB	00Ah, _tekrar_reg
	ICALL?L	L00001
	MOVE?CT	001h, _vezne_enable
	ICALL?L	L00001
	MOVE?CT	001h, _sira_enable
	ICALL?L	L00001
	CALL?L	_vezne_art
	ICALL?L	L00001
	CALL?L	_buzer
	ICALL?L	L00001
	GOTO?L	_loop
	ICALL?L	L00001
	LABEL?L	L00069	
	ICALL?L	L00001
	CMPNE?TCL	_vezne9_b, 001h, L00071
	ICALL?L	L00001
	MOVE?CB	018h, _vezne_bul
	ICALL?L	L00001
	MOVE?CB	009h, _vezne_no
	ICALL?L	L00001
	MOVE?CB	00Ah, _tekrar_reg
	ICALL?L	L00001
	MOVE?CT	001h, _vezne_enable
	ICALL?L	L00001
	MOVE?CT	001h, _sira_enable
	ICALL?L	L00001
	CALL?L	_vezne_art
	ICALL?L	L00001
	CALL?L	_buzer
	ICALL?L	L00001
	GOTO?L	_loop
	ICALL?L	L00001
	LABEL?L	L00071	
	ICALL?L	L00001
	CMPNE?TCL	_vezne10_b, 001h, L00073
	ICALL?L	L00001
	MOVE?CB	01Bh, _vezne_bul
	ICALL?L	L00001
	MOVE?CB	00Ah, _vezne_no
	ICALL?L	L00001
	MOVE?CB	00Ah, _tekrar_reg
	ICALL?L	L00001
	MOVE?CT	001h, _vezne_enable
	ICALL?L	L00001
	MOVE?CT	001h, _sira_enable
	ICALL?L	L00001
	CALL?L	_vezne_art
	ICALL?L	L00001
	CALL?L	_buzer
	ICALL?L	L00001
	GOTO?L	_loop
	ICALL?L	L00001
	LABEL?L	L00073	
	ICALL?L	L00001
	GOTO?L	_loop

	LABEL?L	_reset_at	
	ICALL?L	L00001
	MOVE?CB	000h, _y
	ICALL?L	L00001
	MOVE?CB	000h, _vezne_no
	ICALL?L	L00001
	MOVE?CB	000h, _vezne_no_birler
	ICALL?L	L00001
	MOVE?CB	000h, _vezne_no_onlar
	ICALL?L	L00001
	MOVE?CB	000h, _sayac_reg
	ICALL?L	L00001
	MOVE?CB	000h, _sayac_reg + 00001h
	ICALL?L	L00001
	MOVE?CB	000h, _sayac_reg + 00002h
	ICALL?L	L00001
	MOVE?CB	000h, _numara_reg
	ICALL?L	L00001
	MOVE?CB	000h, _numara_reg + 00001h
	ICALL?L	L00001
	MOVE?CB	000h, _numara_reg + 00002h
	ICALL?L	L00001
	MOVE?CB	000h, _z
	LABEL?L	L00075	
	CMPGT?BCL	_z, 01Dh, L00076
	ICALL?L	L00001
	AIN?CBB	000h, _vezne_reg, _y
	ICALL?L	L00001
	ADD?BCB	_y, 001h, _y
	ICALL?L	L00001
	NEXT?BCL	_z, 001h, L00075
	LABEL?L	L00076	
	ICALL?L	L00001
	RETURN?	

	LABEL?L	_vezne_art	
	ICALL?L	L00001
	CMPNE?BCL	_sayac_reg, 009h, L00077
	ICALL?L	L00001
	CMPNE?BCL	_sayac_reg + 00001h, 009h, L00079
	ICALL?L	L00001
	CMPNE?BCL	_sayac_reg + 00002h, 009h, L00081
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	LABEL?L	L00081	
	ICALL?L	L00001
	MOVE?CB	000h, _sayac_reg + 00001h
	ICALL?L	L00001
	MOVE?CB	000h, _sayac_reg
	ICALL?L	L00001
	ADD?BCB	_sayac_reg + 00002h, 001h, _sayac_reg + 00002h
	ICALL?L	L00001
	GOTO?L	_vezne_aktar
	ICALL?L	L00001
	LABEL?L	L00079	
	ICALL?L	L00001
	MOVE?CB	000h, _sayac_reg
	ICALL?L	L00001
	ADD?BCB	_sayac_reg + 00001h, 001h, _sayac_reg + 00001h
	ICALL?L	L00001
	GOTO?L	_vezne_aktar
	ICALL?L	L00001
	LABEL?L	L00077	
	ICALL?L	L00001
	ADD?BCB	_sayac_reg, 001h, _sayac_reg
	ICALL?L	L00001
	GOTO?L	_vezne_aktar

	LABEL?L	_vezne_aktar	
	ICALL?L	L00001
	AIN?BBB	_sayac_reg, _vezne_reg, _vezne_bul
	ICALL?L	L00001
	ADD?BCW	_vezne_bul, 001h, T1
	AIN?BBW	_sayac_reg + 00001h, _vezne_reg, T1
	ICALL?L	L00001
	ADD?BCW	_vezne_bul, 002h, T1
	AIN?BBW	_sayac_reg + 00002h, _vezne_reg, T1
	ICALL?L	L00001
	MOVE?BB	_sayac_reg, _numara_reg
	ICALL?L	L00001
	MOVE?BB	_sayac_reg + 00001h, _numara_reg + 00001h
	ICALL?L	L00001
	MOVE?BB	_sayac_reg + 00002h, _numara_reg + 00002h
	ICALL?L	L00001
	RETURN?	

	LABEL?L	_goster	
	ICALL?L	L00001
	MOVE?CB	001h, _i
	LABEL?L	L00083	
	CMPGT?BCL	_i, 00Fh, L00084
	ICALL?L	L00001
	MOVE?BB	_i, PORTB
	ICALL?L	L00001
	AOUT?BBB	_vezne_reg, _y, _lcd_reg
	ICALL?L	L00001
	ADD?BCB	_y, 001h, _y
	ICALL?L	L00001
	CALL?L	_cevir
	ICALL?L	L00001
	MOVE?BB	_lcd_reg, PORTD
	ICALL?L	L00001
	LOW?T	_en1
	ICALL?L	L00001
	PAUSEUS?C	064h
	ICALL?L	L00001
	HIGH?T	_en1
	ICALL?L	L00001
	NEXT?BCL	_i, 001h, L00083
	LABEL?L	L00084	
	ICALL?L	L00001
	MOVE?CB	001h, _i
	LABEL?L	L00085	
	CMPGT?BCL	_i, 00Fh, L00086
	ICALL?L	L00001
	MOVE?BB	_i, PORTB
	ICALL?L	L00001
	AOUT?BBB	_vezne_reg, _y, _lcd_reg
	ICALL?L	L00001
	ADD?BCB	_y, 001h, _y
	ICALL?L	L00001
	CALL?L	_cevir
	ICALL?L	L00001
	MOVE?BB	_lcd_reg, PORTD
	ICALL?L	L00001
	LOW?T	_en2
	ICALL?L	L00001
	PAUSEUS?C	064h
	ICALL?L	L00001
	HIGH?T	_en2
	ICALL?L	L00001
	NEXT?BCL	_i, 001h, L00085
	LABEL?L	L00086	
	ICALL?L	L00001
	MOVE?CB	000h, _y
	ICALL?L	L00001
	MOVE?BB	_numara_reg, _lcd_reg
	ICALL?L	L00001
	CALL?L	_cevir
	ICALL?L	L00001
	MOVE?BB	_lcd_reg, PORTD
	ICALL?L	L00001
	CMPNE?TCL	_sira_enable, 000h, L00087
	MOVE?CB	000h, PORTD
	LABEL?L	L00087	
	ICALL?L	L00001
	MOVE?CB	003h, PORTA
	ICALL?L	L00001
	PAUSEUS?C	064h
	ICALL?L	L00001
	MOVE?CB	000h, PORTA
	ICALL?L	L00001
	MOVE?BB	_numara_reg + 00001h, _lcd_reg
	ICALL?L	L00001
	CALL?L	_cevir
	ICALL?L	L00001
	MOVE?BB	_lcd_reg, PORTD
	ICALL?L	L00001
	CMPNE?TCL	_sira_enable, 000h, L00089
	MOVE?CB	000h, PORTD
	LABEL?L	L00089	
	ICALL?L	L00001
	MOVE?CB	002h, PORTA
	ICALL?L	L00001
	PAUSEUS?C	064h
	ICALL?L	L00001
	MOVE?CB	000h, PORTA
	ICALL?L	L00001
	MOVE?BB	_numara_reg + 00002h, _lcd_reg
	ICALL?L	L00001
	CALL?L	_cevir
	ICALL?L	L00001
	MOVE?BB	_lcd_reg, PORTD
	ICALL?L	L00001
	CMPNE?TCL	_sira_enable, 000h, L00091
	MOVE?CB	000h, PORTD
	LABEL?L	L00091	
	ICALL?L	L00001
	MOVE?CB	001h, PORTA
	ICALL?L	L00001
	PAUSEUS?C	064h
	ICALL?L	L00001
	MOVE?CB	000h, PORTA
	ICALL?L	L00001
	CALL?L	_vezne_no_bul
	ICALL?L	L00001
	MOVE?BB	_vezne_no_onlar, _lcd_reg
	ICALL?L	L00001
	CALL?L	_cevir
	ICALL?L	L00001
	MOVE?BB	_lcd_reg, PORTD
	ICALL?L	L00001
	CMPNE?TCL	_vezne_enable, 000h, L00093
	MOVE?CB	000h, PORTD
	LABEL?L	L00093	
	ICALL?L	L00001
	MOVE?CB	004h, PORTA
	ICALL?L	L00001
	PAUSEUS?C	064h
	ICALL?L	L00001
	MOVE?CB	000h, PORTA
	ICALL?L	L00001
	MOVE?BB	_vezne_no_birler, _lcd_reg
	ICALL?L	L00001
	CALL?L	_cevir
	ICALL?L	L00001
	MOVE?BB	_lcd_reg, PORTD
	ICALL?L	L00001
	CMPNE?TCL	_vezne_enable, 000h, L00095
	MOVE?CB	000h, PORTD
	LABEL?L	L00095	
	ICALL?L	L00001
	MOVE?CB	005h, PORTA
	ICALL?L	L00001
	PAUSEUS?C	064h
	ICALL?L	L00001
	MOVE?CB	000h, PORTA
	ICALL?L	L00001
	RETURN?	

	LABEL?L	_goster1	
	ICALL?L	L00001
	MOVE?CB	000h, _y
	ICALL?L	L00001
	MOVE?CB	001h, _b
	LABEL?L	L00097	
	CMPGT?BCL	_b, 014h, L00098
	ICALL?L	L00001
	MOVE?CB	001h, _i
	LABEL?L	L00099	
	CMPGT?BCL	_i, 00Fh, L00100
	ICALL?L	L00001
	MOVE?BB	_i, PORTB
	ICALL?L	L00001
	AOUT?BBB	_vezne_reg, _y, PORTD
	ICALL?L	L00001
	ADD?BCB	_y, 001h, _y
	ICALL?L	L00001
	LOW?T	_en1
	ICALL?L	L00001
	PAUSEUS?C	064h
	ICALL?L	L00001
	HIGH?T	_en1
	ICALL?L	L00001
	NEXT?BCL	_i, 001h, L00099
	LABEL?L	L00100	
	ICALL?L	L00001
	MOVE?CB	001h, _i
	LABEL?L	L00101	
	CMPGT?BCL	_i, 00Fh, L00102
	ICALL?L	L00001
	MOVE?BB	_i, PORTB
	ICALL?L	L00001
	AOUT?BBB	_vezne_reg, _y, PORTD
	ICALL?L	L00001
	ADD?BCB	_y, 001h, _y
	ICALL?L	L00001
	LOW?T	_en2
	ICALL?L	L00001
	PAUSEUS?C	064h
	ICALL?L	L00001
	HIGH?T	_en2
	ICALL?L	L00001
	NEXT?BCL	_i, 001h, L00101
	LABEL?L	L00102	
	ICALL?L	L00001
	MOVE?CB	000h, _y
	ICALL?L	L00001
	NEXT?BCL	_b, 001h, L00097
	LABEL?L	L00098	
	ICALL?L	L00001
	MOVE?CB	000h, _y
	ICALL?L	L00001
	RETURN?	

	LABEL?L	_vezne_no_bul	
	ICALL?L	L00001
	ICALL?L	L00001
	CMPNE?BCL	_vezne_no, 000h, L00105
	ICALL?L	L00001
	MOVE?CB	000h, _vezne_no_birler
	ICALL?L	L00001
	MOVE?CB	000h, _vezne_no_onlar
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00104
	LABEL?L	L00105	
	CMPNE?BCL	_vezne_no, 001h, L00106
	ICALL?L	L00001
	MOVE?CB	001h, _vezne_no_birler
	ICALL?L	L00001
	MOVE?CB	000h, _vezne_no_onlar
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00104
	LABEL?L	L00106	
	CMPNE?BCL	_vezne_no, 002h, L00107
	ICALL?L	L00001
	MOVE?CB	002h, _vezne_no_birler
	ICALL?L	L00001
	MOVE?CB	000h, _vezne_no_onlar
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00104
	LABEL?L	L00107	
	CMPNE?BCL	_vezne_no, 003h, L00108
	ICALL?L	L00001
	MOVE?CB	003h, _vezne_no_birler
	ICALL?L	L00001
	MOVE?CB	000h, _vezne_no_onlar
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00104
	LABEL?L	L00108	
	CMPNE?BCL	_vezne_no, 004h, L00109
	ICALL?L	L00001
	MOVE?CB	004h, _vezne_no_birler
	ICALL?L	L00001
	MOVE?CB	000h, _vezne_no_onlar
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00104
	LABEL?L	L00109	
	CMPNE?BCL	_vezne_no, 005h, L00110
	ICALL?L	L00001
	MOVE?CB	005h, _vezne_no_birler
	ICALL?L	L00001
	MOVE?CB	000h, _vezne_no_onlar
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00104
	LABEL?L	L00110	
	CMPNE?BCL	_vezne_no, 006h, L00111
	ICALL?L	L00001
	MOVE?CB	006h, _vezne_no_birler
	ICALL?L	L00001
	MOVE?CB	000h, _vezne_no_onlar
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00104
	LABEL?L	L00111	
	CMPNE?BCL	_vezne_no, 007h, L00112
	ICALL?L	L00001
	MOVE?CB	007h, _vezne_no_birler
	ICALL?L	L00001
	MOVE?CB	000h, _vezne_no_onlar
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00104
	LABEL?L	L00112	
	CMPNE?BCL	_vezne_no, 008h, L00113
	ICALL?L	L00001
	MOVE?CB	008h, _vezne_no_birler
	ICALL?L	L00001
	MOVE?CB	000h, _vezne_no_onlar
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00104
	LABEL?L	L00113	
	CMPNE?BCL	_vezne_no, 009h, L00114
	ICALL?L	L00001
	MOVE?CB	009h, _vezne_no_birler
	ICALL?L	L00001
	MOVE?CB	000h, _vezne_no_onlar
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00104
	LABEL?L	L00114	
	CMPNE?BCL	_vezne_no, 00Ah, L00115
	ICALL?L	L00001
	MOVE?CB	000h, _vezne_no_birler
	ICALL?L	L00001
	MOVE?CB	001h, _vezne_no_onlar
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	LABEL?L	L00115	
	LABEL?L	L00104	

	LABEL?L	_cevir	
	ICALL?L	L00001
	ICALL?L	L00001
	CMPNE?BCL	_lcd_reg, 000h, L00118
	ICALL?L	L00001
	MOVE?CB	03Fh, _lcd_reg
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00117
	LABEL?L	L00118	
	CMPNE?BCL	_lcd_reg, 001h, L00119
	ICALL?L	L00001
	MOVE?CB	006h, _lcd_reg
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00117
	LABEL?L	L00119	
	CMPNE?BCL	_lcd_reg, 002h, L00120
	ICALL?L	L00001
	MOVE?CB	05Bh, _lcd_reg
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00117
	LABEL?L	L00120	
	CMPNE?BCL	_lcd_reg, 003h, L00121
	ICALL?L	L00001
	MOVE?CB	04Fh, _lcd_reg
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00117
	LABEL?L	L00121	
	CMPNE?BCL	_lcd_reg, 004h, L00122
	ICALL?L	L00001
	MOVE?CB	066h, _lcd_reg
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00117
	LABEL?L	L00122	
	CMPNE?BCL	_lcd_reg, 005h, L00123
	ICALL?L	L00001
	MOVE?CB	06Dh, _lcd_reg
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00117
	LABEL?L	L00123	
	CMPNE?BCL	_lcd_reg, 006h, L00124
	ICALL?L	L00001
	MOVE?CB	07Dh, _lcd_reg
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00117
	LABEL?L	L00124	
	CMPNE?BCL	_lcd_reg, 007h, L00125
	ICALL?L	L00001
	MOVE?CB	007h, _lcd_reg
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00117
	LABEL?L	L00125	
	CMPNE?BCL	_lcd_reg, 008h, L00126
	ICALL?L	L00001
	MOVE?CB	07Fh, _lcd_reg
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	GOTO?L	L00117
	LABEL?L	L00126	
	CMPNE?BCL	_lcd_reg, 009h, L00127
	ICALL?L	L00001
	MOVE?CB	06Fh, _lcd_reg
	ICALL?L	L00001
	RETURN?	
	ICALL?L	L00001
	LABEL?L	L00127	
	LABEL?L	L00117	

	LABEL?L	_buzer	
	ICALL?L	L00001
	HIGH?T	_buzzer
	ICALL?L	L00001
	MOVE?CB	001h, _b
	LABEL?L	L00128	
	CMPGT?BCL	_b, 028h, L00129
	ICALL?L	L00001
	CALL?L	_goster
	ICALL?L	L00001
	NEXT?BCL	_b, 001h, L00128
	LABEL?L	L00129	
	ICALL?L	L00001
	LOW?T	_buzzer
	ICALL?L	L00001
	RETURN?	

	LABEL?L	_buzer1	
	ICALL?L	L00001
	HIGH?T	_buzzer
	ICALL?L	L00001
	MOVE?CB	001h, _b
	LABEL?L	L00130	
	CMPGT?BCL	_b, 073h, L00131
	ICALL?L	L00001
	CALL?L	_goster
	ICALL?L	L00001
	NEXT?BCL	_b, 001h, L00130
	LABEL?L	L00131	
	ICALL?L	L00001
	LOW?T	_buzzer
	ICALL?L	L00001
	RETURN?	

	LABEL?L	_buzer2	
	ICALL?L	L00001
	MOVE?CB	001h, _b
	LABEL?L	L00132	
	CMPGT?BCL	_b, 096h, L00133
	ICALL?L	L00001
	CALL?L	_goster
	ICALL?L	L00001
	NEXT?BCL	_b, 001h, L00132
	LABEL?L	L00133	
	ICALL?L	L00001
	RETURN?	

	END
