;**********************************************************************
;                                                                     *
;    Filename:	    lcdtest.asm                                       *
;    Date:                                                            *
;    Author:        el@jap.hu                                         *
;    Reference:     http://jap.hu/electronic/                         *
;                                                                     * 
;**********************************************************************
; HISTORY
;
; 002 - 20030622 demo for public release
;**********************************************************************

	list      p=16F84             ; list directive to define processor
	#include <p16F84.inc>         ; processor specific variable definitions
	#include "lcdlib.inc"


	__CONFIG   _CP_OFF & _WDT_OFF & _PWRTE_ON & _HS_OSC
	 ; WDT=watchdog, PWRTE=power on timer, HS=high speed osc

.objda	UDATA 0x20
;* variables in the main program
dummy0	res 1
dummy1	res 1

.objtest CODE 0

;* RESET *
Reset		goto main
		nop
		nop
		nop

;* INT *
Interrupt	retfie

.main	CODE

GLOBAL		messages
messages	movwf PCL
msg_welcome	dt "LCD test string.                        (C) Jap, 2001.", 0, 0

;* Message table *
main		clrf PORTA
		clrf PORTB

		movlw 7
		movwf 0x1f; this is for F628 compatibility

		movlw 0xff
		TRIS PORTA ; porta all input

		MOVLW 0x80
		TRIS PORTB

                BSF STATUS, RP0 ;bank 1
                BCF OPTION_REG, NOT_RBPU ;internal pullups on port B enabled
                BCF STATUS, RP0 ;bank 0

		call lcd_init
		movlw msg_welcome
		call lcd_strout

		movlw d'245'
		call lcd_decout
		movlw ' '
		call lcd_chrout

		movlw 0x7c
		call lcd_hexout

		movlw 7 ; curs. increment + shift
		call lcd_cmdout

		clrf	dummy0
loop		call	delay250ms
		movf	dummy0, W
		call	lcd_chrout
		incf	dummy0, F
		goto	loop

delay250ms	movlw 0x32
		movwf dummy1
delay_s1	call lcd_delay5ms
		decfsz dummy1, F
		goto delay_s1
		return

		end                       ; directive 'end of program'

