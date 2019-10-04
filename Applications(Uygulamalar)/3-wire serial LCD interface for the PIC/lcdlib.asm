;**********************************************************************
;                                                                     *
;    Filename:	    lcdlib.asm                                        *
;    Date:                                                            *
;    Author:        el@jap.hu                                         *
;                   based on Myke Predko LCD interface hw/sw          *
;                                                                     *
;    Company:       http://jap.hu/                                    *
;                                                                     * 
;**********************************************************************
; HISTORY
;
; 000 - 20010106 initial version, first LCD experiment
; 001 - 20010108 LCD include test, first try
;**********************************************************************
;
;    Notes:
;
; RB4 = LCD E
; RB5 = LCD data CK
; RB6 = LCD data DA

	GLOBAL lcd_init, lcd_strout, lcd_decout, lcd_hexout, lcd_cmdout, lcd_chrout, lcd_delay5ms


	list      p=16F84             ; list directive to define processor
	#include <p16F84.inc>         ; processor specific variable definitions

#define LCD_E	PORTB, 4
#define LCD_CK	PORTB, 5
#define LCD_DA	PORTB, 6

.lcda	UDATA
;***** VARIABLE DEFINITIONS
ptr		res 1 ; chrout pointer
lcd_tmp		res 1 ; LCD shift-out register
lcd_ntmp	res 1 ; LCD shift-out nybble register
lcd_cnt		res 1 ; LCD shift-out counter
lcd_dly1	res 1 ; 160us counter
lcd_dly2	res 1 ; 5ms counter
lcd_buf1	res 1 ; lcd_decout work area
lcd_buf2	res 1

.lcdlib	CODE
		EXTERN messages

;* strout: send a string to the LCD
lcd_strout	movwf ptr
str_0		movf ptr, W
		call messages
		andlw 0xff
		bz str_1
		call lcd_chrout
		incf ptr, F
		goto str_0
str_1		return

;* lcd_hexout: send a hex byte in 2 char ASCII to the LCD
lcd_hexout	movwf	lcd_buf1
		swapf	lcd_buf1, W
		call	lcd_hxout

		movf	lcd_buf1, W
lcd_hxout	andlw	0x0f
		addlw	0xf6
		btfsc	STATUS, C
		addlw	0x07
		addlw	0x3a
		goto	lcd_chrout

;* lcd_decout: send a dec byte in 3 char ASCII to the LCD
lcd_decout	movwf	lcd_buf2
		movlw	'0'
		movwf	lcd_buf1

lcd_dec100	movlw	d'100'
		subwf	lcd_buf2, W
		bnc	lcd_dec10

		movwf	lcd_buf2
		incf	lcd_buf1, F
		goto	lcd_dec100

lcd_dec10	movf	lcd_buf1, W
		call	lcd_chrout

		movlw	'0'
		movwf	lcd_buf1

lcd_dec11	movlw	d'10'
		subwf	lcd_buf2, W
		bnc	lcd_dec1

		movwf	lcd_buf2
		incf	lcd_buf1, F
		goto	lcd_dec11

lcd_dec1	movf	lcd_buf1, W
		call	lcd_chrout

		movlw	'0'
		addwf	lcd_buf2, W
		goto	lcd_chrout
		
;* lcdinit: initialize the LCD module
lcd_init	call lcd_delay5ms ; power-up delay
		call lcd_delay5ms
		call lcd_delay5ms

		movlw 3
		bcf LCD_DA ; Make sure the RS Flag = 0
		call lcd_nybout

		call lcd_delay5ms ; Wait for the LCD to Power Up

		movlw 3
		bcf LCD_DA
		call lcd_nybout
		call lcd_delay5ms ;160us

		movlw 3 ; Reset Again
		bcf LCD_DA
		call lcd_nybout
		call lcd_delay160us

		movlw 2 ; Now, Set Interface Length to 4 Bits
		bcf LCD_DA
		call lcd_nybout
		call lcd_delay160us

		movlw 0x028
		call lcd_cmdout ; Now, Can Just Send Instructions - Set 4 Bits, 2 Lines
		movlw 0x00C     ; Turn Display On
		call lcd_cmdout
		movlw 0x001     ; Clear the Display, setup the Cursor
		call lcd_cmdout
		movlw 0x006     ; Set the Entry Mode
		goto lcd_cmdout


;* lcd_cmdout: send an LCD command
lcd_cmdout	movwf lcd_tmp
		;bcf INTCON, GIE

		bcf LCD_DA ; Start with the R/S Line Low

		swapf lcd_tmp, w ; Get the High Nybble to Send
		call lcd_nybout

		bcf LCD_DA ; Now, Send the low Nybble

		movf lcd_tmp, w
		call lcd_nybout

		;bsf INTCON, GIE

		call lcd_delay160us ; Wait for the LCD to Process the Instruction

		movlw 0x0FC       ; "Clear Display" and "Cursor At Home" Instructions
		andwf lcd_tmp, w  ; Require 5 msec Delay to Complete
		btfsc STATUS, Z
		call lcd_delay5ms

		return

;* lcd_chrout: send an LCD character code
lcd_chrout	movwf lcd_tmp    ; Save the Value for the Second Nybble
		;bcf INTCON, GIE ; Turn OFF Interrupts During Write

		bsf LCD_DA ; Start with the R/S Line High

		swapf lcd_tmp, w ; Get the High Nybble to Send
		call lcd_nybout

		bsf LCD_DA ; Now, Send the low Nybble

		movf lcd_tmp, w
		call lcd_nybout

		;bsf INTCON, GIE
		goto lcd_delay160us ; Wait for the LCD to Process the Instruction


;* lcd_nybout: send an LCD nybble out, with clocking out LCD_DA first
lcd_nybout	movwf lcd_ntmp ; Save the 4 Bits to Display

		bcf LCD_CK ; Clock out the Contents of LCD_DA
		bsf LCD_CK

		movlw 4    ; Now, Shift out four more bits
		movwf lcd_cnt

lcd_nyb0	bcf LCD_DA
		rrf lcd_ntmp ; Load Carry with the LSB
		btfsc STATUS, C
		bsf LCD_DA ; Set the Bit (if Appropriate)

		bcf LCD_CK ; Clock out the Bit
		bsf LCD_CK

		decfsz lcd_cnt
		goto  lcd_nyb0


		bsf LCD_E ; Toggle the 'E' Clock
		bcf LCD_E

		return

lcd_delay160us	movlw 0x36 ; calibrated for 4 MHz
		movwf lcd_dly1
lcd_delay0	decfsz lcd_dly1, F
		goto lcd_delay0
		return

lcd_delay5ms	movlw 0x20
		movwf lcd_dly2
lcd_delay1	call lcd_delay160us
		decfsz lcd_dly2, F
		goto lcd_delay1
		return
		end                       ; directive 'end of program'

