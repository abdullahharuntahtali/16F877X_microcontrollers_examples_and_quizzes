;**********************************************************************
;                                                                     
;	AT Keyboard Shift Lookup Table
;	==============================
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
;	Keyboard lookup table for special characters typed with SHIFT
;	button active.
;
;**********************************************************************

KBDSHIFTtable ; some of the items are located here with 'compressed' offset
	addwf	PCL,F
	DT	"/(#*;"	; 0x3D - 0x41
	retlw	0	; invalid entry
	retlw	0	; 
	retlw	0	; 
	DT	"=)"	; 0x45 - 0x46
	retlw	0	; 
	DT	"%:_"	; 0x48 - 0x4A
	retlw	0	; 
	retlw	0x5C	; "\" 0x4C
	retlw	0	; 
	DT	"?@&"	; 0x4E - 0x50	(replaced ° by @)
	retlw	0	; 
	retlw	'{'	; 0x52
	retlw	0	; 
	DT	"[~"	; 0x54 - 0x55
	retlw	0	; 
	retlw	A'+'	; 0x57
	retlw	0	; 
	retlw	0	; 
	retlw	0	; 
	retlw	A']'	; 0x5B
	retlw	0	; 
	retlw	A'}'	; 0x5D
	retlw	0	; 
	retlw	A'"'	; 0x5F
	retlw	0	; 
KBDSHIFTtableEND retlw	A'>'	; 0x61


	IF (high (KBDSHIFTtable) != high (KBDSHIFTtableEND))
		ERROR "Keyboard lookup SHIFTtable hits page boundary!"
	ENDIF
