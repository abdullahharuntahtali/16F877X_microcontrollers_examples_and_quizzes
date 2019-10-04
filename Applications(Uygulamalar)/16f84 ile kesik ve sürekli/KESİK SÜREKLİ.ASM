
;kesik ve sürekli çalýþma
;=====================================================================
                LIST        P=16F84A
                INCLUDE    "P16F84A.INC"

                CBLOCK         h'0C'
SAYAC            
SAYAC_1
SAYI
                ENDC
                BSF         STATUS,5
                CLRF        TRISB
                MOVLW       H'FF'
                MOVWF       TRISA
                BCF         STATUS,5
                CLRF        PORTB
                CLRF        PORTA
TEST
	        CLRF        PORTB
                BTFSC       PORTA,0   
                GOTO        SUREKLI
                BTFSC       PORTA,1
                GOTO        KESIK
                GOTO        TEST
KESIK
                MOVLW       B'11001001'
		MOVWF       PORTB
                BTFSC       PORTA,1
                GOTO        KESIK
                BCF         PORTB,1
                GOTO        TEST

SUREKLI
                MOVLW       B'11101101'
		MOVWF       PORTB
                
DUR 


                BTFSS       PORTA,2
                GOTO        DUR
                CLRF        PORTB
                GOTO        TEST
GECIKME         
               	MOVLW          H'FF'
             	MOVWF          SAYAC
       DONGU1            
		MOVLW          H'FF'
                             MOVWF          SAYAC_1
       DONGU2
                DECFSZ         SAYAC_1,F
                GOTO           DONGU2
         	DECFSZ         SAYAC,F
         	GOTO           DONGU1
		RETURN
                END 
