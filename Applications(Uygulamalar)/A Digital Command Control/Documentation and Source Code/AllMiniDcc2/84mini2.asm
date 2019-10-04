         LIST P=16F84
	include <p16c84.inc>
; File: minidcc2.asm
;
;This version includes service mode - 4 types
; 2 Standard speed steps - 14 and 28 (Selectable)
;
;This version works with both 16C84 or 16F84
;
;        
;DCC Controller - Using Multiplex Keyboard 4x4 and LCD Readout
;Drives four locomotives at any selectable address (3, 4, 5 and 6 default on initial startup)
;
;Function Fl supported - Headlights ON and OFF
;Output to Booster on Porta,0 RA0 (pin 17)
;Sync pulse on Porta,4 RA4 (pin3)  - used for scope testing (needs pullup)
; Note: in this version, the sync pulse has been replace with a complementary
; DCC output pulse designed at driving an L298 directly without the use
; of an inverter. (74ls04) - 
;Clock is 4mHz ceramic resonator (or Crystal)  - Timing based on this clock
;Configuration: XS - WatchDog (WDT):OFF - Power On Timer (PWT):ON
;
;The following are the connections from the PIC to the LCD module (pin 1-14) Standard 16x2 char.
;
;Enable for LCD on Porta,1 RA1 (pin 18) to LCD pin 6 - LCD Pin 5 R/W to Ground
;RS on Portb,4 RB4 (pin 10) to LCD pin 5 (this is the read select - data or instruction
;I/O 1 to 4 is on PortB 0 to 3 RB0-RB3 (pin 6,7,8 and 9) to LCD pin 11,12,13,14
; On the LCD, Pin 1 is ground and pin 2 is +5v - pin 3 is a voltage between 0-5v for contrast.
; Other pins are not used. This is using the 4 bit protocole for the LCD
;
; uses 4*4 matrix keybord with 2.2k between RB4-7 and keyboard and RB0-3
; Preset address 3-4-5 et 6 (Can be changed from 0 to 127 (display
;   will show only two last digits - 00 to 99 and 00 to 27)
;
;
; LDC Style:         |==================|
; (16 char x2 lines) | Loc:03*04*05-06* |
;                    | >000>000>022>002 |
;                    |==================| 
;
; First line indicates loco address with Star indicating Light ON
;   and "-" indicating lights off - Function Group 1 (FL)
; Direction "->" before speed indicates Forward or Reverse "<-" 
;
; Matrix keyboard 16 switches to control 4 locos
;
;
;      C1 C2 C3 C4
;     ===============
; R1  = 13 14 15 16 =
; R2  =  9 10 11 12 =
; R3  =  5  6  7  8 = 
; R4  =  1  2  3  4 =
;     ===============
; Note 1 : On my setup, I use the following buttons for various functions:
;       Button 1 = Speed Increase (step 0-31) - Loco 1 - address 03
;       button 2 = Speed Decrease 
;       Button 3 = Direction Change
;       Button 4 = Headlights On or OFF
;       Button 5 = Speed Increase (Loco2) etc...   address 04 ...
; I have a version with 128 speed steps - but it becomes tedious to 
; push the buttons to increase and decrease speed
; I am developing another version using a 16c71 (and) a 16c73 that uses
; four Potentiometers for speed control 
;
; Additional Switches on PortA,2 RA2 (Pin 1) and PortA,3 RA3 (Pin2)
;  for Emergency Stop Toggle (all locos) and Service Operations Mode toggle
;  Connect with Pull-up (appx 2.2k) to V+ and short to ground with switch
;
; LDC Style:         |==================|
; (16 char x2 lines) | Statn#1 #2 #3 #4 |
;                    | Addr 03`04 05 06 |
;                    |==================|
; 
;  Pressing Service mode switch brings up 2 programming functions:
;      1 - Station address programming
;               Press button 1 and 2 to change loco 1 Station address
;               Press button 5 and 6 to change loco 2 Station address
;               Press...
;      2 - To change from 28 to 14 step, press button - press button 4, 8,
;           12 and 16 respectively - a small ` will appear near the address
;           to indicate 14 speed mode.    
;      3 - Values in 1 and 2 above will remain in memory even with power off
;

; LDC Style:         |==================|
; (16 char x2 lines) | Serv Mode Pag/Rg |
;                    | CV:001-000 01-00 |
;                    |==================| 
;
;  Pressing Service mode once more will move to CV Programming mode
;       1 - In this mode, CV# are changed with button 1 and 2
;       2 - CV Values are changed with button 5 and 6
;       3 - Press button 3,7,11 or 15 to send signal to decoder
;          (Ensure only one decoder at a time on programming track)
;       4 - Four (4) modes of programming are supported:
;              Button 3 sends Page programming 
;                   (see right of display for Page/Reg information)
;              Button 7 sends Physical register code (1 to 8)
;              Button 11 sends Direct Programming code (1 to 256)
;              Button 15 sends Advanced Direct Programming (1 to 256)  
;
; Note 2 : It is possible to operate without the LCD readout (for a very
;          inexpensive DCC control) using LEDs on portb to show speed step.
; 	 : in this case just ignore the connection to the LCD module
;	 : on power-up, the default is a reset then forward all loco speed 0
;	 : by repeatedly pushing button 1, speed will increase from 0 to 31
;	 : going from Stop, EStop, 1,2,3,... to 28	           
; 
; Note 3 : A booster must be connected between the output of the 16c84 and the track
;	 :  many schematic exist on the internet - this is simple to build.
;
; Note 4 : This version was tested with Digitrax FX decoders (N and H)
;           programming mode works with all of them
;        ; Use Register and Page for MRC decoder
;        ; Advanced and Direct decoding does not work with MRC - TCR414W1-97
;          but works ok with page and direct register programming
;        ; Not tried with Lenz or other make (I don't have any!)
;               
;
; Note 5 : Code was optimised with numerous GOTOs instead of CAlls and 
;               RETURNn to save code space
;
;
;             18 17 16 15 14 13 12 11 10  
;            |---------------------------|
;            |                           | 
;            |    16c84  or 16f84        |
;            |---------------------------|
;              1  2  3  4  5  6  7  8  9
;
;
;---------------------------------------------------------------------------
;       Revision Date:   June 1998
;       Copyright(c) DbRc 1998 - Robert Cote - Denise Baribeau
;                                 Ottawa - Canada
;
;             NOTE: This code is not in the public domain - It cannot
;                   be used commercially without the written permission
;                   of the author.
;---------------------------------------------------------------------------                                                        
;
; Output TTL compatible - uses L298 booster - Should work with any
;                                       standard booster
; Credits : Microchip (for matrix key board routine)
;           Mike Brandt for the ideas on the PC assembler Driver
;           John Becker for LCD/BCD Routines and his excellent turorial
;               published in Everyday Practical Electronics (March/April
;               and May 1998)
;            DCC pulse generation - NMRA Sarps and my own translation
;                into assembler code               
;               
;         
;******************************************************************************
;


	__CONFIG   _CP_OFF &_WDT_OFF & _XT_OSC
        ERRORLEVEL  -302

; Defines ------------------------------------------------

#define Page0   BCF STATUS,5
#define Page1   BSF STATUS,5

; Equates ------------------------------------------------


Loco1Add        equ     .3      ;preset loco#1 to 4 address (3,4,5 and6)
Loco2Add        equ     .4
Loco3Add        equ     .5
Loco4Add        equ     .6

keyhit          equ     .0              ;bit 0 --> key-press on
DebnceOn        equ     .1              ;bit 1 --> debounce on
noentry         equ     .2              ;no key entry = 0
ServKey         equ     .3              ;bit 3 --> service key
ServMod         equ     .4 
ServBusy        equ     .5
EstopOn         equ     .6
EstopBusy       equ     .7     
DirFlag         equ     .5              ;for 14 and 28 speed steps
FlFlag          equ     .4              ;used with function group 1
ServRept        equ     .6              ;# of repeats for Service Commands
ResetRept       equ     .20             ;Reset repeat
CTDIV           equ     .99             ;Used to preset timer0
MaxSpeed28      equ     .31             ;now in binary format
MaxSpeed14      equ     .15
LPreamb         equ     .25           ;Long Preamble (20) SRP 9...
SPreamb         equ     .15             ;Short Preamble (10) SRP 9...
StepFlag1       equ     .0
StepFlag2       equ     .1
StepFlag3       equ     .2        
StepFlag4       equ     .3
RegBase         equ     0ch             ;Register starting address
                                        ;use 0ch for 16c84
                                        ;move up for 16c73 and 16c74

; Registers ----------------------------------------------
; All 36 memory spaces used - some registers doubled up when
; no conflict arose and names were deemed to be more appropriate
; in sub-routines
;
;----------------------------------------
; Counter and Temporary Storage Registers

TempC   equ     RegBase+.00        ;temp general purpose RegBase
temp    equ     RegBase+.00
SavTmp1 equ     RegBase+.00
LOOPA   EQU     RegBase+.00        ;loop counter 2 - LCD use only

TempD   equ     RegBase+.01
R0      equ     RegBase+.01
SavTmp2 equ     RegBase+.01
        
TempE   equ     RegBase+.02
R1      equ     RegBase+.02
GetTmp  equ     RegBase+.02


Debnce  equ     RegBase+.04        ;debounce counter


NewKey  equ     RegBase+.05
TCount  equ     RegBase+.05
PageNo  equ     RegBase+.05

STORE1  EQU     RegBase+.06        ;general store 1
ServCnt equ     RegBase+.06

STORE2  EQU     RegBase+.07        ;general store 2



RSLINE  EQU     RegBase+.09        ;RS line flag for LCD

PBBuf   equ     RegBase+.10

loops   equ     RegBase+.11

loops2  equ     RegBase+.12

txByte	equ			RegBase+.13     ; Transmitted byte (address, instructions,etc.)
count   equ     RegBase+.13

txCount	equ			RegBase+.14     ; Counter for transmit routine
LSB     equ     RegBase+.14

byte1bf	equ			RegBase+.28	; byte memory for dcc signal XOR - Error mode

byte2bf	equ			RegBase+.29

byte3bf	equ			RegBase+.30    

byte4bf	equ			RegBase+.31

; Flags and Important static storage registers


KeyFlag equ     RegBase+.03        ;flags related to key pad

spdir1	equ	RegBase+.15	; Speed and direction register
spdir2	equ	RegBase+.16	; Speed and direction register 2 ...
spdir3	equ	RegBase+.17	; 
spdir4	equ	RegBase+.18	; 

loco1ad equ	RegBase+.19	; save address of 1st loco here
loco2ad	equ	RegBase+.20	;  etc...
loco3ad	equ	RegBase+.21
loco4ad	equ	RegBase+.22

SpdFlag equ     RegBase+.23     ;14/28 speedstep flag

fung1_1	equ	RegBase+.24	;function Group 1 (1 to 5) FL f1 f2 f3 f4 
fung1_2	equ	RegBase+.25
fung1_3	equ	RegBase+.26
fung1_4	equ	RegBase+.27	


bcdspd1 equ RegBase+.32
bcdspd2 equ RegBase+.33
bcdspd3 equ RegBase+.34
bcdspd4 equ RegBase+.35

ModeFl  equ RegBase+.08     ;Mode 1-2-4-8 Normal /Programme1 ...

; The following information is imbedded in the EEROM memory
; First - default address 03, 04, 05 and 06 with 28 speed mode preset
; Second - the LCD Service mode text is saved as ASCIIz to save code space
; Nearly all EEROM memory used

        org     2100h           ;Preset Loco address in EEROM
        de      .03,.04,.05,.06,b'00001111'        
        de      "Statn#1 #2 #3 #4",0      ;Starts at 05h        
        de      "Serv Mode Pag/Rg",0      ;Starts at 16h(ASCIIz style)
        de      " Emergency Stop!",0      ;Starts at 27h           

        org     .0
Begin
        call    InitPorts       ;Setup up all ports


 
        call    InitLCD         ;Initialize LCD Display        
	call	DCCReset								;send 20 reset pulses to initialize decoder
        goto    Start           ;skip over interrupt vector           

        org     .4
        goto    Begin           ;Interrupt not used

        
;---------------------------------------------------------------
Start

MainLoop:
        movf    ModeFl,f
        btfss   Status,Z        ;if ModeF1=0 then operate
        goto    PgmMode         ;else programming mode     
           
Main1:  ;call    SyncPulse       ;Used for scope synchronization when testing
   
        call    DCCIdle
        call    DCCZero        
        call    SyncPulse
        call    SendDCCPulse1   ;Send Loco#1 info (Preamble/Address/Speed)            
        call    SendDCCPulse2   ;send loco#2 info ...
        call    SendDCCPulse3
        call    SendDCCPulse4
        call    DCCIdle
        call    FuncGroup1_1        
        call    FuncGroup1_2        
        call    FuncGroup1_3        
        call    FuncGroup1_4        
          
        goto    MainLoop

PgmMode
        
        call    DCCReset
Pg1:    ;call    SyncPulse
        call    DCCZero
        call    SyncPulse
        call    DCCIdle
        call    DCCIdle        
        call    KeyTest
        call    DCCZero
        movf    ModeFl,f
        btfsc   Status,Z        ;if ModeF1=0 then operate
        goto    Main1           ;else Service mode
        goto    Pg1
        
KeyTest
        call    ScanKeys
        btfsc   KeyFlag,ServKey ;key service pending
        call    ServiceKey      ;yes then service                
        return


;---------------------------------------------------

InitPorts
        Page1              ;select pg 1
        movlw   b'00001100'     ;Make RA0/1 and 4 outputs	
	movwf	TRISA		;make RA2/3 as inputs  
        clrf    TRISB           ;make RB0-7 outputs
        Page0                   ;select page 0       
        clrf    PORTA
        bsf     Porta,4         ;preset DCC complementary output to 1        
        clrf    PORTB           ;
        movlw   RegBase + 1
        movwf   FSR
        movlw   .36 						;EndReg-StrReg   ;number of registers to clear
        movwf   TempC
Ini1:   clrf    INDF
        incf    FSR,f          ;clear all registers starting at 0ch
        decfsz  TempC,f
        goto    Ini1

        
        movlw   Loco1Ad         ;Get  Loco1 to 4 and SpeedFlag
        movwf   FSR
        clrf    loops           ;five values to retrieve 
Ini2:   movfw   loops
        call    GetPrm      
        movwf   INDF       
        incf    FSR,f
        incf    loops,f
        movlw   b'00000101'     ;have we reached 5 yet
        xorwf   loops,w
        btfss   Status,Z
        goto    Ini2
       







        call    ClrBcd          ;Go preset Speed and direction	

	movlw	b'10010000'	;default Headlight ON
	movwf	fung1_1	
	movwf	fung1_2
	movwf	fung1_3
	movwf	fung1_4        
        return
;---------------------Table for LCD Readout

TABLCD: addwf PCL,F             ;LCD initialisation table
        retlw b'00110011'       ;initialise lcd - first byte
        retlw b'00110011'       ;2nd byte (repeat of first)
        retlw b'00110010'       ;set for 4-bit operation
        retlw b'00101100'       ;set for 2 lines
        retlw b'00000110'       ;set entry mode to increment each address
        retlw b'00001100'       ;set display on, cursor off, blink off
        retlw b'00000001'       ;clear display
        retlw b'00000010'       ;return home, cursor & RAM to zero
                                ;end initialisation table        
         
;---------------------------------------------------------------------
; Keyboard Look-up Table

GetValCom
        movf    TempC,w     
        addwf   PCL, F
        retlw   .0
        retlw   .1
        retlw   .2
        retlw   .3
        retlw   .4
        retlw   .5
        retlw   .6
        retlw   .7
        retlw   .8
        retlw   .9
        retlw   0ah
        retlw   0bh
        retlw   0ch
        retlw   0dh
        retlw   0eh
        retlw   0fh

;--------------------------------------------------------------

CommandTable:
        addwf   PCL,f  ;this is a jump table according to key press

                                        ;       C1 C2 C3 C4
                                        ;     ===============
                                        ; R1  = 13 14 15 16 =
                                        ; R2  =  9 10 11 12 =
                                        ; R3  =  5  6  7  8 = 
                                        ; R4  =  1  2  3  4 =
                                        ;     ===============
        goto    Fl1             ;button 4 
        goto    Dir1            ;button 3
        goto    SpdDn1          ;button 2
        goto    SpdUp1          ;button 1

        goto    FL2             ;button 8 
        goto    Dir2            ;button 7 ...
        goto    SpdDn2
        goto    SpdUp2

        goto    FL3             
        goto    Dir3           
        goto    SpdDn3
        goto    SpdUp3

        goto    FL4             
        goto    Dir4           
        goto    SpdDn4
        goto    SpdUp4

;---------------------------------------------------------
PgmTable
        ;andlw   b'00000111'     ;Maximum 3 commands for now!
        addwf   PCL,f          
        goto    Pgm1    ;Station Address
        goto    Pgm2    ;Service Mode Direct CV writing
        goto    Pgm3    ;Operations mode (normal)
;---------------------------------------------------------------
;   End of Tables (Ensure that this is within first 256 bytes) 00FFh
;---------------------------------------------------------------
; Emergency Stop routine - all channels at once - Called from ScanKeys
;                                                       PortA
Estop
        btfsc   KeyFlag,DebnceOn
        return
        movf    ModeFl,f
        btfss   Status,Z
        return                 
        bsf     KeyFlag,DebnceOn ;set flag
        movlw   .4
        movwf   Debnce          ;load debounce time         
        movlw   b'01000000';toggle emergency stop flag
        xorwf   Keyflag,f
        btfss   Keyflag,EStopON
        goto    ClkShw          ;return and refresh LCD        
        call    DCCReset    ;Stop but keep sending DCC info
        call    ClrBcd
        call    ClkShw
        movlw   b'11000000' ;Move cursor to second line
        call    LcdLin        
        movlw   027h
        goto    WrLcdLine       ;Write "Emergency Stop!"



        
;--------------------------------------------------------------

PgmMode1                        ;called from ScanKeys        
        btfsc   KeyFlag,DebnceOn
        return            
        bsf     KeyFlag,DebnceOn ;set flag
        movlw   .4
        movwf   Debnce
        call    ClrBcd   
        movfw   ModeFl
        incf    ModeFl,f 
        bcf     KeyFlag,EStopON ;re-enable keyboard      
        goto    PgmTable
;------------------------------------------------
ClrBcd
        movlw   b'01100000'     ;mask speed type and direction        
        movwf   spdir1           
        movwf   spdir2          
        movwf   spdir3        
        movwf   spdir4
        btfss   spdflag,StepFlag1
        bsf     spdir1,4
        btfss   spdflag,StepFlag2
        bsf     spdir2,4        
        btfss   spdflag,StepFlag3
        bsf     spdir3,4
        btfss   spdflag,StepFlag4
        bsf     spdir4,4        
        clrf    bcdspd1
        clrf    bcdspd2
        clrf    bcdspd3
        clrf    bcdspd4     
        return
;---------------------------------------------------------------
Pgm1:   
        movlw   b'10000000' ;Move cursor to first line
        call    LCDLIN      
        movlw   05h
        call    WrLCDLine

AddLn2: movlw   b'11000000' ;Move cursor to second line
        call    LCDLIN      
                            ;dt "Addr 00 00 00 00" (style)
        movlw   'A'
        call    LcdOut
        movlw   'd'
        call    LcdOut
        movlw   'd'
        call    LcdOut
        movlw   'r'
        call    LcdOut
        movlw   ' '
        btfss   spdflag,StepFlag1
        movlw   b'01100000'   ; \
        call    LcdOut       

        movfw   loco1ad
        call    Bcd1
        movlw   ' '
        btfss   spdflag,StepFlag2
        movlw   b'01100000'   ; '\'
        call    LcdOut   

        movfw   loco2ad
        call    Bcd1
        movlw   ' '
        btfss   spdflag,StepFlag3
       movlw   b'01100000' 
        call    LcdOut   

        movfw   loco3ad
        call    Bcd1
        movlw   ' '
        btfss   spdflag,StepFlag4
        movlw   b'01100000'
        call    LcdOut   

        movfw   loco4ad
        goto    Bcd1            ;save last return by going direct

;-----------------------------------------------------------
; Direct CV Programming LCD Readout
;----------------------------------------
Pgm2:   
        movlw   b'10000000'     ;Move cursor to first line
        call    LCDLIN      
        movlw   016h
        call    WrLCDLine


AddCv2: movlw   b'11000000'     ;Move cursor to second line
        call    LCDLIN
                        ;   "Serv Mode  Pag R
        movlw   'C'     ;dt "CV:000-000 00-00"
                        ;   "CV:002=000 
        call    LcdOut
        movlw   'V'
        call    LcdOut
        movlw   ':'
        call    LcdOut
        movfw   bcdspd1
        movwf   bcdspd3         ;save raw CV# in 3 and 4
        movwf   bcdspd4         ;Show CV normalized to 1
        addlw   .1
        call    Bcd2            ;CV# with 1 added (CV#1=00000000)
        movlw   '-'
        call    LcdOut
        movfw   bcdspd2         ;CV data - leave as shown 0=0
        call    Bcd2
        call    LcdSpace

        bcf     Status,C        ;Determine Page # from raw CV
        rrf     bcdspd3,f       ;divide by two and by two again for Page#
        bcf     Status,C
        rrf     bcdspd3,w
        addlw   .1               ;CV#1 to CV#4 are Page 1 Reg. 0 to 3
        movwf   bcdspd3                
        call    Bcd1            ;Show page# on LCD
        movlw   '-'
        call    LcdOut
        
        movfw   bcdspd1         ;use first 2 bits of counter for Reg.#
        andlw   b'00000011'     ;mask first 2 bits for Register # /Page mode                     
        movwf   bcdspd4
        goto    Bcd1            ;Show them on LCD as Register#
                                ;On exit spd3 has page and spd4 has reg.
;--------------------------------------------------------------
Pgm3:   call    ClrBcd          ;reset speed registers 
        clrf    ModeFl          ;revert to Ops Mode
        clrf    loops           ;five values to save        
        movlw   Loco1Ad         ;Save Loco1 to 4 and SpeedFlag (in reverse)
        movwf   FSR
PgmS1:  movfw   INDF
        movwf   SavTmp1
        movfw   loops        
        call    SetPrm
        incf    FSR,f
        incf    loops,f
        movlw   b'00000101'     ;have we reached 5 yet
        xorwf   loops,w
        btfss   Status,Z
        goto    PgmS1
        goto    ClkShw       

;---------------------------------------------------------------
;  This routine expects the EEROM relative address in W and will output
;   to the LCD an asciiz string.
WrLCDLine

        movwf   loops
WrLCD1: movfw   loops
        call    GetPrm
        movf    GetTmp,f
        btfsc   Status,Z
        return               
        call    LcdOut
        incf    loops,f
        goto    WrLCD1
       
;---------------------------------------------------------------------


;---------------------------------------------------------------
FL1:                            ;Turns Lights ON/OFF
        
        btfsc   ModeFL,0
        goto    SetSpeed1
        movlw	b'00010000'
        btfss   SpdFlag,StepFlag1       ; 0 ->14   1->28 steps      
        xorwf   spdir1,f        
	xorwf	fung1_1,f
        return
SetSpeed1:
        bsf     fung1_1,FlFlag
        movlw   b'00000001'
        xorwf   SpdFlag,f
        bcf     spdir1,4
        btfss   SpdFlag,StepFlag1        
        bsf     spdir1,4
        goto    AddLn2
;---------------------------------------------------------------
FL2:
        btfsc   ModeFL,0
        goto    SetSpeed2
 
        movlw	b'00010000'
        btfss   spdflag,StepFlag2     
        xorwf   spdir2,f   		
	xorwf	fung1_2,f
        return
SetSpeed2:
        bsf     fung1_2,FlFlag
        movlw   b'00000010'
        xorwf   SpdFlag,f
        bcf     spdir2,4
        btfss   SpdFlag,StepFlag2        
        bsf     spdir2,4
        goto    AddLn2
;---------------------------------------------------------------
FL3:
        btfsc   ModeFL,0
        goto    SetSpeed3
 
        movlw	b'00010000'
        btfss   spdflag,StepFlag3     
        xorwf   spdir3,f   		
	xorwf	fung1_3,f
        return
SetSpeed3:
        bsf     fung1_3,FlFlag
        movlw   b'00000100'
        xorwf   SpdFlag,f
        bcf     spdir3,4
        btfss   SpdFlag,StepFlag3        
        bsf     spdir3,4
        goto    AddLn2    
;---------------------------------------------------------------
FL4:
        btfsc   ModeFL,0
        goto    SetSpeed4
 
        movlw	b'00010000'
        btfss   spdflag,StepFlag4     
        xorwf   spdir4,f   		
	xorwf	fung1_4,f
        return
SetSpeed4:
        bsf     fung1_4,FlFlag
        movlw   b'00001000'
        xorwf   SpdFlag,f
        bcf     spdir4,4
        btfss   SpdFlag,StepFlag4        
        bsf     spdir4,4
        goto    AddLn2    
;---------------------------------------------------------------
Dir1:                           ;Toggles Direction Bit (28Speed)
        

        btfsc   ModeFL,1
        goto    PgmReg1
        movlw   b'00100000'     ;would use bit 6 in 128 step mode
        xorwf   spdir1,f
        return

        
PgmReg1:                
        call    DCCReset
        movfw   bcdspd3         ;has page number from LCD
        movwf   PageNo
        call    CVPagePreset
        call    DCCReset
        call    CVPhyWrite
        call    DCCReset
        movlw   .1
        movwf   PageNo
        call    CVPagePreset    ;reset to page 1 after use
        goto    DCCReset
;---------------------------------------------------------------

Dir2: 
       
        btfsc   ModeFL,1
        goto    PgmReg2
        movlw   b'00100000'
        xorwf   spdir2,f
        return


PgmReg2
        call    DCCReset
        movfw   bcdspd1
        movwf   bcdspd4         ;send raw CV value to Physical write
        call    CVPhyWrite
        goto    DCCReset
                    


;---------------------------------------------------------------
Dir3:

        btfsc   ModeFL,1        
        goto    PgmReg3
        movlw   b'00100000'
        xorwf   spdir3,f
        return

        
PgmReg3:
        call    DCCReset      
        call    CVWriteDirect
        call    CVWriteDirect
        goto    DCCReset        
        
        
;---------------------------------------------------------------
;---------------------------------------------------------------
Dir4:
        btfsc   ModeFL,1        
        goto    PgmReg4 
        movlw   b'00100000'
        xorwf   spdir4,f
        return


        
PgmReg4:
        call    DCCReset      
        call    CVWriteExtendedDirect
        call    CVWriteExtendedDirect
        goto    DCCReset               

;---------------------------------------------------------------


SpdUp1: btfsc   ModeFL,0
        goto    LocAd1        
        btfsc   ModeFL,1        ;check for CV programming mode
        goto    CvAdd1          ;if not do sped adjust routine
        movlw   MaxSpeed28      ;default to 31
        btfss   SpdFlag,StepFlag1
        movlw   MaxSpeed14 
        xorwf   bcdspd1,w       
        btfsc   STATUS,Z
        return
        incf    bcdspd1,f
        btfss   SpdFlag,StepFlag1
        goto    LcAd1           ;increment the register directly
	movlw	b'00010000'
	xorwf	spdir1,f	;toggle lsb of 28 speed
	btfss	spdir1,4	;check if lsb is zero or one
LcAd1:	incf	spdir1,f	;if clear then increment next 4 msb (0-3)	
        return
LocAd1: 
        incf    Loco1Ad,f
        call    AddLn2
        return
CvAdd1: incf    bcdspd1,f
        goto    AddCv2

;---------------------------------------------------------------
;---------------------------------------------------------------
SpdUp2: btfsc   ModeFL,0
        goto    LocAd2
        btfsc   ModeFL,1        ;check for CV programming mode
        goto    CvAdd2          ;if not do sped adjust routine

        movlw   MAXSPEED28        ;default to 31 in bcd
        btfss   SpdFlag,StepFlag2
        movlw   MaxSpeed14 
        xorwf   bcdspd2,w       
        btfsc   STATUS,Z
        return
        incf    bcdspd2,f
        btfss   SpdFlag,StepFlag2
        goto    LcAd2           ;increment the register directly
	movlw	b'00010000'
	xorwf	spdir2,f	;toggle lsb of 28 speed
	btfss	spdir2,4	;check if lsb is zero or one
LcAd2:  incf    spdir2,f
        return
LocAd2:
        incf    Loco2Ad,f
        call    AddLn2
        return
CvAdd2: incf    bcdspd2,f
        goto    AddCv2

;---------------------------------------------------------------
;---------------------------------------------------------------
SpdUp3: btfsc   ModeFL,0
        goto    LocAd3
        btfsc   ModeFL,1
        return
        movlw   MAXSPEED28        ;default to 15 in bcd
        btfss   SpdFlag,StepFlag3
        movlw   MaxSpeed14 
        xorwf   bcdspd3,w       
        btfsc   STATUS,Z
        return
        incf    bcdspd3,f
        btfss   SpdFlag,StepFlag3
        goto    LcAd3           ;increment the register directly
	movlw	b'00010000'
	xorwf	spdir3,f	;toggle lsb of 28 speed
	btfss	spdir3,4	;check if lsb is zero or one
LcAd3   incf    spdir3,f
        return
LocAd3:
        incf    Loco3Ad,f
        goto    AddLn2


;---------------------------------------------------------------
;---------------------------------------------------------------
SpdUp4: btfsc   ModeFL,0
        goto    LocAd4
        btfsc   ModeFL,1
        return
        movlw   MAXSPEED28        ;default to 15 in bcd
        btfss   SpdFlag,StepFlag4
        movlw   MaxSpeed14 
        xorwf   bcdspd4,w       
        btfsc   STATUS,Z
        return
        incf    bcdspd4,f
        btfss   SpdFlag,StepFlag4
        goto    LcAd4           ;increment the register directly
	movlw	b'00010000'
	xorwf	spdir4,f	;toggle lsb of 28 speed
	btfss	spdir4,4	;check if lsb is zero or one
LcAd4:  incf    spdir4,f
        return
LocAd4:
        incf    Loco4Ad,f
        goto    AddLn2


;---------------------------------------------------------------
;---------------------------------------------------------------
SpdDn1:
        btfsc   ModeFL,0
        goto    LocAd5
        btfsc   ModeFL,1        ;check for CV programming mode
        goto    CvSub1          ;if not do sped adjust routine

        movfw   bcdspd1
        btfsc   STATUS,Z
        return
        decf    bcdspd1,f
        btfss   SpdFlag,StepFlag1
        goto    LcAd5           ;decrement the register directly
	movlw	b'00010000'
	xorwf	spdir1,f								;toggle lsb of 28 speed
	btfsc	spdir1,4								;check if lsb is zero or one	
LcAd5:	decf	   spdir1,f
        return
LocAd5:
        decf    Loco1Ad,f
        call    AddLn2
        return
CvSub1: decf    bcdspd1,f
        goto    AddCv2

;---------------------------------------------------------------
;---------------------------------------------------------------
SpdDn2: btfsc   ModeFL,0
        goto    LocAd6
        btfsc   ModeFL,1        ;check for CV programming mode
        goto    CvSub2          ;if not do sped adjust routine

        movfw   bcdspd2
        btfsc   STATUS,Z
        return
        decf    bcdspd2,f
        btfss   SpdFlag,StepFlag2
        goto    LcAd6           ;decrement the register directly

	movlw	b'00010000'
	xorwf	spdir2,f	;toggle lsb of 28 speed
	btfsc	spdir2,4	;check if lsb is zero or one		
LcAd6:  decf    spdir2,f
        return
LocAd6:
        decf    Loco2Ad,f
        call    AddLn2
        return
CvSub2: decf    bcdspd2,f
        goto    AddCv2
      
;---------------------------------------------------------------
;---------------------------------------------------------------
SpdDn3: btfsc   ModeFL,0
        goto    LocAd7
        btfsc   ModeFL,1
        return
        movfw   bcdspd3
        btfsc   STATUS,Z
        return
        decf    bcdspd3,f
        btfss   SpdFlag,StepFlag3
        goto    LcAd7           ;decrement the register directly

	movlw	b'00010000'
	xorwf	spdir3,f	;toggle lsb of 28 speed
	btfsc	spdir3,4	;check if lsb is zero or one		
LcAd7:  decf    spdir3,f
        return
LocAd7:
        decf    Loco3Ad,f
        goto    AddLn2
       

;---------------------------------------------------------------
;---------------------------------------------------------------
SpdDn4: btfsc   ModeFL,0
        goto    LocAd8
        btfsc   ModeFL,1
        return
        movfw   bcdspd4
        btfsc   STATUS,Z
        return
        decf    bcdspd4,f
	movlw	b'00010000'
        btfss   SpdFlag,StepFlag4
        goto    LcAd8           ;decrement the register directly

	xorwf	spdir4,f	;toggle lsb of 28 speed
	btfsc	spdir4,4	;check if lsb is zero or one
LcAd8:  decf    spdir4,f
        return
LocAd8:
        decf    Loco4Ad,f
        goto    AddLn2
                
;---------------------------------------------------------------

;---------------------------------------------------------------
; This routine writes to the internal EEROM - W-> address SavTmp1 -> data
;  but prevents writing if value to be the same (saves wear and tear on 
;  write cycle)



SetPrm
        movwf   SavTmp2        ;save address for later
        call    GetPrm          ;GetTmp as value
        xorwf   SavTmp1,w       ;if SavTmp1 same as GetTmp then return
        btfsc   Status,Z
        return
        movfw   SavTmp2        ;restore address and write   

        movwf   EEADR
       
        Page1
        bsf     EECON1,WREN
        Page0
        movf    SavTmp1,w
        movwf   EEDATA

        Page1           ;protocole for write routine (Microchip)
        movlw   055h
        movwf   EECON2
        movlw   0aah
        movwf   EECON2
        bsf     EECON1,WR
        
ChkWrt: btfss   EECON1,4
        goto    ChkWrt
        bcf     EECON1,WREN
        bcf     EECON1,4
        page0
        bcf     INTCON,6
        return
;----------------------------------------
; This routine reads from the internal EEROM (W has address - GetTmp has
;  data along with W as well)

GetPrm
        movwf   EEADR
        page1
        bsf     EECON1,RD
        page0
        movf    EEDATA,w
        movwf   GetTmp
        return

;---------------------------------------------------------------



InitLCD  ;This is the LCD Display 16*2 Initialization routine
;--------------------------------------------------------
        call    PAUSIT     ;15 ms delay before starting LCD       
LCDSET: clrf    loops      ;clr LCD set-up loop
        clrf    RSLINE     ;clear RS line for instruction send
LCDST2: movf    loops,W     ;get table address
        call    TABLCD     ;get set-up instruction
        call    LCDOUT     ;perform it
        incf    loops,F     ;inc loop
        btfss   loops,3    ;has last LCD set-up instruction now been done?
        goto    LCDST2     ;no
        
        call    PAUSIT
   
        
        
CLKSHW: 
        movlw   b'10000000'     ;Move cursor to first line

        call    LCDLIN          
        movlw   'L'        
        call    LCDOUT
        movlw   'o'
        call    LCDOUT  
        movlw   'c'
        call    LCDOUT
        movlw   ':'
        call    LCDOUT
        movfw   loco1ad
        call    Bcd1
        movlw   '-'
        btfsc   fung1_1,4
        movlw   '*'
        call    LCDOUT
        movfw   loco2ad
        call    Bcd1
        movlw   '-'
        btfsc   fung1_2,4
        movlw   '*'
        call    LCDOUT
        movfw   loco3ad
        call    Bcd1
        movlw   '-'
        btfsc   fung1_3,4
        movlw   '*'
        call    LCDOUT
        movfw   loco4ad
        call    Bcd1
        movlw   '-'
        btfsc   fung1_4,4
        movlw   '*'        
        call    LCDOUT
        movlw   b'11000000'     ;show time second line
        call    LCDLIN    
        movlw   07eh            ;b'01111110'; ->
        btfss   spdir1,DirFlag
        movlw   07fh            ;b'01111111'; <-
        call    LCDOUT
        movf    bcdspd1,W   ;get speed
        call    Bcd2

LC1:    movlw   07eh            ;b'01111110'; ->
        btfss   spdir2,DirFlag
        movlw   07fh            ;b'01111111'; <-
        call    LCDOUT

        movf    bcdspd2,W   ;get speed
        call    Bcd2


     
;Lstop2: call    Lstop
LC2:    movlw   07eh            ;b'01111110'; ->
        btfss   spdir3,DirFlag
        movlw   07fh            ;b'01111111'; <-
        call    LCDOUT

        movf    bcdspd3,W   ;get speed
        call    Bcd2


;Lstop3: call    Lstop
LC3:    movlw   07eh            ;b'01111110'; ->
        btfss   spdir4,DirFlag
        movlw   07fh            ;b'01111111'; <-
        call    LCDOUT

        movf    bcdspd4,W   ;get speed
        goto    Bcd2
        

LCDFRM: movwf   STORE2    ;split & format decimal byte for LCD
        swapf   STORE2,W  ;swap byte into W to get tens
        andlw   .15        ;AND to get nibble
        iorlw   .48        ;OR with 48 to make ASCII value
LCDZS1: call    LCDOUT     ;send to LCD
        movf    STORE2,W   ;get units
LCDFR1: andlw   .15        ;AND to get nibble
        iorlw   .48        ;OR with 48 to make ASCII value
LCDOUT: movwf   STORE1    ;temp store value that will be output to LCD
        movlw   .20        ;set minimum time between sending full bytes to
        movwf   LOOPA     ;LCD - value of 20 seems OK for this prog with
DELAY:  decfsz  LOOPA,F  ;XTAL clk of upto 5MHz, possibly 5.5MHz
        goto    DELAY
        call    SENDIT     ;send MSB, then (by default) send LSB

SENDIT: swapf   STORE1,F  ;swap byte nibbles
        movf    STORE1,W   ;get nibble (MSB)
        andlw   .15        ;AND to isolate nibble
        iorwf   RSLINE,W  ;OR the RS bit
        movwf   PORTB     ;output the byte
        bsf     PORTA,1     ;set E high  
        bcf     PORTA,1     ;set E low        
        return
Bcd1                    ;this routine writes 1 BCD to LCD display
        movwf   LSB
        call    bin8bcd3
        movfw   R1
        goto    LCDFRM  ;replace call with goto

Bcd2                    ;this routine writes 2 BCD to LCD display
        movwf   LSB
        call    bin8bcd3
        movfw   R0
        call    LCDFR1
        movfw   R1
        goto    LCDFRM     ;format and sent it to LCD

LCDLIN: bcf     RSLINE,4    ;sets LCD command/line
        call    LCDOUT     ;and outputs cmmand code to LCD
        bsf     RSLINE,4    ;set RS flag
        return

PAUSIT: 
	movlw	.20        ;use 10 for 15 milliseconds 10 * 1.5 ms
	movwf	loopa
Pau2:	movlw	.150
	movwf	loops
	call	t10us
	decfsz	loopa,f
	goto	Pau2
	return
	



;-------------------------------------------------------------------------

;-------------------------------------------------------------------------

       
;-------------------------------------------------------------------------
;ServiceKey, does the software service for a keyhit. After a key service,
;the ServKey flag is reset, to denote a completed operation.

ServiceKey
        
        movf    NewKey,w        ;get key value             
        call    CommandTable        
        bcf     KeyFlag,ServKey ;reset service flag
        movf    ModeFl,f
        btfsc   Status,Z
        call    CLKSHW   
        return

;
;
;ScanKeys, scans the 4X4 keypad matrix and returns a key value in
;NewKey (0 - F) if a key is pressed, if not it clears the keyhit flag.
;Debounce for a given keyhit is also taken care of.
;The rate of key scan is 20mS with a 4.096Mhz clock.
ScanKeys
CheckPortA 
        btfss   PortA,2         ;Toggle Service/Ops Mode?
        goto    Estop
        btfss   PortA,3         ;Emergency Brake? Then Fall True
        goto    PgmMode1
          
      
; Original ScanKeys routine
        
        
        btfss   KeyFlag,DebnceOn ;debounce on?
        goto    Scan1           ;no then scan keypad
        decfsz  Debnce, F       ;else dec debounce time
        return                  ;not over then return
        bcf     KeyFlag,DebnceOn ;over, clr debounce flag
        return                  ;and return
Scan1   
        btfsc   Keyflag,EStopON     ;Is this an emergency stop?
        return                      ;Yes, then disable matrix keyboard    

        call    SavePorts       ;save port values
        movlw   B'11101111'     ;init TempD
        movwf   TempD
ScanNext
        movf    PORTB,w        ;read to init port
        bcf     INTCON,RBIF     ;clr flag
        rrf     TempD, F        ;get correct column
        btfss   STATUS,C        ;if carry set?
        goto    NoKey           ;no then end
        movf    TempD,w         ;else output
        movwf   PORTB          ;low column scan line
        nop
        btfss   INTCON,RBIF     ;flag set?
        goto    ScanNext        ;no then next
        btfsc   KeyFlag,keyhit  ;last key released?
        goto    SKreturn        ;no then exit
        bsf     KeyFlag,keyhit  ;set new key hit
        swapf   PORTB,w        ;read port
        movwf   TempE           ;save in TempE
        call    GetKeyValue     ;get key value 0 - F
        movwf   NewKey          ;save as New key
        bsf     KeyFlag,ServKey ;set service flag
        bsf     KeyFlag,DebnceOn ;set flag
        movlw   .4
        movwf   Debnce          ;load debounce time
SKreturn
        goto    RestorePorts    ;restore ports

;
NoKey
        bcf     KeyFlag,keyhit  ;clr flag
        goto    SKreturn
;
;GetKeyValue gets the key as per the following layout
;
;                  Col1    Col2    Col3    Col3
;                  (RB3)   (RB2)   (RB1)   (RB0)
;
;Row1(RB4)           0       1       2       3
;
;Row2(RB5)           4       5       6       7
;
;Row3(RB6)           8       9       A       B
;
;Row4(RB7)           C       D       E       F
;
GetKeyValue
        clrf    TempC
        btfss   TempD,3         ;first column
        goto    RowValEnd
        incf    TempC, F
        btfss   TempD,2         ;second col.
        goto    RowValEnd
        incf    TempC, F
        btfss   TempD,1         ;3rd col.
        goto    RowValEnd
        incf    TempC, F        ;last col.
RowValEnd
        btfss   TempE,0         ;top row?
        goto    GetValCom       ;yes then get 0,1,2&3
        btfss   TempE,1         ;2nd row?
        goto    Get4567         ;yes the get 4,5,6&7
        btfss   TempE,2         ;3rd row?
        goto    Get89ab         ;yes then get 8,9,a&b
Getcdef
        bsf     TempC,2         ;set msb bits
Get89ab
        bsf     TempC,3         ;       /
        goto    GetValCom       ;do common part
Get4567
        bsf     TempC,2
        goto    GetValCom
;
;SavePorts, saves the porta and portb condition during a key scan
;operation.
SavePorts

        movf    PORTB,w        ;get port b
        movwf   PBBuf           ;save in buffer
        movlw   0xff            ;make all high
        movwf   PORTB          ;on port b
        Page1
        bcf     OPTION_REG,7     ;enable pull ups
        movlw   B'11110000'     ;port b hi nibble inputs
        movwf   TRISB   ;&0x7f     ;lo nibble outputs
        Page0
        return
;
;RestorePorts, restores the condition of porta and portb after a
;key scan operation.
RestorePorts
        movf    PBBuf,w         ;get port n
        movwf   PORTB
        Page1
        bsf     OPTION_REG,7     ;disable pull ups
        clrf    TRISB   ;&0x7f     ;as well as PORTB
        Page0        
        return
;-------------------

;
SendDCCPulse1
	call	Preamble
	call	AddressByte1
	goto	SpeedDirByte1        
SendDCCPulse2
	call	Preamble
	call	AddressByte2
	goto	SpeedDirByte2        
SendDCCPulse3
	call	Preamble
	call	AddressByte3
	goto	SpeedDirByte3        
SendDCCPulse4
	call	Preamble
	call	AddressByte4	
        goto SpeedDirByte4


;----------------------------------------------


AddressByte1:
	movfw	loco1ad
        goto    AddCom
AddressByte2:
	movfw	loco2ad
        goto    AddCom
AddressByte3:
        movfw   loco3ad
        goto    AddCom
AddressByte4:
        movfw   loco4ad ;just fall through AddCom
AddCom:	movwf	byte1bf        
	movwf	txByte
	call	ByteTx
	goto	DCCZero


;-------------------------------------------------------

;-------------------------------------------------------
;-------- Either 14 or 28 steps depending on CV29 setup
SpeedDirByte1:
	movfw	spdir1
        goto    SpdCom
SpeedDirByte2:
        movfw   spdir2
        goto    SpdCom
SpeedDirByte3:
        movfw   spdir3
        goto    SpdCom
SpeedDirByte4:
        movfw   spdir4
SpdCom:	movwf	byte2bf
;SpdCom2:
	movwf	txByte
	call	ByteTx
	call	DCCZero
        goto    ErrorByte
;--------------------------------------------------------

; Function group one instruction (100)

FuncGroup1_1:
	call	Preamble
	call	AddressByte1
	movfw	fung1_1
        goto    SpdCom ;FunCom
FuncGroup1_2:
	call	Preamble
	call	AddressByte2
	movfw	fung1_2
        goto    SpdCom  ;FunCom
FuncGroup1_3:
	call	Preamble
	call	AddressByte3
	movfw	fung1_3
        goto    SpdCom  ;FunCom
FuncGroup1_4:
	call	Preamble
	call	AddressByte4
	movfw	fung1_4
        goto    Spdcom



;----------------------------------------------------------------------









;----------------------------------------------------------------


;-------------------------------------------------------
CVPagePreset            ;preset page register to 1 (sarp 9....)
                        ;Enter with PageNo set to page desired
        movlw   ServRept
        movwf   ServCnt
CVP1:   call    Preamble        ;dcczero built in
        movlw   b'01111101'
        movwf   txByte
        movwf   byte1bf
        call    ByteTx      ; call all registers (broadcast)    
        call    DCCZero
        movfw   PageNo        
        movwf   byte2bf
        movwf   txByte
        call    ByteTx
        call    DCCZero        
        call    ErrorByte
        decfsz  ServCnt,f
        goto    CVP1            ;Repeat 6 times        
        return        
        
;-----------------------------------------------
CVPhyWrite
        movlw   ServRept
        movwf   ServCnt

CVPh1:  call    Preamble        ;dcczero built in
        movfw   bcdspd4        ;Register number (from 0 to 3) 
        andlw   b'01111111'
        iorlw   b'01111000'        
        movwf   txByte
        movwf   byte1bf
        call    ByteTx      ; call all registers (broadcast)    
        call    DCCZero
        movfw   bcdspd2         ;
        movwf   byte2bf
        movwf   txByte
        call    ByteTx
        call    DCCZero
        call    ErrorByte 
        decfsz  ServCnt,f
        goto    CVPh1
        return          
;----------------------------
; 
CVWriteExtendedDirect        
        
        call    Preamble        ;dcczero built in
        clrf    txByte
        clrf    byte1bf
        call    ByteTx      ; call all registers (broadcast)    
        call    DCCZero
        movlw   b'11101100' ;Instruction byte (Write Registers)
        movwf   byte2bf
CVEntry:
        movwf   txByte          ;send byte
        call    ByteTx
        call    DCCZero
        movfw   bcdspd1         ;CV number (Real value minus one)
        movwf   byte3bf
        movwf   txByte
        call    ByteTx
        call    DCCZero
        movfw   bcdspd2         ;Value to go into CV
        movwf   byte4bf
        movwf   txByte
        call    ByteTx
        call    DCCZero
        goto    ErrorByte    
       

CVWriteDirect
        
        call    LongPreamble        ;dcczero built in
        clrf    byte2bf             ;not used - must clear
        movlw   b'01111100'
        movwf   byte1bf
        goto    CVEntry

;--------------------------------------------         
   

LcdSpace
        movlw   ' '
        goto    LcdOut        
;------------------------------------------
SyncPulse:
	bcf  	PORTA,4
	nop	;for 1 us pulse appx
	bsf	PORTA,4
	return
;--------------------------------------------------


DCCReset	
	movlw	ResetRept
	movwf   STORE1
DCCR1:	call 	Preamble
	clrf	txByte
	clrf	byte1bf
	clrf	byte2bf
	call	ByteTx
	call	DCCZero
        clrf    txByte
	call	ByteTx
	call	DCCZero
	call	ErrorByte	
        decfsz	STORE1,f
	goto	DCCR1
	return




;-----------------------------------------

;-------------------------------------------------------
DCCIdle	
	call	Preamble
	movlw	b'11111111'  ; all ones
	movwf	txByte
	movwf	byte1bf
	call	ByteTx
	goto	Dc1
Dc1:	goto	Dc2
Dc2:	goto	Dc3
Dc3:	nop
	call	DCCZero
	clrf	txByte
	clrf	byte2bf
	call	ByteTx
	call	DCCZero
	goto	ErrorByte	
;---------------------------------------------------------------
LongPreamble:           ;Long Preamble is minimum 20 ones
        movlw   LPreamb     
        goto    Prea1
Preamble:
        movlw   SPreamb ;need a minimum of 10 ones as a preamble
Prea1:	movwf	LOOPA
Prea2:	nop
	nop
	nop
	nop
	nop
	call 	DCCOne
	decfsz	LOOPA,f
	goto	Prea2
	goto	pr1
pr1:	goto	pr2
pr2:	goto	pr3
pr3:	nop
	goto 	DCCZero	;Indicate Start bit before address byte
	

;--------------------------------------------------------
ByteTx:	movlw	.8
	movwf	txCount
	bcf	STATUS,0
Byte1:	btfss	txByte,7
	goto	Byte2
	;nop
	;nop
	call	DCCOne
	nop
	nop
Byte3:	rlf	txByte,F
	decfsz	txCount,F
	goto	Byte1	
	return
Byte2:	call	DCCZero
	goto	Byte3	
;-------------------------------------------------------


ErrorByte
	movfw	byte1bf
	xorwf	byte2bf,w	;exclusive or bit wise byte1 and 2 buffers
	xorwf	byte3bf,w	;provide for extended packets (3-4) for later
	xorwf	byte4bf,w
	movwf	txByte
	call	ByteTx
	call	DCCOne		;end packet with ONE
        clrf    byte3bf
        clrf    byte4bf         ;reset those 2 - 1 and 2 always used
        movf    ModeFl,f
        btfsc   Status,Z 
        call    KeyTest       
        goto    DCCZero       

;----------------------------------------------------------
DCCOne:

	nop
	nop
	movlw   .3	;for 58us pulse (4*10us+10+8)
	movwf   loops
	call    t10us
        call    toggle
	nop
	nop	
	movlw   .4	;for 58us
	movwf   loops
	call    t10us
        goto    toggle
	;return
;----------------------------------
DCCZero:
       
        nop
        nop
        nop
	movlw   .7	;for 100us pulse (9*10us+10)
	movwf   loops
	call    t10us
        call    toggle
	movlw   .8	;for 10us pulse (1*10us)
	nop
	nop
	nop
	nop
	movwf   loops
	call    t10us
        goto    toggle
	;return
;------------------------------------
toggle
        movlw   b'00000001' ;mask for XOR
        xorwf   porta,f
        return

;------------------------------------

;-------------------------------------------------------------



bin8bcd3
; 8 bit binary to 3 digit BCD
; LSB = 0255
; R0= 02  R1=55
        bcf     STATUS,C
        movlw   .8
        movwf   count
        clrf    R0
        clrf    R1
loop16  rlf     LSB,f
        rlf     R1,f
        rlf     R0,f
        decfsz  count,f
        goto    adjdecl
        retlw   .0
adjdecl:
        movlw   R1
        call    adjbcd
        movlw   R0    
        call    adjbcd
        goto    loop16

adjbcd: movwf   FSR
        movlw   .3
        addwf   indf,w
        movwf   temp
        btfsc   temp,3
        movwf   indf
        movlw   30h
        addwf   indf,w
        movwf   temp
        btfsc   temp,7
        movwf   indf
        retlw   0

;-------------------------------- 

;---------------------------------------------------------
t10us      ;measures from 10 us to 2.5ms - Enter with loops set at desired
           ;delay
	nop  ; additional delay of 5 us with 5 nop here
	nop
	nop
	nop
	nop
t10us2
         movlw   .1
         movwf   loops2         
t10us1   nop
         nop
         nop       
	 decfsz  loops2,F         
	 goto    t10us1
         decfsz  loops,F
         goto    t10us2
         retlw   0
;------------------------------------------------------------------------
;======================================================================= 
        END 

;----------------------------------------  Minidcc2.asm (November 2000)        
