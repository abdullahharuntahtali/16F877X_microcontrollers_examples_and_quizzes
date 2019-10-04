list p=16F877A
#include <P16F877A.inc>
__config H'3F31'
BUTONLAR EQU 0X25
ORG 0X00; Ana program baslangic adresi
GOTO ANA_PROGRAM
ORG 0X004; kesme baslangic adresi
RETFIE
ANA_PROGRAM
BSF STATUS,RP0; Bank-1'e gecis yapildi
BCF OPTION_REG,7; PortB Pull-up register aktif
MOVLW H'0F'
MOVWF TRISB;PortB ilk dört bit giris, son dört bit cikisi
BCF STATUS,RP0;Bank-0 secildi
DONGU
MOVF PORTB,W; PortB W registerine aktarildi
MOVWF BUTONLAR; sonuc 0x25 adresine yazildi
COMF BUTONLAR,F
SWAPF BUTONLAR,W; 25h adresindeki ilk dört bit ile
;son dört bit yer degistirildi
MOVWF PORTB; sonuc PORTB'ye gönderildi
GOTO DONGU
END