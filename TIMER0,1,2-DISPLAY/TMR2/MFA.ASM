	list p=16F877A
	include "p16F877A.inc"	
	__config H'3F39' 
	ORG 	0
	clrf 	PCLATH		
	goto 	ana_program	
	ORG 	4
interrupt
	banksel PIR1		
	btfss	PIR1, 1	
	goto	int_j1	
	bcf 	PIR1, 1	
int_j1
	retfie
ana_program
	banksel TRISB		
	clrf 	TRISB		
	bcf 	STATUS, RP0	
	clrf 	PORTB		
	movlw	0xFF
	movwf 	T2CON	
	clrf	TMR2	
	bsf 	STATUS, RP0	
	bsf	PIE1, 1		
	movlw	0xC0		
	movwf	INTCON
ana_j1
	goto 	ana_j1	

	END	

