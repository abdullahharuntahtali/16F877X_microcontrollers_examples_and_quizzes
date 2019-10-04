REM Programm zur Ansteuerung der Punktmatrixanzeige
REM mit Leuchtdioden 5*7 Matrix
REM Der Text wird von rechts nach links durchgeschoben
REM bis die Anzeige wieder vollstaendig geloescht ist
REM Danach Pause von 1s und Beginn von vorn falls keine
REM Tastenbetaetigung
REM --------------------------------------------------
REM Schnittstelleninit
REM --------------------------------------------------
   OPEN "COM2:9600,N,8,1,CS,DS" FOR OUTPUT AS #1
   PRINT #1, CHR$(12);
REM Eingabeaufforderung auf dem Bildschirm
REM --------------------------------------------------
CLS
LOCATE 10, 1
    PRINT " Geben Sie bitte den Text ein :"
    PRINT "Maximal 120 Zeichen einschlieálich Leerzeichen"
LOCATE 15, 1
REM ------------------------------------------------------
REM Eingabeschleife
REM ------------------------------------------------------
    Z$ = ""
    AN = 0
M1: A$ = INKEY$
    IF A$ = "" THEN GOTO M1
    PRINT A$;
    IF A$ = CHR$(13) THEN GOTO M2
    Z$ = Z$ + A$
    AN = AN + 1
    IF AN < 121 THEN GOTO M1
REM -------------------------------------------------------
REM Ausgabeschleife
REM -------------------------------------------------------
M2: V = 0
M3:    FOR ZA = V + 1 TO V + 12
       PRINT #1, MID$(Z$, ZA, 1);
       NEXT ZA
    V = V + 1
       FOR ZT = 1 TO 50000
       NEXT ZT
       PRINT #1, CHR$(12);
    IF V < LEN(Z$) THEN GOTO M3
    SLEEP (1)
    A$ = INKEY$
    IF A$ = "" GOTO M2
    END







