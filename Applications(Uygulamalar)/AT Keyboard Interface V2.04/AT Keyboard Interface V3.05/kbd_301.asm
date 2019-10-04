;***************************************************************************
;                                                                     
;	AT Keyboard Interface V3.01  (with LCD Display)
;	===============================================
;
;	written by Peter Luethi, 4.1.2001, Dietikon, Switzerland
;	http://www.electronic-engineering.ch
;	last update: 17.04.2004
;
;	V3.01b:	Added LCDcflag (LCD command/data flag) to comply with
;		latest LCD modules. Changed controller type to flash
;		device, i.e. PIC16F77.
;		(17.04.2004)
;
;	V3.01:	Made forward compatible (yes, this is feasible) by
;		implementing/completing ALT and CTRL flags. Added
;		labels to support non-implemented ALT and CTRL
;		enhancements. (2.1.2002)
;
;	V3.00:	Initial release (4.1.2001)
;
;	This code and accompanying files may be distributed freely and
;	modified, provided this header with my name and this notice remain
;	intact. Ownership rights remain with me.
;	You may not sell this software without my approval.
;
;	This software comes with no guarantee or warranty except for my
;	good intentions. By using this code you agree to indemnify me from
;	any liability that might arise from its use.
;
;	
;	SPECIFICATIONS:
;	===============
;	Processor:			Microchip PIC 16F77 (16C74A)
;	Clock Frequency:		4.00 / 8.00 MHz XT
;	Throughput:			1 / 2 MIPS
;	RS232 Baud Rate:		9600 / 19200 baud with BRGH = 1
;	Keyboard Routine Features:	Capability of bi-directional
;					communication between controller
;					and keyboard (keys & LEDs)
;	Acquisition Methodology:	Preemptive, interrupt-based
;					keyboard scan pattern acquisition
;					routine, with decoding to ASCII
;					characters during normal operation
;					(incl. LCD display and RS232 activities)
;	Code Size of entire Program:	832 instruction words
;	Required Hardware:		AT Keyboard, MAX 232,
;					HD44780 compatible dot matrix LCD
;					(2x16, 2x20 or 2x40 characters)
;	Required Software:		RS232 terminal
;
;
;	ABSTRACT:
;	=========
;	Fully operating RS232 terminal with completely bi-directional
;	communication capabilities. This program converts AT keyboard scan 
;	patterns to ASCII characters and transmits them afterwards to the
;	target device by using the RS232 transmission protocol. Both RS232
;	data reception and transmission possible.
;	Support of english (QWERTY) and modified swiss-german (QWERTZ)
;	'codepages'. Entry of user data on local AT keyboard and visualization
;	on dot matrix LCD display.
;
;
;	DESCRIPTION:
;	============
;	Developed and tested on Microchip PIC 16C74A.
;	Any key stroke on the keyboard connected to the PIC will send the
;	corresponding scan code from the keyboard to the microcontroller.
;	Afterwards, the microcontroller converts the keyboard scan code to
;	ASCII characters and transmits them to the personal computer across
;	the RS232 link.
;	Visualization of received data on the first line, user-entered data
;	on the second line of the dot matrix LCD display. This routine is
;	best used with a 2 line by 20 or 40 characters LCD display.
;	This program features also the capability of bi-directional
;	communication between controller and keyboard for configuration
;	purposes and to control the keyboard LEDs.
;
;	The keyboard scan pattern capture and decoding is done by an
;	interrupt service routine. The event, which triggers the interrupt
;	is a falling edge on the keyboard clock line at the KBDclkpin
;	(PORTB,0). The keyboard data (scan code) will be fetched at the
;	KBDdatapin (PORTA,0). The configuration of the KBDclkpin interrupt
;	is done by the KEYBOARDinit macro.
;
;	RS232 data exchange is carried out by using the internal USART of
;	the PIC 16C74A. RS232 data reception is done on an interrupt
;	based acquisition scheme, provided by the USART.
;
;	For the AT keyboard layout, English and modified Swiss-German
;	'codepages' are supported:
;	QWERTY and QWERTZ keyboard layout
;
;
;	IMPLEMENTED FEATURES:
;	=====================
;	- Bi-directional communication between microcontroller application
;	  and remote RS232 client.
;	- Bi-directional communication between microcontroller and keyboard.
;	- Bi-directional communication between microcontroller and LCD
;	  display.
;	- Visualization of received and transmitted characters on local LCD.
;	- Parametrizable LCD display width: constant 'LCDwidth'
;	- Support for all keyboard characters typed with shift button active 
;	  and inactive.
;	- English and modified Swiss-German 'codepages' available
;	  (QWERTY and QWERTZ)
;	  Include the desired keyboard lookup tables at the correct location.
;	- Caps Lock implemented
;	- Num Lock always active
;	- Possibility to implement short-cuts or user defined characters
;	  for 'Esc', 'Num Lock', 'Scroll Lock' and 'F1' - 'F12' keys
;
;	- Further enhancement, not implemented: Support of ASCII conversion
;	  from direct ALT-DEC and CTRL-HEX entries, e.g. ALT + 6 + 4 = @
;	  or CTRL + 3 + F = ?
;
;
;	LIMITATIONS:
;	============
;	- No support for ALT-GR characters.
;	- No support for arrow buttons, 'Home', 'Del', 'PageUp', 'PageDown',
;	  'Insert', 'End' because there exists no character/command
;	  corresponding to the ASCII character map. (But it is possible to
;	  use them for short-cuts or user defined characters, if the special 
;	  code routine (0xE0) is altered.)
;
;
;	NOTE:
;	=====
;	This program needs 'ORG' directives to locate tables within entire
;	memory pages. To allow for slight modifications, the code has not
;	been optimized to the utmost extent regarding program memory
;	placement. This can be carried out using the program memory window
;	of MPLAB showing the hexadecimal representation of the code.
;
;
;	CREDITS:
;	========
;	- Craig Peacock, the author of the excellent page about keyboards
;	  "Interfacing the PC's Keyboard" available at his website:
;	  http://www.beyondlogic.org/keyboard/keybrd.htm
;
;***************************************************************************

;***** COMPILATION MESSAGES & WARNINGS *****

	ERRORLEVEL -207 	; Found label after column 1.
	ERRORLEVEL -302 	; Register in operand not in bank 0.

;***** PROCESSOR DECLARATION & CONFIGURATION *****

	PROCESSOR 16F77
	#include "p16f77.inc"

	;PROCESSOR 16C74A
	;#include "p16c74a.inc"
	
	; embed Configuration Data within .asm File.
	__CONFIG   _CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC & _BODEN_ON

;***** MEMORY STRUCTURE *****

	;ORG     0x00	processor reset vector, declared below
	;ORG     0x04	interrupt service routine, declared below

;***** HARDWARE DECLARATION *****

	#define	KBDdatapin PORTA,0x00	; keyboard data input port
	#define	KBDdatatris TRISA,0x00
	#define	KBDclkpin PORTB,0x00	; keyboard clock input port (IntB)
	#define	KBDclktris TRISB,0x00
	LCDtris	equ	TRISB
	LCDport	equ	PORTB
	#define	LCDwidth d'40'		; define character width of LCD
					; display
;***** CONSTANT DECLARATION *****

	CONSTANT BASE = 0x20	; Base address of user file registers
	CONSTANT LF =	d'10'	; Line Feed
	CONSTANT CR =	d'13'	; Carriage Return
	CONSTANT TAB =	d'9'	; Tabulator
	CONSTANT BS =	d'8'	; Backspace
	CONSTANT SL =	d'0'	; control bit for keyboard scroll lock LED
	CONSTANT NL =	d'1'	; control bit for keyboard num lock LED
	CONSTANT CL =	d'2'	; control bit for keyboard caps lock LED

;***** REGISTER DECLARATION *****

	TEMP1	set	BASE+d'0'	; Universal temporary register
	TEMP2	set	BASE+d'1'	; ATTENTION !!!
	TEMP3	set	BASE+d'2'	; They are used by various modules.
	TEMP4	set	BASE+d'3'	; If you use them, make sure not to use
	TEMP5	set	BASE+d'4'	; them concurrently !
	TEMP6	set	BASE+d'5'
	TEMP7	set	BASE+d'6'

	FLAGreg	equ	BASE+d'7'	; register containing various flags
	FLAGreg2 equ	BASE+d'8'
	#define	RSflag	FLAGreg,0x00	; RS232 data reception flag
	#define	RELflag	FLAGreg,0x01	; release flag (0xF0)
	#define	SHIflag	FLAGreg,0x02	; shift flag (0x12 / 0x59)
	#define	SPEflag	FLAGreg,0x03	; special code flag (0xE0)
	#define	CAPflag	FLAGreg,0x04	; caps lock flag (0x0D)
	#define	ALTflag	FLAGreg,0x05	; ALT flag (0x11)
	#define	CTRLflag FLAGreg,0x06	; CTRL flag (0x14)
	#define	KBDflag	FLAGreg,0x07	; keyboard data reception flag
	#define	KBDtxf	FLAGreg2,0x00	; keyboard transmission flag
	#define	PARITY	FLAGreg2,0x01	; parity bit to be calculated
	#define	KBDexpf	FLAGreg2,0x02	; keyboard expect function flag
	#define	LCDbusy	FLAGreg2,0x03	; LCD busy flag
	#define	LCDcflag FLAGreg2,0x04	; LCD command/data flag
	#define	LCD_ln	FLAGreg2,0x05	; LCD line flag: 0 = line 1, 1 = line 2

	RXreg	equ	BASE+d'9'	; RS232 RX-Data register

	W_TEMP	equ	BASE+d'10'	; context register (ISR)
	STATUS_TEMP equ	BASE+d'11'	; context register (ISR)
	PCLATH_TEMP equ	BASE+d'12'	; context register (ISR)
	FSR_TEMP equ	BASE+d'13'	; context register (ISR)

	KBDcnt	equ	BASE+d'14'	; IRQ based keyboard scan pattern counter
	KBD	equ	BASE+d'15'	; keyboard scan code & ascii data register
	KBDcopy	equ	BASE+d'16'	; keyboard scan code register
	KBDleds	equ	BASE+d'17'	; keyboard LEDs' status register
	KBDexpval set	BASE+d'3'	; temporary KBD expected response value
	LCDpos1	equ	BASE+d'18'	; LCD output position counter
	LCDpos2	equ	BASE+d'19'	; LCD output position counter

;***** INCLUDE FILES *****

	ORG	0xC0
	#include "..\..\m_bank.asm"
	#include "..\..\m_wait.asm"
	#include "..\..\m_lcd_bf.asm"

;***** MACROS *****

KEYBOARDinit macro
	BANK1
	bsf	KBDclktris	; set input with weak pull-up
	bsf	KBDdatatris	; set input with weak pull-up
	bcf	OPTION_REG,INTEDG ; keyboard interrupt on falling edge
	BANK0
	movlw	b'10010000'
	iorwf	INTCON,F	; enable global & RB0/INT interrupts
	bcf	INTCON,RBIF	; clear uninitialized RBIF flag
	endm

RS232init macro
	BANK1			; Asynchronous USART assignment:
	bsf	TXSTA,BRGH	; BRGH = 1
	movlw	d'25'		; baud rate assignment: 9600 baud
	movwf	SPBRG
	BANK0
	bsf	RCSTA,SPEN	; enable serial port
	BANK1
	bsf	PIE1,RCIE	; enable serial reception interrupt
	bsf	TXSTA,TXEN	; enable serial transmission
	BANK0
	movlw	b'11000000'	; enable gobal and peripheral interrupts
	iorwf	INTCON,F
	bsf	RCSTA,CREN	; enable continuous reception
	endm

SEND	macro	send_char
	movlw	send_char
	call	_RSxmit
	endm

SENDw	macro
	call	_RSxmit
	endm

KBDcmd	macro	_KBDcmd		; this macro transmits the literal _KBDcmd
	movlw	_KBDcmd		;  to the AT keyboard
	movwf	KBD
	call	ODDpar		; calculate odd parity of TX data
	call	KBDcomd		; transmit contents of KBD reg. to keyboard
	endm

KBDcmdw	macro			; this macro transmits the value of w to the
	movwf	KBD		;  AT keyboard
	call	ODDpar		; calculate odd parity of TX data
	call	KBDcomd		; transmit contents of KBD reg. to keyboard
	endm

KBDexp	macro	_KBDresp	; keyboard expect function: busy wait for kbd response
	movlw	_KBDresp	; load expected kbd response
	call	KBDexpt
	endm

;***** SUBROUTINES *****

_RSxmit	BANK1
_RSbusy	btfss	TXSTA,TRMT	; check, if previous transmission
	goto	_RSbusy		; has been terminated
	BANK0
	movwf	TXREG		; send next char
	RETURN

KBDcomd	;*** host to keyboard command transmission ***
	bcf	INTCON,INTE	; disable RB0/INT interrupt
	BANK1			; hold keyboard (with kbd clk low):
	bcf	KBDclktris	; set clk line to output
	bcf	KBDdatatris	; set data line to output
	BANK0
	bcf	KBDclkpin	; set keyboard clk line low
	bcf	KBDdatapin	; set keyboard data line low
	movlw	0x20		; load temporary counter
	movwf	TEMP1
_KBDtx1	decfsz	TEMP1,F		; wait loop: approx. 60 us @ 4 MHz
	goto	_KBDtx1
	clrf	KBDcnt		; init kbd scan pattern acquisition counter
	BANK1
	bsf	KBDclktris	; release keyboard clk line, set to input
	BANK0
	bsf	KBDtxf		; set keyboard TX flag
	bcf	INTCON,INTF	; clear RB0/INT interrupt flag
	bsf	INTCON,INTE	; re-enable RB0/INT interrupt
_KBDtx2	btfsc	KBDtxf		; wait loop: poll for completion
	goto	_KBDtx2		; not yet completed, loop
	RETURN

ODDpar	;*** odd parity = NOT(XOR(bits[0..7])) ***
	movwf	TEMP3		; target, which the parity bit is built from
	movlw	0x08
	movwf	TEMP4		; loop counter
	clrf	TEMP5		; the ones' counter / bit counter
_ODDpar	btfsc	TEMP3,0x00	; check for ones
	incf	TEMP5,F		; increment ones' counter
	rrf	TEMP3,F
	decfsz	TEMP4,F		; decrement loop counter
	goto	_ODDpar
	bcf	PARITY		; clear parity
	btfss	TEMP5,0x00	; check ones' counter for even value
	bsf	PARITY		; if even, set parity bit (= odd parity)
	RETURN

KBDexpt	;*** keyboard expect function: busy wait for kbd response ***
	movwf	KBDexpval	; load expected kbd response to KBDexpval
	bsf	KBDexpf		; set flag
_KBDexp	btfsc	KBDexpf		; wait loop: poll for completion
	goto	_KBDexp		; not yet completed, loop
	RETURN

RSdisp	;*** LCD display routine for received RS232 characters ***
	movfw	LCDpos1		; get LCD position counter
	sublw	LCDwidth - 1	; w = LCDwidth - 1 - w
	bc	_RSdsp1		; branch if res positive or zero
	bcf	LCD_ln		; line flag = 0 (LCD line 1)
	call	LCDclrline	; call LCD clear line subroutine
_RSdsp1	movfw	LCDpos1		; load cursor position to w
	iorlw	b'10000000'	; mask
	call	LCDcomd		; call LCD command subroutine to place cursor
	movfw	RXreg		; check for carriage return
	sublw	0x0D		; w = 0x0D - w
	bnc	_RSdsp2		; no carry if result negative, branch 
	bz	_RScr		; branch on zero: carriage return
_RSbspc	movfw	RXreg		; else, check for backspace
	sublw	0x08		; w = 0x08 - w
	bnz	_RSend		; no backspace, exit
	movfw	LCDpos1		; else, decrement LCD cursor position
	bz	_RSend		; if zero, do nothing & exit
	decf	LCDpos1,F	; decrement cursor position
	movfw	LCDpos1		; load cursor position to w
	iorlw	b'10000000'	; mask
	call	LCDcomd		; call LCD command subroutine 
	LCDchar	' '		; erase with blank character
	goto	_RSend		; exit
_RScr	bcf	LCD_ln		; line flag = 0 (LCD line 1)
	call	LCDclrline	; call LCD clear line subroutine
	goto	_RSend		; exit
_RSdsp2	movfw	RXreg
	LCDw			; display RS232 data on LCD
	incf	LCDpos1,F	; increment LCD position counter
_RSend	bcf	RSflag		; reset RS232 data reception flag
	BANK1
	bsf	PIE1,RCIE	; re-enable USART reception interrupt
	BANK0			;  (interrupt flag already cleared in ISR)
	RETURN

LCDclrline ;*** clears either LCD line 1 or 2 ***
	movlw	LCDwidth	; get LCD character width
	btfsc	LCD_ln		; check LCD line flag
	goto	_clrln2		; if flag is set, clear LCD line 2
_clrln1	movwf	LCDpos1		; store LCD char width in position counter
	LCD_DDAdr 0x00		; move cursor to beginning of first line
_clr1	LCDchar	' '		; put subsequent blanks on LCD to clear line
	decfsz	LCDpos1,F	; decrement counter
	goto	_clr1
	LCD_DDAdr 0x00		; reset cursor to beginning of line
	clrf	LCDpos1		; reset LCD position counter
	RETURN
_clrln2	movwf	LCDpos2		; store LCD char width in position counter
	LCD_DDAdr 0x40		; move cursor to beginning of second line
_clr2	LCDchar	' '		; put subsequent blanks on LCD to clear line
	decfsz	LCDpos2,F	; decrement counter
	goto	_clr2
	LCD_DDAdr 0x40		; reset cursor to beginning of line
	clrf	LCDpos2		; reset LCD position counter
	RETURN


;***** INTERRUPT SERVICE ROUTINE *****

	ORG	0x04		; interrupt vector location

ISR	;************************
	;*** ISR CONTEXT SAVE ***
	;************************

	bcf	INTCON,GIE	; disable all interrupts
	btfsc	INTCON,GIE	; assure interrupts are disabled
	goto	ISR
	movwf	W_TEMP		; context save: W
	swapf	STATUS,W	; context save: STATUS
	movwf	STATUS_TEMP	; context save
	clrf	STATUS		; bank 0, regardless of current bank
	movfw	PCLATH		; context save: PCLATH
	movwf	PCLATH_TEMP	; context save
	clrf	PCLATH		; page zero, regardless of current page
	bcf	STATUS,IRP	; return to bank 0
	movfw	FSR		; context save: FSR
	movwf	FSR_TEMP	; context save
	;*** context save done ***

	;**************************
	;*** ISR MAIN EXECUTION ***
	;**************************

	;*** check origin of interrupt ***
	btfsc	INTCON,INTF	; check RB0/INT interrupt flag
	goto	_ISR_KBD	; if set, it was a keyboard interrupt
	;goto	_ISR_RS232	; else, it was a USART interrupt

	;******************************
	;*** RS232 DATA ACQUISITION ***
	;******************************
_ISR_RS232
	movfw	RCREG		; get RS232 data
	movwf	RXreg
	bsf	RSflag		; enable RS232 data reception flag
	BANK1			;  (for display routine)
	bcf	PIE1,RCIE	; disable USART reception interrupt
	BANK0			;  (will be re-enabled in normal subroutine)
	goto	_RS232end		; exit

_ISR_KBD ;*** check origin of keyboard interrupt ***
	btfss	KBDtxf		; check keyboard TX flag
	goto	_ISR_KBDacq	; if cleared, keyboard data acquisition,
	;goto	_ISR_KBDxmit	; else keyboard data transmission

	;******************************************
	;*** HOST TO KEYBOARD DATA TRANSMISSION ***
	;******************************************
_ISR_KBDxmit
	;*** data transmission ***
	movfw	KBDcnt		; get kbd scan pattern acquisition counter
	sublw	d'7'		; w = d'7' - KBDcnt (*)
	bnc	_KBDparo	; branch if negative (carry == 0)
	btfss	KBD,0x00	; serial transmission of keyboard data
	bcf	KBDdatapin
	btfsc	KBD,0x00
	bsf	KBDdatapin
	rrf	KBD,F		; rotate right keyboard TX data register
	goto	_INCF		; exit

	;*** parity transmission ***
_KBDparo movfw	KBDcnt		; get kbd scan pattern acquisition counter
	sublw	d'8'		; w = d'8' - KBDcnt
	bnc	_KBDrel		; branch if negative (carry == 0)
	btfss	PARITY		; put parity bit on keyboard data line
	bcf	KBDdatapin
	btfsc	PARITY
	bsf	KBDdatapin
	goto	_INCF		; exit

	;*** data and parity transmission completed, turn around cycle ***
_KBDrel	movfw	KBDcnt		; get kbd scan pattern acquisition counter
	sublw	d'9'		; w = d'9' - KBDcnt
	bnc	_KBDack		; branch if negative (carry == 0)
	BANK1
	bsf	KBDdatatris	; release keyboard data line, set to input
	BANK0
	goto	_INCF		; exit

_KBDack	movfw	KBDcnt		; get kbd scan pattern acquisition counter
	sublw	d'11'		; w = d'11' - KBDcnt
	bnc	_INCF		; exit if negative (carry == 0)
	clrf	KBDcnt		; reset kbd scan pattern acquisition counter
	bcf	KBDtxf		; clear keyboard transmission flag
	goto	_KBDend

	;*****************************************
	;*** KEYBOARD SCAN PATTERN ACQUISITION ***
	;*****************************************
_ISR_KBDacq
	;*** check start bit ***
	tstf	KBDcnt		; check
	bnz	_KBDdat		; branch on no zero
	btfsc	KBDdatapin	; test start bit of keyboard data input
	goto	_KBDabort	; no valid start bit, abort
	goto	_INCF		; exit

	;*** keyboard scan pattern acquisition ***
_KBDdat	movfw	KBDcnt		; get kbd scan pattern acquisition counter
	sublw	d'8'		; w = d'8' - KBDcnt (*)
	bnc	_KBDpari	; branch if negative (carry == 0)
	btfss	KBDdatapin	; get keyboard data input
	bcf	KBD,0x07	; (bit operations do not alter zero flag)
	btfsc	KBDdatapin
	bsf	KBD,0x07	
	bz	_INCF		; exit on zero (zero flag still valid from (*))
	rrf	KBD,F		; do this only 7 times
	goto	_INCF		; exit

	;*** ignore parity bit ***
_KBDpari movfw	KBDcnt		; get kbd scan pattern acquisition counter
	sublw	d'9'		; w = d'9' - KBDcnt
	bnc	_KBDstp		; branch if negative (carry == 0)
	goto	_INCF		; exit

	;*** check stop bit ***
_KBDstp	btfss	KBDdatapin	; check if stop bit is valid
	goto	_KBDabort	; if not set, abort
	btfsc	KBDexpf		; check for active expect function flag
	goto	_KBDchk		; if set, goto expect value checking routine
	bsf	KBDflag		; else set reception flag to decode KBD
	;*** stall keyboard ***
	; to prevent the arrival of more data before having finished decoding
	BANK1			; hold keyboard (with kbd clk low):
	bcf	KBDclktris	; set clk line to output
	BANK0
	bcf	KBDclkpin	; set keyboard clk line low (stall)
	;*** disable RB0/INT interrupt line ***
	bcf	INTCON,INTE	; disable RB0/INT interrupt
	goto	_KBDterm	; terminate successfully
_KBDchk	movfw	KBDexpval
	subwf	KBD,W		; w = KBD - w
	bnz	_KBDabort	; check zero flag, branch should never occur
	bcf	KBDexpf		; clear flag
	clrf	KBDcnt		; reset kbd scan pattern acquisition counter
	goto	_KBDend		; exit ISR successfully

_KBDabort clrf	KBD		; abort / invalid data
_KBDterm clrf	KBDcnt		; reset kbd scan pattern acquisition counter
	goto	_KBDend		; terminate execution of keyboard ISR

	;***********************************
	;*** CLEARING OF INTERRUPT FLAGS ***
	;***********************************
	; NOTE: Below, I only clear the interrupt flags! This does not
	; necessarily mean, that the interrupts are already re-enabled.
	; Basically, interrupt re-enabling is carried out at the end of
	; the corresponding service routine in normal operation mode.
	; The flag responsible for the current ISR call has to be cleared
	; to prevent recursive ISR calls. Other interrupt flags, activated
	; during execution of this ISR, will immediately be served upon
	; termination of the current ISR run.
_RS232end
	bcf	PIR1,RCIF	; clear USART RX interrupt flag
	goto	ISRend		; terminate execution of ISR

_INCF	incf	KBDcnt,F	; increment acquisition counter
_KBDend	bcf	INTCON,INTF	; clear RB0/INT interrupt flag
	;goto	ISRend		; terminate execution of ISR

	;*****************************************
	;*** ISR TERMINATION (CONTEXT RESTORE) ***
	;*****************************************

ISRend	movfw	FSR_TEMP	; context restore
	movwf	FSR		; context restore
	movfw	PCLATH_TEMP	; context restore
	movwf	PCLATH		; context restore
	swapf	STATUS_TEMP,W	; context restore
	movwf	STATUS		; context restore
	swapf	W_TEMP,F	; context restore
	swapf	W_TEMP,W	; context restore
	RETFIE			; enable global interrupt (INTCON,GIE)

;***** END OF INTERRUPT SERVICE ROUTINE *****


;***** KEYBOARD SCAN PATTERN DECODING SUBROUTINE *****

KBDdecode
	;**********************************************************
	;*** KEYBOARD SCAN CODE PRE-DECODING, SET / CLEAR FLAGS ***
	;**********************************************************

	;*** check key release scan code (F0) ***
	movfw	KBD		; get scan code
	movwf	KBDcopy		; make backup of scan code for later use
	sublw	0xF0		; check if FO has been sent:
	bnz	_KBD_1		; branch if no 'release' scan code occured
	bsf	RELflag		; set key release flag if 'release' occured
	bcf	SPEflag		; clear special code flag always on release
	goto	_ClrStall	; abort with nothing to display
_KBD_1	btfss	RELflag		; check release flag, exit if cleared:
	goto	_KBD_2		; release flag has not been set, branch
	;*** release flag has been set / key release is in progress: ***
	bcf	RELflag		; clear key release flag
	;*** if release of SHIFT key, clear shift flag: ***
	movfw	KBD		; check left shift button (0x12):
	sublw	0x12		; subtract, check if zero
	bz	_clrSHI		; if zero, branch
	movfw	KBD		; check right shift button (0x59):
	sublw	0x59		; subtract, check if zero
	skpnz			; skip on non zero
_clrSHI	bcf	SHIflag		; clear shift flag
	;*** check for CAPS LOCK activity: ***
	movfw	KBD		; check caps lock key release:
	sublw	0x58		; subtract, check if zero
	bnz	_clrALT		; if not zero, branch
	btfss	CAPflag		; check flag, clear flag if set:
	goto	_setCAP		; flag has not been set, branch
	bcf	CAPflag		; clear caps lock flag
	;*** switch keyboard's caps lock LED off ***
	KBDcmd	0xED		; keyboard LEDs' control command
	KBDexp	0xFA		; expect keyboard acknowledge (FA)
	bcf	KBDleds,CL	; clear caps lock bit
	movfw	KBDleds		; load keyboard LEDs' status
	KBDcmdw			; send keyboard LEDs' control data
	KBDexp	0xFA		; expect keyboard acknowledge (FA)
	goto	_ClrStall	; abort with nothing to display
_setCAP	bsf	CAPflag		; set caps lock flag
	;*** switch keyboard's caps lock LED on ***
	KBDcmd	0xED		; keyboard LEDs' control command
	KBDexp	0xFA		; expect keyboard acknowledge (FA)
	bsf	KBDleds,CL	; set caps lock bit
	movfw	KBDleds		; load keyboard LEDs' status
	KBDcmdw			; send keyboard LEDs' control data
	KBDexp	0xFA		; expect keyboard acknowledge (FA)
	goto	_ClrStall	; abort with nothing to display
	;*** check for ALT activity: ***
_clrALT	movfw	KBD		; check ALT key release:
	sublw	0x11		; subtract, check if zero
	bnz	_clrCTRL	; if not zero, branch (to next check)
	bcf	ALTflag		; clear flag
	goto	_ALTdec		; goto ALT-DEC-Entry conversion/display routine
	; /not implemented, enhancement/
	;*** check for CTRL activity: ***
_clrCTRL movfw	KBD		; check CTRL key release:
	sublw	0x14		; subtract, check if zero
	bnz	_ClrStall	; if not zero, branch / exit
	bcf	CTRLflag	; clear flag
	goto	_CTRLhex	; goto CTRL-HEX-Entry conversion/display routine
	; /not implemented, enhancement/


	;****************************************************
	;* The following table has to be located within one *
	;* page to allow for correct lookup functionality.  *
	;* Therefore, additional ISR code has been moved    *
	;* further down.                                    *
	;****************************************************

	;*********************************************************************
	;* LOOKUP TABLE FOR KEYBOARD-SCAN-CODE TO ASCII-CHARACTER CONVERSION *
	;*********************************************************************

	ORG	0x270			; if necessary, move table

	#include "..\tables\eng_main.asm"  	; English 'codepage'
	;#include "..\tables\ger_main.asm"  	; modified Swiss-German 'codepage'

	;****************************************************
	;* The following code belongs also to the interrupt *
	;* service routine and has been moved down to this  *
	;* place to allow the main keyboard decode lookup   *
	;* table to be located within one page.             *
	;* The code below may be arranged on another page,  *
	;* but that doesn't matter.                         *
	;****************************************************

	;********************************
	;*** SCAN CODE RANGE CHECKING ***
	;********************************

_KBD_2	;*** check if special code (0xE0) has been submitted previously ***
	btfss	SPEflag
	goto	_KBD_3
	;*** decoding of scan code with preceeding special code (0xE0) ***
	; (decoding currently only necessary for 'E0 4A' = '/')
	movfw	KBD
	sublw	0x4A		; 0x4A - w
	bnz	_NOSUP		; branch on non-zero
	movlw	'/'		; store '/' in KBD
	movwf	KBD
	goto	_OUTP
_NOSUP	;*** check if scan code 0x5A or smaller has occurred ***
	movfw	KBD
	sublw	0x5A		; 0x5A - w
	bc	_KBD_3		; carry if result positive or zero, branch
	;*** range exceeded (above 0x5A) ***
	; it's one of the following keys: arrow button, 'Home', 'Del',
	; 'PageUp', 'PageDown', 'Insert', 'End'
	; these keys are currently not used, so
	goto	_ClrStall
_KBD_3	;*** check if scan code 0x61 or smaller has occurred ***
	movfw	KBD
	sublw	0x61		; 0x61 - w
	bc	KBD_dec		; carry if result positive or zero, goto table
	movlw	d'14'
	subwf	KBD,F		; KBD = KBD - d'14'
	;*** check if scan code 0x61 (0x6F-d'14') or smaller has occurred ***
	movfw	KBD
	sublw	0x61		; 0x61 - w
	bnc	_KBD_4		; no carry if result negative, goto _KBD_4
	movlw	d'25'
	addwf	KBD,F		; KBD = KBD + d'25'
	goto	KBD_dec
_KBD_4	;*** check if scan code 0x78 (0x86 - d'14') or higher has occurred ***
	movfw	KBD
	sublw	0x77		; 0x77 - w
	bc	KBD_dec		; carry if result zero or positive, branch
	;*** no character to display: ***
	;*** check for special code (0xE0): 0xD2 = 0xE0 - d'14' ***
	movfw	KBD
	sublw	0xD2		; 0xD2 - w
	skpnz			; skip if not zero
	bsf	SPEflag		; special code occurred, set flag
	goto _ClrStall		; abort with nothing to display

	;*******************************************************
	;*** SCAN CODE DECODING & ASCII CHARACTER CONVERSION ***
	;*******************************************************

	;*** DECODE SCAN CODE ***
KBD_dec	movlw	HIGH KBDtable	; get correct page for PCLATH
	movwf	PCLATH		; prepare right page bits for table read
	movfw	KBD
	call	KBDtable	; GET CORRESPONDING KEYBOARD CHAR IN LOOKUP TABLE
	movwf	KBD		; save result to KBD
	tstf	KBD		; test KBD to get the zero flag
	bz	_ClrStall	; abort if KBD is zero / invalid entry, nothing to display

	;*** check for ALT-DEC-Entry ***
	; /not implemented, enhancement/
	;btfsc	ALTflag		; check flag
	;goto	_ALTstr		; jump if set

	;*** check for CTRL-HEX-Entry ***
	; /not implemented, enhancement/
	;btfsc	CTRLflag	; check flag
	;goto	_CTRLstr	; jump if set

	;*** convert only LETTERS to capital letters: ***
	; a letter in KBD value has to be in range from 0x61 to 0x7A
	movfw	KBD
	sublw	0x60		; 0x60 - w
	bc	_SHICHR		; carry if result greater or equal zero = no letter, exit
	movfw	KBD
	sublw	0x7A		; 0x7A - w
	bnc	_SHICHR		; no carry if result negative = no letter, exit
	;*** there is now a letter in KBD, check conversion to capital letter: ***
	movfw	KBD
	btfsc	CAPflag		; check caps lock flag
	goto	_SHIset		; flag has been set
	btfss	SHIflag		; check shift flag
	goto	_OUTP		; no flag, exit
	goto	_cnvCAP		; flag has been set, convert to capital letter
_SHIset	btfsc	SHIflag		; check shift flag
	goto	_OUTP		; flag has been set, exit
_cnvCAP	addlw	d'224'		; convert to capital letter (+ d'224')
	movwf	KBD
	;goto	_OUTP		; (uncomment in case _OUTP will be moved)

	;***************************************************
	;*** KEYBOARD DATA OUTPUT TO RS232 & LCD DISPLAY ***
	;***************************************************

_OUTP	;*** RS232 ***
	movfw	KBD
	SENDw			; send actual pressed keyboard character
	;*** LCD: treat "Backspace" as special case ***
	movfw	KBD		; check for backspace (d'8')
	sublw	d'8'		; d'8' - w
	bnz	_chkLn		; if not zero, branch
	;*** it is now a backspace ***
	movfw	LCDpos2		; load actual LCD cursor position
	bz	_ClrStall	; if zero, do nothing & exit
	decf	LCDpos2,F	; decrement LCD cursor position
	movfw	LCDpos2		; load cursor position to w
	addlw	0x40		; add offset (LCD line 2)
	iorlw	b'10000000'	; mask
	movwf	TEMP6		; store LCD DDRAM address pattern
	call	LCDcomd		; call LCD command subroutine 
	LCDchar	' '		; overwrite displayed character with blank
	movfw	TEMP6		; read back LCD DDRAM address pattern
	call	LCDcomd		; call LCD command subroutine
	goto	_ClrStall	; exit
	;*** check for necessary clearing of LCD line ***
_chkLn	movfw	LCDpos2		; get LCD position counter
	sublw	LCDwidth - 1	; w = LCDwidth - 1 - w
	bc	_LCDout		; branch if res positive or zero
	bsf	LCD_ln		; line flag = 1 (LCD line 2)
	call	LCDclrline	; call LCD clear line subroutine
_LCDout	movfw	LCDpos2		; load cursor position to w
	addlw	0x40		; add offset (LCD line 2)
	iorlw	b'10000000'	; mask
	call	LCDcomd		; call LCD command subroutine to place cursor
	movfw	KBD
	LCDw			; display keyboard character on LCD
	incf	LCDpos2,F	; increment LCD position counter
	goto _ClrStall		; (uncomment in case _ClrStall will be moved)

	;************************************************
	;*** SPECIAL COMMANDS I (with special output) ***
	;************************************************

_CRLF	bsf	LCD_ln		; line flag = 1 (LCD line 2)
	call	LCDclrline	; call LCD clear line subroutine
	SEND	CR		; on "Enter", send CR and LF to RS232
	SEND	LF
	RETLW	0		; clear w to obtain invalid entry

	;**********************************************************
	;*** STALL RELEASE & CLEAR KEYBOARD DATA RECEPTION FLAG ***
	;**********************************************************
_ClrStall 
	BANK1
	bsf	KBDclktris	; set clk line back to input (and goes high)
	BANK0			;	(release stall)
	bcf	KBDflag		; clear keyboard data reception flag
	bsf	INTCON,INTE	; re-enable interrupt RB0/INT
	RETURN

	;****************************************************
	;*** SPECIAL COMMANDS II (without special output) ***
	;****************************************************

_SHIFT	bsf	SHIflag		; set shift flag
	RETLW	0		; clear w to obtain invalid entry

_ALT	bsf	ALTflag		; set ALT flag
	RETLW	0		; clear w to obtain invalid entry

_CTRL	bsf	CTRLflag	; set CTRL flag
	RETLW	0		; clear w to obtain invalid entry

	;***********************************************
	;*** ALT-DEC & CTRL-HEX STORING & CONVERSION ***
	;***********************************************
	; store typed numbers in CTRLreg1 - CTRLreg3
_CTRLstr ; /not implemented, enhancement/
_ALTstr	; /not implemented, enhancement/

_ALTdec	; PRE: ALT + [1..3] numbers (e.g. ALT + 6 + 4 = @) in CTRLreg1 - 3
	; POST: convert ALT-DEC-Entry after release of ALT key, return
	;       ascii value converted from numbers
	; /not implemented, enhancement/

_CTRLhex ; PRE: CTRL + [1..2] letters/numbers (e.g. CTRL + 3 + F = ?)
	;       in CTRLreg1 - 2
	; POST: convert ALT-DEC-Entry after release of ALT key, return
	;       ascii value as concatenated hex value from numbers
	; /not implemented, enhancement/

	; catch all handler for non-implemented features:
	goto	_ClrStall	; abort & exit (nothing to display/send)

	;*****************************************************************
	;*** SCAN CODE DECODING & ASCII CONVERSION FOR 'SHIFT' ENTRIES ***
	;*****************************************************************

_SHICHR	;*** special character decoding typed with shift button active ***
	; check for active shift button, if not active, branch
	btfss	SHIflag
	goto	_OUTP		; branch
	; check for 'backspace', 'tab', 'linefeed' and 'carriage return' :
	; (here, KBD has already been converted to ASCII character values)
	movfw	KBD
	sublw	d'13'		; d'13' - w
	bc	_OUTP		; carry if result zero or positive, branch

	;*** range check: abort if KBDcopy greater than 0x61 ***
	; (KBDcopy has the value of the original keyboard scan code)
	movfw	KBDcopy
	sublw	0x61		; 0x61 - w
	bnc	_OUTP		; no carry if result negative, branch
	;*** check if KBDcopy greater than 0x3C ***
	movfw	KBDcopy
	sublw	0x3C		; 0x3C - w
	bc	_SHICH1		; carry if result zero or positive, branch
	movlw	d'61'
	subwf	KBDcopy,F	; KBDcopy = KBDcopy - d'61'
	goto	_SHICH3
	;*** check if KBDcopy greater than 0x24 ***
_SHICH1	movfw	KBDcopy
	sublw	0x24		; 0x24 - w
	bc	_SHICH2		; carry if result zero or positive, branch
	movlw	d'35'
	subwf	KBDcopy,F	; KBDcopy = KBDcopy - d'35'
	goto	_SHICH3
	;*** else ***
_SHICH2	movlw	d'4'
	addwf	KBDcopy,F	; KBDcopy = KBDcopy + d'4'

_SHICH3	movlw	HIGH KBDSHIFTtable ; get correct page for PCLATH
	movwf	PCLATH		; prepare right page bits for table read
	movfw	KBDcopy
	call	KBDSHIFTtable	; GET CORRESPONDING KEYBOARD CHAR IN LOOKUP TABLE
	movwf	KBD		; save result to KBD
	goto	_OUTP

	;*******************************************************
	;* The following table has also to be located within   *
	;* one page to allow for correct lookup functionality. *
	;*******************************************************

	;**********************************************************************
	;* LOOKUP TABLE FOR SPECIAL CHARACTERS TYPED WITH SHIFT BUTTON ACTIVE *
	;**********************************************************************

	;ORG	0x??			; if necessary, move table

	#include "..\tables\eng_shif.asm"  	; English 'codepage'
	;#include "..\tables\ger_shif.asm"  	; modified Swiss-German 'codepage'

;***** END OF SCAN PATTERN DECODING SUBROUTINE *****


;************** MAIN **************

MAIN	ORG	0x00

	BANK1
	clrf	OPTION_REG	; INTEDG bit cleared => INTB on falling edge
	goto	_MAIN

	ORG	0x1A0

_MAIN	bsf	KBDclktris	; set keyboard clock line as input explicitely
	bsf	KBDdatatris	; set keyboard data line as input explicitely
	;*** configure port A to digital inputs !!! ***
	; Note: I have spent approx. 25 hours on debugging the keyboard
	; interface in conjunction with the PIC 16C74A, because the
	; port A inputs are set to analog inputs by default !!!
	movlw	b'00000111'
	movwf	ADCON1
	BANK0
	movlw	b'11111000'
	andwf	INTCON,F	; clear all interrupt flags

	;*** RS232 INITIALIZATION ***
	RS232init		; RS232 initialization

	;*** AT KEYBOARD INITIALIZATION ***
	KEYBOARDinit		; Keyboard initialization
	movlw	b'00000010'
	movwf	KBDleds		; init keyboard LEDs' status register
	clrf	KBDcnt		; clear IRQ based scan pattern counter
	clrf	FLAGreg		; clear all flags (keyboard & others)
	clrf	FLAGreg2

	;*** LCD INITIALIZATION ***
	LCDinit			; LCD display initialization
	movlw	LCDwidth
	movwf	LCDpos1		; init LCD output position counters
	clrf	LCDpos2

	;*** define amount of table items for startup message ***
	#define	tab_items d'40'
	movlw	tab_items	; store amount of table items in counter
	movwf	TEMP6

	;*** transmit startup message ***
_ILOOP	movlw	HIGH WelcomeTable ; get correct page for PCLATH
	movwf	PCLATH		; prepare right page bits for table read
	movfw	TEMP6		; get actual count-down value
	sublw	tab_items	; table offset: w = tab_items - TEMP3
	call	WelcomeTable	; call lookup table
	movwf	TEMP7		; create backup of fetched item
	SENDw			; RS232 output
	movfw	TEMP7
	LCDw			; LCD output
	decfsz	TEMP6,F		; decrement counter
	goto	_ILOOP
	SEND	CR		; carriage return
	SEND	LF		; line feed
	SEND	LF

	;*** reset keyboard ***
	KBDcmd	0xFF		; reset keyboard
	KBDexp	0xFA		; expect keyboard acknowledge (FA)

	;*** switch keyboard LEDs on (default status) ***
	KBDcmd	0xED		; keyboard LEDs' control command
	KBDexp	0xFA		; expect keyboard acknowledge (FA)
	movfw	KBDleds		; load keyboard LEDs' status
	KBDcmdw			; send keyboard LEDs' control data
	KBDexp	0xFA		; expect keyboard acknowledge (FA)

	;*** switch scroll lock LED on (example) ***
	KBDcmd	0xED		; keyboard LEDs' control command
	KBDexp	0xFA		; expect keyboard acknowledge (FA)
	bsf	KBDleds,SL	; set scroll lock bit
	movfw	KBDleds		; load keyboard LEDs' status
	KBDcmdw			; send keyboard LEDs' control data
	KBDexp	0xFA		; expect keyboard acknowledge (FA)

	;******************************
_MLOOP	btfsc	KBDflag		; check scan pattern reception flag
	call	KBDdecode	; if set, call decoding routine
	btfsc	RSflag		; check RS232 data reception flag
	call	RSdisp		; if set, call display routine
	goto	_MLOOP
	;******************************

	;ORG	0x??		; if necessary, move table

WelcomeTable
	addwf	PCL,F		; add offset to table base pointer
	DT	"PIC 16C74A AT Keyboard Decoder connecte" ; create table
WTableEND DT "d"

	IF (high (WelcomeTable) != high (WTableEND))
		ERROR "WelcomeTable hits page boundary!"
	ENDIF

	END
