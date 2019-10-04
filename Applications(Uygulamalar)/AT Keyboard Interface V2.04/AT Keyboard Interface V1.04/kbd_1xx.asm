;***************************************************************************
;                                                                     
;	AT Keyboard Interface V1.04
;	===========================
;
;	written by Peter Luethi, 12.07.2000, Switzerland
;	http://www.electronic-engineering.ch
;	last update: 19.04.2004
;
;	V1.04:	Re-structured ISR to comply with latest modules, added
;		label _ISR_RS232error
;		(19.04.2004)
;
;	V1.03:	Improved AT keyboard and RS232 initialization,
;		fixed RBIF/INTF interrupt initialization issue.
;		Changed keyboard data pin to PORTA,4 (open-collector).
;		(16.08.2003)
;
;	V1.02:	Made forward compatible (yes, this is feasible) by
;		implementing/completing ALT and CTRL flags. Added
;		labels to support non-implemented ALT and CTRL
;		enhancements. (3.1.2002)
;
;	V1.01:	Changed from non-preemptive to preemptive interrupt-based
;		keyboard scan pattern acquisition scheme.
;		Now only the scan pattern acquisition is carried out
;		during the interrupt service routine, the decoding
;		happens during normal operation mode when the flag
;		"KBDflag" has been set after having completed the entire
;		scan pattern reception. (16.7.2001)
;
;	V1.00:	Initial release (12.7.2000)
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
;	Processor:			Microchip PIC 16F84
;	Clock Frequency:		4.00 MHz XT
;	Throughput:			1 MIPS
;	RS232 Baud Rate:		9600 baud (depends on the module included)
;	Serial Output:			9600 baud, 8 bit, no parity, 1 stopbit
;	Keyboard Routine Features:	Capability of uni-directional
;					communication between microcontroller
;					and keyboard
;	Acquisition Methodology:	Preemptive, interrupt-based
;					keyboard scan pattern acquisition
;					routine, with decoding to ASCII
;					characters during normal operation
;	Code Size of entire Program:	523 instruction words
;	Required Hardware:		AT Keyboard, MAX 232
;	Required Software:		RS232 terminal
;
;
;	ABSTRACT:
;	=========
;	This routine converts AT keyboard scan patterns to ASCII characters
;	and transmits them afterwards to the target device by using the
;	RS232 transmission protocol.
;	Support of english (QWERTY) and modified swiss-german (QWERTZ)
;	'codepages'. This implementation features no visual interface.
;	Unidirectional data flow: Transmission only for characters typed on
;	the local keyboard.
;
;
;	DESCRIPTION:
;	============
;	Developed and tested on PIC 16F84.
;	Any key stroke on the keyboard connected to the PIC will send the
;	corresponding scan code from the keyboard to the microcontroller.
;	Afterwards, the microcontroller converts the keyboard scan code to
;	ASCII characters and sends them to the computer terminal via the
;	RS232 connection.
;
;	The keyboard scan pattern capture and decoding is done by an
;	interrupt service routine. The event, which triggers the interrupt
;	is a falling edge on the keyboard clock line at the KBDclkpin
;	(PORTB,0). The keyboard data (scan code) will be fetched at the
;	KBDdatapin (PORTA,4).
;	There is only RS232 transmission, so only the TXport (PORTA,0) is
;	connected. Since PORTB,0 is already used by the keyboard clock line,
;	there exists no possibility to use it also for RS232 reception.
;	The configuration of the KBDclkpin interrupt is done by the
;	KEYBOARDinit macro.
;
;	For the AT keyboard layout, English and modified Swiss-German
;	'codepages' are supported:
;	QWERTY and QWERTZ keyboard layout
;
;
;	IMPLEMENTED FEATURES:
;	=====================
;	- Uni-directional communication between microcontroller application
;	  and remote RS232 client.
;	- Uni-directional communication between microcontroller and keyboard.
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
;	- Minimized keyboard routine with support for only uni-directional
;	  communication from keyboard to controller, therefore no control
;	  over keyboard status LEDs.
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
;	- Steve Lawther for inspirations concerning the scan code fetch
;	  routine (for bring-up version 1.00 of this program).
;
;***************************************************************************

;***** COMPILATION MESSAGES & WARNINGS *****

	ERRORLEVEL -207 	; Found label after column 1.
	ERRORLEVEL -302 	; Register in operand not in bank 0.

;***** PROCESSOR DECLARATION & CONFIGURATION *****

	PROCESSOR 16F84
	#include "p16f84.inc"
	
	; embed Configuration Data within .asm File.
	__CONFIG   _CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC

;***** MEMORY STRUCTURE *****

	;ORG     0x00	processor reset vector, declared below
	;ORG     0x04	interrupt service routine, declared below

;***** PORT DECLARATION *****

	#define	TXport	PORTA,0x00	; RS232 output port, could be
	#define	TXtris	TRISA,0x00	; any active push/pull port
	#define	KBDdatapin PORTA,0x04	; keyboard data input port
	#define	KBDdatatris TRISA,0x04	; (open-collector pin)
	#define	KBDclkpin PORTB,0x00	; keyboard clock input port (IntB)
	#define	KBDclktris  TRISB,0x00  ; @ INTF interrupt source (RB0)

;***** CONSTANT DECLARATION *****

	CONSTANT BASE = 0x0C	; Base address of user file registers	

;***** REGISTER DECLARATION *****

	TEMP1	set	BASE+d'0' ; Universal temporary register
	TEMP2	set	BASE+d'1' ; ATTENTION !!!
	TEMP3	set	BASE+d'2' ; They are used by various modules.
	TEMP4	set	BASE+d'3' ; If you use them, make sure not to use
				  ; them concurrently !
	FLAGreg	equ	BASE+d'4' ; register containing keyboard and other flags

	TXD	equ	BASE+d'5' ; RS232 TX-Data register
	RXD	equ	BASE+d'6' ; RS232 RX-Data register (not used here, but m_rs232
				  ; requires its declaration)
	KBDcnt	equ	BASE+d'7'	; IRQ based keyboard scan pattern counter
	KBD	equ	BASE+d'8'	; keyboard scan code & ascii data register
	KBDcopy	equ	BASE+d'9'	; keyboard scan code register
	#define	RELflag	FLAGreg,0x00	; release flag (0xF0)
	#define	SHIflag	FLAGreg,0x01	; shift flag (0x12 / 0x59)
	#define	SPEflag	FLAGreg,0x02	; special code flag (0xE0)
	#define	CAPflag	FLAGreg,0x03	; caps lock flag (0x0D)
	#define	ALTflag	FLAGreg,0x04	; ALT flag (0x11)
	#define	CTRLflag FLAGreg,0x05	; CTRL flag (0x14)
	#define	KBDflag	FLAGreg,0x06	; keyboard data reception flag

	; interrupt context save/restore
	W_TEMP	equ	BASE+d'10'	; context register (ISR)
	STATUS_TEMP equ	BASE+d'11'	; context register (ISR)
	PCLATH_TEMP equ	BASE+d'12'	; context register (ISR)
	FSR_TEMP equ	BASE+d'13'	; context register (ISR)

;***** INCLUDE FILES *****

	ORG	0x190
	#include "..\..\m_bank.asm"
	#include "..\..\m_wait.asm"
	#include "..\..\m_rs096.asm"	; 9600 baud @ 4 MHz

;***** MACROS *****

KEYBOARDinit macro
	BANK1
	bsf	KBDclktris	; set keyboard clock line to input explicitely
	bsf	KBDdatatris	; set keyboard data line to input explicitely
	bcf	OPTION_REG,INTEDG ; keyboard interrupt on falling edge
	BANK0
	bsf	INTCON,INTE	; enable RB0/INT interrupts
	endm

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

	;*****************************************
	;*** KEYBOARD SCAN PATTERN ACQUISITION ***
	;*****************************************

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
_ISR_RS232error
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
	bcf	CAPflag		; clear flag
	goto	_ClrStall	; abort with nothing to display
_setCAP	bsf	CAPflag		; set flag if cleared
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

	;ORG	0x??			; if necessary, move table

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
	;*** decoding of scan code with preceding special code (0xE0) ***
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

	;*************************************
	;*** KEYBOARD DATA OUTPUT TO RS232 ***
	;*************************************

_OUTP	;*** RS232 ***
	movfw	KBD
	SENDw			; send actual pressed keyboard character
	goto _ClrStall		; (uncomment in case _ClrStall will be moved)

	;************************************************
	;*** SPECIAL COMMANDS I (with special output) ***
	;************************************************

_CRLF	SEND	CR		; on 'Enter', send CR and LF to RS232
	movlw	LF		; put LF to w, return
	RETURN

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
	clrf	OPTION_REG	; PORTB pull-ups enabled
	goto	_MAIN

	ORG	0x1E0

_MAIN	;*** RS232 INITIALIZATION ***
	; Do not call RS232init, since we have no RS232 reception and
	; PORTB,0 is already used by the keyboard.
	; (Note: KEYBOARDinit and RS232init are almost equal)
	; Initialize only RS232 transmission (TXport):
	bcf	TXtris		; set RS232 output
	BANK0
	bsf	TXport		; set default state: logical 1

	;*** AT KEYBOARD INITIALIZATION ***
	KEYBOARDinit		; keyboard initialization
	clrf	KBDcnt		; clear IRQ based scan pattern counter
	clrf	FLAGreg		; clear all flags (keyboard & other)

	;*** ENABLE ALL INTERRUPTS ***
	movlw	b'11111000'
	andwf	INTCON,F	; clear all interrupt flags
	bsf	INTCON,GIE	; enable global interrupt

	;*** define amount of table items for startup message ***
	#define	tab_items d'42'
	movlw	tab_items	; store amount of table items in counter
	movwf	TEMP3

	;*** transmit startup message ***
_ILOOP	movlw	HIGH WelcomeTable ; get correct page for PCLATH
	movwf	PCLATH		; prepare right page bits for table read
	movfw	TEMP3		; get actual count-down value
	sublw	tab_items	; table offset: w = tab_items - TEMP3
	call	WelcomeTable	; call lookup table
	SENDw
	decfsz	TEMP3,F		; decrement counter
	goto	_ILOOP

	;******************************
_MLOOP	btfsc	KBDflag		; check scan pattern reception flag
	call	KBDdecode	; if set, call decoding routine
	goto	_MLOOP
	;******************************

	ORG	0x210		; align table within page

WelcomeTable
	addwf	PCL,F		; add offset to table base pointer
	DT	"PIC 16F84 AT Keyboard Decoder connected" ; create table
	retlw	CR		; Carriage Return
	retlw	LF		; Line Feed
WTableEND retlw	LF		; Line Feed

	IF (high (WelcomeTable) != high (WTableEND))
		ERROR "Welcome table hits page boundary!"
	ENDIF

	END
