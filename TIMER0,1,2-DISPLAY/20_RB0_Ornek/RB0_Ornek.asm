list p = 16F877A
include "P16F877A.inc"

Sayac_Display equ 0x23

ORG 0
goto Ana_Program

ORG 4

Kesme 
	BTFSS INTCON,INTF
	retfie
	incf Sayac_Display
	call Lookup
	movwf PORTD
	BCF INTCON,INTF
	retfie	

Ana_Program
	CLRF Sayac_Display
	CLRF PORTD
	CLRF PORTA
	CLRF PORTB
	MOVLW B'00001010'
	MOVWF PORTA

	BSF STATUS,RP0
	CLRF TRISD
	CLRF TRISA
	MOVLW B'00000001'
	MOVWF TRISB

	BCF OPTION_REG,7
	
	MOVLW B'11010000'
	MOVWF INTCON
	
	BCF STATUS,RP0
	
Dongu
	goto Dongu


Lookup
	movf Sayac_Display,w
	addwf PCL,f
		
	nop
	retlw B'00111111' ; 0
	retlw B'00000110' ; 1
	retlw B'01011011' ; 2
	retlw B'01001111' ; 3
	retlw B'01100110' ; 4
	retlw B'01101101' ; 5
	retlw B'01111101' ; 6
	retlw B'00000111' ; 7
 	retlw B'01111111' ; 8
	CLRF Sayac_Display
	retlw B'01101111' ; 9

end
