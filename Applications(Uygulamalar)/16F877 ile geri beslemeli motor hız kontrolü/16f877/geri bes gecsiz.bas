'****************************************************************
'*  Name    : UNTITLED.BAS                                      *
'*  Author  : [select VIEW...EDITOR OPTIONS]                    *
'*  Notice  : Copyright (c) 2004 [select VIEW...EDITOR OPTIONS] *
'*          : All Rights Reserved                               *
'*  Date    : 06.12.2004                                        *
'*  Version : 1.0                                               *
'*  Notes   :                                                   *
'*          :                                                   *
'****************************************************************
 ADCON1=$0E             
 TRISA=$3F            
 TRISB=00              
 TRISC=00              
 TRISD=00               
 TRISE=00
 CCP1CON=$0C
 CCP2CON=$0C  
 T2CON=$05              
 PORTB=$00
 PORTD=$00
 
 SAY VAR WORD
 SAYA VAR WORD
 SAYB VAR WORD
 
 DEFINE ADC_BITS  12    
 DEFINE ADC_CLOCK 3    
 DEFINE ADC_SAMPLES 5  
 
 BASLA:
 CCPR1L=$80
 BIR:
 ADCIN 0,SAY
 PORTB=SAY
 ADCIN 1,SAYA
 PORTD=SAYA
 IF SAY=SAYA THEN BIR
 IF SAY>SAYA THEN IKI
 IF SAY<SAYA THEN UC
 GOTO BIR
 IKI:
 CCPR1L=CCPR1L+1
 IF CCPR1L=$FF THEN DORT
 GOTO BIR
 UC:
 CCPR1L=CCPR1L-1
 IF CCPR1L=$00 THEN BES
 GOTO BIR
 DORT:
 ADCIN 0,SAY
 PORTB=SAY
 ADCIN 1,SAYA
 PORTD=SAYA
 IF SAY<=SAYA THEN UC
 GOTO DORT
 BES:
 ADCIN 0,SAY
 PORTB=SAY
 ADCIN 1,SAYA
 PORTD=SAYA
 IF SAY>=SAYA THEN IKI
 GOTO BES
 
 
 

 
 
 
 
