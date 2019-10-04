
	list p=16F877A
	include "p16F877A.inc"	
	__config H'3F31' 
	ORG 	0
	clrf 	PCLATH	
	goto 	ana_program	
	ORG 	4		
interrupt
	banksel  PIR1		
	bcf 	PIR1, 0		
	retfie
ana_program
	banksel TRISB			
	clrf 	TRISB		
	movlw 	0x01
	banksel T1CON		
	movwf 	T1CON		
	bcf 	PIR1, TMR1IF
	banksel PIE1		
	bsf 	PIE1, TMR1IE	
	movlw 	0xF0
	banksel PORTB		
	movwf 	PORTB		
	movlw 	0xC0			
	movwf 	INTCON		
ana_j1				
	goto 	ana_j1	
	END	