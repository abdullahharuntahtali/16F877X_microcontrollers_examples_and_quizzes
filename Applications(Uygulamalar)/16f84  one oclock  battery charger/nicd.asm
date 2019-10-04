
; *********************************************************************
; NiCd fast loader
; implements delta-U off-switch
;
; Jaap Havinga 5 jun 2000 
; 
;
; *********************************************************************
	list	p=16F84A
	include <p16f84a.inc>
	
; genereer config data
 __config	_HS_OSC
; __config	_RC_OSC

; RA0 = (IN)  ADC comparator 0=RC < U_measure, 1 = RC > U_measure
; RA1 = (OUT) ADC reset (active HI)
; RA2 = (OUT) charge current on=1/off=0

#define ADC_COMP_BIT	0
#define ADC_RESET_BIT	1
#define CHARGE_BIT	2


#define BANK_LOW	bcf	STATUS,RP0
#define BANK_HIGH	bsf	STATUS,RP0


#define TIMER_PERIOD	D'250'	 

	; tmr0 is sinds het optreden van de irq 7 steps verder
	; daarnaast zal na het laden van de nieuwe waarde de
	; tmr 2 steps stilstaan.
	; voor een juiste periode moet de timer value met 7+2 = 9 steps
	; gecorrigeerd worden
#define TIMER_CORRECTION_VALUE	D'9'

#define	TIMERCOUNT	 (H'ff'-TIMER_PERIOD+TIMER_CORRECTION_VALUE)  

; geeft periode tussen twee metingen aan  
;	(1 sec = 4000 * 250 us, 4000 = fa0h)
#define MEASURE_TIME_HI	H'0f'
#define MEASURE_TIME_LO	H'a0'

; geeft charge-periode aan in MEASURE_TIME perioden
; 2uur = 2*60*(60*1 sec) = 7200 * 1 sec, 7200 = 1C20
#define CHARGE_TIME_HI	H'1C'
#define CHARGE_TIME_LO	H'20'

#define RESET_PULSE	D'4'

#define STATE_CHARGE_READY 	0
#define STATE_RESET_ADC	  	1
#define STATE_MEASURE_ADC 	2

; 30 measures with negative delta before end charge
#define NEG_DELTA_COUNT		D'30'	
; delta is considered negative if Umax - Uactual > 1 = Umargin
#define DELTA_MARGIN		D'1'

; display defines
#define	RS_BIT	1
#define RW_BIT	2
#define	E_BIT	3

; *************** used registers *********************
 

TIME_MeasureLo		equ	H'0C'
TIME_MeasureHi		equ	H'0D'
TIME_ChargeLo		equ	H'0E'
TIME_ChargeHi		equ	H'0F'
MEASUREMENT 		equ	H'10' 
MaxMEASUREMENT 		equ	H'12' 
CURRENT_STATE		equ	H'14'
TIME_ResetPulse		equ	H'15'
nNegDelta		equ	H'16'

temp			equ	H'17'
temp1			equ	H'18'
temp2			equ	H'19'
tempHex			equ	H'1A'
tempHexNibble		equ	H'1B'


; *************** Start of program *********************

; hier starten we
	org	0x00 
reset 
	goto	init

; *************** IRQ handler *********************
	org	0x04
irq
	BANK_LOW
	CLRWDT				; eerst moeten we de waakhond uitzetten!
	
	btfss	INTCON,T0IE		; was timer going off? 
	retfie				;  goodbye
	
	movlw	TIMERCOUNT		; reload timer
	movwf	TMR0;

	btfsc	CURRENT_STATE,STATE_CHARGE_READY
	retfie				;  not charging anymore, goodbye (do not enable irq again )

	btfss	CURRENT_STATE,STATE_RESET_ADC
  	goto	test_StateIsMeasurement
	
	decfsz	TIME_ResetPulse,F		; reset should last a few ms
	goto	goodbye

	clrf	MEASUREMENT 		; clear result 
	bcf	CURRENT_STATE, STATE_RESET_ADC	 ; reset state is over
	bsf	CURRENT_STATE, STATE_MEASURE_ADC ; and goto measurement-state
	bcf	PORTA,ADC_RESET_BIT		; clear reset output
	goto	goodbye

test_StateIsMeasurement
	btfss	CURRENT_STATE,STATE_MEASURE_ADC
	goto	dec_counters

	incf 	MEASUREMENT , F	; increment measurement counters

	btfsc	PORTA, ADC_COMP_BIT	; Comparator says ready?
	goto	dec_counters
	bcf	CURRENT_STATE,STATE_MEASURE_ADC		; turn off measurementstate
	
	call 	Home1  
	movfw	MEASUREMENT 
	call	Display_Hex
	movlw	D'6'
	call	MoveTo1 
	movfw	MaxMEASUREMENT 
	call	Display_Hex
 
	movlw	D'10'
	call	MoveTo0 
	movfw	TIME_ChargeHi
	call	Display_Hex
	movfw	TIME_ChargeLo
	call	Display_Hex

	; compare with prev. measurement

	movfw	MaxMEASUREMENT 
	subwf	MEASUREMENT ,W		;f-w = measure - prev   
	btfsc	STATUS,C		; negative?
	goto 	no_measurement_carry	
	addlw	DELTA_MARGIN			;see if we get it positive now...
	btfsc	STATUS,C		; negative?
	goto 	no_measurement_carry_NoMax	
	
	decfsz	nNegDelta,F		; yes, decrement negative delta counter
	goto	no_NegDelta		; not ended
	goto	Charge_Ready		; counter is 0, so stop charging
					
no_measurement_carry		
	movfw	MEASUREMENT 		; so measurement is larger, set maxValue
	movwf	MaxMEASUREMENT  

no_measurement_carry_NoMax
	movlw	NEG_DELTA_COUNT		; we want to be sure
	movwf	nNegDelta
no_NegDelta 
	bsf	PORTA,CHARGE_BIT	; set charging on
	goto 	goodbye			; leave now 

dec_counters 
	movlw	D'1'
	subwf	TIME_MeasureLo, F
	btfsc	STATUS,C
	goto	goodbye
	decf	TIME_MeasureHi, F  
	btfss	STATUS,Z		; should start measurement?
	goto	goodbye
 
	movlw	MEASURE_TIME_HI		; yes, first reset counters
	movwf	TIME_MeasureHi
	movlw	MEASURE_TIME_LO
	movwf	TIME_MeasureLo
	 
	movlw	D'1'
	subwf	TIME_ChargeLo, F
	btfsc	STATUS,C
	goto	no_charge_Carry
	decf 	TIME_ChargeHi, F
	btfsc	STATUS,Z		; is charge-timeout reached?
	goto	Charge_Timeout

no_charge_Carry
	movlw	RESET_PULSE
	movwf	TIME_ResetPulse
	bsf	CURRENT_STATE,STATE_RESET_ADC	; goto reset-state
	bsf	PORTA,ADC_RESET_BIT		; set reset output
	bcf	PORTA,CHARGE_BIT		; shut off charging
	
	  
goodbye
	bcf	INTCON,T0IF		; enable irq again 
	retfie				;  goodbye

Charge_Timeout
	call 	Cls
	call	STR_TIMEOUT
	goto	finish
Charge_Ready
	call 	Cls
	call	STR_READY
finish
	bsf	CURRENT_STATE,STATE_CHARGE_READY
	bcf	PORTA,CHARGE_BIT	; shut off
	retfie				;  goodbye(do not enable irq again )
	
	
		
; *************** End of IRQ handler *********************


; *************** INIT part ****************
init 
	
	BANK_LOW

; *************** init ports ***************
	clrf	PORTA	; set data A op 0 
	clrf	PORTB 

	BANK_HIGH
	
	movlw	H'1'
	movwf	TRISA	; set A to input
	clrf	TRISB	; set B  to output 

	BANK_LOW

	movlw	MEASURE_TIME_HI	 
	movwf	TIME_MeasureHi
	movlw	MEASURE_TIME_LO
	movwf	TIME_MeasureLo

	movlw	CHARGE_TIME_HI		 
	movwf	TIME_ChargeHi
	movlw	CHARGE_TIME_LO
	movwf	TIME_ChargeLo
	 
	clrf	CURRENT_STATE
	clrf	MaxMEASUREMENT  

	movlw	NEG_DELTA_COUNT	 
	movwf	nNegDelta
	
	
	BANK_HIGH
	
; *************** 16F84 initialisatie ***************
					; zet de opties
	movlw	B'11001000'		; PullUp disabled, rb0 rising edge irq, psa to wdt, rate = 0
	movwf	OPTION_REG
	
	BANK_LOW

	call	InitDisplay
	call	STR_CHARGE
	CLRWDT				; de waakhond uitzetten! (gaat om de 18 ms af!!)
				
	movlw	TIMERCOUNT 		;; initialiseer timer
	movwf	TMR0
	bsf	INTCON,GIE		; enable interrupts
	bsf	INTCON,T0IE 		; enable timer 0 irq   
 

; *************** main function ***************
loop	goto	loop			; wait for interrupt
 
delay40us	CLRWDT
	movlw	D'11'	
	movwf	temp1
loop40us decfsz	temp1,f
	goto	loop40us	
	return
	

delay4ms
	movlw	D'100'
	movwf	temp2
loop4ms		
	call delay40us 
	decfsz	temp2,f
	goto	loop4ms	
	return	 

WaitDisplayReady 
	CLRWDT
	BANK_HIGH
	movlw	H'f0'
	movwf	TRISB	; set B to input
	BANK_LOW 
	clrf	PORTB
	bsf	PORTB,RW_BIT
	bsf	PORTB,E_BIT 
WaitLoop	
	nop
	nop  
	btfsc 	PORTB,7
	goto	WaitLoop

	clrf	PORTB
	BANK_HIGH
	movlw	H'00'
	movwf	TRISB	; set B to output
	BANK_LOW
	return
	
write_nibbleD
	andlw	H'f0'
	iorlw	h'02'
	movwf	PORTB
	bsf	PORTB,E_BIT 
	nop
	bcf	PORTB,E_BIT  
	return

write_byteD
	movwf	temp
	call	write_nibbleD
	rlf	temp,f
	rlf	temp,f
	rlf	temp,f
	rlf	temp,f
	movfw	temp
	call	write_nibbleD 
	goto	WaitDisplayReady

write_nibbleC
	andlw	H'f0'
	movwf	PORTB
	bsf	PORTB,E_BIT 
	nop
	bcf	PORTB,E_BIT  
	return

write_byteC 
	movwf	temp
	call	write_nibbleC
	rlf	temp,f
	rlf	temp,f
	rlf	temp,f
	rlf	temp,f
	movfw	temp
	call	write_nibbleC
	goto	WaitDisplayReady

InitDisplay
	call	delay4ms		; delay power up
	call	delay4ms
	call	delay4ms
	call	delay4ms 
	call	delay4ms 
	movlw	H'30'			; 8 bit mode
	call	write_nibbleC
	call	delay4ms 
	movlw	H'30'			; 8 bit mode
	call	write_nibbleC
	call	delay4ms 
	movlw	H'30'			; 8 bit mode
	call	write_nibbleC
	call	delay4ms 

	movlw	H'20'			; 4 bit mode
	call	write_nibbleC
	call	delay4ms 

	movlw	H'28'			; 4 bit mode
	call	write_byteC 


	movlw	H'08'			; display off, cursor off,  
	call	write_byteC 

	movlw	H'0e'			; display on, cursor on,   blinking cursor
	call	write_byteC 

	movlw	H'06'			; cursor moving right, no shift display
	call	write_byteC  

Cls	movlw	H'01'			;  
	goto	write_byteC 		; exit init also
 
Home0	clrw
MoveTo0	iorlw	H'80'			;  
	goto	write_byteC 		;  

Home1	clrw
MoveTo1 iorlw	H'C0'			;  
	goto	write_byteC 		;  

Display_Hex	
	movwf	tempHex
	movwf	tempHexNibble
	rrf	tempHexNibble,f
	rrf	tempHexNibble,f
	rrf	tempHexNibble,f
	rrf	tempHexNibble,f
	call	display_hexNibble
	movfw	tempHex
	movwf	tempHexNibble

display_hexNibble
	movlw	h'0f'
	andwf	tempHexNibble,f
	movlw	D'10'
	subwf	tempHexNibble,w	;f-w = d-10
	btfsc	STATUS,C
	goto	hex_af	
	movfw	tempHexNibble
	iorlw	H'30'
	goto	write_byteD
hex_af	addlw	h'41'
	goto	write_byteD
	 
STR_CHARGE  
	movlw	A'C'
	call	write_byteD
	movlw	A'h'
	call	write_byteD
	movlw	A'a'
	call	write_byteD
	movlw	A'r'
	call	write_byteD
	movlw	A'g'
	call	write_byteD
	movlw	A'e'
	goto	write_byteD


STR_READY 
	movlw	A'R'
	call	write_byteD
	movlw	A'e'
	call	write_byteD
	movlw	A'a'
	call	write_byteD
	movlw	A'd'
	call	write_byteD
	movlw	A'y'
	goto	write_byteD

STR_TIMEOUT  
	movlw	A'T'
	call	write_byteD
	movlw	A'i'
	call	write_byteD
	movlw	A'm'
	call	write_byteD
	movlw	A'e'
	call	write_byteD
	movlw	A'O'
	goto	write_byteD
	movlw	A'u'
	goto	write_byteD
	movlw	A't'
	goto	write_byteD
	END

 
