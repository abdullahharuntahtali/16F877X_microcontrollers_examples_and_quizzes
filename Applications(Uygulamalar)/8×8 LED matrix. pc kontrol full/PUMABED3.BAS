REM Demoprogramm zur Ansteuerung der Punktmatrixanzeige
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
REM ------------------------------------------------------
    CLS
    LOCATE 10, 10
    PRINT "Demoprogramm fuer Laufschrift"
    LOCATE 12, 10
    PRINT "Abbruch mit beliebiger Taste"
    Z$ = "Diese Schaltung wurde von Andreas Koehler fuer ELEKTOR entwickelt."
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







