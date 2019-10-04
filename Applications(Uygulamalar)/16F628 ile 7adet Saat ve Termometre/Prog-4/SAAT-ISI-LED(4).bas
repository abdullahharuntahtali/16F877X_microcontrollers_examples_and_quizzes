'****************************************************************
'*  Name    : SAAT-TERMO.BAS                                      *
'*  Author  : [Erol Tahir Erdal]                                *
'*  Notice  : Copyright (c) 2005 [ETE]                          *
'*          : All Rights Reserved                               *
'*  Date    : 23.06.2005                                        *
'*  Version : 1.0  LED (4)                                             *
'*  Notes   : SICAKLIK KUSURAT YAZMIYOR AMA EKSI SICAKLIK       *
'*          :  GOSTEREBÝLÝYOR                                   *
'****************************************************************
PORTA=255:portb=0
TRISB=1   
TRISA=%00011111  
'-----------------------------------------------------------------
@ DEVICE pic16F628                      'iþlemci 16F628                                
@ DEVICE pic16F628, WDT_ON              'Watch Dog timer açýk
@ DEVICE pic16F628, PWRT_ON             'Power on timer açýk
@ DEVICE pic16F628, PROTECT_OFF         'Kod Protek kapalý
@ DEVICE pic16F628, MCLR_off            'MCLR pini kullanýlMIYOR.
@ DEVICE pic16F628, INTRC_OSC_NOCLKOUT  'Dahili osilatör kullanýlacak 
'-----------------------------------------------------------------
'DEFINE OSC 4
'-------------------------------------------------------------------------
ON INTERRUPT GoTo KESME   'kesme oluþursa KESME adlý etikete git.
OPTION_REG=%0100000    'dahili Pull up dirençleri aktif edildi ayrýca pullup direncine gerek yok.
INTCON=%10010000  'Kesmeler aktif ve RB0/INT kesmesi aktif

CMCON=7    '16F628 de komparatör pinleri iptal hepsi giriþ çýkýþ
'----------------------------------------------------------------------------
Comm_Pin    VAR	PortA.4     ' One-wire Data-Pin "DQ" PortB.0 da
Busy        VAR BIT         ' Busy Status-Bit
POZ         VAR BIT        
HAM         VAR	WORD        ' Sensör HAM okuma deðeri
ISI         VAR WORD        ' Hesaplanmýþ ISI deðeri
Float       VAR WORD        ' Holds remainder for + temp C display
X           VAR WORD  
Y           VAR BYTE  
SAYI        VAR BYTE   
SIGN_BITI   VAR HAM.Bit11   '   +/- sýcaklýk Ýþaret biti,  1 = olursa eksi sýcaklýk
NEGAT_ISI   CON 1           ' Negatif_Cold = 1
Deg         CON 223         ' ° iþareti
SIGN        VAR BYTE        '  ISI deðeri için  +/-  iþaret
TEMP        VAR BYTE         ' Div32 bit hesap için geçici deðiþken
SAYAC       VAR BYTE
SN          VAR BYTE
DAK         VAR BYTE
SAAT        VAR BYTE
GUN         VAR BYTE
symbol  SEC   =PORTA.0
SYMBOL  ASAGI =PORTA.1 
SYMBOL  YUKARI=PORTA.2
SYMBOL  DTA=PORTA.6
SYMBOL  CLK=PORTB.1

'-----------------------------------------------------------------------------
CLEAR  'tüm deðiþkenler sýfýrlandý
PAUSE 200
Y=1 :POZ=0
'-----------------------------------------------------------------------------
 PORTB=0  
BASLA: 
       IF Y>6 THEN
           IF Y>=11 THEN Y=1
           GOSUB EKRAN1
           GOTO ATLA
       ENDIF        
       GOSUB EKRAN0
       
ATLA:  if SEC=0 THEN AYAR  'MODE TUÞUNA BASILMIÞ ÝSE AYAR'A GÝT
       gosub SENSOROKU     'SONSÖR OKU VE SICAKLIÐI EKRANA YAZ
       GOTO BASLA

EKRAN0:if PORTB.0=1 then low porta.3
       X= SAAT DIG 1:GOSUB AL
       SHIFTOUT DTA,CLK,1,[SAYI]
       HIGH PORTB.2:PAUSEUS 2:LOW PORTB.2
       
       X= SAAT DIG 0:GOSUB AL
       SHIFTOUT  DTA,CLK,1,[SAYI]
       HIGH PORTB.3:PAUSEUS 2:LOW PORTB.3 

       X= DAK DIG 1:GOSUB AL
       SHIFTOUT DTA,CLK,1,[SAYI]
       HIGH PORTB.4:PAUSEUS 2:LOW PORTB.4
       
       X= DAK DIG 0:GOSUB AL
       SHIFTOUT DTA,CLK,1,[SAYI]
       HIGH PORTB.5:PAUSEUS 2:LOW PORTB.5
       
       X= sn DIG 1:GOSUB AL
       SHIFTOUT DTA,CLK,1,[SAYI]
       HIGH PORTB.6:PAUSEUS 2:LOW PORTB.6
       
       X= SN DIG 0:GOSUB AL
       SHIFTOUT DTA,CLK,1,[SAYI]
       HIGH PORTB.7:PAUSEUS 2:LOW PORTB.7
       RETURN
       
AL:    LOOKUP X,[63,6,91,79,102,109,125,7,127,111,99,57],SAYI :RETURN

EKRAN1:LOW PORTA.3 
       SAYI=0
       SHIFTOUT DTA,CLK,1,[SAYI]
       HIGH PORTB.2:PAUSEUS 2:LOW PORTB.2
       IF SIGN_BITI = NEGAT_ISI THEN SAYI=64
       SHIFTOUT DTA,CLK,1,[SAYI]
       HIGH PORTB.3:PAUSEUS 2:LOW PORTB.3
       
       x=(ISI DIG 1):GOSUB AL
       SHIFTOUT DTA,CLK,1,[SAYI]
       HIGH PORTB.4:PAUSEUS 2:LOW PORTB.4
       x=(ISI DIG 0):GOSUB AL
       SHIFTOUT DTA,CLK,1,[SAYI]
       HIGH PORTB.5:PAUSEUS 2:LOW PORTB.5
       X=10:GOSUB AL 
       SHIFTOUT DTA,CLK,1,[SAYI]
       HIGH PORTB.6:PAUSEUS 2:LOW PORTB.6 
       X=11:GOSUB AL
       SHIFTOUT DTA,CLK,1,[SAYI]
       HIGH PORTB.7:PAUSEUS 2:LOW PORTB.7
       RETURN
       
AYAR:  POZ=1:SN=0 
       gosub FLASH       
       WHILE SEC=0 
       WEND
HOUR:  GOSUB EKRAN0
       LOW PORTA.3
       IF SEC=0 THEN MINBIR
       IF YUKARI=0 THEN
          SAAT=SAAT+1
          IF SAAT=24 THEN SAAT=0       
        ENDIF   
        IF ASAGI=0 THEN
           SAAT=SAAT-1
           IF SAAT=255 THEN SAAT=23
        ENDIF   
        GOSUB GECIKME
        GOTO HOUR
        
MINBIR: 
        GOSUB FLASH
        WHILE SEC=0
        WEND
        
MINUTE: GOSUB eKRAN0
       LOW PORTA.3
       IF SEC=0 THEN ara
        IF YUKARI=0 THEN
           DAK=DAK+1
           IF DAK=60 THEN DAK=0
        ENDIF
        IF ASAGI=0 THEN
           DAK=DAK-1
           IF DAK=255 THEN DAK=59              
        ENDIF
        GOSUB GECIKME
        GOTO MINUTE
        
SECBIR: WHILE SEC=0
        WEND

GECIKME:
        FOR X=0 TO 1800
        PAUSEUS 100
        NEXT
        RETURN

ARA:    
        GOSUB FLASH
        HIGH PORTA.3
        WHILE SEC=0  
        wend
        POZ=0
        goto BASLA

FLASH:
      TOGGLE PORTA.3:PAUSE 150:TOGGLE PORTA.3:PAUSE 150
      TOGGLE PORTA.3:PAUSE 150:TOGGLE PORTA.3:PAUSE 150 
      return               

'----------------ISI SENSÖR OKUMA BÖLÜMÜ --------------------------------
SENSOROKU:
           ham=$ff5e:Gosub hesapla:return 'NORMAL ÇALIÞMADA BU SATIR SÝLÝNECEK
           OWOUT   Comm_Pin, 1, [$CC, $44]' ISI deðerini oku
Bekle:
           OWIN    Comm_Pin, 4, [Busy]    ' Busy deðerini oku
           IF      Busy = 0 THEN Bekle  ' hala meþgulmü? , evet ise goto Bekle..!
           OWOUT   Comm_Pin, 1, [$CC, $BE]' scratchpad memory oku
           OWIN    Comm_Pin, 2, [HAM.Lowbyte, HAM.Highbyte]' Ýki byte oku ve okumayý bitir.
           GOSUB   Hesapla
           RETURN
    
Hesapla:                 ' Ham deðerden Santigrat derece hesabý
    Sign  = "+"
    IF SIGN_BITI = NEGAT_ISI THEN
       Sign   = "-"  
       temp=($ffff-ham+1)*625
       ISI  = DIV32 10 
       GOTO GEC   
    endif
    TEMP = 625 * (HAM+1)        ' 
    ISI = DIV32 10          ' Div32 hassas derece hesabý için 32 bit bölme yapýyoruz.
GEC:
    FLOAT = (ISI //1000)/100
    ISI=ISI/1000
    RETURN                      

DISABLE
KESME:   IF POZ=1 then CIK
         SN=SN+1 
          Y=Y+1       'saniye deðeri bir artýrýlýyor
           if y<7 then high porta.3
            IF SN=60 THEN  'saniye 60 olmuþ ise 1 dakika süre geçti ohalde
              SN=0        ' saniye sýfýrlanýyor
               DAK=DAK+1   ' dakika deðeri bir artýrýlýyor
                  IF DAK=60 then   'dakika 60 olmuþ ise 1 saat süre geçti
                     DAK=0         ' dakika sýfýrlanýyor
                     SAAT=SAAT+1   ' saat deðeri bir artýrýlýyor
                        IF SAAT=24 THEN  'saat 24 olmuþ ise 1 gün geçti
                           SAAT=0        'saat sýfýrlanýyor
                        ENDIF 
                  ENDIF
            ENDIF
CIK:     INTCON.1=0  'TMR0 Kesme bayraðý sýfýrlanýyor
         RESUME
         ENABLE
         
END
         
                      
