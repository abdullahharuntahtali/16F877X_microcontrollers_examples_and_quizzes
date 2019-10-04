; LAUFSRS6.ASM    
; fuer das LAUFSCHRIFT-Projekt.
;
;  Programm auf dem AT89S8252 (Flash-Programmierung)
;  W. Waetzig  							 24.07.2003
;
; Der Microprozessor AT98S8252 treibt eine Laufschrift-Zeile mit 60*8 LEDs.
; Auf dieser werden maximal 10 Zeichen dargestellt.
;
; Eine PC-Tastatur ist ueber ein FIFO (MOS 40105) direkt angeschlossen.
; Für diese wird der Scan-Code nach ASCII umkodiert mit der Möglichkeit,
; die Zeichenkodierung von deutscher Tastatur auf englische umzuschalten.
;
; Die serielle Schnittstelle kann zur Eingabe der Zeichen und der Steuer-
; Kommandos alternativ genutzt werden.
; Die Baudrate (150/300/600/1200 Bd) dafür wird durch Jumper an den 
; Pins P3.2/P3.3 eingestellt.
;
; Das System ist mit der Real-Time-Clock DS1302 und einer Datums-Anzeige
; erweitert.
;
; Zur Kontolle der Eingabe mittels der Tastatur werden die Werte des Textblocks
; (textsel) und der Text-Zeile (lastfct) jeweils in einem eigenen 4-Bit-LED-Display 
; binär angezeigt. 
; Die Tastatur-Auswahl (EN/DE) wird im höchsten Bit dieser Anzeige (textsel)
; angezeigt: LED ein bei Tastatur EN.
;
; Vom internen RAM werden 120 Byte als Display-Puffer für die LED-Zeile genutzt.
; Mit der Interrupt-Frequenz von 3600 Hz erfolgt die Ansteuerung einer Spalte 
; in der LED-Zeile; die Bildwiederhol-Frequenz beträgt somit 60 Hz.
;
; In einem Text-Block (256 Bytes) im EEPROM werden 12 Zeilen mit je 20 Zeichen
; gespeichert.
; Das gesamte EEPROM (2048 Bytes) ist in 8 wählbare Text-Blöcke aufgeteilt.
; Jeder Text-Block mit 240 nutzbaren Zeichen kann im Roll-Modus durchlaufend
; angezeigt werden.
;
;
; Spezial-Funktionen
; ==================
; Code  Tastatur-	Serielles	ausgeführte	
; Wert  Zeichen	Kommando	Funktion
;--------------------------------------------------------------------------
;  01	  F1		#1		Auswahl der Text-Zeile #1
;  ..	  F2..F8	#2..#8		Auswahl der Text-Zeilen #2..#8
;  09	  F9		#9		Auswahl der Text-Zeile #9
;  10	  F10		#A		Auswahl der Text-Zeile #10
;  11	  F11		#B		Auswahl der Text-Zeile #11
;  12	  F12		#C		Auswahl der Text-Zeile #12
;  13	  CR 		#+		gehe zur naechsten Text-Zeile
;  14	  BCK / ENTF	#-		1 Zeichen zurueckgehen
;  15	  SHIFT left/right		Klein/Gross-Buchstaben-Umschaltung
;  16	  ROLLEN	#R		rollt die Laufschrift (ein/aus)
;  17	  ALT-GR			Umschaltung auf die Sonderzeichen @{[]}~|\
;  18	  POS1		#0		Anfang der Zeile und Ruecksetzen Rollen
;  19	  DRUCK Fx Fy	#D #1 #2	Automatische Text-Anzeige #Fx..#Fy
;					Die Text-Zeilen von Fx bis Fy werden durch
;					kontinuierliches Rollen der Laufschrift
;					angezeigt.
;  20	  NUM		#N		Display: 1.normal/2.invers/3.blinken
;  21	  PAUSE Fx	#P #x		Auswahl des Textblocks Fx = F1..F8	
;					mit je 12 Text-Zeilen zu 20 Zeichen
;  22	  ENTER  	#Z		loescht die aktuelle Text-Zeile
;  23	  ESC Fx Z E	#E #x ZE	Steuerung der RTC - Anzeige mit:
;					ESC ESC  Uhrzeit und Datum in 5 sec Intervall,
;					ESC " "  nur Uhrzeit im Sekundentakt.
;  24   EINFG  	#*		Text-Eingabe ueber mehrere Zeilen (ein/aus)
;					mit maximal 240 Zeichen.
;					Der Beginn der Eingabe erfolgt in der mit Fx
;					gewählten Text-Zeile.
;  25   Bild oben			Umschaltung auf EN-Tastatur
;  26	  Bild unten			Umschaltung auf DE-Tastatur
;
; Funktionstasten beim Setzen der RTC: ESC Fx ZE
;			F1	Sekunden	ZE = 00..59
;			F2	Minuten 	ZE = 00..59
;			F3	Stunden 	ZE = 00..23
;			F4	Tagesdatum	ZE = 01..31
;			F5	Monat		ZE = 01..12
;			F6	Wochentag	ZE = 01..07
;			F7	Jahr		ZE = 00..99
;
; Darstellung der Umlaute bei serieller Ein/Ausgabe
; Zeichen  Ersatz  interner
;  Kode     Wert    Kode 
;	"ß" =  :s =  081h
;	"ä" =  :a =  082h
;	"Ä" =  :A =  083h
;	"ö" =  :o =  084h
;	"Ö" =  :O =  085h
;	"ü" =  :u =  086h
;	"Ü" =  :U =  087h
;
; -------------------------------------------------------------------------------
;
#include 8051.H
;
; Pin-Belegung vom AT89S2852
;=========================
;			P3.0	RXD	serial in
;			P3.1	TXD	serial out
;			P3.2	(INT0)	Selektor Baud-Rate
;			P3.3	(INT1)	Selektor Baud-Rate
TST_SER	.equ	P3.4		;input	Selektor Tastatur/Serielle Steuerung
RTC_IOL	.equ	P3.5		;RTC input/output-line
RTC_CLK	.equ	P3.6		;RTC clock output
RTC_RES	.equ	P3.7		;RTC reset
;
DSP_CLK	.equ	P1.0		;Laufschrift-Display Clock-Signal
DSP_DAT	.equ	P1.1		;Laufschrift-Display Data-Signal
TST_DAT	.equ	P1.2		;Tastatur DATA (Eingang/Ausgang)
TST_CLK	.equ	P1.3		;Tastatur CLOCK
FIF_DAT	.equ	P1.4		;FIFO Data (Eingang) 	(MOS 40105)
FIF_SFT	.equ	P1.5		;FIFO Shift-out (Ausgang)		[FLASH-Prog. MOSI]
FIF_DTR	.equ	P1.6		;FIFO Data-ready (Eingang)		[FLASH-Prog. MISO]
FIF_ENB	.equ	P1.7		;FIFO Enable (Ausgang)  	 	[FLASH-Prog. SCK]
;
;	P2	P2.0 .. P2.7		Ausgangsdaten fuer Zeilen des LED-Display-Arrays
;
FLG_TXW	.equ	P0.0		;FLAG Bit fuer Text-Wechsel gesetzt von Timer
FLG_T12	.equ	P0.1		;FLAG Anzeige fuer 1./2. Texthaelfte
FLG_INV	.equ	P0.2		;FLAG Indikator fuer inversen Display (NUM)
ANZ_SEL	.equ	P0.3		;Anzeige-Selektor
;		P0.4 .. P0.7	Binär-Anzeige für 2 * 4 LEDs
;
; Einstellen der Baud-Rate fuer UART-Timer-2:
;	mit RCAP = (RCAP2H,RCAP2L)
;	und OSC  = Oszillator-Frequenz
;	ergibt sich
; =>	Baud = OSC / (32 * [65536 - RCAP] )
;	und
; =>	RCAP = 65536 - OSC / (32 * Baud).
; Bei einer Oszillator-Frequenz von: 11.059.200 Hz ergeben sich:
;	fuer 9600 Baud:	RCAP = 65500 = (FF,DC)
;	fuer 4800 Baud:	RCAP = 65464 = (FF,B8)
;	fuer 2400 Baud:	RCAP = 65392 = (FF,70)
;	fuer 1200 Baud:	RCAP = 65248 = (FE,E0)
;	fuer  600 Baud:	RCAP = 64960 = (FD,C0)
;	fuer  300 Baud:	RCAP = 64384 = (FB,80)
;	fuer  150 Baud:	RCAP = 63232 = (F7,00)
;
; -------------------------------------------------------------------------------
;
;  Interrupt-Adressen vom AT98S8252
		.org	0000h
		ljmp	reset		; Reset-Vektor
		.org	0003h
		ljmp	intte0		; Interrupt extern Button 0
		.org	000bh
		ljmp	inttf0		; Interrupt Timer 0
		.org	0013h
		ljmp	inte1		; Interrupt extern Button 1
		.org	001bh
		ljmp	inttf1		; Interrupt Timer 1
		.org	0023h
		ljmp	intser		; Interrupt Seriell
		.org	002bh
		ljmp	inttf2		; Interrupt Timer 2
;
; zusaetzliche Register fuer AT98S2852
WMCON		.equ	096h
;
;  Variables
zeitdat 	.equ	060h	; Zaehler fuer RTC-Umschalter
thischar	.equ	061h	; input-char.  / delay-cnt.
lastchar	.equ	062h	; output-char. / delay-cnt.
comdchar	.equ	063h	; Kommando-Zeichen Seriell
rollcnt 	.equ	064h	; Zaehler fuer 16 Hz Text-Rollen (Timer-1)
rtcdata 	.equ	065h	; RTC-Daten-Byte
rtcount 	.equ	066h	; RTC-Schiebe-Zaehler
rtcvalu 	.equ	067h	; RTC-Hilfswert
dispval 	.equ	068h	; Anzeige-Wert
textsel  	.equ	069h	; Selektor fuer den Textblock (0..7)
blinknt 	.equ	06Ah	; Zaehler fuer Blink-Periode
dispinv 	.equ	06Bh	; Display invers=(01)/blinken=(10)
dispcyc 	.equ	06Ch	; RTC-Display-Zaehler
dispmax 	.equ	06Dh	; max. Index fuer Display
atdspf1  	.equ	06Eh	; Automatische Text-Anzeige: Start-Fx
atdspf2 	.equ	06Fh	; Automatische Text-Anzeige: Stopp-Fx
tasdata 	.equ	070h	; Tastatur-Daten-Byte
tparity 	.equ	071h	; Parity Tastatur-Sende-Daten / Ausgabe Seriell
tbitcnt 	.equ	072h	; Parity Bit-Zaehler
roltext 	.equ	073h	; Indikator fuer Text rollen
lastfct 	.equ	074h	; zuletzt genutzte Funktionstaste (1..12)
scancod 	.equ	075h	; Code von der Tastatur
codesft 	.equ	076h	; Flags: Klein-/Gross-Buchstaben + ALT-GR + EN/DE
textrnd 	.equ	077h	; 00..19	Index fuer den Text-lesen
textwnd 	.equ	078h	; 00..19	Index fuer den Text-schreiben
textadr 	.equ	079h	; Start-Adresse des Textes im EEPROM
textbyt 	.equ	07Ah	; zu schreibendes Byte
dispchr 	.equ	07Bh	; Zeichen fuer den Display
dispcnt 	.equ	07Ch	; Zaehler fur den Display
laufsft 	.equ	07Dh	; Pixel-shift 0..119
laufcnt 	.equ	07Eh	; Zaehler in Display-Puffer 0..59
laufind 	.equ	07Fh	; Index in Laufschrift-Puffer 0..119
;
;F0		.equ	PSW.5	; Flag fuer Text-Eingabe 
NEGATIV	.equ	ACC.7	; Flag fuer Negativ-Anzeige im ACC
;
laufsta 	.equ	080h	; Feld fuer Laufschrift im RAM, Laenge=120 Bytes
;
;=============================================================================
;
startext	.byte	"(C)Elektor          ",0
;
reset		mov	P0,#000h		; disable P0
		mov	P1,#0FCh		; enable TST_DAT + TST_CLK + FIF_DAT-FIF_ENB
		mov	P3,#01fh		; enable P3 0..4
		mov	IE,#00000010b		; IE.4=0 serial port
						; IE.3=0 timer 1 	/ IE.1=1 timer 0
						; IE.2=0 ext. int.1 	/ IE.0=0 ext. int. 0
		mov	TMOD,#00000010b	; Timer-0: 8 Bits, auto-reload
						; timer-operation, start TCON.4
						; Timer-1: OFF
		mov	TH0,#0			; Timer-0 Zaehlwert
		mov	TL0,#0
;		mov	TH1,#0			; Timer-1 Zaehlwert
;		mov	TL1,#0
		mov	TCON,#00010000b	; TCON.4 Timer-0 ON 
						; TCON.6 Timer-1 OFF
; initialisiere UART
;		jb	TST_SER,reset1
		acall	serialin
		mov	lastchar,#0
		mov	thischar,#0
;
; ==== laufschrift
reset1		mov	IP,#00000010b		; IP.1 timer 0 on high prio
		mov	WMCON,#0		;reset EEPROM-reg.+DPTR0
		mov	R0,#laufsta	; Display-Puffer
		mov	dispinv,#0	; Display invers=(01)/blinken=(10)
		clr	FLG_INV		; Indikator fuer inversen Display	
		setb	DSP_DAT		; Data-Signal
		setb	FIF_DTR		; FIFO-Test
		mov	laufcnt,#0	; Pixel-Zaehler
		mov	rollcnt,#225	; 16 Hz-Zaehler fuer ROLLEN
		clr	FLG_TXW		; Bit fuer Text-Wechsel
		mov	codesft,#0	;SHIFT-Taste + ALT-GR + Tastatur-Kode
		acall	drukfres	;laufsft,roltext,atdspf1,atdspf2
;
; ====== setze Tastatur: Scan-Code 3
		jnb	TST_SER,reset2
		acall	setztast
;
; ====== Starte die RTC
reset2		acall	rtcenabl
;
; ===========setze Display
		mov	textsel,#0	; Textblock #0
		mov	lastfct,#1	;zuletzt genutzte F-Taste
		mov	A,lastfct	; Start mit F1-Taste
		acall	eepinit0
		acall	anftext 	;fuelle Start-Text in das EEPROM
		acall	eepinit1
		acall	display1
		acall	display2
		acall	display3	; sende Text seriell
		clr	FIF_ENB		; enable FIFO
		clr	F0		; PSW.5=F0 Flag fuer Text-Eingabe
		mov	tparity,#0	; Ausgabe-Zeichen Seriell
		setb	EA		; IE.7 interrupt ON
		ajmp	txloop
;
;=============================================================================
;
; ======interrupt INT0 (Pin P3.2)
intte0		nop
;		push	PSW	; sichern Status-Register
;		push	ACC	; sichern ACC
;		nop
;intbret 	pop	ACC	; ruecksichern ACC
;		pop	PSW	; ruecksichern Status-Register	
		reti
;
;---------------------------------------------------------------
;
; ======interrupt timer0 === Haupt-Schleife, Interrupt-Frequenz = 3600 Hz
;	erzeuge den Strobe-Puls fuer das Laufschrift-LED-Array 
;	steuere die Anzeige von textsel/lastfct
inttf0		push	PSW	; sichern Status-Register
		push	ACC	; sichern ACC
; berechne aktuellen Index im Display-Puffer
		mov	A,laufcnt
		add	A,laufsft	; counter+shift
		mov	laufind,A	; => index
		jnb	NEGATIV,int0x0	; index > 127?
		anl	A,#07Fh	; index-128
		add	A,#008h	;correct value
		sjmp	int0x1
int0x0		clr	C		;clear Carry-bit
		subb	A,#120		; index-120
		jnb	NEGATIV,int0x1
		mov	A,laufind
int0x1		add	A,#laufsta	; index in Byte-buffer
		mov	R0,A
		mov	A,@R0		; hole naechstes Byte
		jb	FLG_INV,int0x2	; Display invers
		cpl	A
int0x2		mov	P2,ACC		;Ausgabe auf Port 2
		setb	DSP_CLK		; => Strobe-Puls
		clr	DSP_DAT		; Data-Signal
		clr	DSP_CLK
; vermeide Ueberlauf im Display-Puffer
		inc	laufcnt	; Zaehler im Puffer
		mov	A,laufcnt
		cjne	A,#60,int0x3	; Zaehler = 60?
		mov	laufcnt,#0
		setb	DSP_DAT		; Data-Signal
; Anzeige von textsel und lastfct, codesft.3 = Tastatur-Bit
int0x3  	jb	ANZ_SEL,int0x4
		mov	A,codesft
		anl	A,#008h
		orl	A,textsel
		inc	A
		sjmp	int0x5
int0x4  	mov	A,lastfct
int0x5  	swap	A
		cpl	A
		anl	A,#0F0h
		mov	dispval,A
		mov	A,P0
		anl	A,#00Fh
		orl	A,dispval
		mov	P0,A
		cpl	ANZ_SEL
; Zaehler fuer 3600:225=16 Hz fuer Rollen und Blinken
int0ret	djnz	rollcnt,i0return
		mov	rollcnt,#225
; ======interrupt   - fuer Increment Text-ROLLEN, Frequenz 16 Hz
;	roltext.7 (80)	-> Flag Text-Wechsel
;	roltext.0 (01)	-> Flag fuer Rollen (laufsft+1)
;	roltext.5 (20)	-> Flag RTC-Display
;	roltext.4 (10)	-> Flag Start RTC-Display
;	roltext.3 (08)	-> Flag RTC Datum/Uhrzeit je 5 sec
;	Signale Text-Wechsel
		mov	A,roltext
		jnb	NEGATIV,intef1	; Text-Wechsel ?
		inc	laufsft
		mov	A,laufsft
		cjne	A,#60,intef0
		setb	FLG_TXW		; Indikator
		setb	FLG_T12		; 1./2. Text-Haelfte
		sjmp	intef3
intef0  	cjne	A,#120,intef3
		setb	FLG_TXW		; Indikator
		clr	FLG_T12		; 1./2. Text-Haelfte
		sjmp	intef2
;	Signale Text Rollen
intef1  	jnb	ACC.0,intef3	; Text-Umlauf
		inc	laufsft
		mov	A,laufsft
		cjne	A,#120,intef3
intef2	 	mov	laufsft,#0
		sjmp	intef4
;	RTC-Display Zeit-Info pro sec
intef3  	mov	A,roltext
		jnb	ACC.5,intef4
		djnz	dispcyc,intef4
		mov	dispcyc,#16
		setb	ACC.4		; Flag zum RTC-Lesen+Display
		mov	roltext,A
;	Signale Display invers/blinken
intef4		mov	A,dispinv	; Display invers=(01)/blinken=(10)
		jz	intef5
		jnb	ACC.1,intef5
		djnz	blinknt,intexx
		mov	blinknt,#8
		cpl	FLG_INV		; => blinken
		sjmp	intexx
intef5	 	mov	C,ACC.0
		mov	FLG_INV,C		; => invers
;    interrupt return
intexx	 	nop
i0return	pop	ACC		; ruecksichern ACC 
		pop	PSW		; ruecksichern Status-Register
		reti
;
;---------------------------------------------------------------
;
; ======interrupt INT1 (Pin P3.3)
inte1		nop
;		push	PSW		; sichern Status-Register
;		push	ACC		; sichern ACC
;		nop
;intes0	pop	ACC		; ruecksichern ACC	
;		pop	PSW		; ruecksichern Status-Register
		reti
;
;---------------------------------------------------------------
;
; ======interrupt timer1 
inttf1		nop
;		push	PSW		; sichern Status-Register
;		push	ACC		; sichern ACC
;	return
;		pop	ACC		; ruecksichern ACC	
;		pop	PSW		; ruecksichern Status-Register
		reti
;
;---------------------------------------------------------------
;
; ======interrupt seriell (RXD=Pin 3.0 / TXD=Pin P3.1)
intser		nop
;		push	PSW		; sichern Status-Register
;		push	ACC		; sichern ACC
; == Eingabe-Zeichen
;		jnb	RI,intser2	; SCON.0 RX-Flag
;		clr	RI		; loeschen
;		mov	A,SBUF		; Eingabe-Zeichen
;		mov	crxd,A		; gespeichert
;		nop
;		sjmp	intserx
; == Ausgabe-Zeichen, gesendet durch: mov SBUF,A
;intser2 	jnb	TI,intserx	; SCON.1 TX-Flag
;		clr	TI		; loeschen
;		nop
; interrupt return
;intserx 	pop	ACC	; ruecksichern ACC 
;		pop	PSW	; ruecksichern Status-Register
		reti
;
;---------------------------------------------------------------
;
; interrupt timer2
inttf2		nop
		reti
;
; ========= LOOP ===========================================================
;
; Spezial-Funktionen
;	01 .. 12	F1 .. F12		Auswahl der Text-Zeilen #1 .. #12
;	13		CR 			gehe zur naechsten Zeile
;	14		BCK / ENTF		1 Zeichen zurueck
;	15		SHIFT left/right	Klein/Gross-Buchstaben
;	16		ROLLEN			rollt die Laufschrift
;	17		ALT-GR			Umschaltung Sonderzeichen @{[]}~|\
;	18		POS1			Anfang der Zeine und Ruecksetzen Rollen
;	19		DRUCK Fx1 Fx2		Automatische Text-Anzeige #Fx(1)..#Fx(2)
;	20	 	NUM			Display: 1.normal/2.invers/3.blinken
;	21		PAUSE Fx		Auswahl des Textblocks Fx = F1..F8	
;	22		ENTER			loescht die aktuelle Text-Zeile
;	23		ESC			RTC-Steuerung
;	24		EINFG			Text-Eingabe ueber mehrere Zeilen
;  25   Bild oben			Umschaltung auf EN-Tastatur
;  26	  Bild unten			Umschaltung auf DE-Tastatur
;
;	TST_SER	Selektor Tastatur/Seriell
;	FIF_DTR	FIFO Data-ready (Eingang)
;	FLG_TXW	Bit fuer Text-Wechsel (gesetzt von Timer-1)
;	FLG_T12	Anzeige fuer 1./2. Texthaelfte (gesetzt von Timer-1)
;	FLG_INV	Indikator fuer inversen Display
;	PSW.5=F0	Flag fuer Text-Eingabe
;
; Abfrage, ob FIFO/Seriell aktiv oder Text-Wechsel (Timer-1)
txloop		jb	TST_SER,txlopt	; Selektor Tastatur/Seriell
		jnb	RI,txlop0	; SCON.0 receive interrupt flag ?
		sjmp	txlopr	
txlopt		jnb	FIF_DTR,txlop0	; FIFO ?
txlopr		mov	A,roltext
		jnb	NEGATIV,txlop4	; => kein Text-Wechsel
		acall	drukfres	;Reset Zeiger
		sjmp	txloop
; ===========RTC-Display
txlop0  	mov	A,roltext
		jnb	ACC.4,txlop1	; => kein RTC-Display
		clr	ACC.4
		mov	roltext,A
		jnb	ACC.3,txlop0a
		djnz	zeitdat,txlop0b	; zaehle 5 sec
		mov	zeitdat,#5
		mov	A,laufsft	; Auswahl Zeit / Datum
		jnz	txlop0a
		mov	laufsft,#60	; => Datum-Display
		sjmp	txlop0b
txlop0a 	mov	laufsft,#0
txlop0b 	acall	rtcdispl	; read RTC und Display
; ===========Text-Wechsel ?
txlop1  	jnb	FLG_TXW,txloop	; Text-Wechsel ?
		clr	FLG_TXW
		jb	FLG_T12,txlop2
		acall	display2	; 2. Texthaelfte
		acall	display3	; sende Text seriell
		sjmp	txloop
txlop2		mov	A,lastfct	; letzter Text
		cjne	A,atdspf2,txlop3	; = End-Text ?
		mov	lastfct,atdspf1	; Anfangs-Text #
		sjmp	txlop3a
txlop3  	inc	lastfct		; naechster Text
txlop3a 	mov	A,lastfct
		acall	eepinit0	; Auswahl der Texte nach F-Taste
		acall	eepinit1	; setze textwnd auf freies Zeichen
		acall	display1	; 1. Texthaelfte
		sjmp	txloop
;
;------------Funktionen ausfuehren -------------------------------------
; Zeichen von Tastatur/Seriell lesen und abfragen	
txlop4		acall	ztastser	;lies Zeichen von Tastatur/Seriell
		mov	scancod,A	;sichere Code
		jnz	testx0
; Text ausgeben Seriell
		acall	display3
		sjmp	txloop		; ignoriere Code=0
;-----	Funktionstasten F1..F12
testx0		clr	C
		subb	A,#13		;test nach F1..F12
		jnb	NEGATIV,testjmp	; => keine F-Taste
		mov	comdchar,scancod	; fuer Kommando Seriell
		acall	ftasten 	; Funktions-Tasten
		ajmp	txloop
;=====Sonder-Code-Bearbeitung
testjmp 	clr	C
		subb	A,#19
		jnb	NEGATIV,jmptexte	; Zeichen speichern
		mov	comdchar,scancod	; fuer Kommando Seriell
		add	A,#19
		rl	A
		mov	DPTR,#jmptable
		jmp	@A+DPTR
jmptable	ajmp	testx13	; Carriage-Return	
		ajmp	testx14	; =BCK? Backspace
		ajmp	testx15	; =SFT?
		ajmp	testx16 	; =ROL?
		ajmp	testx17	; =ALT-GR
		ajmp	testx18	; =POS1
		ajmp	testx19	; =DRUCK
		ajmp	testx20	; =NUM
		ajmp	testx21 	; =PAUSE
		ajmp	testx22	; =ENTER
		ajmp	testx23	; =ESC
		ajmp	testx24	; =EINFG
		ajmp	testx25	; =Bild oben
		ajmp	testx26	; =Bild unten
jmptexte	ajmp	testspz
;
;-----	/13/Carriage-Return --- gehe zur naechsten Zeile
testx13 	acall	crreturn	; Carriage-Return
		ajmp	txloop
;-----/14/Backspace-Taste: Text um 1 Zeichen kuerzen
testx14 	acall	backspc	; =BCK? Backspace
		ajmp	txloop
;-----/15/Shift-Taste
;		codesft.0 = Flag SHIFT
testx15 	mov	A,codesft	; =SFT?
		cpl	ACC.0
		mov	codesft,A
		ajmp	txloop		
;-----/16/Text Rollen
;		roltext.0 = Flag Text-Rollen
testx16 	mov	A,roltext	; =ROL?
		cpl	ACC.0
		mov	roltext,A
		ajmp	txloop
;-----/17/ALT-GR		Umschaltung Sonderzeichen @{[]}\~|
;		codesft.7 = Flag Sonderzeichen
testx17 	mov	A,codesft
		setb	NEGATIV
		mov	codesft,A
		ajmp	txloop
;-----/18/POS1		Stopp Rollen, Text-Display an den Anfang
testx18 	mov	roltext,#0
		mov	laufsft,#0
		mov	dispinv,#0
		ajmp	txloop
;-----/19/DRUCK Fx1 Fx2		Automatische Anzeige der Texte von Fx(1) bis Fx(2)
testx19 	acall	drucktxt	; Automatische Anzeige der Texte
	 	ajmp	txloop
;-----/20/NUM		Display: 1.normal/2.invers/3.blinken
testx20 	inc	dispinv
		mov	A,dispinv
		cjne	A,#3,testx9a
		mov	dispinv,#0
testx9a 	mov	blinknt,#8
		ajmp	txloop
;-----/21/PAUSE	Fx	Auswahl des Text-Blocks 0..7
testx21 	acall	pausetxt	; Text-Block
		ajmp	txloop
;-----/22/ENTER	loescht die aktuelle Text-Zeile
testx22 	acall	enterkey	; loesche Zeile
		ajmp	txloop
;-----/23/ESC	steuert die RTC
testx23 	acall	rtcsetzen	; steuere RTC
		mov	roltext,#020h
		jz	testxc1
		mov	roltext,#028h
testxc1 	mov	dispcyc,#16
		mov	zeitdat,#5
		mov	laufsft,#0
		acall	rtcdispl	; starte Display
		acall	rtcdseri	; sende RTC-Clock-Info seriell
		ajmp	txloop
;-----/24/EINFG	Text-Eingabe ueber mehrere Zeilen (ein/aus)
testx24 	jb	F0,testxd1	; PSW.5 Flag fuer Text-Eingabe
		acall	enterkey	; Textzeile loeschen
		mov	dispinv,#1	; Display invers
		sjmp	testxd2
testxd1 	mov	dispinv,#0	; Display normal
		mov	scancod,#1
		acall	ftasten	; letzte Text-Zeile abschliessen
testxd2 	cpl	F0		; PSW.5 Flag fuer Text-Eingabe
		ajmp	txloop
;-----/25/Bild-oben-Taste
;		codesft.3 = Flag Tastatur-Kode
testx25 	mov	A,codesft	; =Bild-oben?
		setb	ACC.3
		mov	codesft,A
		ajmp	txloop		
;-----/26/Bild-unten-Taste
testx26 	mov	A,codesft	; =Bild-unten?
		clr	ACC.3
		mov	codesft,A
		ajmp	txloop
;
;----- speichern der Zeichen im EEPROM + setze Display,
;	 Index=textwnd zeigt auf das naechste Zeichen
testspz 	mov	A,scancod
		acall	storchar	; Speichern des Zeichens
		ajmp	txloop
;
; ================== UNTERPROGRAMME ==========================
;
; ====== setze Tastatur (bei Interrupt OFF)
setztast	setb	TST_CLK		;Port TST_CLK als Eingang <= CLK
		setb	TST_DAT		;Port TST_DAT als Ausgang => DATA
		mov	A,#0EDh	;alle LEDs ein
		acall	tastsend
		mov	A,#007h	;
		acall	tastsend
		mov	A,#0F0h	;setze Scan-Code 3 (F0+F3)
		acall	tastsend
		mov	A,#003h
		acall	tastsend
		mov	A,#0F3h	;Tastatur-Wiederholung langsam (F3+7F)
		acall	tastsend
		mov	A,#07Fh	;
		acall	tastsend
;		mov	A,#0F9h	;keinen Break-Code fuer Shift
;		acall	tastsend
		ret
;
; ===========================================================
;
; Warte n Millisec, n in ACC
waittime	mov	thischar,#0
		mov	lastchar,A
waitx1		nop
		nop
		djnz	thischar,waitx1 	; 4 microsec * n
		djnz	lastchar,waitx1
		ret
;
; ===========================================================
;
;------Serielle Schnittstelle initialisieren
serialin	mov	SCON,#01010000b	; serial port mode: 8 Bit UART, REN=1
;	Auswahl der Baud-Rate ueber P3.2/P3.3, setze Timer-2
		mov	A,P3
		rr	A
		anl	A,#6		; (P3.2/P3.3)*2
		mov	DPTR,#baudtabl
		movc	A,@A+DPTR	; 1. Byte
		mov	RCAP2H,A
		mov	A,P3
		rr	A
		anl	A,#6		; (P3.2/P3.3)*2
		inc	DPTR
		movc	A,@A+DPTR	; 2. Byte
		mov	RCAP2L,A
		mov	T2CON,#00110100b	;T2CON.2/.4/.5=RCLK+TCLK+start T2
		mov	SBUF,#0		; Leerzeichen ausgeben
		ret
;
;-------------------------------------------------------------
;
;------Lies das naechste Zeichen von Tastatur oder von Seriell
ztastser	jnb	TST_SER,ztast1	; => Selektor Tastatur / Seriell
		acall	tastempf	; lies Scancode von Tastatur
		acall	convcode	; Konvertiere nach ASCII + Kommandos
		sjmp	ztastz
; Zeichen von Seriell
ztast1  	mov	A,lastchar	; noch ein Zeichen ausgeben?
		jz	ztast2
		mov	A,thischar	; letztes umkodiertes Zeichen
		sjmp	ztasty
ztast2  	acall	seriread	; Lies ASCII-Zeichen von seriell
		cjne	A,#023h,ztast3	; Kommando-Sequenz ? "#"
		mov	lastchar,A	; Kommando-Symbol
		acall	seriread	; lies naechstes Zeichen
		mov	thischar,A	; Steuer-Symmbol
		acall	convcomd	; Konvertiere Kommando
		cjne	A,thischar,ztasty	; Zeichen wurde umkodiert
		mov	A,lastchar
		sjmp	ztastz
ztast3 	cjne	A,#03Ah,ztasty	; Umlaute ? ":"
		mov	lastchar,A	; Kommando-Symbol
		acall	seriread	; lies naechstes Zeichen
		mov	thischar,A	; Steuer-Symmbol
		acall	coninuml	; Konvertiere Umlaute
		cjne	A,thischar,ztasty	; Zeichen wurde umkodiert
		mov	A,lastchar
		sjmp	ztastz
ztasty  	mov	lastchar,#0
ztastz  	ret
;
;---------------------------------------------------------------
;
;-----Starte den Display fuer LED-Array und Seriell
initdisp	mov	A,lastfct	
		acall	eepinit0	; Auswahl der Texte nach F-Taste
		acall	eepinit1	; setze textwnd auf freies Zeichen
	 	acall	display1	; Display der Zeichen
		acall	display2
		jb	F0,initdix	; PSW.5 keine Text-Ausgabe im mehrfach-Mode
		acall	display3	; sende Text seriell
initdix 	ret
;
;-----	Carriage-Return --- gehe zur naechsten Zeile
crreturn	mov	A,lastfct
		inc	A
		mov	scancod,A
		cjne	A,#13,crretx1
		mov	scancod,#1
crretx1 	sjmp	ftastx0
;
;-----	Funktionstasten F1..F12 - Auswahl der Text-Zeile #Fx
ftasten 	mov	A,scancod
		cjne	A,lastfct,ftastx0	; zuletzt genutzte F-Taste
		sjmp	ftastxx
ftastx0  	mov	A,lastfct
		acall	eepclose		; zuletzt genutzten Text beenden
		mov	lastfct,scancod	; neue F-Taste
	 	mov	A,lastfct
		jz	ftastxx
		acall	initdisp	; Starte den Display
		mov	roltext,#0
		mov	laufsft,#0
ftastxx 	ret
;
;---------------------------------------------------------------
;-----ENTER	loescht die aktuelle Text-Zeile
enterkey	mov	textwnd,#0
		mov	roltext,#0
		mov	laufsft,#0
		sjmp	backx1
;
;---------------------------------------------------------------
;-----	Backspace-Taste: Text um 1 Zeichen kuerzen
backspc 	mov	A,textwnd	;Text-Index
		jz	backsxx
		dec	textwnd	;index -1
backx1 	clr	A
		acall	eepwrit	;speichere NUL als Text-Ende
		dec	textwnd	;setze Index auf NUL-Zeichen
	 	acall	display1	;Display der Zeichen
		acall	display2
		jb	F0,backsxx	; keine Text-Ausgabe im mehrfach-Mode
		acall	display3	; sende Text seriell
backsxx 	ret
;
;---------------------------------------------------------------
;-----DRUCK	Fx1 Fx2	Automatische Anzeige der Text-Zeilen von Fx1..Fx2
drucktxt	mov	A,lastfct
		acall	eepclose	;letzt genutzten Text beenden
;	1. F-Taste lesen
		acall	ztastser	; Lies Zeichen
		jz	drukfres
		mov	scancod,A
		clr	C
		subb	A,#13		;test nach F1..F12
		jnb	NEGATIV,drukfres	; ==> Fehler
		mov	atdspf1,scancod	; Start-Text-#
;	2. F-Taste lesen
		acall	ztastser	; Lies Zeichen
		jz	drukfres
		mov	scancod,A
		clr	C
		subb	A,#13		;test nach F1..F12
		jnb	NEGATIV,drukfres	; ==> Fehler
		mov	atdspf2,scancod	; Stopp-Text-#
;	Test, ob F2 >= F1
		mov	A,atdspf2
		clr	C
		subb	A,atdspf1	; F2 < F1 ?
		jb	NEGATIV,drukfres	; ==> Fehler
;	starte automatische Anzeige
		mov	lastfct,atdspf1
		acall	initdisp	;Starte den Display
		mov	roltext,#080h	; => Start autom. Text-Anzeige
		sjmp	druckxx		; ==> Start
;	Reset Werte: 2. Eingang zu drukftxt
drukfres	mov	laufsft,#0	; Pixel-shift
		mov	roltext,#0	; Text-Roll-Indikator
		mov	atdspf1,#0	; Start-Fx
		mov	atdspf2,#0	; Stopp-Fx
druckxx 	ret
;
;---------------------------------------------------------------
;-----PAUSE	Fx	Auswahl des Text-Blocks 0..7
pausetxt	mov	A,lastfct
		acall	eepclose	;letzt genutzten Text beenden
		acall	ztastser	; lies Zeichen
		jz	pausexx
		clr	C
		subb	A,#9		; Test 1..8
		jnb	NEGATIV,pausexx
		add	A,#8	
		anl	A,#7	
		mov	textsel,A	; Block-#
		mov	lastfct,#1
		mov	laufsft,#0	; Pixel-shift
		mov	roltext,#0	; Text-Roll-Indikator
		acall	initdisp	;Starte den Display
pausexx	ret
;
;---------------------------------------------------------------
;----- speichern der Zeichen im EEPROM + setze Display,
;	 Index=textwnd zeigt auf das naechste Zeichen
storchar	acall	codealtg	; Sonderzeichen
		mov	A,scancod	;hole Code
		acall	eepwrit	;speichere Zeichen (textwnd)
;	Umschalten auf naechste Zeile + loeschen, wenn Eingabe mehrzeilig
		jnb	F0,storcx1	; PSW.5=F0 Flag Text-Eingabe
		mov	A,textwnd
		cjne	A,#20,storcx1	; Zeile voll?
;		acall	display3	; Ausgabe Seriell
		acall	crreturn	; neue Zeile (Fx+1)
		acall	enterkey	; Zeile loeschen
;	verschiebe den Text bei mehr als 9 Zeichen
storcx1	mov	A,textwnd
		clr	C
		subb	A,#9
		jb	NEGATIV,storcxx
		mov	B,#6
		mul	AB
		mov	laufsft,A
		mov	roltext,#0
storcxx 	acall	display1	;Display der Zeichen
		acall	display2
;		acall	display3	; sende Text seriell
		ret
;
; ===========================================================
;
;fuelle Anfangs-Text in das EEPROM
anftext 	mov	DPTR,#startext
		mov	A,textwnd	;index im EEPROM-Puffer
		movc	A,@A+DPTR
		acall	eepwrit	; => EEPROM
		mov	A,textwnd
		cjne	A,#20,anftext
		ret
;
; ===========================================================
;
; Konvertierung des Tastatur-Codes => ASCII
;	Code in ACC, return mit ASCII-Zeichen in ACC
;	scancod	Code von der Tastatur
;	codesft.0	Indikator fuer Shift-Key 0..1
;	codesft.3	Indikator fuer Tastatur EN/DE
convcode	mov	scancod,A	;sichere Code
		cjne	A,#084h,convx1	;Nb8
		mov	A,#02Dh		;"-"
		sjmp	convxx
convx1		anl	A,#080h	; code>=128 ?
		jz	convx2
		clr	A
		sjmp	convxx
convx2		mov	A,codesft
		jb	ACC.3,convx3	; Tastatur-Kode = EN
		mov	DPTR,#tastasc		;Kodier-Tabelle DE
		sjmp	convx4
convx3		mov	DPTR,#keybasc		;Kodier-Tabelle EN
convx4		mov	A,codesft	;SHIFT?
		rrc	A
		mov	A,scancod
		rlc	A		;scancode*2+shift
		movc	A,@A+DPTR	;Code = tastasc[scancode*2+shift]
convxx		ret
;
; ===========================================================
;
; Umkodierung ALT-GR	Umschaltung Sonderzeichen @{[]}~|\
;	Zeichen in scancod => neues Zeichen in scancod
;	codesft.7	Indikator fuer ALT-GR
codealtg	mov	A,codesft		;ALT-GR ?
		jnb	NEGATIV,codeaxy
		clr	NEGATIV
		mov	codesft,A
		mov	A,scancod
		cjne	A,#071h,codeax1	; q
		mov	A,#040h		; @
		sjmp	codeaxx
codeax1 	cjne	A,#037h,codeax2	; 7
		mov	A,#07Bh		; {
		sjmp	codeaxx
codeax2 	cjne	A,#038h,codeax3	; 8
		mov	A,#05Bh		; [
		sjmp	codeaxx
codeax3 	cjne	A,#039h,codeax4	; 9
		mov	A,#05Dh		; ]
		sjmp	codeaxx
codeax4 	cjne	A,#030h,codeax5	; 0
		mov	A,#07Dh		; }
		sjmp	codeaxx
codeax5 	cjne	A,#02Bh,codeax6	; +
		mov	A,#07Eh		; ~
		sjmp	codeaxx
codeax6 	cjne	A,#03Ch,codeax7	; <
		mov	A,#07Ch		; |
		sjmp	codeaxx
codeax7 	cjne	A,#081h,codeaxx	; ß
		mov	A,#05Ch		; \
codeaxx 	mov	scancod,A
codeaxy 	ret	
;
; ===========================================================
;
; Berechne Parity des Data-Byte, Zeichen in ACC
;	tparity	Parity-Bit
;	tbitcnt	Bit-Zaehler
calcpar 	mov	tbitcnt,#8
		mov	tparity,#0
calcx1		rrc	A
		jnc	calcx2
		inc	tparity		;zaehle gesetzte Bits
calcx2		djnz	tbitcnt,calcx1
		inc	tparity		;Anzahl gerade/ungerade
		ret
;
; Warte auf Daten im FIFO, Daten-Bit => C
waitdata	nop
		jnb	FIF_DTR,waitdata	;Data-ready?
		mov	C,FIF_DAT		;hole Daten-Bit
		clr	FIF_SFT		;SHIFT-OUT-Puls
		setb	FIF_SFT
		ret
;
;---------------------------------------------------------------
;
; sende Zeichen in ACC direkt an die Tastatur
;	tasdata	Data-Byte
;	tparity	Parity-Bit
;	tbitcnt	Bit-Zaehler
;	TST_DAT	Tastatur DATA
;	TST_CLK	Tastatur CLOCK
;	gesendete Sequenz, Bit wird uebernommen bei Tastatur-CLK ^
;	0bit  bit0 bit1 bit2 bit3 bit4 bit5 bit6 bit7 prty stop
tastsend	mov	tasdata,A	;sichere Zeichen
		acall	calcpar	;berechne Parity in tparity
		clr	TST_DAT		;Port TST_DAT sende 0
		mov	tbitcnt,#8
tastsx0 	jb	TST_CLK,$		;===CLK-v ==> Start-Bit
		mov	A,tasdata	;Data-Byte
		rrc	A		;unteres Daten-Bit >= C
		mov	TST_DAT,C		;C => Tastatur-DATA
		mov	tasdata,A
		jnb	TST_CLK,$		;===CLK-^
		djnz	tbitcnt,tastsx0	;naechster Zyklus
		jb	TST_CLK,$		;===CLK-v 
		mov	A,tparity	;Parity-Bit
		rrc	A		;=> C
		mov	TST_DAT,C		;C => Tastatur-DATA
		jnb	TST_CLK,$		;===CLK-^
		jb	TST_CLK,$		;===CLK-v
		setb	TST_DAT		;Port TST_DAT als Ausgang => DATA
		jnb	TST_CLK,$		;===CLK-^
		mov	A,#50	
		acall	waittime	;warte 50 Millisec
		ret
;
; ===========================================================
;
; lies Zeichen von der Tastatur ueber ein FIFO => ACC
;	tasdata	Data-Byte
;	tbitcnt	Bit-Zaehler
;	FIF_DAT	FIFO Data (Eingang)
;	FIF_SFT	FIFO Shift-out (Ausgang)		FLASH-Prog. MOSI
;	FIF_DTR	FIFO Data-ready (Eingang)		FLASH-Prog. MISO
;	FIF_ENB	FIFO Enable (Ausgang)		FLASH-Prog. SCK
;	gesendete Sequenz, Bit wird uebernommen bei Data-ready
;	sbit  bit0 bit1 bit2 bit3 bit4 bit5 bit6 bit7 prty stop
tastempf	clr	FIF_ENB		;FIFO Enable (Ausgang)
		setb	FIF_SFT		;FIFO Shift-out (Ausgang)
		setb	FIF_DAT		;FIFO Data (Eingang)
;		setb	FIF_DTR		;FIFO Data-ready (Eingang)
		acall	waitdata	;===CLK ==> Start-Bit
		mov	tbitcnt,#8	; => 8 Daten-Bits
tastex1 	acall	waitdata	;===CLK
		mov	A,tasdata
		rrc	A
		mov	tasdata,A	;schiebe Datenbit => Byte
		djnz	tbitcnt,tastex1	;naechster Zyklus
		mov	tbitcnt,#2	; => Parity- und Stop-Bit
tastex3 	acall	waitdata	;===CLK, ignoriere Bits Parity/stop
		djnz	tbitcnt,tastex3	;naechster Zyklus
		mov	A,tasdata
		ret
;
; ===========================================================
;
; initalisiere die EEPROM-Pointer, # der Text-Zeile im ACC
; Im Spezial-Register WMCON [96h] sind die EEPROM-Steuer-Bits.
; Text wird im EEPROM gespeichert als:
;	max. 20 Zeichen, Textende mit NUL
; Tasten F1..F12 (1..12) waehlen den entsprechenden Text aus.
; 12 * 21 Zeichen => 252 Zeichen gesamt
;	textrnd	00..19	Index fuer den Text-lesen
;	textwnd	00..19	Index fuer den Text-schreiben
;	textadr	Start-Adresse des Textes im EEPROM
;	textbyt	zu schreibendes Byte
eepinit0 	dec	A		; F-Taste -1
		jnb	NEGATIV,eepint1
		clr	A
eepint1 	mov	B,#21
		mul	AB		;Index * 21
		mov	textadr,A	;Start-Adresse
		mov	textrnd,#0	;Text-Index lesen
		mov	textwnd,#0	;Text-Index schreiben
		ret
;
;setze Zeiger fuer textwnd auf das naechste freie Zeichen
eepinit1	nop
eepix1		acall	eepread	;lies Zeichen aus EEPROM(textrnd)
		jz	eepix2		;Text ist zuende (NUL)
		cpl	A	
		jnz	eepix3		;Text mit FF ueberschreiben mit NUL
		dec	textrnd
		mov	textwnd,textrnd
		clr	A
		acall	eepwrit	;ueberschreibe mit NUL EEPROM(textwnd)
eepix2		dec	textrnd
		sjmp	eepix4
eepix3		mov	A,textrnd
		cjne	A,#20,eepix1	;teste naechstes Zeichen
		mov	textwnd,textrnd	;Textfeld ist zuende, schreibe NUL
		clr	A
		acall	eepwrit	;ueberschreibe mit NUL EEPROM(textwnd)
eepix4		mov	textwnd,textrnd
		mov	textrnd,#0	;Text-Index EEPROM-lesen	
		ret
;
;Text im EEPROM abschliessen, F-Taste im ACC
;	textwnd zeigt auf das naechste Zeichen
eepclose	jz	eepclx1	; F-Taste = 0
		mov	textrnd,textwnd
		acall	eepread	; lies Zeichen, test ob NUL
		jz	eepclx1
		clr	A
		acall	eepwrit	;schreibe NUL
eepclx1 	ret
;
; ===========================================================
;
; lese das naechste Byte aus dem EEPROM in den ACC
;	textrnd	00..19	Index fuer den Text-lesen
;	textadr	Start-Adresse des Textes im EEPROM
;	textbyt	gelesenes Byte
eepread 	mov	WMCON,#00001000b	;enable EEPROM access
		mov	DPH,textsel		; <= Textblock
		mov	A,textrnd
		add	A,textadr
		mov	DPL,A		;lower Byte of DPTR
		movx	A,@DPTR	; hole Byte
		mov	textbyt,A
		mov	A,textrnd	;teste Index auf Ueberlauf
		cjne	A,#20,eeprx1
		mov	textbyt,#0
		sjmp	eeprx2
eeprx1		inc	textrnd	;Text-Index +1
eeprx2		mov	WMCON,#0
		mov	A,textbyt	;gelesenes Zeichen
		ret
;
; ===========================================================
;
; schreibe das naechste Byte im ACC in das EEPROM
;	textwnd	00..19	Index fuer den Text-schreiben
;	textadr	Start-Adresse des Textes im EEPROM
;	textbyt	zu schreibendes Byte
eepwrit 	mov	textbyt,A	;speichere Byte
		mov	WMCON,#00011000b	;enable EEPROM access + writing
		mov	DPH,textsel		; <= Textblock
		mov	A,textwnd
		add	A,textadr
		mov	DPL,A		;lower Byte of DPTR
		mov	A,textwnd	;teste Index auf Ueberlauf
		cjne	A,#20,eepwx0
		sjmp	eepwx2
eepwx0		mov	A,textbyt	;Byte
		movx	@DPTR,A		;schreibe Byte
eepwx1		mov	A,WMCON		; warten auf Ende des Schreibens
		anl	A,#00000010b	;Test auf RDY=1
		jz	eepwx1
		inc	textwnd		;Text-Index +1
eepwx2		mov	WMCON,#0
		ret
;
; ===========================================================
;
;------Einstellen der RTC
; Sequenz:	ESC Fx ZW EW 
;		ESC ESC		Display Zeit/Datum alle 5 sec	
rtcsetzen	nop
; F-Taste lesen
		acall	ztastser	; lies Zeichen
		jz	rtcerror
		cjne	A,#23,rtcset1	; = ESC ?
		sjmp	rtcexit
rtcset1	clr	C
		subb	A,#8		; Test nach F1..F7
		jnb	NEGATIV,rtcerror
		add	A,#7
		mov	rtcdata,A	; Fx-1 => rtcdata
; 1. Ziffer lesen
		acall	ztastser	; lies Zeichen
		clr	C
		subb	A,#030h	; Test nach "0"
		jb	NEGATIV,rtcerror
		clr	C
		subb	A,#10		; Test nach "9"
		jnb	NEGATIV,rtcerror
		add	a,#10
		swap	A
		mov	rtcvalu,A	; Zehner-Ziffer
; 2. Ziffer lesen
		acall	ztastser	; lies Zeichen
		clr	C
		subb	A,#030h	; Test nach "0"
		jb	NEGATIV,rtcerror
		clr	C
		subb	A,#10		; Test nach "9"
		jnb	NEGATIV,rtcerror
		add	a,#10
		orl	A,rtcvalu	; + Einer-Ziffer
; schreibe Wert in die RTC
		mov	rtcvalu,A
		mov	A,rtcdata	; Adresse in der RTC
		acall	rtcwrite
; starte RTC-Display
rtcerror	clr	A
rtcexit	ret
;
;-------------------------------------------------------------
;
;------Display Datum und Uhrzeit
;	Format: " hh:mm:ss " und "dd.mm.20jj"
rtcdispl	mov	textrnd,#0
		mov	dispmax,#20
		mov	R1,#laufsta
; Uhrzeit im Format: " hh:mm:ss "
		mov	A,#020h
		acall	dispimag	; " "
		mov	A,#2
		acall	rtcdigit	; <= hh
		mov	A,#03Ah
		acall	dispimag	; ":"
		mov	A,#1
		acall	rtcdigit	; <= mm
		mov	A,#03Ah
		acall	dispimag	; ":"
		mov	A,#0
		acall	rtcdigit	; <= ss
		mov	A,#020h
		acall	dispimag	; " "
; Datum im Format:  "dd.mm.20jj"
		mov	A,#3
		acall	rtcdigit	; <= dd
		mov	A,#02Eh
		acall	dispimag	; "."
		mov	A,#4
		acall	rtcdigit	; <= mm
		mov	A,#02Eh
		acall	dispimag	; "."
		mov	A,#032h
		acall	dispimag	; "2"
		mov	A,#030h
		acall	dispimag	; "0"
		mov	A,#6
		acall	rtcdigit	; <= jj
		ret
;-------------------------------------------------------------
;
; Display Zehner- und Einer-Stelle der RTC
rtcdigit	acall	rtcread	; lies Wert, Adresse im ACC und rtcvalu
		swap	A
		anl	A,#00Fh
		orl	A,#030h
		acall	dispimag	; Zehner-Stelle
		mov	A,rtcvalu
		anl	A,#00Fh
		orl	A,#030h
		acall	dispimag	; Einer-Stelle
		ret
;
; ===========================================================
;
; Fuelle den Display-Puffer mit dem Zeichen-Image des Zeichens im ACC
; 	Zeichen=0	fuelle SPACE
;	Zeichen=80h	setze MARK und fuelle SPACE
;	dispchr		ASCII-Wert
;	dispcnt		Zaehler
dispimag	jz	dispim1		; fuelle SPACE
		jnb	NEGATIV,dispim2		; test auf MARK
		anl	A,#07Fh
		jnz	dispim2		; Umlaute
; setze MARK
		mov	A,R1
		cjne	A,#laufsta,dispim0	; am Anfang?
		sjmp	dispim1
dispim0 	mov	A,#1
		dec	R1
		mov	@R1,A		; MARK => Display-Puffer
		inc	R1
; fuelle Display mit SPACE	
dispim1 	clr	A
		sjmp	dispspc
; Auswahl der Image-Tabelle
dispim2 	mov	dispchr,A
		clr	C
		subb	A,#32
		jnb	NEGATIV,dispim3		; ASCII < 32 ?
		add	A,#32
dispspc 	mov	dispchr,A
		mov	DPTR,#charimg0	; = Tabelle 0 (Umlaute)
		sjmp	dispimt
dispim3 	clr	C
		subb	A,#32
		jnb	NEGATIV,dispim4		; ASCII < 64 ?
		add	A,#32
 		mov	dispchr,A
		mov	DPTR,#charimg1	; = Tabelle 1
		sjmp	dispimt
dispim4 	clr	C
		subb	A,#32
		jnb	NEGATIV,dispim5		; ASCII < 96 ?
		add	A,#32
		mov	dispchr,A
		mov	DPTR,#charimg2	; = Tabelle 2
		sjmp	dispimt
dispim5 	mov	dispchr,A
		mov	DPTR,#charimg3	; = Tabelle 3
; lies Zeichen-Image aus Tabelle
dispimt 	mov	dispcnt,#5	;Stellen-Zaehler
		mov	B,#5
		mul	AB
		mov	dispchr,A	;=>Index in Tabelle
dispim6 	mov	A,dispchr
		movc	A,@A+DPTR	;Zeichen aus Tabelle
		mov	@R1,A		;=> Display-Puffer
		inc	R1
		inc	dispchr
		djnz	dispcnt,dispim6	;zaehle Stellen
; Trennspalte
		clr	A
		mov	@R1,A		; NUL => display-Puffer
		inc	R1 
		ret
;
; ===========================================================
;
; Display Zeichen aus dem Text-Puffer.
; eepinit hatte vorher die Zeiger gesetzt.
;	textadr	Start-Adresse des Textes im EEPROM, Ende durch NUL
;	R1		Zeiger im Display-Puffer
;	dispchr	ASCII-Wert
;	dispcnt	Zaehler
;	dispmax	max. Index fuer Zeichen
;	wenn	textrnd < textwnd:	Zeichen uebernehmen
;	wenn	textrnd = textwnd:	MARK+SPACE
;	wenn	textrnd > textwnd:	SPACE
display1 	mov	textrnd,#0	;Index=0
		mov	R1,#laufsta	;Zeiger im Display-Puffer
		mov	dispmax,#10
		sjmp	dispx0
;	Eingang fuer den Display der 2. Haelfte
display2	mov	dispmax,#20
;	Schleife fuer textrnd = 0..9 oder textrnd = 10..19
dispx0		mov	A,textrnd	; Zeichen-Index
		cjne	A,dispmax,dispx1
		sjmp	dispend
dispx1  	cjne	A,textwnd,dispx2	;Text zuende?
		mov	A,#080h	;	MARK+SPACE
		sjmp	dispx3
dispx2  	jc	dispx4
		mov	A,#0		; 	SPACE
dispx3	 	inc	textrnd
		sjmp	dispx5	 	
dispx4	 	acall	eepread	;holt naechstes ASCII-Zeichen, setzt textrnd
dispx5		acall	dispimag	; speichere Image im Display-Puffer
		sjmp	dispx0		;naechstes Zeichen
dispend 	ret
;
;=====sende den angewaehlten Text nach Seriell
display3	jb	TST_SER,dispsx	; Selektor Tastatur/Seriell
		mov	A,tparity	; letztes Zeichen = LF ?
		cjne	A,#00Ah,dispcrlf
		sjmp	disptlc
dispcrlf	acall	serwcrlf	; CR/LF seriell
; Ausgabe von textsel, lastfct und comdchar
disptlc	acall	dispstlc
; Ausgabe der Text-Zeile		
		mov	textrnd,#0	;Index=0
disps0		mov	A,textrnd	; Zeichen-Index
		cjne	A,textwnd,disps1
		sjmp	disps3
disps1  	acall	eepread	;holt naechstes ASCII-Zeichen, setzt textrnd
		jz	disps3		; = NUL
		cpl	A
		jz	disps3		; = FF
		cpl	A
		jnb	NEGATIV,disps2	; Umlaute ?
		mov	dispchr,A
		mov	A,#03Ah	; ":"
		acall	serwrite	; sende Zeichen Seriell
		mov	A,dispchr
		acall	conutuml	; Ersatz-Darstellung		
disps2		acall	serwrite	; sende Zeichen Seriell
		sjmp	disps0
disps3		acall	serwcrlf	; CR/LF seriell
dispsx		ret
;
; Ausgabe von textsel, lastfct und comdchar
dispstlc	mov	A,textsel
		inc	A
		orl	A,#030h
		acall	serwrite
		mov	A,lastfct
		clr	C
		subb	A,#00Ah
		jb	NEGATIV,dispsf
		add	A,#007h
dispsf		add	A,#03Ah
		acall	serwrite
		jnb	F0,dispsg	; Text-Eingabe mehrzeilig ?
		mov	comdchar,#24
dispsg		mov	A,comdchar
		mov	DPTR,#comdtabl
		movc	A,@A+DPTR
		acall	serwrite
		mov	A,#03Eh	; ">"
		acall	serwrite
		ret
;
; =========================================================================
;
;erzeugt das Kommando-Byte fuer die RTC 
; (WR=0/RD=1 in bit#0 and REG=1/CLK=0 in bit#6) 
; Register-# im ACC, R/W in C
;	RTC_IOL	RTC input/output-line
;	RTC_CLK	RTC clock output
;	RTC_RES	RTC reset
rtcpinit	clr	RTC_RES		; RTC-reset
		clr	RTC_CLK		; => RTC-clock
		anl	A,#01Fh
		rlc	A		; R/W-Bit aus C
		orl	A,#080h 	;setze Bits #6 + #7
		mov	rtcdata,A	;=> Kommando
		setb	RTC_RES		; enable RTC
		ret
;
;------------schiebe Datenbyte in die RTC mit clock-puls, Byte in rtcdata
rtcwbyte	mov	rtcount,#8
		mov	A,rtcdata
rtcwbyt1	clr	RTC_CLK		; => RTC_CLK =0
		rrc	A		; bit0 => C
		mov	RTC_IOL,C		; => RTC_DATA
		nop
		setb	RTC_CLK		; => RTC_CLK =1 strobe
		djnz	rtcount,rtcwbyt1
		ret
;
;------------lies Data-byte von der RTC mit clock-pulse, Byte in rtcvalu
rtcrbyte	setb	RTC_IOL		; => RTC_DATA Start-Bit
		mov	rtcount,#8
		sjmp	rtcrbyt2
rtcrbyt1	setb	RTC_CLK		; => RTC_CLK =1 
		nop
rtcrbyt2	clr	RTC_CLK		; => RTC_CLK =0 strobe Data
		nop
		mov	C,RTC_IOL		; RTC_DATA => C
		rrc	A
		djnz	rtcount,rtcrbyt1
		ret
;
;------schreibe Byte in rtcvalu nach RTC-Adresse in ACC
rtcwrite	clr	C		; C=0 => write
		acall	rtcpinit	; erzeuge Kommando
		acall	rtcwbyte	; schreibe Kommando
		mov	rtcdata,rtcvalu
		acall	rtcwbyte	; schreibe Daten		
		clr	RTC_CLK
		clr	RTC_RES
		ret
;
;------lies Byte nach rtcvalu von RTA-Adresse in ACC
rtcread 	setb	C		; C=1 => read
		acall	rtcpinit	; erzeuge Kommando
		acall	rtcwbyte	; schreibe Kommando
		acall	rtcrbyte	; lies Daten
		mov	rtcvalu,A
		clr	RTC_RES
		ret
;
;------------Starte die RTC:  WP => #7 und TRICKLE-ENBLE => #8
rtcenabl	mov	rtcvalu,#0
		mov	A,#07
		acall	rtcwrite	;enable WP => #7
		mov	rtcvalu,#0A5h
		mov	A,#08
		acall	rtcwrite	;TRICKLE-ENABLE => #8
		ret		
;
; =========================================================================
;
;------Zeichen lesen seriell => ACC + local-Echo
seriread	jnb	RI,$	; SCON.0 receive interrupt flag ?
		clr	RI
		mov	A,SBUF		; lade Zeichen
		mov	scancod,A
		jb	NEGATIV,serire1	; ASCII-Code > 127 ignorieren
		clr	C
		subb	A,#32		; ASCII-Code < 32 ignorieren
		jnb	NEGATIV,serire2
serire1 	mov	scancod,#0
serire2 	mov	A,scancod
		jz	serire3
		acall	serwrite	; local-Echo des Zeichens
serire3	jnz	serire4
		acall	serwcrlf	; CR/LF seriell
		mov	A,scancod
serire4 	ret
;
;------Zeichen im ACC ausgeben seriell
serwrite	jnb	TI,$		; SCON.1 transmit interrupt flag ?
		clr	TI
		mov	SBUF,A		; Zeichen ausgeben
		mov	tparity,A
		ret
;
;------CR/LF seriell ausgeben
serwcrlf	mov	A,#00Dh		; CR
		acall	serwrite
		mov	A,#00Ah		; LF
		acall	serwrite
		ret
;
;------Kommandos in ACC von serieller Schnittstelle konvertieren
convcomd	clr	C
		subb	A,#32	
	 	mov	DPTR,#funkcode	;Kodier-Tabelle
		movc	A,@A+DPTR		; code = ascomnd[ASCII-32]
		ret
;
; Zeichen  Ersatz  interner
;  Kode     Wert    Kode 
;	"ß" =  :s =  081h
;	"ä" =  :a =  082h
;	"Ä" =  :A =  083h
;	"ö" =  :o =  084h
;	"Ö" =  :O =  085h
;	"ü" =  :u =  086h
;	"Ü" =  :U =  087h
;
;------Konvertiere Ersatz-Darstellung Eingabe Seriell
coninuml	cjne	A,#073h,coninu1	; "s"
		mov	A,#081h
		sjmp	coninxx
coninu1 	cjne	A,#061h,coninu2	; "a"
		mov	A,#082h
		sjmp	coninxx
coninu2 	cjne	A,#041h,coninu3	; "A"
		mov	A,#083h
		sjmp	coninxx
coninu3 	cjne	A,#06Fh,coninu4	; "o"
		mov	A,#084h
		sjmp	coninxx
coninu4 	cjne	A,#04Fh,coninu5	; "O"
		mov	A,#085h
		sjmp	coninxx
coninu5 	cjne	A,#075h,coninu6	; "u"
		mov	A,#086h
		sjmp	coninxx
coninu6 	cjne	A,#055h,coninxx	; "U"
		mov	A,#087h
		sjmp	coninxx
coninxx 	ret
;
;------Konvertiere Ersatz-Darstellung Ausgabe Seriell
conutuml	anl	A,#007h
		mov	DPTR,#tableuml
		movc	A,@A+DPTR
		ret
;
;------Sende seriell Datum und Uhrzeit
;	Format: " hh:mm:ss " und "dd.mm.20jj"
rtcdseri	jb	TST_SER,rtcdsxx	; Selektor Tastatur/Seriell
; Ausgabe von textsel, lastfct und comdchar
		acall	dispstlc
; Ausgabe des Datums und der Uhrzeit
		mov	A,#020h
		acall	serwrite	; " "
		mov	A,#2
		acall	rtcdconv	; <= hh
		mov	A,#03Ah
		acall	serwrite	; ":"
		mov	A,#1
		acall	rtcdconv	; <= mm
		mov	A,#03Ah
		acall	serwrite	; ":"
		mov	A,#0
		acall	rtcdconv	; <= ss
		mov	A,#020h
		acall	serwrite	; " "
; Datum im Format:  "dd.mm.20jj"
		mov	A,#3
		acall	rtcdconv	; <= dd
		mov	A,#02Eh
		acall	serwrite	; "."
		mov	A,#4
		acall	rtcdconv	; <= mm
		mov	A,#02Eh
		acall	serwrite	; "."
		mov	A,#032h
		acall	serwrite	; "2"
		mov	A,#030h
		acall	serwrite	; "0"
		mov	A,#6
		acall	rtcdconv	; <= jj
		acall	serwcrlf	; CR/LF seriell
rtcdsxx	ret
;-------------------------------------------------------------
;
; Sende seriell Zehner- und Einer-Stelle der RTC
rtcdconv	acall	rtcread	; lies Wert, Adresse im ACC und rtcvalu
		swap	A
		anl	A,#00Fh
		orl	A,#030h
		acall	serwrite	; Zehner-Stelle
		mov	A,rtcvalu
		anl	A,#00Fh
		orl	A,#030h
		acall	serwrite	; Einer-Stelle
		ret
;
; =========================================================================
;
; Tabelle fuer Umlaute
tableuml	.byte	" ","s","a","A","o","O","u","U"
		.byte "W. Waetzig: RTC SER KEY 07-2003"
;
; Tabelle fuer Werte der Baud-Raten
baudtabl	.byte	0F7h,000h	;150 Baud
		.byte	0FBh,080h	;300 Baud
		.byte	0FDh,0C0h	;600 Baud
		.byte	0FEh,0E0h	;1200 Baud
		.byte	0FFh,070h	;2400 Baud
		.byte	0FFh,0B8h	;4800 Baud
		.byte	0FFh,0DCh	;9600 Baud
;
; Umkodierung vom Tastatur-Code => ASCII
; Tastenbelegung nach deutscher Tastatur DE
; Spezial-Funktionen
;	01 .. 12	F1 .. F12		Auswahl der Text-Zeilen #1 .. #12
;	13		CR 			gehe zur naechsten Zeile
;	14		BCK / ENTF		1 Zeichen zurueck
;	15		SHIFT left/right	Klein/Gross-Buchstaben
;	16		ROLLEN			rollt die Laufschrift
;	17		ALT-GR			Umschaltung Sonderzeichen @{[]}~|\
;	18		POS1			Anfang der Zeile und Ruecksetzen Rollen
;	19		DRUCK Fx1 Fx2		Automatische Text-Anzeige #Fx(1)..#Fx(2)
;	20		NUM			Display invers/blinken
;	21		PAUSE Fx		Auswahl des Textblocks Fx = F1..F8	
;	22		ENTER			loescht die aktuelle Text-Zeile
;	23		ESC			RTC-Steuerung
;	24		EINFG			Text-Eingabe mehrzeilig
;	25		Bild oben		EN-Tastatur
;	26		Bild unten		DE-Tastatur
tastasc:		
;	00	nul,nul,nul,nul,nul,nul,nul,nul,nul,nul,nul,nul,nul,nul,f1 ,f1,
	.byte	000,000,000,000,000,000,000,000,000,000,000,000,000,000,001,001
;	08	esc,esc,nul,nul,nul,nul,nul,nul,nul,nul,tab,tab,"^","°",f2 ,f2
	.byte	023,023,000,000,000,000,000,000,000,000," "," ","^",27h,002,002
;	10	nul,nul,stl,stl,shl,shl,"<",">",cpl,cpl,"q","Q","1","!",f3 ,f3
	.byte	000,000,000,000,015,015,"<",">",000,000,"q","Q","1","!",003,003
;	18	nul,nul,alt,alt,"y","Y","s","S","a","A","w","W","2",""",f4 ,f4,
	.byte	000,000,000,000,"y","Y","s","S","a","A","w","W","2",22h,004,004
;	20	nul,nul,"c","C","x","X","d","D","e","E","4","$","3","§",f5 ,f5,
	.byte	000,000,"c","C","x","X","d","D","e","E","4","$","3",000,005,005
;	28	nul,nul,spc,spc,"v","V","f","F","t","T","r","R","5","%",f6 ,f6
	.byte	000,000," "," ","v","V","f","F","t","T","r","R","5",25h,006,006
;	30	nul,nul,"n","N","b","B","h","H","g","G","z","Z","6","&",f7 ,f7,
	.byte	000,000,"n","N","b","B","h","H","g","G","z","Z","6","&",007,007
;	38	nul,nul,alg,alg,"m","M","j","J","u","U","7","/","8","(",f8 ,f8,
	.byte	000,000,017,017,"m","M","j","J","u","U","7","/","8","(",008,008
;	40	nul,nul,",",";","k","K","i","I","o","O","0","=","9",")",f9 ,f9,
	.byte	000,000,",",";","k","K","i","I","o","O","0","=","9",")",009,009
;	48	nul,nul,".",":","-","_","l","L","ö","Ö","p","P","ß","?",f10,f10,
	.byte	000,000,".",":","-","_","l","L",84h,85h,"p","P",81h,"?",010,010
;	50	nul,nul,nul,nul,"ä","Ä","#","'","ü","Ü","´","`",f11,f11,drk,drk,
	.byte	000,000,000,000,82h,83h,23h,27h,86h,87h,27h,27h,011,011,019,019
;	58	nul,nul,shr,shr,ret,ret,"+","*",nul,nul,nul,nul,f12,f12,rol,rol,
	.byte	000,000,015,015,013,013,"+","*",000,000,000,000,012,012,016,016
;	60	cdn,cdn,cl ,cl ,pau,pau,cup,cup,etf,etf,end,end,bck,bck,enf,enf,
	.byte	000,000,000,000,021,021,000,000,014,014,000,000,014,014,024,024
;	68	nul,nul,1n ,1n ,cr ,cr ,4n ,4n ,7n ,7n ,bdn,bdn,ps1,ps1,bup,bup
	.byte	000,000,"1","1",013,013,"4","4","7","7",026,026,018,018,025,025
;	70	0n ,0n ,efn,efn,2n ,2n ,5n ,5n ,6n ,6n ,8n ,8n ,num,num,/n ,/n ,
	.byte	"0","0",",",",","2","2","5","5","6","6","8","8",020,020,"/","/"
;	78	nul,nul,ent,ent,3n ,3n ,nul,nul,+n ,+n ,9n ,9n ,*n ,*n ,nul,nul,
	.byte	000,000,022,022,"3","3",000,000,"+","+","9","9","*","*",000,000
;
; Umkodierung vom Tastatur-Code => ASCII
; Tastenbelegung nach englischer (US) Tastatur EN
keybasc:		
;	00	nul,nul,nul,nul,nul,nul,nul,nul,nul,nul,nul,nul,nul,nul,f1 ,f1,
	.byte	000,000,000,000,000,000,000,000,000,000,000,000,000,000,001,001
;	08	esc,esc,nul,nul,nul,nul,nul,nul,nul,nul,tab,tab,"'","~",f2 ,f2
	.byte	023,023,000,000,000,000,000,000,000,000," "," ",27h,7Eh,002,002
;	10	nul,nul,stl,stl,shl,shl,"\","|",cpl,cpl,"q","Q","1","!",f3 ,f3
	.byte	000,000,000,000,015,015,5Ch,7Ch,000,000,"q","Q","1","!",003,003
;	18	nul,nul,alt,alt,"z","Z","s","S","a","A","w","W","2","@",f4 ,f4,
	.byte	000,000,000,000,"z","Z","s","S","a","A","w","W","2",40h,004,004
;	20	nul,nul,"c","C","x","X","d","D","e","E","4","$","3","#",f5 ,f5,
	.byte	000,000,"c","C","x","X","d","D","e","E","4","$","3",23h,005,005
;	28	nul,nul,spc,spc,"v","V","f","F","t","T","r","R","5","%",f6 ,f6
	.byte	000,000," "," ","v","V","f","F","t","T","r","R","5",25h,006,006
;	30	nul,nul,"n","N","b","B","h","H","g","G","y","Y","6","^",f7 ,f7,
	.byte	000,000,"n","N","b","B","h","H","g","G","y","Y","6",5Eh,007,007
;	38	nul,nul,alg,alg,"m","M","j","J","u","U","7","&","8","*",f8 ,f8,
	.byte	000,000,000,000,"m","M","j","J","u","U","7","&","8","*",008,008
;	40	nul,nul,",","<","k","K","i","I","o","O","0",")","9","(",f9 ,f9,
	.byte	000,000,",","<","k","K","i","I","o","O","0",")","9","(",009,009
;	48	nul,nul,".",">","/","?","l","L",";",":","p","P","-","_",f10,f10,
	.byte	000,000,".",">","/","?","l","L",";",":","p","P","-","_",010,010
;	50	nul,nul,nul,nul,"'",""","\","|","[","{","=","+",f11,f11,drk,drk,
	.byte	000,000,000,000,27h,22h,5Ch,7Ch,"[","{","=","+",011,011,019,019
;	58	nul,nul,shr,shr,ret,ret,"]","}",nul,nul,nul,nul,f12,f12,rol,rol,
	.byte	000,000,015,015,013,013,"]","}",000,000,000,000,012,012,016,016
;	60	cdn,cdn,cl ,cl ,pau,pau,cup,cup,etf,etf,end,end,bck,bck,enf,enf,
	.byte	000,000,000,000,021,021,000,000,014,014,000,000,014,014,024,024
;	68	nul,nul,1n ,1n ,cr ,cr ,4n ,4n ,7n ,7n ,bdn,bdn,ps1,ps1,bup,bup
	.byte	000,000,"1","1",013,013,"4","4","7","7",026,026,018,018,025,025
;	70	0n ,0n ,efn,efn,2n ,2n ,5n ,5n ,6n ,6n ,8n ,8n ,num,num,/n ,/n ,
	.byte	"0","0",",",",","2","2","5","5","6","6","8","8",020,020,"/","/"
;	78	nul,nul,ent,ent,3n ,3n ,nul,nul,+n ,+n ,9n ,9n ,*n ,*n ,nul,nul,
	.byte	000,000,022,022,"3","3",000,000,"+","+","9","9","*","*",000,000
;extra Abfrage auf 84 
	;84	-n	
;
; =============================================================================

;
;	Umkodierung der Steuer-Kodes von der seriellen Schnittstelle
;	#* => Funktions-Kode
funkcode
; 20h		" ","!",""","#","$","%","&","'","(",")","*","+",",","-",".","/"
;		" ","!",""","#","$","%","&","'","(",")",ENF,CR ,",",BCK,".","/"
	.byte	" ","!",22h,"#","$",25h,"&",27h,"(",")",024,013,",",014,".","/"

; 30h		"0","1","2","3","4","5","6","7","8","9",":",";","<","=",">","?"
;		POS,F1 ,F2 ,F3 ,F4 ,F5 ,F6 ,F7 ,F8 ,F9 ,":",";","<","=",">","?"
	.byte	018,001,002,003,004,005,006,007,008,009,":",";","<","=",">","?"

; 40h		"@","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O"
;		"@",F10,F11,F12,DRK,ESC,"F","G","H","I","J","K","L","M",NUM,"O"
	.byte	"@",010,011,012,019,023,"F","G","H","I","J","K","L","M",020,"O"

; 50h		"P","Q","R","S","T","U","V","W","X","Y","Z","[","\","]","^","_"
;		PAU,"Q",ROL,"S","T","U","V","W","X","Y",ENT,"[","\","]","^","_"
	.byte	021,"Q",016,"S","T","U","V","W","X","Y",022,"[",5Ch,"]","^","_"

; 60h		"`","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o"
;		"`",f10,f11,f12,drk,esc,"f","g","h","i","j","k","l","m",num,"o"
	.byte	"`",010,011,012,019,023,"f","g","h","i","j","k","l","m",020,"o"

; 70h		"p","q","r","s","t","u","v","w","x","y","z","{","|","}","~"," "
;		pau,"q",rol,"s","t","u","v","w","x","y",ent,"{","|","}","~"," "
	.byte	021,"q",016,"s","t","u","v","w","x","y",022,"{","|","}","~"," "
;
;
comdtabl
	.byte	" ","1","2","3","4","5","6","7"
	.byte	"8","9","A","B","C","+","-"," "
	.byte	"R"," ","0","D","N","P","Z","E"
	.byte	"*"
;
; =============================================================================
;
; Tabelle mit Darstellung der Zeichen
; Eingabe im ASCII-Code von 020h .. 07Fh
;
charimg0
	.byte	000h,000h,000h,000h,000h	; " "
	.byte	07Fh,084h,082h,0A2h,05Ch	; "ß"
	.byte	01Ch,0A2h,022h,0A2h,03Eh	; "ä"
	.byte	0BEh,048h,088h,048h,0BEh	; "Ä"
	.byte	01Ch,0A2h,022h,0A2h,01Ch	; "ö"
	.byte	0BCh,042h,042h,042h,0BCh	; "Ö"
	.byte	03Ch,082h,002h,082h,03Ch	; "ü"
	.byte	0BCh,002h,002h,002h,0BCh	; "Ü"

charimg1
	.byte	000h,000h,000h,000h,000h	; " "
	.byte	000h,000h,0FAh,000h,000h	; "!"
	.byte	000h,0C0h,000h,0C0h,000h	; """
	.byte	028h,0FEh,028h,0FEh,028h	; "#"
	.byte	064h,092h,0FEh,092h,04Ch	; "$"
	.byte	0C4h,0C8h,010h,026h,046h	; "%"
	.byte	06Ch,092h,08Ah,046h,00Eh	; "&"
	.byte	000h,000h,0C0h,000h,000h	; "'"

	.byte	000h,000h,07Ch,082h,000h	; "("
	.byte	000h,082h,07Ch,000h,000h	; ")"
	.byte	054h,038h,07Ch,038h,054h	; "*"
	.byte	010h,010h,07Ch,010h,010h	; "+"
	.byte	001h,006h,006h,000h,000h	; ","
	.byte	010h,010h,010h,010h,010h	; "-"
	.byte	000h,006h,006h,000h,000h	; "."
	.byte	006h,008h,010h,020h,0C0h	; "/"

	.byte	07Ch,08Ah,092h,0A2h,07Ch	; "0"
	.byte	000h,042h,0FEh,002h,000h	; "1"
	.byte	042h,086h,08Ah,092h,062h	; "2"
	.byte	044h,082h,092h,092h,06Ch	; "3"
	.byte	030h,050h,090h,0FEh,010h	; "4"
	.byte	0E4h,0A2h,0A2h,0A2h,09Ch	; "5"
	.byte	07Ch,092h,092h,092h,00Ch	; "6"
	.byte	080h,09Eh,0A0h,0C0h,080h	; "7"

	.byte	06Ch,092h,092h,092h,06Ch	; "8"
	.byte	060h,092h,092h,092h,07Ch	; "9"
	.byte	000h,036h,036h,000h,000h	; ":"
	.byte	001h,036h,036h,000h,000h	; ";"
	.byte	000h,010h,028h,044h,000h	; "<"
	.byte	000h,014h,014h,014h,000h	; "="
	.byte	000h,044h,028h,010h,000h	; ">"
	.byte	000h,040h,08Ah,070h,000h	; "?"

charimg2
	.byte	07Ch,082h,0BAh,0AAh,078h	; "@"
	.byte	03Eh,048h,088h,048h,03Eh	; "A"
	.byte	0FEh,092h,092h,092h,06Ch	; "B"
	.byte	07Ch,082h,082h,082h,044h	; "C"
	.byte	0FEh,082h,082h,082h,07Ch	; "D"
	.byte	0FEh,092h,092h,092h,082h	; "E"
	.byte	0FEh,090h,090h,090h,080h	; "F"
	.byte	07Ch,082h,082h,092h,05Eh	; "G"

	.byte	0FEh,010h,010h,010h,0FEh	; "H"
	.byte	000h,082h,0FEh,082h,000h	; "I"
	.byte	084h,082h,082h,082h,0FCh	; "J"
	.byte	0FEh,010h,028h,044h,082h	; "K"
	.byte	0FEh,002h,002h,002h,002h	; "L"
	.byte	0FEh,040h,030h,040h,0FEh	; "M"
	.byte	0FEh,020h,010h,008h,0FEh	; "N"
	.byte	07Ch,082h,082h,082h,07Ch	; "O"

	.byte	0FEh,090h,090h,090h,060h	; "P"
	.byte	07Ch,082h,08Ah,086h,07Ch	; "Q"
	.byte	0FEh,090h,098h,094h,062h	; "R"
	.byte	064h,092h,092h,092h,04Ch	; "S"
	.byte	080h,080h,0FEh,080h,080h	; "T"
	.byte	0FCh,002h,002h,002h,0FCh	; "U"
	.byte	0F0h,00Ch,002h,00Ch,0F0h	; "V"
	.byte	0FCh,002h,01Eh,002h,0FCh	; "W"

	.byte	0C6h,028h,010h,028h,0C6h	; "X"
	.byte	0C0h,020h,01Eh,020h,0C0h	; "Y"
	.byte	086h,08Ah,092h,0A2h,0C2h	; "Z"
	.byte	000h,000h,0FEh,082h,000h	; "["
	.byte	0C0h,020h,010h,008h,006h	; "\"
	.byte	000h,082h,0FEh,000h,000h	; "]"
	.byte	020h,040h,080h,040h,020h	; "^"
	.byte	001h,001h,001h,001h,001h	; "_"

charimg3
	.byte	000h,000h,00Ch,000h,000h	; "`"
	.byte	01Ch,022h,022h,022h,03Eh	; "a"
	.byte	0FEh,022h,022h,022h,01Ch	; "b"
	.byte	01Ch,022h,022h,022h,014h	; "c"
	.byte	01Ch,022h,022h,022h,0FEh	; "d"
	.byte	01Ch,02Ah,02Ah,02Ah,010h	; "e"
	.byte	010h,07Fh,090h,090h,040h	; "f"
	.byte	018h,025h,025h,025h,03Eh	; "g"

	.byte	0FEh,020h,020h,020h,01Eh	; "h"
	.byte	000h,002h,0BEh,002h,000h	; "i"
	.byte	002h,001h,001h,0BEh,000h	; "j"
	.byte	0FEh,018h,024h,042h,000h	; "k"
	.byte	000h,0FCh,002h,002h,004h	; "l"
	.byte	01Eh,020h,01Eh,020h,01Eh	; "m"
	.byte	03Eh,020h,020h,020h,01Eh	; "n"
	.byte	01Ch,022h,022h,022h,01Ch	; "o"

	.byte	01Fh,024h,024h,024h,018h	; "p"
	.byte	018h,024h,024h,024h,03Fh	; "q"
	.byte	01Eh,020h,020h,020h,010h	; "r"
	.byte	010h,02Ah,02Ah,02Ah,004h	; "s"
	.byte	020h,0FCh,022h,002h,004h	; "t"
	.byte	03Ch,002h,002h,002h,03Ch	; "u"
	.byte	038h,004h,002h,004h,038h	; "v"
	.byte	03Ch,002h,01Eh,002h,03Ch	; "w"

	.byte	022h,014h,008h,014h,022h	; "x"
	.byte	020h,011h,00Fh,010h,020h	; "y"
	.byte	022h,026h,02Ah,032h,022h	; "z"
	.byte	000h,010h,07Ch,082h,000h	; "{"
	.byte	000h,000h,0FFh,000h,000h	; "|"
	.byte	000h,082h,07Ch,010h,000h	; "}"
	.byte	010h,020h,010h,008h,010h	; "~"
	.byte	000h,000h,000h,000h,000h	; " "
;
; ===========================================================
;
		.end


