;***************************************************************************
;                                                                     
;	AT Keyboard Interface V3.05  (with LCD Display)
;	===============================================
;
;	written by Peter Luethi, 04.01.2001, Dietikon, Switzerland
;	http://www.electronic-engineering.ch
;	last update: 17.04.2004
;
;	V3.05:	Added LCDcflag (LCD command/data flag) to comply with
;		latest LCD modules. Changed controller type to flash
;		device, i.e. PIC16F77.
;		(17.04.2004)
;
;	V3.04:	Fixed issue in RS232 hardware reception service routine.
;		Reads now both data bytes out of double-buffered RX FIFO.
;		Tries to eliminate some sporadic reception hangs under
;		heavy full-duplex traffic scenarios.
;		In case of FIFO overrun errors in the USART receive logic,
;		the service routine performs a partial reset of the USART
;		receive logic. No specific error handling for RS232
;		reception framing errors.
;		(17.10.2003)
;
;	V3.03:	Improved AT keyboard and RS232 initialization,
;		fixed RBIF/INTF interrupt initialization issue.
;		Changed keyboard data pin to PORTA,4 (open-collector).
;		Fixed ALT-DEC and CTRL-HEX issue on right side keys.
;		Added special LCD treatment for 'tabulator' key.
;		(14.08.2003)
;
;	V3.02:	Implemented support for ASCII conversion from direct ALT-DEC
;		and CTRL-HEX entries. Accepts both keypad and keyboard
;		numbers, as well as upper and lower case letters [a..f].
;		(03.01.2002)
;
;	V3.01:	Made forward compatible (yes, this is feasible) by
;		implementing/completing ALT and CTRL flags. Added
;		labels to support non-implemented ALT and CTRL
;		enhancements. (02.01.2002)
;
;	V3.00:	Initial release (04.01.2001)
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
;	Serial Output:			9600 baud, 8 bit, no parity, 1 stopbit
;	Keyboard Routine Features:	Capability of bi-directional
;					communication between controller
;					and keyboard (keys & LEDs)
;	Acquisition Methodology:	Preemptive, interrupt-based
;					keyboard scan pattern acquisition
;					routine, with decoding to ASCII
;					characters during normal operation
;					(incl. LCD display and RS232 activities)
;	Code Size of entire Program:	1039 instruction words
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
;	Developed and tested on Microchip PIC 16F77, previously on PIC 16C74A.
;
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
;	KBDdatapin (PORTA,4). The configuration of the KBDclkpin interrupt
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
;	- Support of ASCII conversion from direct ALT-DEC entries, e.g.
;	  ALT + 6 + 4 = @   (ALT + [1..3] numbers)
;	- Support of ASCII conversion from direct CTRL-HEX entries, e.g.
;	  CTRL + 3 + F = ?  (CTRL + [1..2] letters/numbers)
;	- ALT-DEC and CTRL-HEX features work for both, keypad and keyboard
;	  numbers, as well as with upper and lower case letters [a..f]
;
;	- Possibility to implement short-cuts or user defined characters
;	  for 'Esc', 'Num Lock', 'Scroll Lock' and 'F1' - 'F12' keys
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
	__CONFIG   _CP_OFF & _WDT_OFF & _PWRTE_ON & _HS_OSC & _BODEN_ON

;***** MEMORY STRUCTURE *****

	;ORG     0x00	processor reset vector, declared below
	;ORG     0x04	interrupt service routine, declared below

;***** PORT DECLARATION *****

	#define	KBDdatapin PORTA,0x04	; keyboard data input port
	#define	KBDdatatris TRISA,0x04	; (open-collector pin)
	#define	KBDclkpin PORTB,0x00	; keyboard clock input port (IntB)
	#define	KBDclktris  TRISB,0x00  ; @ INTF interrupt source (RB0)

	LCDport	equ	PORTB
	LCDtris	equ	TRISB
	#define	LCDwidth d'40'		; define character width of LCD
					; display
;***** CONSTANT DECLARATION *****

	CONSTANT BASE = 0x20	; base address of user file registers
	CONSTANT LF =	d'10'	; line feed
	CONSTANT CR =	d'13'	; carriage return
	CONSTANT TAB =	d'9'	; tabulator
	CONSTANT BS =	d'8'	; backspace
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
	#define RX2flag	FLAGreg2,0x06	; two RS232 bytes received

	RXreg	equ	BASE+d'10'	; first RS232 RX-Data register
	RXreg2	equ	BASE+d'11'	; second RS232 RX-Data register
	RXtemp	equ	BASE+d'12'	; intermediate data register for LCD output

	W_TEMP	equ	BASE+d'13'	; context register (ISR)
	STATUS_TEMP equ	BASE+d'14'	; context register (ISR)
	PCLATH_TEMP equ	BASE+d'15'	; context register (ISR)
	FSR_TEMP equ	BASE+d'16'	; context register (ISR)

	KBDcnt	equ	BASE+d'18'	; IRQ based keyboard scan pattern counter
	KBD	equ	BASE+d'19'	; keyboard scan code & ascii data register
	KBDcopy	equ	BASE+d'20'	; keyboard scan code register
	KBDleds	equ	BASE+d'21'	; keyboard LEDs' status register
	KBDexpval set	BASE+d'3'	; temporary KBD expected response value
	LCDpos1	equ	BASE+d'22'	; LCD output position counter
	LCDpos2	equ	BASE+d'23'	; LCD output position counter

	CTRLcnt	 equ	BASE+d'24'	; counter for CTRL/ALT stuff
	CTRLreg1 equ	BASE+d'25'	; storage registers for ALT-DEC and
	CTRLreg2 equ	BASE+d'26'	; CTRL-HEX conversion routines
	CTRLreg3 equ	BASE+d'27'

;***** INCLUDE FILES *****

	ORG	0x100
	#include "..\..\m_bank.asm"
	#include "..\..\m_wait.asm"
	#include "..\..\m_lcd_bf.asm"

;***** MACROS *****

KEYBOARDinit macro
	BANK1
	bsf	KBDclktris	; set keyboard clock line to input explicitely
	bsf	KBDdatatris	; set keyboard data line to input explicitely
	bcf	OPTION_REG,INTEDG ; keyboard interrupt on falling edge
	BANK0
	bsf	INTCON,INTE	; enable RB0/INT interrupts
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
	bsf	INTCON,PEIE	; enable peripheral interrupts
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

RSdisplay ;*** LCD display routine for received RS232 characters ***
	; first byte in RXreg
	movfw	RXreg		; retrieve data
	movwf	RXtemp		; store data
	call	_RSdisp		; call output subroutine
	btfss	RX2flag		; check for second data byte received
	goto	RSdispEND
	; second byte in RXreg2, i.e. RX2flag = 1
	movfw	RXreg2		; retrieve data
	movwf	RXtemp		; store data
	call	_RSdisp		; call output subroutine
	bcf	RX2flag		; reset flag
	btfss	RCSTA,OERR	; check for RX overrun (overrun error bit)
	goto	RSdispEND
	; buffer overrun, severe error, reset USART RX logic
	bcf	RCSTA,CREN	; reset USART RX logic, clear RCSTA,OERR
	bcf	RCSTA,FERR	; reset framing error bit
	bsf	RCSTA,CREN	; re-enable continuous reception
RSdispEND
	BANK1
	bsf	PIE1,RCIE	; re-enable USART reception interrupt
	BANK0			;  (interrupt flag already cleared in ISR)
	RETURN

_RSdisp	; output subroutine for serial data received
	movfw	RXtemp		; check first for backspace
	BNEQ	0x08, _RSclr	; no backspace, branch to next check
	movfw	LCDpos1		; else, decrement LCD cursor position
	bz	_RSend		; if zero, do nothing & exit
	decf	LCDpos1,F	; decrement cursor position
	movfw	LCDpos1		; load cursor position to w
	iorlw	b'10000000'	; mask
	call	LCDcomd		; call LCD command subroutine 
	LCDchar	' '		; erase with blank character
	goto	_RSend		; exit
_RSclr	movfw	LCDpos1		; check now for line end: get LCD position counter
	BRS	LCDwidth, _RSdsp1 ; if not at the line end, branch to next check
	bcf	LCD_ln		; line flag = 0 (LCD line 1)
	call	LCDclrline	; call LCD clear line subroutine
_RSdsp1	movfw	LCDpos1		; load cursor position to w
	iorlw	b'10000000'	; mask
	call	LCDcomd		; call LCD command subroutine to place cursor
	movfw	RXtemp		; check for carriage return
	BRG	0x0D, _RSdsp2	; branch on w > 0x0D
	skpz			; skip on zero: it was a carriage return
	goto	_RSend		; else terminate
_RScr	bcf	LCD_ln		; line flag = 0 (LCD line 1)
	call	LCDclrline	; call LCD clear line subroutine
	goto	_RSend		; exit
_RSdsp2	movfw	RXtemp
	LCDw			; display RS232 data on LCD
	incf	LCDpos1,F	; increment LCD position counter
_RSend	bcf	RSflag		; reset RS232 data reception flag
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
	btfsc	INTCON,INTF	; check for RB0/INT interrupt
	goto	_ISR_KBD	; if set, there was an AT keyboard interrupt

	btfsc	PIR1,RCIF	; check for USART interrupt
	goto	_ISR_RS232	; if set, there was an USART interrupt
	goto	ISRend		; unexpected IRQ, terminate execution of ISR

	;******************************
	;*** RS232 DATA ACQUISITION ***
	;******************************
_ISR_RS232
	movfw	RCREG		; get RS232 data (first RX FIFO entry)
	movwf	RXreg		; store first data byte
	btfss	PIR1,RCIF	; check flag for second RX FIFO entry
	goto	_ISR_RS232_A	; no second byte received, branch
	movfw	RCREG		; get RS232 data (second RX FIFO entry)
	movwf	RXreg2		; store second data byte
	bsf	RX2flag		; set flag to indicate second byte received
_ISR_RS232_A
	bsf	RSflag		; enable RS232 data reception flag
	BANK1			;  (for display routine)
	bcf	PIE1,RCIE	; disable USART reception interrupt
	BANK0			;  (will be re-enabled in normal subroutine)
	goto	_RS232end	; exit ISR

	;****************************
	;*** AT KEYBOARD DECODING ***
	;****************************
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
_INCF	incf	KBDcnt,F	; increment acquisition counter
_KBDend	bcf	INTCON,INTF	; clear RB0/INT interrupt flag
	;goto	ISRend		; terminate execution of ISR

_RS232end
	;bcf	PIR1,RCIF	; cleared by hardware: USART RX interrupt flag
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
	bz	_clrSHI		; if zero, branch (to next check)
	movfw	KBD		; check right shift button (0x59):
	sublw	0x59		; subtract, check if zero
	skpnz			; skip on non zero
_clrSHI	bcf	SHIflag		; clear shift flag
	;*** check for CAPS LOCK activity: ***
	movfw	KBD		; check caps lock key release:
	sublw	0x58		; subtract, check if zero
	bnz	_clrALT		; if not zero, branch (to next check)
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
	;*** check for CTRL activity: ***
_clrCTRL movfw	KBD		; check CTRL key release:
	sublw	0x14		; subtract, check if zero
	bnz	_ClrStall	; if not zero, branch / exit
	bcf	CTRLflag	; clear flag
	goto	_CTRLhex	; goto CTRL-HEX-Entry conversion/display routine


	;****************************************************
	;* The following table has to be located within one *
	;* page to allow for correct lookup functionality.  *
	;* Therefore, additional ISR code has been moved    *
	;* further down.                                    *
	;****************************************************

	;*********************************************************************
	;* LOOKUP TABLE FOR KEYBOARD-SCAN-CODE TO ASCII-CHARACTER CONVERSION *
	;*********************************************************************

	ORG	0x230			; if necessary, move table

	;#include "..\tables\eng_main.asm"  	; English 'codepage'
	#include "..\tables\ger_main.asm"  	; modified Swiss-German 'codepage'

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
	;*** decoding of scan code with preceding special code (0xE0) ***
	; check for ALT-DEC or CTRL-HEX activity
	btfsc	ALTflag
	goto	_KBD_3
	btfsc	CTRLflag
	goto	_KBD_3
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
	goto	_ClrStall	; abort with nothing to display

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
	btfsc	ALTflag		; check flag
	goto	_ALTstr		; jump if set

	;*** check for CTRL-HEX-Entry ***
	btfsc	CTRLflag	; check flag
	goto	_CTRLstr	; jump if set

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
	;*** LCD: treat 'backspace' as special case ***
	movfw	KBD		; check for backspace (d'8')
	BNEQ	d'8', _TAB	; branch if KBD != 8
	;*** it is now a 'backspace' ***
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
_TAB	;*** LCD: treat 'tabulator' as special case ***
	movfw	KBD		; check for tabulator (d'9')
	BNEQ	d'9', _chkLn	; branch if KBD != 9
	;*** it is now a 'tabulator', just add one extra space ***
	movfw	LCDpos2		; get LCD position counter
	BREG	LCDwidth-0x1, _TAB2 ; check for 'near EOL'
	LCDchar	' '		; add extra space, if not near EOL
	incf	LCDpos2,F	; and increment LCD position counter
_TAB2	movlw	a' '
	movwf	KBD		; store second space in KBD
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
	goto _ClrStall		; exit

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
	goto	_alt_2
_CTRL	bsf	CTRLflag	; set CTRL flag
_alt_2	clrf	CTRLcnt		; clear counter for CTRL/ALT conversion stuff
	clrf	CTRLreg1	; clear storage registers for CTRL-HEX
	clrf	CTRLreg2	; and ALT-DEC conversion routines
	clrf	CTRLreg3
	RETLW	0		; clear w to obtain invalid entry

	;***********************************************
	;*** ALT-DEC & CTRL-HEX STORING & CONVERSION ***
	;***********************************************
	; store typed numbers in CTRLreg1 - CTRLreg3
_CTRLstr ; check for capital letter [A..F], i.e. KBD in [0x41..0x46]
	movfw	KBD
	sublw	0x40		; 0x40 - w
	bc	_ALTstr		; carry if result >= 0, go to number check
	movfw	KBD
	sublw	0x46		; 0x46 - w
	bnc	_CTRLstr2	; no carry if result negative, go to next check
	; valid capital letter [A..F], convert to lower case (+ 0x20)
	bsf	KBD,0x5		; KBD += 0x20
 	goto	_CTRLstr3	; jump for storing
_CTRLstr2 ; check for lower case letter [a..f], i.e. KBD in [0x61..0x66]
	movfw	KBD
	sublw	0x60		; 0x60 - w
	bc	_ALTstr		; carry if result >= 0, go to number check
	movfw	KBD
	sublw	0x66		; 0x66 - w
	bc	_CTRLstr3	; carry if result >= 0, valid lower case letter [a..f]
_ALTstr	;*** check for number, i.e. KBD in [0x30..0x39]: ***
	movfw	KBD
	sublw	0x29		; 0x29 - w
	bc	_ClrStall	; carry if result >= 0, no number, exit
	movfw	KBD
	sublw	0x39		; 0x39 - w
	bnc	_ClrStall	; no carry if result negative, no number, exit
_CTRLstr3 ;*** store letter/number now ***
	tstf	CTRLcnt
	bnz	_cnt_1		; branch if not zero
	incf	CTRLcnt,F	; increment counter (0->1)
	movfw	KBD
	movwf	CTRLreg1	; store first number
	goto	_ClrStall	; abort & exit
_cnt_1	decfsz	CTRLcnt,W	; decrement counter, don't store
	goto	_cnt_2		; counter > 1
	incf	CTRLcnt,F	; increment counter (1->2)
	movfw	KBD
	movwf	CTRLreg2	; store second number
	goto	_ClrStall	; abort & exit
_cnt_2	movfw	CTRLcnt
	sublw	0x02		; 0x02 - w
	bnz	_ClrStall	; if result not zero: overflow, abort & exit
	incf	CTRLcnt,F	; increment counter (2->3)
	movfw	KBD
	movwf	CTRLreg3	; store third number
	goto	_ClrStall	; abort & exit

_ALTdec	; PRE: ALT + [1..3] numbers (e.g. ALT + 6 + 4 = @) in CTRLreg1 - 3
	; POST: convert ALT-DEC-Entry after release of ALT key, return
	;       ascii value converted from numbers
	tstf	CTRLcnt		; check, if counter has been incremented
	bz	_ClrStall	; if not, abort & exit
	movlw	0x30
	subwf	CTRLreg1,F	; CTRLreg1 = CTRLreg1 - 0x30
	subwf	CTRLreg2,F	; CTRLreg2 = CTRLreg2 - 0x30
	subwf	CTRLreg3,F	; CTRLreg3 = CTRLreg3 - 0x30
	;*** check if counter == 1 ***
	decf	CTRLcnt,F	; decrement counter
	bnz	_altd_1		; branch if not zero
	movfw	CTRLreg1	; get the only stored value
	movwf	KBD		; store in output register
	goto	_altd_3		; jump
_altd_1	;*** check if counter == 2 ***
	decf	CTRLcnt,F	; decrement counter
	bnz	_altd_2		; branch if not zero
	;*** check ok, convert now ***
	movlw	HIGH BCDtable	; get correct page for PCLATH
	movwf	PCLATH		; prepare right page bits for table read
	;*** 10's in CTRLreg1, 1's in CTRLreg2 ***
	movfw	CTRLreg1	; get the first stored value (10's)
	call	BCDtable	; BCD2BIN conversion through lookup table
	addwf	CTRLreg2,W	; add value in W to reg 2, store in W
	movwf	KBD		; store in output register
	goto	_altd_3		; jump
_altd_2	;*** else counter >= 3 ***
	;*** 100's in CTRLreg1, 10's in CTRLreg2, 1's in CTRLreg3 ***
	;*** range check: CTRLreg1 <= 2 ***
	movfw	CTRLreg1	; get the first stored value (100's)
	sublw	0x02		; 0x02 - w
	bnc	_ClrStall	; no carry if result negative, abort & exit
	;*** check ok, convert now ***
	movlw	HIGH BCDtable	; get correct page for PCLATH
	movwf	PCLATH		; prepare right page bits for table read
	movfw	CTRLreg1	; get the first stored value (100's)
	addlw	d'10'		; add offset for lookup table
	call	BCDtable	; BCD2BIN conversion through lookup table
	movwf	CTRLreg1	; store new value back to register
	movfw	CTRLreg2	; get the second stored value (10's)
	call	BCDtable	; BCD2BIN conversion through lookup table
	addwf	CTRLreg1,F	; add value in W to reg 1, and store
	movfw	CTRLreg3	; get the third stored value (1's)
	addwf	CTRLreg1,W	; add both registers, store in W
	movwf	KBD		; store in output register
_altd_3	clrf	CTRLcnt		; invalidate counter
	goto	_OUTP		; output

	;*******************************************************
	;* The following table has also to be located within   *
	;* one page to allow for correct lookup functionality. *
	;*******************************************************

	;ORG	0x??

BCDtable ; lookup table for BCD2BIN conversion
	addwf	PCL,F
	retlw	d'0'	; 0    BCD for 10's
	retlw	d'10'	; 10
	retlw	d'20'	; 20
	retlw	d'30'	; 30
	retlw	d'40'	; 40
	retlw	d'50'	; 50
	retlw	d'60'	; 60
	retlw	d'70'	; 70
	retlw	d'80'	; 80
	retlw	d'90'	; 90
	retlw	d'0'	; 0    BCD for 100's
	retlw	d'100'	; 100
BCDtableEND retlw d'200' ; 200

	IF (high (BCDtable) != high (BCDtableEND))
		ERROR "Lookup table for BCD2BIN conversion hits page boundary !"
	ENDIF


_CTRLhex ; PRE: CTRL + [1..2] letters/numbers (e.g. CTRL + 3 + F = ?)
	;       in CTRLreg1 - 2
	; POST: convert ALT-DEC-Entry after release of ALT key, return
	;       ascii value as concatenated hex value from numbers
	tstf	CTRLcnt		; check, if counter has been incremented
	bz	_ClrStall	; if not, abort & exit
	movlw	0x30
	subwf	CTRLreg1,F	; CTRLreg1 = CTRLreg1 - 0x30
	subwf	CTRLreg2,F	; CTRLreg2 = CTRLreg2 - 0x30
	; if CTRLregs have numbers, now in [1..9]
	; if CTRLregs have letters [a..f], now in [0x31..0x36]
	; (no plausiblity checks necessary since done during storing)
	;*** first register ***
	btfss	CTRLreg1,0x5	; in [0x31..0x36], bit 5 is set
	goto	_ctrh_1		; it's a number, branch to next check
	; it's a letter: subtract offset, result afterwards in [d'10'..d'15']
	movlw	d'39'
	subwf	CTRLreg1,F	; CTRLreg1 = CTRLreg1 - W
_ctrh_1	;*** second register ***
	btfss	CTRLreg2,0x5	; in [0x31..0x36], bit 5 is set
	goto	_ctrh_2		; it's a number, branch
	; it's a letter: subtract offset, result afterwards in [d'10'..d'15']
	movlw	d'39'
	subwf	CTRLreg2,F	; CTRLreg2 = CTRLreg2 - W
_ctrh_2	;*** check if counter == 1 ***
	decf	CTRLcnt,F	; decrement counter
	bnz	_ctrh_3		; branch if not zero
	movfw	CTRLreg1	; get the only stored value
	movwf	KBD		; store in output register
	goto	_ctrh_4		; jump
_ctrh_3	;*** else counter >= 2, conversion ***
	swapf	CTRLreg1,W	; swap nibbles, store in W
	iorwf	CTRLreg2,W	; merge both registers, store in W
	movwf	KBD		; store in output register
_ctrh_4	clrf	CTRLcnt		; invalidate counter
	goto	_OUTP		; output

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

	;#include "..\tables\eng_shif.asm"  	; English 'codepage'
	#include "..\tables\ger_shif.asm"  	; modified Swiss-German 'codepage'

;***** END OF SCAN PATTERN DECODING SUBROUTINE *****


;************** MAIN **************

MAIN	ORG	0x00

	BANK1
	clrf	OPTION_REG	; PORTB pull-ups enabled
	goto	_MAIN

	ORG	0x440

_MAIN	;*** configure port A ***
	; Note: Initially, I have spent approx. 25 hours on debugging
	; this AT keyboard interface in conjunction with the PIC 16C74A,
	; because the port A inputs are set to analog inputs by default !!!

	; Configure RA0, RA1, RA2, RA3, RA5 to analog inputs,
	; but leave RA4, RE0, RE1, RE2 as digital I/O ports.
	; Analog reference voltage is VDD.
	movlw	b'00000010'
	movwf	ADCON1
	BANK0

	;*** RS232 INITIALIZATION ***
	RS232init		; RS232 initialization

	;*** AT KEYBOARD INITIALIZATION I ***
	KEYBOARDinit		; keyboard initialization

	;*** ENABLE ALL INTERRUPTS ***
	movlw	b'11111000'
	andwf	INTCON,F	; clear all interrupt flags
	clrf	PIR1		; clear all interrupt flags
	clrf	PIR2		; clear all interrupt flags
	bsf	INTCON,GIE	; enable global interrupt

	;*** AT KEYBOARD INITIALIZATION II ***
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
	#define	tab_items d'39'
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
	;bsf	DEBUG0		; ### DEBUGGING ###
	KBDcmd	0xFF		; reset keyboard
	;bsf	DEBUG1		; ### DEBUGGING ###
	;KBDexp	0xFA		; expect 0xFA => issue with some keyboards

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
	call	RSdisplay	; if set, call display routine
	goto	_MLOOP
	;******************************

	;ORG	0x??		; if necessary, move table

WelcomeTable
	addwf	PCL,F		; add offset to table base pointer
	DT	"PIC 16F77 AT Keyboard Decoder connecte" ; create table
WTableEND DT "d"

	IF (high (WelcomeTable) != high (WTableEND))
		ERROR "WelcomeTable hits page boundary!"
	ENDIF

	END
