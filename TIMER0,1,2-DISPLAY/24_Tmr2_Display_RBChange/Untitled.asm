list p = 16F877A
include "P16F877A.inc"
Sayac_Display equ 0x21
Sayac_Kesme equ 0x22

ORG 0
goto Ana_Program

ORG 4

Kesme
	BTFSS INTCON,RBIF
	goto Timer_Kontrol
	goto Tus7_islemler

Timer_Kontrol
	BTFSS PIR1,TMR2IF
	goto Cikis	
	goto Timer_islemler

Tus7_islemler
	BTFSC PORTB,7
	goto Cikis
	movlw B'00000100'
	XORWF T2CON,1
	goto Cikis	

Timer_islemler
	BCF PIR1,TMR2IF
	DECFSZ Sayac_Kesme
	goto Cikis
	
	movlw D'15'
	movwf Sayac_Kesme
	
	incf Sayac_Display
	call Lookup
	movwf PORTD
	goto Cikis

Cikis
	BCF INTCON,RBIF
	retfie


Ana_Program
	MOVLW B'00000001'
	MOVWF PORTA
	CLRF PORTD
	CLRF PORTB
	CLRF TMR2

	movlw D'15'
	movwf Sayac_Kesme
	
	BSF STATUS,RP0
	BCF OPTION_REG,7
	
	MOVLW 0X06
	MOVWF ADCON1
	
	CLRF TRISA
	CLRF TRISD
	MOVLW B'10000000'
	MOVWF TRISB

	movlw D'250'
	MOVWF PR2
	
	BCF STATUS,RP0
	MOVLW B'01111011' 
	MOVWF T2CON

	BCF PIR1,TMR2IF

	BSF STATUS,RP0
	BSF PIE1,TMR2IE

	BCF STATUS,RP0
	MOVLW B'11001000'
	MOVWF INTCON

Dongu
	goto Dongu

Lookup
	movf Sayac_Display,0
	addwf PCL,1
	
	nop 
	retlw b'00111111';0        
	retlw b'00000110';1
	retlw b'01011011';2
	retlw b'01001111';3
	retlw b'01100110';4
	retlw b'01101101';5
	retlw b'01111101';6
	retlw b'00000111';7
	retlw b'01111111';8
	clrf Sayac_Display
	retlw b'01100111';9
	
	end