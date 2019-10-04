	list p=16F877A
	include "p16F877A.inc"	
	Sayac_Adres equ 0x21
	Sayac_Deger equ 0x22
	Durum equ 0x23
	ORG 	0			
	clrf 	PCLATH			
	goto 	ana_program		
	ORG	4	

Kesme
	BANKSEL PIR2
	BTFSS PIR2,EEIF
	goto Cikis
	
	BCF PIR2,EEIF

	BANKSEL EECON1
	bcf EECON1, WREN                 ;Yazma izni kaldýrýldý.

	BANKSEL Sayac_Adres
	decfsz Sayac_Adres
	goto Devam
	goto Cikis

Devam
	BSF Durum,0
	incf Sayac_Deger
	
Okuma_Ayari
	movf Sayac_Adres,w 
    banksel EEADR                                                   
	movwf 	EEADR 
	banksel EECON1
	bcf	EECON1,EEPGD                     ;Veri belleðine eriþim izni.
	bsf	EECON1, RD                       ;EEPROM Okuma modunda.
	banksel EEDATA
	movf	EEDATA, W
	banksel PORTD                        
	movwf	PORTD                        ;EEDATA daki deðer PORTD ye gönderiliyor.

Cikis
	BANKSEL Durum
	retfie

ana_program
	BSF STATUS,RP0
	clrf	TRISD                        ;PORTD çýkýþa yönlendirildi.
	BCF 	STATUS, RP0                                      
	clrf	PORTD
	movlw 0XFF
	movwf Sayac_Adres
	clrf Sayac_Deger
	clrf Durum
	
	BSF PIR2,EEIF

	BSF STATUS,RP0
	BSF PIE2,EEIE               

	BSF INTCON,PEIE
	BSF INTCON,GIE
    
	BANKSEL Sayac_Adres
    
Yazma_Ayari
	movf Sayac_Adres,w
	banksel EEADR                                                  
	movwf 	EEADR 
	BANKSEL Sayac_Deger
	movf Sayac_Deger,w        ; 01010101         ; Adres bilgisi yüklendi.
	banksel EEDATA
	movwf	EEDATA                       ;EEDATA ya yani EEPROM a yazýlacak veri 
                                         ;ADC De dönüþtürülen en deðersiz 8 bit.
	banksel EECON1                      
	bcf	EECON1,EEPGD                     ;Veri belleðine eriþim izni.
	bsf	EECON1, WREN                     ;Yazma etkinleþtirme bit’i set edildi.
	movlw	0x55                         ;Yazma için buradan itibaren 5 satýr aynen korunmalý.                                  
	movwf	EECON2
	movlw	0xAA
	movwf	EECON2
	bsf	EECON1, WR                       ;Yaz komutu verildi.
	
	BANKSEL Durum
	BCF Durum,0

Dongu
	btfss Durum,0					                 ;Gecikme Programý
	goto Dongu                              
 	goto Yazma_Ayari
END

