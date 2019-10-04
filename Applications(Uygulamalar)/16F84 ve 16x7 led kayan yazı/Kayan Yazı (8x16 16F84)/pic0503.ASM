; PIC16C84 ILE YAPILAN 8*16=80 LED LI KAYAN YAZI DEVRESI ICIN PROGRAMDIR
; 32 KARAKTER KULLANILABILIR

	LIST    P = 16C84,  F = INHX8M, n = 66

        PIC84   equ     H'03FF'


;==========================================================================
;
;       Register Definitions
;
;==========================================================================

W                            EQU     H'0000'
F                            EQU     H'0001'

;----- Register Files------------------------------------------------------

INDF                         EQU     H'0000'
TMR0                         EQU     H'0001'
PCL                          EQU     H'0002'
STATUS                       EQU     H'0003'
FSR                          EQU     H'0004'
PORTA                        EQU     H'0005'
PORTB                        EQU     H'0006'
EEDATA                       EQU     H'0008'
EEADR                        EQU     H'0009'
PCLATH                       EQU     H'000A'
INTCON                       EQU     H'000B'


OPTION_REG                   EQU     H'0081'
TRISA                        EQU     H'0085'
TRISB                        EQU     H'0086'
EECON1                       EQU     H'0088'
EECON2                       EQU     H'0089'

;----- STATUS Bits --------------------------------------------------------


IRP                          EQU     H'0007'
RP1                          EQU     H'0006'
RP0                          EQU     H'0005'
NOT_TO                       EQU     H'0004'
NOT_PD                       EQU     H'0003'
Z                            EQU     H'0002'
DC                           EQU     H'0001'
C                            EQU     H'0000'

;----- INTCON Bits --------------------------------------------------------

GIE                          EQU     H'0007'
EEIE                         EQU     H'0006'
T0IE                         EQU     H'0005'
INTE                         EQU     H'0004'
RBIE                         EQU     H'0003'
T0IF                         EQU     H'0002'
INTF                         EQU     H'0001'
RBIF                         EQU     H'0000'

;----- OPTION Bits --------------------------------------------------------

NOT_RBPU                     EQU     H'0007'
INTEDG                       EQU     H'0006'
T0CS                         EQU     H'0005'
T0SE                         EQU     H'0004'
PSA                          EQU     H'0003'
PS2                          EQU     H'0002'
PS1                          EQU     H'0001'
PS0                          EQU     H'0000'

;----- EECON1 Bits --------------------------------------------------------

EEIF                         EQU     H'0004'
WRERR                        EQU     H'0003'
WREN                         EQU     H'0002'
WR                           EQU     H'0001'
RD                           EQU     H'0000'

;==========================================================================
;
;       RAM Definition
;
;==========================================================================

        __MAXRAM H'AF'
        __BADRAM H'07', H'30'-H'7F', H'87'

;==========================================================================
;
;       Configuration Bits
;
;==========================================================================

_CP_ON                       EQU     H'3FEF'
_CP_OFF                      EQU     H'3FFF'
_PWRTE_ON                    EQU     H'3FFF'
_PWRTE_OFF                   EQU     H'3FF7'
_WDT_ON                      EQU     H'3FFF'
_WDT_OFF                     EQU     H'3FFB'
_LP_OSC                      EQU     H'3FFC'
_XT_OSC                      EQU     H'3FFD'
_HS_OSC                      EQU     H'3FFE'
_RC_OSC                      EQU     H'3FFF'




;----------- USER REGISTERS ----------------------------------------------
POINTER                      EQU     H'000C'
HCOUNT                       equ     H'000D'
LCOUNT			     equ     H'000E'					
TEMP1                        EQU     H'002B'
TEMP2                        EQU     H'002C'
TEMP3                        EQU     H'002D'
ZAMAN                        equ     H'002E'
DISP                         EQU     H'002F'

msb             equ     0x29            ;general delay register
lsb             equ     0x2A            ;general delay register
FLCOUNT         equ     H'0027'         ;flas counter
WAITC           equ     H'0026'         ;wait and run
SPECIAL         equ     H'0025'          ;special function register
COUNT1          equ     H'0022'         ;system timer counter
COUNT2          equ     H'0021'         ;system flas timer counter
SYSFUNC         equ     H'0020'         ;system control register

LINE1           EQU     H'0010'
LINE2           EQU     H'0011'
LINE3           EQU     H'0012'
LINE4           EQU     H'0013'
LINE5           EQU     H'0014'
LINE6           EQU     H'0015'
LINE7           EQU     H'0016'
LINE8           EQU     H'0017'
LINE9           EQU     H'0018'
LINE10          EQU     H'0019'
LINE11          EQU     H'001A'
LINE12          EQU     H'001B'
LINE13          EQU     H'001C'
LINE14          EQU     H'001D'
LINE15          EQU     H'001E'
LINE16          EQU     H'001F'
SATIRLAR        EQU     H'0023'


; Display organization
;
;
ZERO    EQU     B'00111111'
ONE     EQU     B'00000110'
TWO     EQU     B'01011011'
THREE   EQU     B'01001111'
FOUR    EQU     B'01100110'
FIVE    EQU     B'01101101'
SIX     EQU     B'01111101'
SEVEN   EQU     B'00000111'
EIGHT   EQU     B'01111111'
NINE    EQU     B'01101111'
BLANK   EQU     B'00000000'
;
DISP1	equ	B'11111110'
DISP2	equ	B'11111101'	; Mapping of Active Display Selection (PORT_A)
;DISP3   equ     B'11111011'
;DISP4   equ     B'11110111'
DISPOFF	equ	H'FF'
SWITCH	equ	B'00001110'	; Activate RB1-3 for switch inputs     


;
;
;

START
        call    SETCPUPORTSTATUS
        call    STEP_CLEAR

KAYANYAZI_1

         MOVLW  H'0000'
         MOVWF  SATIRLAR

KAYANYAZI_2
        INCFSZ  SATIRLAR
        GOTO    KAYANYAZI_3
        GOTO    KAYANYAZI_4

KAYANYAZI_3
        goto    KAYANYAZI_5

KAYANYAZI_4
        goto    KAYANYAZI_1

KAYANYAZI_5

        MOVLW   H'00'
        ADDWF   SATIRLAR,0
        CALL    FINDSHOW
        movwf   LINE1

        MOVLW   H'01'
        ADDWF   SATIRLAR,0
        CALL    FINDSHOW
        movwf   LINE2

        MOVLW   H'02'
        ADDWF   SATIRLAR,0
        CALL    FINDSHOW
        movwf   LINE3

        MOVLW   H'03'
        ADDWF   SATIRLAR,0
        CALL    FINDSHOW
        movwf   LINE4

        MOVLW   H'04'
        ADDWF   SATIRLAR,0
        CALL    FINDSHOW
        movwf   LINE5

        MOVLW   H'05'
        ADDWF   SATIRLAR,0
        CALL    FINDSHOW
        movwf   LINE6

        MOVLW   H'06'
        ADDWF   SATIRLAR,0
        CALL    FINDSHOW
        movwf   LINE7

        MOVLW   H'07'
        ADDWF   SATIRLAR,0
        CALL    FINDSHOW
        movwf   LINE8

        MOVLW   H'08'
        ADDWF   SATIRLAR,0
        CALL    FINDSHOW
        movwf   LINE9

        MOVLW   H'09'
        ADDWF   SATIRLAR,0
        CALL    FINDSHOW
        movwf   LINE10

        MOVLW   H'0A'
        ADDWF   SATIRLAR,0
        CALL    FINDSHOW
        movwf   LINE11

        MOVLW   H'0B'
        ADDWF   SATIRLAR,0
        CALL    FINDSHOW
        movwf   LINE12

        MOVLW   H'0C'
        ADDWF   SATIRLAR,0
        CALL    FINDSHOW
        movwf   LINE13

        MOVLW   H'0D'
        ADDWF   SATIRLAR,0
        CALL    FINDSHOW
        movwf   LINE14

        MOVLW   H'0E'
        ADDWF   SATIRLAR,0
        CALL    FINDSHOW
        movwf   LINE15

        MOVLW   H'0F'
        ADDWF   SATIRLAR,0
        CALL    FINDSHOW
        movwf   LINE16

        MOVLW   D'15'
        MOVWF   ZAMAN
        CALL    STEP_DELAY

        goto    KAYANYAZI_2
;****************************************************************************



;        org     h'0100'
FINDSHOW
;KIRIKKALE ENDUSTRI MESLEK LISESI ELEKTRONIK BOLUMU
showdata
        addwf   PCL,1
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
                                 
        retlw   B'00011111'     ;
        retlw   B'00010101'     ;
        retlw   B'00010101'     ;
        retlw   B'00010001'     ;
        retlw   B'00000000'     ;       E

        retlw   B'00011111'     ;
        retlw   B'00000010'     ;
        retlw   B'00000100'     ;
        retlw   B'00011111'     ;
        retlw   B'00000000'     ;       N

        retlw   B'00011111'     ;
        retlw   B'00010001'     ;
        retlw   B'00010001'     ;
        retlw   B'00001110'     ;
        retlw   B'00000000'     ;       D

        retlw   B'00001101'     ;
        retlw   B'00010000'     ;
        retlw   B'00010000'     ;
        retlw   B'00001101'     ;
        retlw   B'00000000'     ;       ü

        retlw   B'00010010'     ;
        retlw   B'00010101'     ;
        retlw   B'00001001'     ;
        retlw   B'00000000'     ;       S

        retlw   B'00000001'     ;
        retlw   B'00000001'     ;
        retlw   B'00011111'     ;
        retlw   B'00000001'     ;
        retlw   B'00000001'     ;
        retlw   B'00000000'     ;       T

        retlw   B'00011111'     ;
        retlw   B'00000101'     ;
        retlw   B'00001101'     ;
        retlw   B'00010010'     ;
        retlw   B'00000000'     ;       R

        retlw   B'00011101'     ;
        retlw   B'00000000'     ;       i

        retlw   B'00000001'     ;
        retlw   B'00000010'     ;
        retlw   B'00011100'     ;
        retlw   B'00000010'     ;
        retlw   B'00000001'     ;
        retlw   B'00000000'     ;       Y

        retlw   B'00011111'     ;
        retlw   B'00010101'     ;
        retlw   B'00010101'     ;
        retlw   B'00010001'     ;
        retlw   B'00000000'     ;       E

        retlw   B'00011111'     ;
        retlw   B'00010000'     ;
        retlw   B'00010000'     ;
        retlw   B'00010000'     ;
        retlw   B'00000000'     ;       L

        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;



        retlw   B'00011111'     ;
        retlw   B'00010101'     ;
        retlw   B'00010101'     ;
        retlw   B'00010001'     ;
        retlw   B'00000000'     ;       E

        retlw   B'00011111'     ;
        retlw   B'00010000'     ;
        retlw   B'00010000'     ;
        retlw   B'00010000'     ;
        retlw   B'00000000'     ;       L

        retlw   B'00011111'     ;
        retlw   B'00010101'     ;
        retlw   B'00010101'     ;
        retlw   B'00010001'     ;       E
        retlw   B'00000000'     ;

        retlw   B'00011111'     ;
        retlw   B'00000100'     ;
        retlw   B'00001010'     ;
        retlw   B'00010001'     ;
        retlw   B'00000000'     ;       K

        retlw   B'00000001'     ;
        retlw   B'00000001'     ;
        retlw   B'00011111'     ;
        retlw   B'00000001'     ;
        retlw   B'00000001'     ;
        retlw   B'00000000'     ;       T

        retlw   B'00011111'     ;
        retlw   B'00000101'     ;
        retlw   B'00001101'     ;
        retlw   B'00010010'     ;
        retlw   B'00000000'     ;       R

        retlw   B'00001110'     ;
        retlw   B'00010001'     ;
        retlw   B'00010001'     ;
        retlw   B'00001110'     ;
        retlw   B'00000000'     ;       O

        retlw   B'00011111'     ;
        retlw   B'00000010'     ;
        retlw   B'00000100'     ;
        retlw   B'00011111'     ;
        retlw   B'00000000'     ;       N

        retlw   B'00011101'     ;
        retlw   B'00000000'     ;       i

        retlw   B'00011111'     ;
        retlw   B'00000100'     ;
        retlw   B'00001010'     ;
        retlw   B'00010001'     ;
        retlw   B'00000000'     ;       K

        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;



        retlw   B'00011111'     ;
        retlw   B'00010101'     ;
        retlw   B'00010101'     ;
        retlw   B'00001010'     ;       B
        retlw   B'00000000'     ;

        retlw   B'00001101'     ;
        retlw   B'00010010'     ;
        retlw   B'00010010'     ;
        retlw   B'00001101'     ;
        retlw   B'00000000'     ;       ö

        retlw   B'00011111'     ;
        retlw   B'00010000'     ;
        retlw   B'00010000'     ;
        retlw   B'00010000'     ;
        retlw   B'00000000'     ;       L

        retlw   B'00001101'     ;
        retlw   B'00010000'     ;
        retlw   B'00010000'     ;
        retlw   B'00001101'     ;
        retlw   B'00000000'     ;       ü


        retlw   B'00011111'     ;
        retlw   B'00000010'     ;
        retlw   B'00000100'     ;
        retlw   B'00000010'     ;
        retlw   B'00011111'     ;
        retlw   B'00000000'     ;       M

        retlw   B'00001101'     ;
        retlw   B'00010000'     ;
        retlw   B'00010000'     ;
        retlw   B'00001101'     ;
        retlw   B'00000000'     ;       ü

        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;




        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;
        retlw   B'00000000'     ;

return

;****************************************************************************
STEP_CLEAR
        movlw   B'00000000'
        movwf   LINE1
        movwf   LINE2
        movwf   LINE3
        movwf   LINE4
        movwf   LINE5
        movwf   LINE6
        movwf   LINE7
        movwf   LINE8
        movwf   LINE9
        movwf   LINE10
        movwf   LINE11
        movwf   LINE12
        movwf   LINE13
        movwf   LINE14
        movwf   LINE15
        movwf   LINE16

        MOVLW   D'50'
        MOVWF   ZAMAN
        CALL    STEP_DELAY
RETURN
;****************************************************************************


;****************************************************************************
STEP_DELAY
        clrwdt
       ; call    DELAYSYS                        ;20 msec delay
        CALL    RUNTIME
        decfsz  ZAMAN
        goto    STEP_DELAY
return
;****************************************************************************



;****************************************************************************
RUNTIME
;***************************************************************************

;***************************************************************************
WRITEDISP
        ;test
        ;call    delay20
        ;test

        clrwdt
        movlw   D'0'
        movwf   PORTA
        movf    LINE1,0
        movwf   PORTB
        call    delay1

        clrwdt
        movlw   D'1'
        movwf   PORTA
        movf    LINE2,0
        movwf   PORTB
        call    delay1

        clrwdt
        movlw   D'2'
        movwf   PORTA
        movf    LINE3,0
        movwf   PORTB
        call    delay1

        clrwdt
        movlw   D'3'
        movwf   PORTA
        movf    LINE4,0
        movwf   PORTB
        call    delay1

        clrwdt
        movlw   D'4'
        movwf   PORTA
        movf    LINE5,0
        movwf   PORTB
        call    delay1

        clrwdt
        movlw   D'5'
        movwf   PORTA
        movf    LINE6,0
        movwf   PORTB
        call    delay1

        clrwdt
        movlw   D'6'
        movwf   PORTA
        movf    LINE7,0
        movwf   PORTB
        call    delay1

        clrwdt
        movlw   D'7'
        movwf   PORTA
        movf    LINE8,0
        movwf   PORTB
        call    delay1

        clrwdt
        movlw   D'8'
        movwf   PORTA
        movf    LINE9,0
        movwf   PORTB
        call    delay1

        clrwdt
        movlw   D'9'
        movwf   PORTA
        movf    LINE10,0
        movwf   PORTB
        call    delay1

        clrwdt
        movlw   D'10'
        movwf   PORTA
        movf    LINE11,0
        movwf   PORTB
        call    delay1

        clrwdt
        movlw   D'11'
        movwf   PORTA
        movf    LINE12,0
        movwf   PORTB
        call    delay1

        clrwdt
        movlw   D'12'
        movwf   PORTA
        movf    LINE13,0
        movwf   PORTB
        call    delay1

        clrwdt
        movlw   D'13'
        movwf   PORTA
        movf    LINE14,0
        movwf   PORTB
        call    delay1

        clrwdt
        movlw   D'14'
        movwf   PORTA
        movf    LINE15,0
        movwf   PORTB
        call    delay1

        clrwdt
        movlw   D'15'
        movwf   PORTA
        movf    LINE16,0
        movwf   PORTB
        call    delay1

        movlw   H'00'
        movwf   PORTB
        RETURN
;***************************************************************************

;***************************************************************************
SETCPUPORTSTATUS
        bsf     STATUS,RP0
        movlw   H'00'
        movwf   TRISB           ;PORTB pins : O-O-O-O-O-O-O-O
        movlw   B'00000000'
        movwf   TRISA           ;PORTA pins : X-X-X-O-O-O-O-O
        bcf     STATUS,RP0
        movlw   H'00'   
        movwf   PORTA
        movwf   PORTB
RETURN
;***************************************************************************


;****************************************************************************
;*-     Delay Routines                                                     -*
;****************************************************************************
vlong   
	movlw   0xff            ;very long delay, approx 200msec
        movwf   msb
        goto    d1
DELAYSYS                        ;20 msec delay
        movlw   .26
        movwf   msb
        CLRWDT
        CALL    RUNTIME
        goto    d1
delay20                         ;20 msec delay
        movlw   .26
        movwf   msb
        goto    d1
delay16                         ;16 msec delay
        movlw   .21
        movwf   msb
        goto    d1
delay1                          ;approx 750nsec delay
        movlw   .1      
        movwf   msb
d1      movlw   0xff
        movwf   lsb
d2      decfsz  lsb,F
        goto    d2
        decfsz  msb,F
        goto    d1
        return
;****************************************************************************



FINISH
        goto    START

end
