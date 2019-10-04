	list p=16F877A
	include "p16F877A.inc"	

	ORG 	0			
	clrf 	PCLATH			
	goto 	ana_program		
	ORG	4	

Kesme
	Retfie

Yazma_Ayari
	banksel EEADR 
	movlw 0X50                                                    
	movwf 	EEADR 
	movlw 0x55        ; 01010101         ; Adres bilgisi yüklendi.
	movwf	EEDATA                       ;EEDATA ya yani EEPROM a yazýlacak veri 
                                         ;ADC De dönüþtürülen en deðersiz 8 bit.
	banksel EECON1                      
	bcf	EECON1,EEPGD                     ;Veri belleðine eriþim izni.
	bcf	INTCON, GIE                      ;Genel kesmeler pasif. (Yazmada iþlem akýþý bozulmamalý.)
	bsf	EECON1, WREN                     ;Yazma etkinleþtirme bit’i set edildi.
	movlw	0x55                         ;Yazma için buradan itibaren 5 satýr aynen korunmalý.                                  
	movwf	EECON2
	movlw	0xAA
	movwf	EECON2
	bsf	EECON1, WR                       ;Yaz komutu verildi.
	
Yazma_Bekle
	btfsc 	EECON1, WR                   ;Yazma iþlemi tamamlanana kadar bekle (WR=0 olana kadar).
	goto 	Yazma_Bekle
	bcf 	EECON1, WREN                 ;Yazma izni kaldýrýldý.
	return

Okuma_Ayari
	banksel EEADR 
	movlw 0x50                                                         
	movwf 	EEADR 
	banksel EECON1
	bcf	EECON1,EEPGD                     ;Veri belleðine eriþim izni.
	bsf	EECON1, RD                       ;EEPROM Okuma modunda.
	banksel EEDATA
	movf	EEDATA, W
	banksel PORTD                        
	movwf	PORTD                        ;EEDATA daki deðer PORTD ye gönderiliyor.
	return

ana_program
	BSF STATUS,RP0
	clrf	TRISD                        ;PORTD çýkýþa yönlendirildi.
	bcf 	STATUS, RP0                                      
	clrf	PORTD
                       
	call Yazma_Ayari
	call Okuma_Ayari

Dongu					                 ;Gecikme Programý
	goto Dongu                              
 
END

