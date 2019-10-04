; Punktmatrix - Anzeige - Steuerung
; Variante ELEKTOR    (22,1184 MHz)
; mit Anzeigen TA 07-11 (klein) 6 Stueck je Modul
; im Interruppt Betrieb (V.24 Schnittstelle)
; Mit Schalter wird Position im Anzeigeverband festgelegt
; m”glich ist 0...5 6...11 12...17 .....  90...95
; Datenuebertragung erfolgt fuer alle Module mit 9600 baud
; jedes Modul sucht sich seine Zeichen
; Port 3.2 bis 3.5 bestimmt die Position im Verband
; Uebertragung zur Anzeige erfolgt mit 9600 Baud
; Vereinbarungen
	DSEG
ACC:	 EQU 0E0H
B:       EQU 0F0H		;Hilfsregister B
P1:      EQU 90H
P3:      EQU 0B0H
DPH:     EQU 83H
DPL:     EQU 82H
SCON:    EQU 98H		;Controlregister seriell
TMOD:    EQU 89H		;Timercontrollregister
PCON: 	 EQU 87H		;SMOD
TH1:     EQU 8DH		;Timer 1
SBUF:    EQU 99H		;Empfangspuffer
IE:      EQU 0A8H		;Interupptfreigabe
IP:      EQU 0B8H		;Interrupptprioritaet
PSW:     EQU 0D0H		;Programmstatuswort
SP:      EQU 81H                ;Stackpointer
ZAE:     EQU 20H		;Zeichenzaehler
APOS:    EQU 21H		;Anfangsposition im Verband
ZPOS:    EQU 22H		;zweite Position im Verband
DPOS:    EQU 23H                ;dritte Position im Verband
VPOS:    EQU 24H                ;vierte Position im Verband
FPOS:    EQU 25H                ;fuenfte Position im Verband
EPOS:    EQU 26H		;Endposition im Verband
;
	BSEG
ACC.0:   EQU 0E0H
ACC.1:   EQU 0E1H
ACC.2:   EQU 0E2H
ACC.3:   EQU 0E3H
ACC.4:   EQU 0E4H
ACC.5:   EQU 0E5H
ACC.6:   EQU 0E6H
P1.6:    EQU 96H
P1.7:    EQU 97H
TR1:     EQU 8EH		;Timerregister
RI:      EQU 98H		;Empfangsflag
TI:      EQU 99H		;Sendeflag
        CSEG
	ORG 0000H
START:  MOV SP,#70H
	MOV IE,#90H		;Int seriell  und allgemein frei
	MOV IP,#10H		;serieller Int hohe Prioritaet
	MOV SCON,#50H		;serielle Schnittstelle Mod 1
	MOV TMOD,#20H		;Timer 1 Mode 2 Timer 2 keine Funktion
	MOV PCON,#80H		;SMOD = 0 kein Teiler /2
	MOV TH1,#0F4H		;9600 baud bei 22,1184MHz
	SETB TR1		;Timer starten
	CLR RI			;Empfangsint loeschen
	CLR TI                  ;Sendeint loeschen
	CALL PBE		;Positionsbestimmung im Verband
	CALL LOE		;Anfangszustand herstellen
	JMP ZZE         	;zum Beginn des Programms
;
	ORG 0023H
;  Verarbeitungsroutine fuer seriellen Interrupt
;
SERIN:  PUSH ACC
	PUSH PSW
	PUSH B
	MOV B,SBUF		;Zeichen nach B
	MOV A,ZAE		;Zeichenzaehler holen
	INC A			;Zeichenzaehler erhoehen
	MOV ZAE,A		;Zeichenzaehler sichern
	MOV A,B			;Empfangszeichen holen
	CJNE A,#0CH,SER0	;Zeichen fuer Loeschen
	CALL LOE		;loeschen
	JMP SER7                ;in diesem Fall wars das
SER0:	CLR  C			;Carry loeschen
	MOV A,B			;Zeichen holen
	PUSH ACC		;Accu sichern
	SUBB A,#20H             ;pruefen kleiner 20H
	POP ACC
	JNC SER1		;gueltiges Zeichen groesser 20 H
        MOV A,ZAE		;Zeichenzaehler holen
	DEC A			;Zeichenzaehler korrigieren
	MOV ZAE,A		;Zeichenzaehler sichern
	JMP SER7		;das wars
SER1:   MOV A,APOS		;Anfangsposition holen
	CJNE A,ZAE,SER2		;Vergleich Soll-Ist Position
	MOV A,B			;Zeichen nach A
	CLR C			;Carry loeschen
	SUBB A,#20H		;ASCII Code korrigieren
	MOV R2,A		;erstes Zeichen nach R2
	JMP SER7                ;das wars
SER2:   MOV A,ZPOS              ;zweite Position holen
	CJNE A,ZAE,SER3		;Vergleich Soll-Ist Position
	MOV A,B			;Zeichen nach A
	CLR C			;Carry loeschen
	SUBB A,#20H		;ASCII Code korrigieren
	MOV R3,A		;zweites Zeichen nach R3
	JMP SER7                ;das wars
SER3:   MOV A,DPOS              ;dritte Position holen
	CJNE A,ZAE,SER4         ;Vergleich Soll-Ist Position
	MOV A,B			;Zeichen nach A
	CLR C                   ;Carry loeschen
	SUBB A,#20H		;ASCII Code krrigieren
	MOV R4,A                ;drittes Zeichen nach R4
        JMP SER7                ;das wars
SER4:   MOV A,VPOS              ;vierte Position holen
	CJNE A,ZAE,SER5         ;Vergleich Soll-Ist Position
	MOV A,B                 ;Zeichen nach A
	CLR C			;Carry loeschen
	SUBB A,#20H		;ASCII Code korrigieren
	MOV R5,A                ;viertes Zeichen nach R5
	JMP SER7		;das wars
SER5:   MOV A,FPOS		;fuenfte Position holen
	CJNE A,ZAE,SER6         ;Vergleich Soll-Ist Position
	MOV A,B			;Zeichen nach A
	CLR C			;Carry loeschen
	SUBB A,#20H		;ASCII Code korrigieren
	MOV R6,A		;fuenftes Zeichen nach R6
	JMP SER7                ;das wars
SER6:   MOV A,EPOS		;Endposition holen
	CJNE A,ZAE,SER7		;Vergleich Soll-Ist Position
	MOV A,B			;Zeichen nach A
	CLR C			;Carry loeschen
	SUBB A,#20H             ;ASCII Kode korrigieren
        MOV R7,A		;letztes Zeichen nach R7
SER7:   CLR RI			;Empfangsflag loeschen
        CLR TI			;Sendeflag loeschen
	POP B
	POP PSW			;
	POP ACC			;
	RETI			;Zeichen ausserhalb dieser Anzeige
;
; Unterprogramm zur Bestimmung der Position der Anzeige
; innerhalb eines Verbandes von maximal 16 Anzeigen
; mit der einstellbaren Adresse 0 ... 15
;
PBE:	MOV A,P3       		;Port 3 Schalter lesen
	ANL A,#3CH		;nur Schalter bewerten
	CLR C			;Carry loeschen
	RRC A    		;verschieben :2
	CLR C			;Carry loeschen
	RRC A			;verschieben :4
	ANL A,#0FH		;nur Schalterwert
	MOV B,A			;in B sichern
	ADD A,B			;A = A * 2
	ADD A,B			;A = A * 3
        ADD A,ACC               ;A = A * 6
	MOV APOS,A		;Anfangsposition der Anzeige im Verband
	INC A			;2. Position der Anzeige berechnen
	MOV ZPOS,A		;zweite Position ablegen
	INC A			;3. Position im Verband berechnen
	MOV DPOS,A		;dritte Position der Anzeige ablegen
        INC A                   ;4. Position im Verband bestimmen
        MOV VPOS,A              ;vierte Position der Anzeige ablegen
        INC A                   ;5. Position im Verband bestimmen
        MOV FPOS,A              ;fuenfte Position der Anzeige ablegen
        INC A                   ;6. Position im Verband berechnen
        MOV EPOS,A              ;sechste Position der Anzeige ablegen
	RET
;
; eigentliche Anzeigeroutine
;
ZZE:	MOV B,#06H		;sieben Zeilen
ZZS:	MOV A,R2		;erstes Zeichen
	ACALL AZGW		;wandeln
	MOV A,B		        ;Zeile von ZG festlegen
	MOVC A,@A+DPTR		;Zeichengeneratorcode holen
	ACALL ANZ		;erstes Zeichen in Schiebereg
	MOV A,R3                ;zweites Zeichen
        ACALL AZGW		;wandeln
	MOV A,B			;Zeile von ZG festlegen
	MOVC A,@A+DPTR		;Zeichengeneratorcode holen
	ACALL ANZ	        ;zweites Zeichen in Schiebereg
	MOV A,R4		;drittes Zeichen
	ACALL AZGW		;wandeln
	MOV A,B                 ;Zeile von ZG festlegen
	MOVC A,@A+DPTR		;Zeichengeneratorcode holen
	ACALL ANZ		;drittes Zeichen in Schiebereg
	MOV A,R5		;viertes Zeichen
	ACALL AZGW		;wandeln
	MOV A,B			;Zeile von ZG festlegen
	MOVC A,@A+DPTR		;Zeichengeneratorcode holen
	ACALL ANZ		;viertes Zeichen in Schiebereg
	MOV A,R6		;fuenftes Zeichen holen
	ACALL AZGW		;wandeln
	MOV A,B			;Zeile von ZG festlegen
	MOVC A,@A+DPTR		;Zeichengeneratorcode holen
	ACALL ANZ		;fuenftes Zeichen in Schiebereg
	MOV A,R7		;sechstes Zeichen holen
	ACALL AZGW		;wandeln
	MOV A,B			;Zeile von ZG festlegen
	MOVC A,@A+DPTR		;Zeichengeneratorcode holen
	ACALL ANZ		;sechstes Zeichen in Schiebereg
	ANL P1,#0F8H		;Zeilendecoder ruecksetzen
	MOV A,B			;umladen
	ORL P1,A		;Zeile aktivieren
	ACALL ZEIT		;und leuchten lassen
	ACALL ZEIT
	ACALL ZEIT
        ORL P1,#07H		;alle Zeilen unsichtbar
	DEC B           	;bis zur letzten Zeile
        MOV A,B                 ;nach A
	CJNE A,#0FFH,ZZS        ;wars schon Zeile Null ?
	AJMP ZZE		;und weiter gehts
;
ANZ:	MOV C,ACC.4		;Zustand Bit 5 aus ZG nach Carry
	MOV P1.7,C		;zum Portbit
	ACALL CLK		;Taktimpuls
	MOV C,ACC.3		;Zustand Bit 4 aus ZG nach Carry
	MOV P1.7,C		;zum Portbit
	ACALL CLK		;Taktimpuls
        MOV C,ACC.2             ;Zustand Bit 3 aus ZG nach Carry
	MOV P1.7,C		;zum Portbit
        ACALL CLK		;Taktimpuls
	MOV C,ACC.1		;Zustand Bit 2 aus ZG nach Carry
	MOV P1.7,C		;zum Portbit
        ACALL CLK		;Taktimpuls
	MOV C,ACC.0		;Zustand Bit 1 aus ZG nach Carry
	MOV P1.7,C		;das wars
        ACALL CLK		;Taktimpuls
	RET
;
; Takt fuer Schieberegister erzeugen
;
CLK:    SETB P1.6		;Takt auf High
	CLR P1.6		;Takt auf Low
	SETB P1.6		;Takt wieder auf High
	RET
;
; Anzeige loeschen
; alle Bits der Schieberegister werden auf High gesetzt
;
LOE:    PUSH B			;B auf Stack
	MOV B,#2EH		;6 Anzeigen = 30 Bit
LOE1:	SETB P1.7		;Daten auf High
	ACALL CLK		;Taktimpuls
	DJNZ B,LOE1		;alles auf High ?
	POP B
        MOV A,#0FFH		;Zeichenzaehler auf
	MOV ZAE,A		;Anfangsposition setzen
	ORL P1,#07H		;alle Zeilen unscichtbar
	INC A			;A = 00H
	MOV R2,A                ;erstes Zeichen blank
	MOV R3,A                ;zweites Zeichen blank
	MOV R4,A                ;drittes Zeichen blank
	MOV R5,A                ;viertes Zeichen blank
	MOV R6,A                ;fuenftes Zeichen blank
	MOV R7,A                ;letztes Zeichen blank
	RET
;
; Umwandeln ASCII Code in Zeichengeneratorcode
; ASCII Zeichen steht in ACC
; danach steht in DPTR der Anfang der Codetabelle fuer
; das betreffende Zeichen
; der Charactercode besteht aus 7 Bytes deren niedere 5 bit
; die leuchtenden LED's repr„sentieren
;
AZGW:	MOV DPTR,#ACZT		;Anfang Zeichencodetabelle
	MOV R1,A                ;
	ORL A,ACC               ;gleich Null ?
	JZ AZGW2                ;ja
AZGW1:	INC DPTR		;jedes Zeichen besteht
	INC DPTR                ;aus 5 Bytes in der
	INC DPTR		;Zeichencodetabelle muss
	INC DPTR		;deshalb je ASCII Code
	INC DPTR		;der Zeiger um sieben
	INC DPTR
	INC DPTR
	DJNZ R1,AZGW1		;erhoeht werden
AZGW2:	RET
;
ZEIT:   PUSH B
	MOV B,#0FFH		;Zeitkonstante
ZEIT1:	DJNZ B,ZEIT1
        POP B
	RET
;
ACZT:   DEFB 0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH  ;Space
	DEFB 0FBH,0FBH,0FBH,0FBH,0FBH,0FFH,0FBH	 ;!
	DEFB 0F5H,0F5H,0F5H,0FFH,0FFH,0FFH,0FFH  ;"
	DEFB 0F5H,0F5H,0E0H,0F5H,0E0H,0F5H,0F5H  ;#
	DEFB 0FBH,0F0H,0EBH,0F1H,0FAH,0E1H,0FBH  ;$
	DEFB 0E3H,0EAH,0E5H,0FBH,0F4H,0EAH,0F8H  ;%
	DEFB 0F7H,0EBH,0EBH,0F7H,0EAH,0EDH,0F2H  ;&
	DEFB 0F9H,0F9H,0FDH,0FBH,0FFH,0FFH,0FFH  ;'
	DEFB 0FDH,0FBH,0F7H,0F7H,0F7H,0FBH,0FDH  ;(
	DEFB 0F7H,0FBH,0FDH,0FDH,0FDH,0FBH,0F7H  ;)
	DEFB 0FBH,0EAH,0F1H,0FBH,0F1H,0EAH,0FBH  ;*
	DEFB 0FFH,0FBH,0FBH,0E0H,0FBH,0FBH,0FFH  ;+
	DEFB 0FFH,0FFH,0FFH,0F3H,0F3H,0FBH,0F7H  ;,
	DEFB 0FFH,0FFH,0FFH,0F1H,0FFH,0FFH,0FFH  ;-
	DEFB 0FFH,0FFH,0FFH,0FFH,0FFH,0F3H,0F3H  ;.
	DEFB 0FFH,0FEH,0FDH,0FBH,0F7H,0EFH,0FFH  ;/
	DEFB 0F1H,0EEH,0ECH,0EAH,0E6H,0EEH,0F1H  ;0
	DEFB 0FBH,0F3H,0FBH,0FBH,0FBH,0FBH,0F1H  ;1
	DEFB 0F1H,0EEH,0FEH,0F1H,0EFH,0EFH,0E0H  ;2
	DEFB 0F1H,0EEH,0FEH,0F9H,0FEH,0EEH,0F1H  ;3
	DEFB 0FDH,0F9H,0F5H,0EDH,0E0H,0FDH,0FDH  ;4
	DEFB 0E0H,0EFH,0E1H,0FEH,0FEH,0FEH,0E1H  ;5
	DEFB 0F9H,0F7H,0EFH,0E1H,0EEH,0EEH,0F1H  ;6
	DEFB 0E0H,0FEH,0FDH,0FBH,0F7H,0F7H,0F7H  ;7
	DEFB 0F1H,0EEH,0EEH,0F1H,0EEH,0EEH,0F1H  ;8
	DEFB 0F1H,0EEH,0EEH,0F0H,0FEH,0FDH,0F3H  ;9
        DEFB 0FFH,0F3H,0F3H,0FFH,0F3H,0F3H,0FFH  ;:
	DEFB 0F3H,0FBH,0F3H,0F3H,0FFH,0F3H,0F3H  ;;
	DEFB 0FDH,0FBH,0F7H,0EFH,0F7H,0FBH,0FDH  ;<
	DEFB 0FFH,0FFH,0F1H,0FFH,0F1H,0FFH,0FFH	 ;=
	DEFB 0F7H,0FBH,0FDH,0FEH,0FDH,0FBH,0F7H  ;>
	DEFB 0F1H,0EEH,0FEH,0FDH,0FBH,0FFH,0FBH  ;?
        DEFB 0F1H,0EEH,0FEH,0F2H,0EAH,0EAH,0F1H  ;@
	DEFB 0FBH,0F5H,0EEH,0EEH,0E0H,0EEH,0EEH  ;A
	DEFB 0E1H,0F6H,0F6H,0F1H,0F6H,0F6H,0E1H  ;B
	DEFB 0F1H,0EEH,0EFH,0EFH,0EFH,0EEH,0F1H  ;C
	DEFB 0E1H,0F6H,0F6H,0F6H,0F6H,0F6H,0E1H  ;D
	DEFB 0E0H,0EFH,0EFH,0E3H,0EFH,0EFH,0E0H  ;E
	DEFB 0E0H,0EFH,0EFH,0E3H,0EFH,0EFH,0EFH  ;F
	DEFB 0F1H,0EEH,0EFH,0E8H,0EEH,0EEH,0F1H  ;G
	DEFB 0EEH,0EEH,0EEH,0E0H,0EEH,0EEH,0EEH  ;H
	DEFB 0F1H,0FBH,0FBH,0FBH,0FBH,0FBH,0F1H	 ;I
	DEFB 0F8H,0FDH,0FDH,0FDH,0FDH,0FDH,0F3H  ;J
	DEFB 0EEH,0EDH,0EBH,0E7H,0EBH,0EDH,0EEH  ;K
	DEFB 0EFH,0EFH,0EFH,0EFH,0EFH,0EFH,0E0H  ;L
	DEFB 0EEH,0E4H,0EAH,0EAH,0EEH,0EEH,0EEH  ;M
	DEFB 0EEH,0E6H,0EAH,0ECH,0EEH,0EEH,0EEH  ;N
	DEFB 0F1H,0EEH,0EEH,0EEH,0EEH,0EEH,0F1H  ;O
	DEFB 0E1H,0EEH,0EEH,0E1H,0EFH,0EFH,0EFH  ;P
	DEFB 0F1H,0EEH,0EEH,0EEH,0EAH,0EDH,0F2H  ;Q
	DEFB 0E1H,0EEH,0EEH,0E1H,0EBH,0EDH,0EEH  ;R
	DEFB 0F1H,0EEH,0EFH,0F1H,0FEH,0EEH,0F1H  ;S
	DEFB 0E0H,0FBH,0FBH,0FBH,0FBH,0FBH,0FBH  ;T
        DEFB 0EEH,0EEH,0EEH,0EEH,0EEH,0EEH,0F1H  ;U
	DEFB 0EEH,0EEH,0EEH,0F5H,0F5H,0FBH,0FBH  ;V
	DEFB 0EEH,0EEH,0EEH,0EAH,0EAH,0E4H,0EEH  ;W
	DEFB 0EEH,0EEH,0F5H,0FBH,0F5H,0EEH,0EEH  ;X
	DEFB 0EEH,0EEH,0F5H,0FBH,0FBH,0FBH,0FBH  ;Y
	DEFB 0E0H,0FEH,0FDH,0FBH,0F7H,0EFH,0E0H  ;Z
	DEFB 0F1H,0F7H,0F7H,0F7H,0F7H,0F7H,0F1H  ;[
	DEFB 0FFH,0EFH,0F7H,0FBH,0FDH,0FEH,0FFH  ;\
	DEFB 0F1H,0FDH,0FDH,0FDH,0FDH,0FDH,0F1H  ;[
	DEFB 0FBH,0F5H,0EEH,0FFH,0FFH,0FFH,0FFH  ;^
	DEFB 0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0E0H  ;_
        DEFB 0F3H,0F3H,0F7H,0FBH,0FFH,0FFH,0FFH  ;'
	DEFB 0FFH,0FFH,0F1H,0FEH,0F0H,0EEH,0F1H  ;a
	DEFB 0EFH,0EFH,0E9H,0E6H,0EEH,0E6H,0E9H  ;b
	DEFB 0FFH,0FFH,0F8H,0F7H,0F7H,0F7H,0F8H  ;c
	DEFB 0FEH,0FEH,0F2H,0ECH,0EEH,0ECH,0F2H  ;d
	DEFB 0FFH,0FFH,0F1H,0EEH,0E0H,0EFH,0F1H  ;e
	DEFB 0F9H,0F6H,0F7H,0E1H,0F7H,0F7H,0F7H  ;f
	DEFB 0FFH,0FFH,0F0H,0EEH,0F0H,0FEH,0F1H  ;g
	DEFB 0EFH,0EFH,0E9H,0E6H,0EEH,0EEH,0EEH  ;h
	DEFB 0FBH,0FFH,0F3H,0FBH,0FBH,0FBH,0F1H  ;i
	DEFB 0FDH,0FFH,0F9H,0FDH,0FDH,0FDH,0F3H  ;j
	DEFB 0F7H,0F7H,0F6H,0F5H,0F3H,0F5H,0F6H  ;k
	DEFB 0F3H,0FBH,0FBH,0FBH,0FBH,0FBH,0F1H  ;l
	DEFB 0FFH,0FFH,0E5H,0EAH,0EAH,0EAH,0EAH  ;m
	DEFB 0FFH,0FFH,0E9H,0E6H,0EEH,0EEH,0EEH  ;n
	DEFB 0FFH,0FFH,0F1H,0EEH,0EEH,0EEH,0F1H  ;o
	DEFB 0FFH,0FFH,0E1H,0EEH,0E1H,0EFH,0EFH  ;p
	DEFB 0FFH,0FFH,0F0H,0EEH,0F0H,0FEH,0FEH  ;q
	DEFB 0FFH,0FFH,0E9H,0E6H,0EFH,0EFH,0EFH  ;r
	DEFB 0FFH,0FFH,0F0H,0EFH,0F1H,0FEH,0E1H  ;s
	DEFB 0FBH,0FBH,0F0H,0FBH,0FBH,0FBH,0FCH  ;t
	DEFB 0FFH,0FFH,0EEH,0EEH,0EEH,0ECH,0F2H  ;u
	DEFB 0FFH,0FFH,0EEH,0EEH,0EEH,0F5H,0FBH  ;v
	DEFB 0FFH,0FFH,0EEH,0EEH,0EAH,0EAH,0F4H  ;w
        DEFB 0FFH,0FFH,0EEH,0F5H,0FBH,0F5H,0EEH  ;x
	DEFB 0FFH,0FFH,0EEH,0F5H,0FBH,0FBH,0F3H  ;y
        DEFB 0FFH,0FFH,0E0H,0FDH,0FBH,0F7H,0E0H  ;z
	DEFB 0F9H,0F7H,0F7H,0E7H,0F7H,0F7H,0F7H  ;{
	DEFB 0FBH,0FBH,0FBH,0FFH,0FBH,0FBH,0FBH  ;|
	DEFB 0F3H,0FDH,0FDH,0FCH,0FDH,0FDH,0F3H  ;}
	DEFB 0F5H,0EAH,0FFH,0FFH,0FFH,0FFH,0FFH  ;~
	DEFB 0F5H,0EAH,0F5H,0EAH,0F5H,0EAH,0F5H  ;DEL
;
	DEFB 0DH
	DEFB 0AH
	DEFB 0DH
	DEFB 0AH
