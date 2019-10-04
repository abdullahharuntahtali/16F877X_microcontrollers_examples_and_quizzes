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
ACC	DATA 0E0H
B	DATA 0F0H		;Hilfsregister B
P1      DATA 90H
P3      DATA 0B0H
DPH     DATA 83H
DPL     DATA 82H
SCON    DATA 98H		;Controlregister seriell
TMOD    DATA 89H		;Timercontrollregister
PCON 	DATA 87H		;SMOD
TH1     DATA 8DH		;Timer 1
SBUF    DATA 99H		;Empfangspuffer
IE      DATA 0A8H		;Interupptfreigabe
IP      DATA 0B8H		;Interrupptprioritaet
PSW     DATA 0D0H		;Programmstatuswort
SP      DATA 81H                ;Stackpointer
ZAE     DATA 20H		;Zeichenzaehler
APOS    DATA 21H		;Anfangsposition im Verband
ZPOS    DATA 22H		;zweite Position im Verband
DPOS    DATA 23H                ;dritte Position im Verband
VPOS    DATA 24H                ;vierte Position im Verband
FPOS    DATA 25H                ;fuenfte Position im Verband
EPOS    DATA 26H		;Endposition im Verband
;
	BSEG
TR1     BIT 8EH		;Timerregister
RI      BIT 98H		;Empfangsflag
TI      BIT 99H		;Sendeflag

BITMAP  EQU 0400h

        CSEG
	ORG 0000H
	JMP START
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
	JMP SER7          	;in diesem Fall wars das
SER0:	CLR  C			;Carry loeschen
	MOV A,B			;Zeichen holen
	PUSH ACC		;Accu sichern
	SUBB A,#20H       	;pruefen kleiner 20H
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
	JMP SER7         	 ;das wars
SER2:   MOV A,ZPOS        	;zweite Position holen
	CJNE A,ZAE,SER3		;Vergleich Soll-Ist Position
	MOV A,B			;Zeichen nach A
	CLR C			;Carry loeschen
	SUBB A,#20H		;ASCII Code korrigieren
	MOV R3,A		;zweites Zeichen nach R3
	JMP SER7          	;das wars
SER3:   MOV A,DPOS        	;dritte Position holen
	CJNE A,ZAE,SER4   	;Vergleich Soll-Ist Position
	MOV A,B			;Zeichen nach A
	CLR C             	;Carry loeschen
	SUBB A,#20H		;ASCII Code krrigieren
	MOV R4,A         	;drittes Zeichen nach R4
        JMP SER7         	;das wars
SER4:   MOV A,VPOS       	;vierte Position holen
	CJNE A,ZAE,SER5  	;Vergleich Soll-Ist Position
	MOV A,B          	;Zeichen nach A
	CLR C			;Carry loeschen
	SUBB A,#20H		;ASCII Code korrigieren
	MOV R5,A          	;viertes Zeichen nach R5
	JMP SER7		;das wars
SER5:   MOV A,FPOS		;fuenfte Position holen
	CJNE A,ZAE,SER6   	;Vergleich Soll-Ist Position
	MOV A,B			;Zeichen nach A
	CLR C			;Carry loeschen
	SUBB A,#20H		;ASCII Code korrigieren
	MOV R6,A		;fuenftes Zeichen nach R6
	JMP SER7          	;das wars
SER6:   MOV A,EPOS		;Endposition holen
	CJNE A,ZAE,SER7		;Vergleich Soll-Ist Position
	MOV A,B			;Zeichen nach A
	CLR C			;Carry loeschen
	SUBB A,#20H       	;ASCII Kode korrigieren
        MOV R7,A		;letztes Zeichen nach R7
SER7:   CLR RI			;Empfangsflag loeschen
        CLR TI			;Sendeflag loeschen
	POP B
	POP PSW			;
	POP ACC		;
	RETI			;Zeichen ausserhalb dieser Anzeige



; ***********************************************************
; * Start of program                                        *
; ***********************************************************

START:  MOV SP,#70H
	MOV IE,#90H		;Int seriell  und allgemein frei
	MOV IP,#10H		;serieller Int hohe Prioritaet
	MOV SCON,#50H		;serielle Schnittstelle Mod 1
	MOV TMOD,#20H		;Timer 1 Mode 2 Timer 2 keine Funktion
	MOV PCON,#80H		;SMOD = 0 kein Teiler /2
	MOV TH1,#0F4H		;9600 baud bei 22,1184MHz
	SETB TR1		;Timer starten
	CLR RI			;Empfangsint loeschen
	CLR TI           	;Sendeint loeschen
	CALL PBE		;Positionsbestimmung im Verband
	CALL LOE		;Anfangszustand herstellen
	JMP ZZE         	;zum Beginn des Programms





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
        ADD A,ACC         	;A = A * 6
	MOV APOS,A		;Anfangsposition der Anzeige im Verband
	INC A			;2. Position der Anzeige berechnen
	MOV ZPOS,A		;zweite Position ablegen
	INC A			;3. Position im Verband berechnen
	MOV DPOS,A		;dritte Position der Anzeige ablegen
        INC A             	;4. Position im Verband bestimmen
        MOV VPOS,A        	;vierte Position der Anzeige ablegen
        INC A             	;5. Position im Verband bestimmen
        MOV FPOS,A        	;fuenfte Position der Anzeige ablegen
        INC A             	;6. Position im Verband berechnen
        MOV EPOS,A        	;sechste Position der Anzeige ablegen
	RET
;
; eigentliche Anzeigeroutine
;
ZZE:	MOV B,#06H		;sieben Zeilen
ZZS:	MOV A,R2		;First character
        ACALL AZGW		;wandeln
	MOVC A,@A+DPTR		;Zeichengeneratorcode holen
	ACALL ANZ	      	;erstes Zeichen in Schiebereg
	MOV A,R3          	;zweites Zeichen
        ACALL AZGW		;wandeln
	MOVC A,@A+DPTR		;Zeichengeneratorcode holen
	ACALL ANZ	      	;zweites Zeichen in Schiebereg
	MOV A,R4		;drittes Zeichen
	ACALL AZGW		;wandeln
	MOVC A,@A+DPTR		;Zeichengeneratorcode holen
	ACALL ANZ		;drittes Zeichen in Schiebereg
	MOV A,R5		;viertes Zeichen
	ACALL AZGW		;wandeln
	MOVC A,@A+DPTR		;Zeichengeneratorcode holen
	ACALL ANZ		;viertes Zeichen in Schiebereg
	MOV A,R6		;fuenftes Zeichen holen
	ACALL AZGW		;wandeln
	MOVC A,@A+DPTR		;Zeichengeneratorcode holen
	ACALL ANZ		;fuenftes Zeichen in Schiebereg
	MOV A,R7		;sechstes Zeichen holen
	ACALL AZGW		;wandeln
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
      	MOV A,B         	;nach A
	CJNE A,#0FFH,ZZS  	;wars schon Zeile Null ?
	AJMP ZZE		;und weiter gehts
;
ANZ:	MOV C,ACC.4		;Zustand Bit 5 aus ZG nach Carry
	MOV P1.7,C		;zum Portbit
	ACALL CLK		;Taktimpuls
	MOV C,ACC.3		;Zustand Bit 4 aus ZG nach Carry
	MOV P1.7,C		;zum Portbit
	ACALL CLK		;Taktimpuls
        MOV C,ACC.2     	;Zustand Bit 3 aus ZG nach Carry
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
LOE: 	PUSH B			;B auf Stack
	MOV B,#2EH		;6 Anzeigen = 30 Bit
LOE1:	SETB P1.7		;Daten auf High
	ACALL CLK		;Taktimpuls
	DJNZ B,LOE1		;alles auf High ?
	POP B
      	MOV A,#0FFH		;Zeichenzaehler auf
	MOV ZAE,A		;Anfangsposition setzen
	ORL P1,#07H		;alle Zeilen unscichtbar
	INC A			;A = 00H
	MOV R2,A          	;erstes Zeichen blank
	MOV R3,A          	;zweites Zeichen blank
	MOV R4,A          	;drittes Zeichen blank
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
AZGW:	


	RL	A
	RL	A
	RL	A
	MOV R1,A
	ANL A,#11111000B
	ADD A,B
	ADD A,#LOW BITMAP
	MOV DPL,A

	MOV A,R1
	ANL A,#00000111B
	ADD A,#HIGH BITMAP
	MOV DPH,A
        XRL A,ACC
	RET

;
ZEIT: 	PUSH B
	MOV B,#0FFH		;Zeitkonstante
ZEIT1:	DJNZ B,ZEIT1
      	POP B
	RET
;
	ORG BITMAP

ACZT: 	DB 0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,00H  ;Space
      	DB 0FBH,0FBH,0FBH,0FBH,0FBH,0FFH,0FBH,00H  ;!
	DB 0F5H,0F5H,0F5H,0FFH,0FFH,0FFH,0FFH,00H  ;"
	DB 0F5H,0F5H,0E0H,0F5H,0E0H,0F5H,0F5H,00H  ;#
	DB 0FBH,0F0H,0EBH,0F1H,0FAH,0E1H,0FBH,00H  ;$
	DB 0E3H,0EAH,0E5H,0FBH,0F4H,0EAH,0F8H,00H  ;%
	DB 0F7H,0EBH,0EBH,0F7H,0EAH,0EDH,0F2H,00H  ;&
	DB 0F9H,0F9H,0FDH,0FBH,0FFH,0FFH,0FFH,00H  ;'
	DB 0FDH,0FBH,0F7H,0F7H,0F7H,0FBH,0FDH,00H  ;(
	DB 0F7H,0FBH,0FDH,0FDH,0FDH,0FBH,0F7H,00H  ;)
	DB 0FBH,0EAH,0F1H,0FBH,0F1H,0EAH,0FBH,00H  ;*
	DB 0FFH,0FBH,0FBH,0E0H,0FBH,0FBH,0FFH,00H  ;+
	DB 0FFH,0FFH,0FFH,0F3H,0F3H,0FBH,0F7H,00H  ;,
	DB 0FFH,0FFH,0FFH,0F1H,0FFH,0FFH,0FFH,00H  ;-
	DB 0FFH,0FFH,0FFH,0FFH,0FFH,0F3H,0F3H,00H  ;.
	DB 0FFH,0FEH,0FDH,0FBH,0F7H,0EFH,0FFH,00H  ;/
	DB 0F1H,0EEH,0ECH,0EAH,0E6H,0EEH,0F1H,00H  ;0
	DB 0FBH,0F3H,0FBH,0FBH,0FBH,0FBH,0F1H,00H  ;1
	DB 0F1H,0EEH,0FEH,0F1H,0EFH,0EFH,0E0H,00H  ;2
	DB 0F1H,0EEH,0FEH,0F9H,0FEH,0EEH,0F1H,00H  ;3
	DB 0FDH,0F9H,0F5H,0EDH,0E0H,0FDH,0FDH,00H  ;4
	DB 0E0H,0EFH,0E1H,0FEH,0FEH,0FEH,0E1H,00H  ;5
	DB 0F9H,0F7H,0EFH,0E1H,0EEH,0EEH,0F1H,00H  ;6
	DB 0E0H,0FEH,0FDH,0FBH,0F7H,0F7H,0F7H,00H  ;7
	DB 0F1H,0EEH,0EEH,0F1H,0EEH,0EEH,0F1H,00H  ;8
	DB 0F1H,0EEH,0EEH,0F0H,0FEH,0FDH,0F3H,00H  ;9
        DB 0FFH,0F3H,0F3H,0FFH,0F3H,0F3H,0FFH,00H  ;:
	DB 0F3H,0FBH,0F3H,0F3H,0FFH,0F3H,0F3H,00H  ;;
	DB 0FDH,0FBH,0F7H,0EFH,0F7H,0FBH,0FDH,00H  ;<
	DB 0FFH,0FFH,0F1H,0FFH,0F1H,0FFH,0FFH,00H  ;=
	DB 0F7H,0FBH,0FDH,0FEH,0FDH,0FBH,0F7H,00H  ;>
	DB 0F1H,0EEH,0FEH,0FDH,0FBH,0FFH,0FBH,00H  ;?
        DB 0F1H,0EEH,0FEH,0F2H,0EAH,0EAH,0F1H,00H  ;@
	DB 0FBH,0F5H,0EEH,0EEH,0E0H,0EEH,0EEH,00H  ;A
	DB 0E1H,0F6H,0F6H,0F1H,0F6H,0F6H,0E1H,00H  ;B
	DB 0F1H,0EEH,0EFH,0EFH,0EFH,0EEH,0F1H,00H  ;C
	DB 0E1H,0F6H,0F6H,0F6H,0F6H,0F6H,0E1H,00H  ;D
	DB 0E0H,0EFH,0EFH,0E3H,0EFH,0EFH,0E0H,00H  ;E
	DB 0E0H,0EFH,0EFH,0E3H,0EFH,0EFH,0EFH,00H  ;F
	DB 0F1H,0EEH,0EFH,0E8H,0EEH,0EEH,0F1H,00H  ;G
	DB 0EEH,0EEH,0EEH,0E0H,0EEH,0EEH,0EEH,00H  ;H
	DB 0F1H,0FBH,0FBH,0FBH,0FBH,0FBH,0F1H,00H  ;I
	DB 0F8H,0FDH,0FDH,0FDH,0FDH,0FDH,0F3H,00H  ;J
	DB 0EEH,0EDH,0EBH,0E7H,0EBH,0EDH,0EEH,00H  ;K
	DB 0EFH,0EFH,0EFH,0EFH,0EFH,0EFH,0E0H,00H  ;L
	DB 0EEH,0E4H,0EAH,0EAH,0EEH,0EEH,0EEH,00H  ;M
	DB 0EEH,0E6H,0EAH,0ECH,0EEH,0EEH,0EEH,00H  ;N
	DB 0F1H,0EEH,0EEH,0EEH,0EEH,0EEH,0F1H,00H  ;O
	DB 0E1H,0EEH,0EEH,0E1H,0EFH,0EFH,0EFH,00H  ;P
	DB 0F1H,0EEH,0EEH,0EEH,0EAH,0EDH,0F2H,00H  ;Q
	DB 0E1H,0EEH,0EEH,0E1H,0EBH,0EDH,0EEH,00H  ;R
	DB 0F1H,0EEH,0EFH,0F1H,0FEH,0EEH,0F1H,00H  ;S
	DB 0E0H,0FBH,0FBH,0FBH,0FBH,0FBH,0FBH,00H  ;T
        DB 0EEH,0EEH,0EEH,0EEH,0EEH,0EEH,0F1H,00H  ;U
	DB 0EEH,0EEH,0EEH,0F5H,0F5H,0FBH,0FBH,00H  ;V
	DB 0EEH,0EEH,0EEH,0EAH,0EAH,0E4H,0EEH,00H  ;W
	DB 0EEH,0EEH,0F5H,0FBH,0F5H,0EEH,0EEH,00H  ;X
	DB 0EEH,0EEH,0F5H,0FBH,0FBH,0FBH,0FBH,00H  ;Y
	DB 0E0H,0FEH,0FDH,0FBH,0F7H,0EFH,0E0H,00H  ;Z
	DB 0F1H,0F7H,0F7H,0F7H,0F7H,0F7H,0F1H,00H  ;[
	DB 0FFH,0EFH,0F7H,0FBH,0FDH,0FEH,0FFH,00H  ;\
	DB 0F1H,0FDH,0FDH,0FDH,0FDH,0FDH,0F1H,00H  ;[
	DB 0FBH,0F5H,0EEH,0FFH,0FFH,0FFH,0FFH,00H  ;^
	DB 0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0E0H,00H  ;_
        DB 0F3H,0F3H,0F7H,0FBH,0FFH,0FFH,0FFH,00H  ;'
	DB 0FFH,0FFH,0F1H,0FEH,0F0H,0EEH,0F1H,00H  ;a
	DB 0EFH,0EFH,0E9H,0E6H,0EEH,0E6H,0E9H,00H  ;b
	DB 0FFH,0FFH,0F8H,0F7H,0F7H,0F7H,0F8H,00H  ;c
	DB 0FEH,0FEH,0F2H,0ECH,0EEH,0ECH,0F2H,00H  ;d
	DB 0FFH,0FFH,0F1H,0EEH,0E0H,0EFH,0F1H,00H  ;e
	DB 0F9H,0F6H,0F7H,0E1H,0F7H,0F7H,0F7H,00H  ;f
	DB 0FFH,0FFH,0F0H,0EEH,0F0H,0FEH,0F1H,00H  ;g
	DB 0EFH,0EFH,0E9H,0E6H,0EEH,0EEH,0EEH,00H  ;h
	DB 0FBH,0FFH,0F3H,0FBH,0FBH,0FBH,0F1H,00H  ;i
	DB 0FDH,0FFH,0F9H,0FDH,0FDH,0FDH,0F3H,00H  ;j
	DB 0F7H,0F7H,0F6H,0F5H,0F3H,0F5H,0F6H,00H  ;k
	DB 0F3H,0FBH,0FBH,0FBH,0FBH,0FBH,0F1H,00H  ;l
	DB 0FFH,0FFH,0E5H,0EAH,0EAH,0EAH,0EAH,00H  ;m
	DB 0FFH,0FFH,0E9H,0E6H,0EEH,0EEH,0EEH,00H  ;n
	DB 0FFH,0FFH,0F1H,0EEH,0EEH,0EEH,0F1H,00H  ;o
	DB 0FFH,0FFH,0E1H,0EEH,0E1H,0EFH,0EFH,00H  ;p
	DB 0FFH,0FFH,0F0H,0EEH,0F0H,0FEH,0FEH,00H  ;q
	DB 0FFH,0FFH,0E9H,0E6H,0EFH,0EFH,0EFH,00H  ;r
	DB 0FFH,0FFH,0F0H,0EFH,0F1H,0FEH,0E1H,00H  ;s
	DB 0FBH,0FBH,0F0H,0FBH,0FBH,0FBH,0FCH,00H  ;t
	DB 0FFH,0FFH,0EEH,0EEH,0EEH,0ECH,0F2H,00H  ;u
	DB 0FFH,0FFH,0EEH,0EEH,0EEH,0F5H,0FBH,00H  ;v
	DB 0FFH,0FFH,0EEH,0EEH,0EAH,0EAH,0F4H,00H  ;w
        DB 0FFH,0FFH,0EEH,0F5H,0FBH,0F5H,0EEH,00H  ;x
	DB 0FFH,0FFH,0EEH,0F5H,0FBH,0FBH,0F3H,00H  ;y
        DB 0FFH,0FFH,0E0H,0FDH,0FBH,0F7H,0E0H,00H  ;z
	DB 0F9H,0F7H,0F7H,0E7H,0F7H,0F7H,0F7H,00H  ;{
	DB 0FBH,0FBH,0FBH,0FFH,0FBH,0FBH,0FBH,00H  ;|
	DB 0F3H,0FDH,0FDH,0FCH,0FDH,0FDH,0F3H,00H  ;}
	DB 0F5H,0EAH,0FFH,0FFH,0FFH,0FFH,0FFH,00H  ;~
	DB 0F5H,0EAH,0F5H,0EAH,0F5H,0EAH,0F5H,00H  ;DEL

	DB 0DH
	DB 0AH
	DB 0DH
	DB 0AH

END
