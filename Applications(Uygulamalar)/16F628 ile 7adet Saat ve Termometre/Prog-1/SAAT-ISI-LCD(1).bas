'****************************************************************
'*  Name    : KESMETMR0.BAS                                      *
'*  Author  : [Erol Tahir Erdal]                                *
'*  Notice  : Copyright (c) 2005 [ETE]                          *
'*          : All Rights Reserved                               *
'*  Date    : 23.04.2005                                        *
'*  Version : 1.0                                               *
'*  Notes   :                                                   *
'*          :(1)LCD                                                  *
'****************************************************************
PORTA=0:portb=0
TRISB=%11110000   'PortB tamamý giriþ yapýldý.
TRISA=%00000111   'A portu tamamý çýkýþ yapýldý.
'-----------------------------------------------------------------
@ DEVICE pic16F628                      'iþlemci 16F628                                
@ DEVICE pic16F628, WDT_ON              'Watch Dog timer açýk
@ DEVICE pic16F628, PWRT_ON             'Power on timer açýk
@ DEVICE pic16F628, PROTECT_OFF         'Kod Protek kapalý
@ DEVICE pic16F628, MCLR_off            'MCLR pini kullanýlýyor.
@ DEVICE pic16F628, XT_OSC
'@ DEVICE pic16F628, INTRC_OSC_NOCLKOUT  'Dahili osilatör kullanýlacak 
'-----------------------------------------------------------------
DEFINE LCD_DREG		PORTB	'LCD data bacaklarý hangi porta baðlý?
DEFINE LCD_DBIT		4		'LCD data bacaklarý hangi bitten baþlýyor?
DEFINE LCD_EREG		PORTB	'LCD Enable Bacaðý Hangi Porta baðlý?
DEFINE LCD_EBIT		3		'LCD Enable Bacaðý Hangi bite baðlý ?
define LCD RWREG    PORTB   'LCD R/W Bacaðý Hangi Porta baðlý?
define LCD_RWBIT    2       'LCD R/W Bacaðý Hangi bite baðlý ?
DEFINE LCD_RSREG	PORTB	'LCD RS Bacaðý Hangi Porta baðlý ?
DEFINE LCD_RSBIT	1		'LCD RS bacaðý Hangi Bite baðlý  ?
DEFINE LCD_BITS		4		'LCD 4 bit mi yoksa 8 bit olarak baðlý?
DEFINE LCD_LINES	2		'LCD Kaç sýra yazabiliyor
'DEFINE OSC 4
'-------------------------------------------------------------------------
ON INTERRUPT GoTo KESME   'kesme oluþursa KESME adlý etikete git.
OPTION_REG=%10000101   'Pull up dirençleri ÝPTAL- Bölme oraný 1/64.
INTCON=%10100000  'Kesmeler aktif ve TMR0 kesmesi aktif
TMR0=0
CMCON=7    '16F628 de komparatör pinleri iptal hepsi giriþ çýkýþ
'----------------------------------------------------------------------------
Comm_Pin    VAR	Portb.0     ' One-wire Data-Pin "DQ" PortB.0 da
Busy        VAR BIT         ' Busy Status-Bit
HAM         VAR	WORD        ' Sensör HAM okuma deðeri
ISI         VAR WORD        ' Hesaplanmýþ ISI deðeri
Float       VAR WORD        ' Holds remainder for + temp C display
X           VAR WORD       
SIGN_BITI   VAR HAM.Bit11   '   +/- sýcaklýk Ýþaret biti,  1 = olursa eksi sýcaklýk
NEGAT_ISI   CON 1           ' Negatif_Cold = 1
Deg         CON 223         ' ° iþareti
SIGN        VAR BYTE        '  ISI deðeri için  +/-  iþaret
TEMP        VAR BYTE         ' Div32 bit hesap için geçici deðiþken
SAYAC       VAR   BYTE
SN          VAR   BYTE
DAK         VAR   BYTE
SAAT        VAR   BYTE
GUN         VAR   BYTE
symbol  SEC=PORTA.0
SYMBOL  YUKARI=PORTA.2
SYMBOL  ASAGI =PORTA.1
'-----------------------------------------------------------------------------
CLEAR  'tüm deðiþkenler sýfýrlandý
PAUSE 200
LCDOUT $FE,1

'-----------------------------------------------------------------------------

BASLA:
      GOSUB EKRAN0        'SAATÝ EKRANA YAZ
      if SEC=0 THEN AYAR  'MODE TUÞUNA BASILMIÞ ÝSE AYAR'A GÝT
      gosub SENSOROKU     'SONSÖR OKU VE SICAKLIÐI EKRANA YAZ
      GOTO BASLA
      
EKRAN0:
       LCDOUT $FE,$84,DEC2 SAAT,":",DEC2 DAK:RETURN
       
AYAR:  
       WHILE SEC=0 
       WEND
HOUR:  GOSUB EKRAN0
       LCDOUT $FE,$84
       lcdout $FE,$0E  'ÇÝZGÝLÝ KURSÖR AÇIK
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
        
MINBIR: WHILE SEC=0
        WEND
        
MINUTE: GOSUB EKRAN0
       LCDOUT $FE,$87
        IF SEC=0 THEN SECBIR
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
SECOND: 
        GOSUB EKRAN0
        LCDOUT $FE,$8A
        IF SEC=0 THEN ARA
        IF YUKARI=0 THEN
           SN=SN+1
           IF SN=60 THEN SN=0
        ENDIF
        IF ASAGI=0 THEN
           SN=SN-1
           IF SN=255 THEN SN=0
        ENDIF
        GOSUB GECIKME
        GOTO SECOND

GECIKME:
        FOR X=0 TO 1800
        PAUSEUS 100
        NEXT
        RETURN

ARA:    LCDOUT $FE,$0C
        WHILE SEC=0  
        wend
'        gosub GECIKME
        goto BASLA
                
        
'----------------ISI SENSÖR OKUMA BÖLÜMÜ --------------------------------
SENSOROKU: 
           'ham=$FE6F:Gosub hesapla:RETURN bu satýr normal devrede silinecek
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
    LCDOUT $FE,$C4,Sign,DEC ISI,".",DEC1 (Float)," ",Deg,"C " '2. satýrda ýsý
    RETURN

DISABLE
KESME:
      SAYAC=SAYAC+1  'kesme sayacý  1 sn= 61(sayac) x 256 (Tmr0) x 64 (bölme)
      IF SAYAC=61 then  '61 adet kesme olunca 1 sn. süre geçiyor.(999424 us)
         SAYAC=0        'sayaç sýfýrlanýyor
          SN=SN+1
          toggle portb.0       'saniye deðeri bir artýrýlýyor
            IF SN=60 THEN  'saniye 60 olmuþ ise 1 dakika süre geçti ohalde
              SN=0        ' saniye sýfýrlanýyor
               DAK=DAK+1   ' dakika deðeri bir artýrýlýyor
                  IF DAK=60 then   'dakika 60 olmuþ ise 1 saat süre geçti
                     DAK=0         ' dakika sýfýrlanýyor
                     SAAT=SAAT+1   ' saat deðeri bir artýrýlýyor
                        IF SAAT=24 THEN  'saat 24 olmuþ ise 1 gün geçti
                           SAAT=0        'saat sýfýrlanýyor
'                           GUN=GUN+1     'gün deðeri bir artýrýlýyor
'                              IF GUN=365 THEN GUN=0  'gün 365 olmuþ ise
                        endif                    'gün sýfýrlanýyor 1 yýl geçti
                  ENDIF 
            ENDIF
           lcdout $fe,$89,":",DEC2 SN
          ENDIF
CIK:     INTCON.2=0        'TMR0 Kesme bayraðý sýfýrlanýyor
         RESUME
         ENABLE
         
END
         
                      
