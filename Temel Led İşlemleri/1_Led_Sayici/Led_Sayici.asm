	list p=16F877
	include "p16f877.inc"

	Sayac1 equ 0x25
	Sayac2 equ 0x26
	Sayac3 equ 0x27

	ORG 0
	goto ana_program
	clrf PCLATH
	ORG 4

Kesme
	retfie

ana_program
	banksel PORTD
	clrf PORTD
	banksel TRISD
	clrf TRISD
	movlw d'1'
	goto Gecik

Sayma
	banksel PORTD
	incf PORTD	
	movlw d'10'

Gecik
	movwf Sayac1
Sayac2_ayar
	movlw d'255'
	movwf Sayac2
Sayac3_ayar
	movlw d'255'
	movwf Sayac3
Dongu
	decfsz Sayac3,1
	goto Dongu
	decfsz Sayac2,1
	goto Sayac3_ayar
	decfsz Sayac1,1
	goto Sayac2_ayar

	goto Sayma
	
	end