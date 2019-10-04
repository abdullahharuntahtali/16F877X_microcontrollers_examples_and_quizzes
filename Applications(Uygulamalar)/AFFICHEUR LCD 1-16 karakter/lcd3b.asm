;*****************************************
; programme de gestion d'un afficheur LCD 
; 1*16 caractères en mode 4 bits 
; par microcontroleur PIC 16F84
;
;	mai / 2002
;*****************************************

	include "p16f84.inc"

en	equ	0		; ra0 = enable
rs	equ	1		; ra1 = RS
conf2	equ	B'00001110'	; display ON/OFF
conf1a	equ	B'00110011'	; set interface	
conf1b	equ	B'00110010'	; la 1ere instruction
		;est executée 2 fois (mode 8 bits)
clear	equ	B'00000001'	; clear display
caract1 equ	0x80		; ligne1 gauche
caract2	equ	0xC0		; ligne1 droite
compt	equ	0x0D
sauv	equ	0x0F



	org	0x000
	nop
	goto	main

main	org	0x100
	banksel	TRISB		; banc 1
	movlw	B'01110000'
	movwf	TRISB		; port B en sortie
	movlw	B'00111100'
	movwf	TRISA		; port A en entrée

	banksel	PORTA		; banc 0
	
	
	call	tempo
	call	tempo
	call	tempo

	bcf	PORTA,en

	call	init
	movlw	"b"
	call	envdata
	movlw	"o"
	call	envdata
	movlw	"n"
	call	envdata
	movlw	"j"
	call	envdata
	movlw	"o"
	call	envdata
	movlw	"u"
	call	envdata
	movlw	"r"
	call	envdata
	movlw	" "
	call	envdata

	call 	droit

	movlw	"m"
	call	envdata
	movlw	"a"
	call	envdata
	movlw	"i"
	call	envdata
	movlw	" "
	call	envdata
	movlw	"2"
	call	envdata
	movlw	"0"
	call	envdata
	movlw	"0"
	call	envdata
	movlw	"2"
	call	envdata
	
	clrf	INTCON

fin	nop
	goto	fin


tempo	movlw	0xFF
	movwf	compt
bouct	decf	compt,1
	nop
	nop
	btfss	STATUS,2
	goto	bouct	
	return
	
envinit	bsf	PORTA,en
	movwf	sauv	
	swapf	sauv,0		; echange sauv
	andlw	0x0F
	movwf	PORTB
	call 	tempo
	bcf	PORTA,en
	call 	tempo
	bsf	PORTA,en
	movf	sauv,0		; echange sauv
	andlw	0x0F
	movwf	PORTB
	call 	tempo
	bcf	PORTA,en
	call 	tempo
	return

envdata	movwf	sauv	
	swapf	sauv,0		; echange sauv
	andlw	0x0F
	movwf	PORTB
	bsf	PORTA,en
	call 	tempo
	bcf	PORTA,en
	call 	tempo
	movf	sauv,0		; echange sauv
	andlw	0x0F
	movwf	PORTB
	bsf	PORTA,en
	call 	tempo
	bcf	PORTA,en
	call 	tempo
	return

init	bcf	PORTA,rs	; rs=0 => configuration
	movlw	conf1a
	call	envinit
	movlw	conf1b
	call	envinit	
	movlw	conf2
	call	envinit
	movlw	clear
	call	envinit
	movlw	caract1		; écriture 
	call	envinit		; ligne 1 gauche
	bsf	PORTA,rs	; rs=1 => fin de config
	return
	
gauch	bcf	PORTA,rs
	movlw	caract1		; écriture 
	call	envinit		; ligne 1 gauche
	bsf	PORTA,rs	; rs=1 => fin de config
	return

droit	bcf	PORTA,rs
	movlw	caract2		; écriture 
	call	envinit		; ligne 1 droite
	bsf	PORTA,rs	; rs=1 => fin de config
	return

cls	bcf	PORTA,rs
	movlw	clear
	call	envinit
	bsf	PORTA,rs
	return

	end



Message[302] E:\MONTAGES\PIC\LCD1.ASM 25 : Register in operand not in bank 0.  Ensure that bank bits are correct.
Message[302] E:\MONTAGES\PIC\LCD1.ASM 27 : Register in operand not in bank 0.  Ensure that bank bits are correct.
Message[305] E:\MONTAGES\PIC\LCD1.ASM 80 : Using default destination of 1 (file).
Message[302] E:\MONTAGES\PIC\LCD3.ASM 48 : Register in operand not in bank 0.  Ensure that bank bits are correct.
Message[302] E:\MONTAGES\PIC\LCD3.ASM 50 : Register in operand not in bank 0.  Ensure that bank bits are correct.
