

; CPU configuration
; 	
	list P=16F84
	#include "p16f84.inc"
	__config _XT_OSC & _WDT_OFF & _PWRTE_ON

; Define variables at memory locations

; RAM

W_TMP		equ	H'0C'	; temporary store for w in interrupt
STATUS_TMP	equ	H'0D'	; temporary store of status in interrupt  

REMOTE_M	equ	H'0E'	; remote control input ms byte
REMOTE_L	equ	H'0F'	; remote control input LS byte
REM_FLG		equ	H'10'	; flag to indicate current remote control sequencing 
REM_CNT		equ	H'11'	; interrupt count for polling remote control signal
REM_COD		equ	H'12'	; remote control bit counter mode.
TOGGLE		equ	H'13'	; remote control toggle flag
FLAG0		equ	H'14'	; test flag 0
B_STAT		equ	H'15'	; B port input status at power up
A_STAT		equ	H'16'	; A port input status at power up
VALUE_1		equ	H'17'	; delay value
VALUE_2		equ	H'18'	; delay value
FLAG_RM		equ	H'19'	; flag to indicate continuous remote
TG_BIT		equ	H'1A'	; counter of number of incorrect toggle matches
FLG_HL		equ	H'1B'	; high or low remote control sign

; define reset and interrupt vector start addresses

	org	0	  	; start at address 0000h
	goto	MAIN		; normal service routines from Reset vector
	org     4		; interrupt vector 0004h, start interrupt routine here
	goto	INTRUPT



; start interrupt by saving w and status registers before altered by interrupt routine

INTRUPT movwf	W_TMP		; w to w_tmp storage
	swapf	STATUS,w	; status to w
	movwf	STATUS_TMP	; status in status_tmp  
	bcf	STATUS,RP0	; select memory bank 0

; check interrupt	
	
	
	btfsc	INTCON,T0IF	; TMRO overflow interrupt flag then goto counter
	goto	COUNTER		; TMRO overflow so increase counter 
	goto	RECLAIM		; end of interrupt reclaim w and status


; adjust interrupt rate with counter

		
COUNTER	movlw	D'207'		; freq is 4MHz/4/2/50. = 100us
	addwf	TMR0,f		; add to timer register and takes 2 cycles to start counting
	bcf	INTCON,T0IF	; clear TMRO interrupt flag



; check if RA3 has gone low for start of remote control sequence

	btfss	FLAG0,0		; if flag set then test mode
	goto	RM_SQ		; remote sequence started?
	bcf	PORTA,1		;  * tracer for remote decode
	btfsc	REM_FLG,1	; is it the end of remote control sequence
	bcf	PORTA,0		; then clear RA0 stop start indicator
RM_SQ	btfsc	REM_FLG,0	; has remote control sequence started		
	goto	REM_SEQ
	btfsc	PORTA,3		; is RA3 low 
	goto	RECLAIM
	bsf	REM_FLG,0	; set beginning of remote control flag
	
	movlw	D'22'		; initial time period to wait till next start bit
	movwf	REM_CNT
	movlw	D'13'		; shift register counter
	movwf	REM_COD
	bsf	REMOTE_L,0	; set first bit in remote control sequence
	clrf	FLG_HL		; clear bit 1 in high low flag
	bsf	REM_FLG,7	; start bit flag set	
	bsf	PORTA,2		; decode out (acknowledge LED driver)
	btfss	FLAG0,0		; if set then test mode
	goto	RECLAIM
	bsf	PORTA,1		; * tracer for decode (reads level at this point) 
	bsf	PORTA,0		; * start/stop trace	
	goto 	RECLAIM

REM_SEQ	btfsc	REM_FLG,1	; has it finished
	goto	RECLAIM
	decfsz	REM_CNT,f	; decrease interrupt counter for timing
	goto	CKEDGE		; check if change in level
	bcf	REM_FLG,7	; clear start bit flag
	movlw	D'18'		; 18 x 100us = 1.8ms or period between valid bits
	movwf	REM_CNT
	rlf	REMOTE_L,f	; least sig byte in remote control code sequence
	rlf	REMOTE_M,f	; most sig byte 
	movf	PORTA,w		; check bit 3 portA
	andlw	B'00001000'	; mask out bits except bit 3
	movwf	FLG_HL		; place in flag
	btfsc	PORTA,3		; check if high or low
	goto	HI		; high so clear
	bsf	REMOTE_L,0	; if low set this bit
	bsf	PORTA,2		; if high clear this bit
	goto	BY_HI		; bypass high
HI	bcf	REMOTE_L,0	; clear 0 bit
	bcf	PORTA,2 	; acknowledge
BY_HI	
	btfsc	FLAG0,0		; if set test mode 
	bsf	PORTA,1		; * tracer  
	decfsz	REM_COD,f	; decrease shift register count
	goto	RECLAIM
	bsf	REM_FLG,1	; set end of remote control decoding flag
	goto	RECLAIM

; align change in level (edge detect) with REM_CNT counter
 
CKEDGE	btfsc	REM_FLG,7	; start bit flag bypass edge detect as AGC level setting
	goto	RECLAIM
	movlw	B'00001000'	; select bit 3 for PORTA,3
	andwf	PORTA,w		; bit 3
	xorwf	FLG_HL,w	; compare PORTA,3 with FLAG (previous level)		
	btfsc	STATUS,z	; Z=1 if zero then no change
	goto	RECLAIM		; no change 
	movlw	B'00001000'	; select bit 3 for PORTA,3
	andwf	PORTA,w		; bit 3 select 
	movwf	FLG_HL		; reload new level
	movlw	0x3		; count of 3 for REM_CNT
	subwf	REM_CNT,w	; is REM_CNT larger or equal to 3
	btfss	STATUS,c
	goto	RECLAIM		; smaller than 3 
	movf	REM_CNT,w
	sublw	0x6		; check if 6 or less
	btfss	STATUS,c
	goto	RECLAIM		; larger than 6 
	movlw	0x4
	movwf	REM_CNT		; set REM_CNT to 4 to align with change in level
	
; end of interrupt reclaim w and status 

RECLAIM	swapf	STATUS_TMP,w	; status temp storage to w
	movwf	STATUS		; w to status register
	swapf	W_TMP,f		; swap upper and lower 4-bits in w_tmp
	swapf   W_TMP,w		; swap bits and into w register
	retfie			; return from interrupt

;********************************************************************************************** 
  
; RESET		
; Set ports A & B

MAIN	clrf	REM_CNT		; remote control polling counter
	clrf	REM_FLG		; remote control flag status
	clrf	FLAG0		; test
	clrf	FLAG_RM		; continuous remote
	bsf	STATUS,RP0	; select memory bank 1
	movlw	B'11111111'	;  inputs
	movwf	TRISB		; port B data direction register
	movlw	B'10000000'	; 
	movwf	OPTION_REG	; TMRO prescaler is 2, PORTB pullups disabled
	movlw   B'00011111'	;  (1's are inputs) 
	movwf   TRISA		; A port data direction register
	bcf	STATUS,RP0	; select memory bank 0

; check pin status

	btfss	PORTA,2		; if RA2 high set the test flag  		
	goto	IN_CK		; input check
	bsf	FLAG0,0		; set test routine (RA0 is start stop output for remote control)
				; (RA1 is tracer) RA2 normally gives decoded output for ACK LED
IN_CK	movf	PORTB,w		; portB input level (high is toggle, low is momentary)
	movwf	B_STAT		; port B status
	movf	PORTA,w		; look at RA1 and RA0
	movwf	A_STAT		; store in A status
	btfsc	FLAG0,0
	clrf	A_STAT		; clear bits 0 and 1 if in test mode (so momentary)
	bsf	A_STAT,2	; set bit 2 for acknowledge LED
	bsf	STATUS,RP0	; select memory bank 1
	movlw	B'00000000'	;  outputs
	movwf	TRISB		; port B data direction register
	movlw	B'10000000'	; 
	movwf	OPTION_REG	; TMRO prescaler is 2, PORTB pullups disabled
	movlw   B'00011000'	;  (1's are inputs) RA0-2 outputs 
	movwf   TRISA		; A port data direction register
	bcf	STATUS,RP0	; select memory bank 0
	movlw	B'00000000'	; lows
	movwf	PORTB		; portB outputs low
	movlw	B'00000000'
	movwf	PORTA		; portA low 

; interrupt enable 

	bsf	INTCON,T0IE	; set interrupt enable for TMR0 
	bsf	INTCON,GIE	; set global interrupt enable for above


; check remote codes 

; delay

RM_CK	movlw	D'100'		; set delay period of about 120ms between codes
	movwf	VALUE_1		; VALUE_1 = w
	movlw	D'255'		; set delay period value 2 
LP_1	movwf	VALUE_2		; VALUE_2 = w
LP_2	decfsz	VALUE_2,f	; decrease VALUE_2, skip if zero
	goto 	LP_2
	decfsz	VALUE_1,f	; decrease VALUE_1, skip if zero
	goto	LP_1	
	
; remote control decoding
	
	btfss	REM_FLG,0	; remote control sequence started
	goto	CLR_RM1	
	btfss	REM_FLG,1	; is remote control entered flag set
	goto	RM_CK

; count number of codes to delete end of code sequence if button held for several seconds

	btfss	FLAG_RM,0	; is continuous mode set
	goto	XFER
	movf	REMOTE_M,w
	andlw	B'00001000'	; toggle bit
	xorwf	TOGGLE,w	; is toggle bit the same as last time
	btfsc	STATUS,z	; if z is 1 then the same
	goto	XFER 
	decfsz	TG_BIT,f	; toggle counter
	goto	BY_STO		; bypass storing toggle bit
	clrf	FLAG_RM		; clear continuous mode flag
XFER	movf	REMOTE_M,w
	andlw	B'00001000'	; get toggle bit
	movwf	TOGGLE		; store toggle bit
	movlw	D'06'
	movwf	TG_BIT		; count times that toggle bit different
BY_STO	movf	REMOTE_M,w	; most significant remote code 
	andlw	B'00110111'	; mask out bit 7 and 6 and toggle bit 3
		
	xorlw	B'00110010'	; compare with start bits and ms 3-bits of address
	btfss	STATUS,z	; if zero then matching
	goto	CLR_RMF

; compare with address code out if invalid clear REM_FLG
; if valid check command bits and ls 2 address bits then clear REM_FLG
 
	btfss	PORTA,4		; check porta
	goto	SAT2

SAT1	movf	REMOTE_L,w	; least sig remote code
	xorlw	B'00000000'	; bits 0-5 keycode (0), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	ZERO
	movf	REMOTE_L,w
	xorlw	B'00000001'	; bits 0-5 keycode (1), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	ONE 
	movf	REMOTE_L,w
	xorlw	B'00000010'	; bits 0-5 keycode (2), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	TWO
	movf	REMOTE_L,w
	xorlw	B'00000011'	; bits 0-5 keycode (3), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	THREE
  	movf	REMOTE_L,w	; least sig remote code
	xorlw	B'00000100'	; bits 0-5 keycode (4), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	FOUR
	movf	REMOTE_L,w
	xorlw	B'00000101'	; bits 0-5 keycode (5), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	FIVE 
	movf	REMOTE_L,w
	xorlw	B'00000110'	; bits 0-5 keycode (6), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	SIX
	movf	REMOTE_L,w
	xorlw	B'00000111'	; bits 0-5 keycode (7), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	SEVEN
	movf	REMOTE_L,w	; least sig remote code
	xorlw	B'00001000'	; bits 0-5 keycode (8), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	EIGHT
	movf	REMOTE_L,w
	xorlw	B'00001001'	; bits 0-5 keycode (9), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	NINE 

	goto	CLR_RMF


SAT2	movf	REMOTE_L,w	; least sig remote code
	xorlw	B'10000000'	; bits 0-5 keycode (0), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	ZERO
	movf	REMOTE_L,w
	xorlw	B'10000001'	; bits 0-5 keycode (1), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	ONE 
	movf	REMOTE_L,w
	xorlw	B'10000010'	; bits 0-5 keycode (2), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	TWO
	movf	REMOTE_L,w
	xorlw	B'10000011'	; bits 0-5 keycode (3), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	THREE
  	movf	REMOTE_L,w	; least sig remote code
	xorlw	B'10000100'	; bits 0-5 keycode (4), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	FOUR
	movf	REMOTE_L,w
	xorlw	B'10000101'	; bits 0-5 keycode (5), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	FIVE 
	movf	REMOTE_L,w
	xorlw	B'10000110'	; bits 0-5 keycode (6), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	SIX
	movf	REMOTE_L,w
	xorlw	B'10000111'	; bits 0-5 keycode (7), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	SEVEN
	movf	REMOTE_L,w	; least sig remote code
	xorlw	B'10001000'	; bits 0-5 keycode (8), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	EIGHT
	movf	REMOTE_L,w
	xorlw	B'10001001'	; bits 0-5 keycode (9), bit 7 and bit 6 are ls address bits
	btfsc	STATUS,z
	goto	NINE 

	goto	CLR_RMF
	
CLR_RM1	clrf	FLAG_RM		; clear continuous mode flag	
CLR_RMF	clrf	REM_FLG		; remote flag cleared
	bcf	PORTA,2		; decoder out
	btfsc	FLAG_RM,0	; if set then already passed here
	goto	RM_CK

	movf	A_STAT,w	; check portA status (high is toggle so anding will keep status)
	andwf	PORTA,f		; clear all momentary outputs keep toggles at current status
	movf	B_STAT,w
	andwf	PORTB,f 
	btfss	FLAG0,0		; if set then test mode
	goto	RM_CK
	bcf	PORTA,1		; * tracer out
	bcf	PORTA,0		; * start stop for decoder	
	goto	RM_CK

ZERO	btfsc	FLAG0,0		; if set then test mode
	goto	CLR_RMF
	btfsc	FLAG_RM,0	; if set then already passed here
	goto	CLR_RMF
	btfsc	A_STAT,1	; if set then toggle
	goto	TOG_0		; toggle (alternate mode)
	bsf	PORTA,1		; output high
	bsf	FLAG_RM,0	; set continuous mode
	goto	CLR_RMF
TOG_0	btfsc	PORTA,1		; if high clear
	goto	CLR_0
	bsf	PORTA,1		; low so set
	bsf	FLAG_RM,0	; ready for next remote control input
	goto	CLR_RMF	
CLR_0	bcf	PORTA,1		; high so clear
	bsf	FLAG_RM,0	; ready for next remote control
	goto	CLR_RMF

ONE	btfsc	FLAG0,0		; if set then test mode
	goto	CLR_RMF
	btfsc	FLAG_RM,0	; if set then already passed here
	goto	CLR_RMF
	btfsc	A_STAT,0	; if set then toggle
	goto	TOG_1		; toggle (alternate mode)
	bsf	PORTA,0		; output high
	bsf	FLAG_RM,0	; set continuous mode
	goto	CLR_RMF
TOG_1	btfsc	PORTA,0		; if high clear
	goto	CLR_1
	bsf	PORTA,0		; low so set
	bsf	FLAG_RM,0	; ready for next remote control input
	goto	CLR_RMF	
CLR_1	bcf	PORTA,0		; high so clear
	bsf	FLAG_RM,0	; ready for next remote control
	goto	CLR_RMF

TWO	btfsc	FLAG_RM,0	; if set then already passed here
	goto	CLR_RMF
	btfsc	B_STAT,7	; if set then toggle
	goto	TOG_2		; toggle (alternate mode)
	bsf	PORTB,7		; 2 output high
	bsf	FLAG_RM,0	; set continuous mode
	goto	CLR_RMF
TOG_2	btfsc	PORTB,7		; if high clear
	goto	CLR_2
	bsf	PORTB,7		; low so set
	bsf	FLAG_RM,0	; ready for next remote control input
	goto	CLR_RMF	
CLR_2	bcf	PORTB,7		; high so clear
	bsf	FLAG_RM,0	; ready for next remote control
	goto	CLR_RMF

THREE	btfsc	FLAG_RM,0	; if set then already passed here
	goto	CLR_RMF
	btfsc	B_STAT,6	; if set then toggle
	goto	TOG_3		; toggle (alternate mode)
	bsf	PORTB,6		; output high
	bsf	FLAG_RM,0	; set continuous mode
	goto	CLR_RMF
TOG_3	btfsc	PORTB,6		; if high clear
	goto	CLR_3
	bsf	PORTB,6		; low so set
	bsf	FLAG_RM,0	; ready for next remote control input
	goto	CLR_RMF	
CLR_3	bcf	PORTB,6		; high so clear
	bsf	FLAG_RM,0	; ready for next remote control
	goto	CLR_RMF
FOUR	btfsc	FLAG_RM,0	; if set then already passed here
	goto	CLR_RMF
	btfsc	B_STAT,5	; if set then toggle
	goto	TOG_4		; toggle (alternate mode)
	bsf	PORTB,5		; output high
	bsf	FLAG_RM,0	; set continuous mode
	goto	CLR_RMF
TOG_4	btfsc	PORTB,5		; if high clear
	goto	CLR_4
	bsf	PORTB,5		; low so set
	bsf	FLAG_RM,0	; ready for next remote control input
	goto	CLR_RMF	
CLR_4	bcf	PORTB,5		; high so clear
	bsf	FLAG_RM,0	; ready for next remote control
	goto	CLR_RMF
FIVE	btfsc	FLAG_RM,0	; if set then already passed here
	goto	CLR_RMF
	btfsc	B_STAT,4	; if set then toggle
	goto	TOG_5		; toggle (alternate mode)
	bsf	PORTB,4		; output high
	bsf	FLAG_RM,0	; set continuous mode
	goto	CLR_RMF
TOG_5	btfsc	PORTB,4		; if high clear
	goto	CLR_5
	bsf	PORTB,4		; low so set
	bsf	FLAG_RM,0	; ready for next remote control input
	goto	CLR_RMF	
CLR_5	bcf	PORTB,4		; high so clear
	bsf	FLAG_RM,0	; ready for next remote control
	goto	CLR_RMF
SIX	btfsc	FLAG_RM,0	; if set then already passed here
	goto	CLR_RMF
	btfsc	B_STAT,3	; if set then toggle
	goto	TOG_6		; toggle (alternate mode)
	bsf	PORTB,3		; output high
	bsf	FLAG_RM,0	; set continuous mode
	goto	CLR_RMF
TOG_6	btfsc	PORTB,3		; if high clear
	goto	CLR_6
	bsf	PORTB,3		; low so set
	bsf	FLAG_RM,0	; ready for next remote control input
	goto	CLR_RMF	
CLR_6	bcf	PORTB,3		; high so clear
	bsf	FLAG_RM,0	; ready for next remote control
	goto	CLR_RMF
SEVEN	btfsc	FLAG_RM,0	; if set then already passed here
	goto	CLR_RMF
	btfsc	B_STAT,2	; if set then toggle
	goto	TOG_7		; toggle (alternate mode)
	bsf	PORTB,2		; output high
	bsf	FLAG_RM,0	; set continuous mode
	goto	CLR_RMF
TOG_7	btfsc	PORTB,2		; if high clear
	goto	CLR_7
	bsf	PORTB,2		; low so set
	bsf	FLAG_RM,0	; ready for next remote control input
	goto	CLR_RMF	
CLR_7	bcf	PORTB,2		; high so clear
	bsf	FLAG_RM,0	; ready for next remote control
	goto	CLR_RMF
EIGHT	btfsc	FLAG_RM,0	; if set then already passed here
	goto	CLR_RMF
	btfsc	B_STAT,1	; if set then toggle
	goto	TOG_8		; toggle (alternate mode)
	bsf	PORTB,1		; output high
	bsf	FLAG_RM,0	; set continuous mode
	goto	CLR_RMF
TOG_8	btfsc	PORTB,1		; if high clear
	goto	CLR_8
	bsf	PORTB,1		; low so set
	bsf	FLAG_RM,0	; ready for next remote control input
	goto	CLR_RMF	
CLR_8	bcf	PORTB,1		; high so clear
	bsf	FLAG_RM,0	; ready for next remote control
	goto	CLR_RMF
NINE	btfsc	FLAG_RM,0	; if set then already passed here
	goto	CLR_RMF
	btfsc	B_STAT,0	; if set then toggle
	goto	TOG_9		; toggle (alternate mode)
	bsf	PORTB,0		; output high
	bsf	FLAG_RM,0	; set continuous mode
	goto	CLR_RMF
TOG_9	btfsc	PORTB,0		; if high clear
	goto	CLR_9
	bsf	PORTB,0		; low so set
	bsf	FLAG_RM,0	; ready for next remote control input
	goto	CLR_RMF	
CLR_9	bcf	PORTB,0		; high so clear
	bsf	FLAG_RM,0	; ready for next remote control
	goto	CLR_RMF

	end		 	
