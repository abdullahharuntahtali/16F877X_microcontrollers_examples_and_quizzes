list p=16F877A;derleyici için bilgi verildi
#include <P16F877A.inc>;gerekli isim-adress eþleþmesi yapýldý
__config H'3F31'
SAYAC1 EQU 0X20;sayac1 deðiþkeni adresi tanmlandý
SAYAC2 EQU 0X22;sayac2 deðiþkeni adresi tanmlandý
SAYAC3 EQU 0X25;sayac3 deðiþkeni adresi tanmlandý
ORG 0X00;reset vektör adresi
GOTO ANA_PROGRAM ;ana programa git
ORG 0X004; ;kesme vektör adresi
KESME;--------------------------------------------------------------
BTFSS INTCON,5;tmr0 kesmesine izin verilmiþ mi bak
GOTO KESME_BÝTÝR
BTFSS INTCON,2 ;tmr0 kesmesi bayraðý kalkmýþ mý bak
GOTO KESME_BÝTÝR
BCF INTCON,2 ;tekrar kesme gelebilmesi için bayraðý indir
MOVLW D'6' ; 
MOVWF TMR0; tmr0'a 6 ön deðerini yükle
INCF SAYAC1,F ;sayac1'in deðerini artýr
INCF SAYAC2,F; sayac2'in deðerini artýr
MOVLW D'125' 
SUBWF SAYAC1,W ;sayac1 - working
BTFSS STATUS,C ; sayac1-working>=0 ise c=1 olur
GOTO KONTROL 
GOTO LEDYAK1 ;c=1 ise 1.led yak
KONTROL;------------------------------------------------------------
MOVLW D'200' 
SUBWF SAYAC2,W ;sayac2 - working
BTFSS STATUS,C ;sayac2 - working>=0 ise c=1
GOTO KESME_BÝTÝR
CLRF SAYAC2 ;sayac2 sýfýrla
BTFSS PORTD,1 ;led2 yanýyor mu?
GOTO YAK2 ;sönükse yak
BCF PORTD,1 ;yanýyorsa söndür
GOTO KESME_BÝTÝR
LEDYAK1;------------------------------------------------------------
INCF SAYAC3,F ;kesiþim kontrolü için sayaç
CLRF SAYAC1 ;sayac1 i sýfýrla
BTFSC SAYAC3,3 ;sayac3 8 mi
GOTO KESÝSÝM;sayac3 8 oldu ise git kesisim'e
BTFSS PORTD,0 ; led1 yanýyormu
GOTO YAK1 ;sönükse yak
BCF PORTD,0 ;yanýksa söndür
GOTO KESME_BÝTÝR
KESÝSÝM;----------------------------------------------------------------
CLRF SAYAC2 ;sayac2 sýfýrla
CLRF SAYAC3  ;sayac1 sýfýrla
BTFSS PORTD,0 ;led1 yanýyormu?
GOTO YAK1 ;yanmýyorsa yak
BCF PORTD,0 ;yanýyorsa söndür
BTFSS PORTD,1 ;led2 yanýyormu?
GOTO YAK2 ;yanmýyorsa yak
BCF PORTD,1;yanýyorsa söndür
KESME_BÝTÝR;--------------------------------------------------------
RETFIE
YAK1;---------------------------------------------------------------
BSF PORTD,0
GOTO KESME_BÝTÝR
YAK2;---------------------------------------------------------------
BSF PORTD,1
GOTO KESME_BÝTÝR
ANA_PROGRAM;--------------------------------------------------------
BSF STATUS,RP0 ;01 nolu banka geçiþ yapýldý
CLRF TRISD ;portd çýkýþ yapýldý
MOVLW B'00000100' ; prescaler deðeri 1/16 yapýldý
MOVWF OPTION_REG 
MOVLW B'10100000' ;genel ve tmr0 kesmelerine izin verildi
MOVWF INTCON
BCF STATUS,RP0 ;00 nolu bank'a geçildi
CLRF PORTD ;portd sýfýrlandý
MOVLW D'6' ;tmr0 6 ön deðeri yüklendi
MOVWF TMR0 
CLRF SAYAC1 ;sýfýrlama iþlemleri yapýldý
CLRF SAYAC2
CLRF SAYAC3
DONGU
GOTO DONGU ;dön
END
