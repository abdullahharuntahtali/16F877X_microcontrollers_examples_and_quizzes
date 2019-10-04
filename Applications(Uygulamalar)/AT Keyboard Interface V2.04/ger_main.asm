;**********************************************************************
;                                                                     
;	AT Keyboard Main Lookup Table
;	=============================
;
;	written by Peter Luethi, 12.07.2000, Dietikon, Switzerland
;	http://www.electronic-engineering.ch
;	last update: 28.01.2003
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
;	VERSION:
;	========
;	Modified SWISS-GERMAN keyboard layout (QWERTZ 'codepage')
;
;	DESCRIPTION:
;	============
;	Keyboard lookup table, 'main' refers to decoding of all keys
;	typed without any shift key active.
;
;**********************************************************************

KBDtable ; (not used for characters typed with shift button active)
	addwf	PCL,F
	retlw	0	; invalid entry
	retlw	A'9'	; F9 -> 9	0x01
	retlw	0	; 
	retlw	A'5'	; F5 -> 5
	retlw	A'3'	; F3 -> 3
	retlw	A'1'	; F1 -> 1
	retlw	A'2'	; F2 -> 2
	retlw	A'2'	; F12 -> 2
	retlw	0	;
	retlw	A'0'	; F10 -> 0
	retlw	A'8'	; F8 -> 8	0x0A
	retlw	A'6'	; F6 -> 6
	retlw	A'4'	; F4 -> 4
	retlw	0x09	; TAB
	retlw	A'§'	; 
	retlw	0	;
	retlw	0	;		0x10
	goto	_ALT	; ALT	(set/clear ALT flag)
	goto	_SHIFT	; SHIFT	(set/clear SHIFT flag)
	retlw	0	;
	goto	_CTRL	; CTRL	(set/clear CTRL flag)
	DT	"q1"	; DT: MPASM directive to create a table (retlw x)
	retlw	0	; 
	retlw	0	; 
	retlw	0	; 		0x19
	DT	"ysaw2"	;
	retlw	0	; 
	retlw	0	; 		0x20
	DT	"cxde43";
	retlw	0	; 
	retlw	0	; 
	retlw	A' '	; SPACE
	DT	"vftr5"	;
	retlw	0	; 
	retlw	0	; 		0x30
	DT	"nbhgz6";
	retlw	0	; 
	retlw	0	; 
	retlw	0	; 
	DT	"mju78"	;
	retlw	0	; 
	retlw	0	; 		0x40
	DT	",kio09";
	retlw	0	; 
	retlw	0	; 
	DT	".-löp'";
	retlw	0	; 
	retlw	0	;		0x50 
	retlw	0	; 
	retlw	A'ä'	; 
	retlw	0	; 
	retlw	A'ü'	; 
	retlw	A'^'	; 
	retlw	0	; 
	retlw	0	; 
	retlw	0	; CAPS LOCK, check and alter CAPflag on key release
	goto	_SHIFT	; SHIFT
	goto	_CRLF	; CR,LF		0x5A
	retlw	A'!'	; 
	retlw	0	; 
	retlw	A'$'	; 
	retlw	0	; 
	retlw	0	; 
	retlw	0	; 
	retlw	A'<'	; 		0x61
;*** begin compression (scan code - d'14') ***
	DT	"0.2568"
	retlw	0	; ESCAPE	0x76
	retlw	0	; NUM LOCK
	DT	"1+3-*9"
	retlw	0	; SCROLL LOCK	0x7E
;*** begin compression (scan code - d'14' + d'35') ***
	retlw	0x08	; BACKSPACE
	retlw	0	; 
	retlw	0	; 
	retlw	A'1'	; 		0x82
;*** begin compression (scan code - d'14') ***
	retlw	A'7'	; 
;*** begin compression (scan code - d'14' + d'35') ***
	retlw	A'4'
KBDtableEND	retlw	A'7'


	IF (high (KBDtable) != high (KBDtableEND))
		ERROR "Keyboard lookup table hits page boundary!"
	ENDIF
