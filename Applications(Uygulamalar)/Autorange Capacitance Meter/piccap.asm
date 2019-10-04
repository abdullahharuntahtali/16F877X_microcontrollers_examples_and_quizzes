;------------------------------------------------------------------------------------------------------------------------
; Source code for the PIC16F873A based Capacitance Meter. (5pF to 2500uF range)  
;------------------------------------------------------------------------------------------------------------------------
;	**Analog Pinouts
;	Vin-	-	RA0, Channel 0.
;	Vin+	-	RA3, Channel 3.
;
;	**Capacitance (Cx) Charge Controller. (Active Low)
;	Low Range	- RB4
;	High Range	- RB3
;
;	**Push Buttons for Calibration.
;	Save Button	- RB5, Active Low
;	+ Button	- RB6, Active Low
;	- Button	- RB7, Active Low	
;
;	**LCD Pinouts
;	1	Vss -	Ground, 3rd pin of the potentiometer
;  	2	Vcc	-	5V DC, 1st pin of the potentiometer
;  	3 	Vee	-	Middle pin of the potentiometer
;  	4 	RS	-	RB0		(Data - 1, Instruction - 0)
;  	5 	R/W	-	RB1		(R - 1, W - 0)
;	6 	E	-	RB2		(Enable Pulse)
;	7 	DB0	-	RC0		(LSB)
;	8 	DB1	-	RC1
;	9 	DB2	-	RC2
; 	10	DB3	-	RC3		(Lower 4 bits)
; 	11	DB4 -	RC4		(Upper 4 bits)
; 	12	DB5	-	RC5
; 	13	DB6	-	RC6
; 	14	DB7	-	RC7		(MSB)
;
;	Instruction Cycle Time = 1 / (4MHz / 4) = 1us per instruction
;------------------------------------------------------------------------------------------------------------------------
		LIST P=16F873A           
		INCLUDE "p16f873a.inc"   
;		ERRORLEVEL -302        
		__CONFIG _PWRTE_OFF & _HS_OSC & _WDT_OFF & _WRT_OFF & _LVP_OFF & _BODEN_OFF;  configuration switches

		CBlock 0x20
		
		visdelay
		N				
		FIXDELAY		; Delay registers.
		
		fractHi
		offsetsub		; Corrective calibration value.

		pointer			; Message character pointer.

		DIVIDENDHI
		DIVIDENDLO
		DIVISORHI
		DIVISORLO
		QUOTIENTHI
		QUOTIENTLO
		REMAINDERHI
		REMAINDERLO
		COUNT			; 16 bit divide method registers.

		digit0
		digit1
		digit2
		digit3
		digit4
		digit5			; Individual display digit registers.
		EndC

		org 0x00
		nop				; Reserved for ICD II.
		goto start

start		call initports		; Initialize the PORTs.
			call setupTMR1		; Setup Timer1 module.
			call INITLCD		; Initializes LCD.
			call dischargecap	; Discharge Cx and enable the comparator module.
			call dispstartmsg	; Displays the default start message.

loadeeprom	movlw 0x00			; 0x00 of EEPROM holds offsetsub corrective calibration value.
			call eepromread		; Read data pointed at address 0x00.
			movwf offsetsub		; Load data into offsetsub.

main		btfss PORTB, 6		; Check if either of RB6 or RB7 buttons were pushed,
			incf offsetsub, f	; if they were, adjust the offset subtractor accordingly.
			btfss PORTB, 7
			decf offsetsub, f
			btfsc PORTB, 5
			goto sampling
			
			banksel EEADR		; Select location 0x00 of EEPROM.
			movlw 0x00
			movwf EEADR
			banksel EEDATA		
			movf offsetsub, w	; Write calibrated offset data to 0x00.
			movwf EEDATA
			call eepromwrite	; Initiate EEPROM write.
			call dispsavemsg	; Display saving message.
			call visualdelay	; Visual delay for viewer.
			
sampling	call sampleLo		; Begin sampling Cx, cycles every 255ms.
			goto main
			
;------------------------------------------------------------------------------------------------------------------------
; Subroutine to initialize the PORTs as Inputs or Outputs.
;------------------------------------------------------------------------------------------------------------------------		

initports
			banksel TRISA		; Select TRISA, B, and C banks.
			movlw b'11111111'	; Define PORTA as Inputs.
			movwf TRISA

			movlw b'11100000'	; RB5 to RB7 are inputs, the rest are outputs.
			movwf TRISB

			movlw b'00000000'	; All PORTC pins are output.
			movwf TRISC

			banksel PORTA		; Select PORTA bank.
			clrf PORTB			; Clear PORTB and PORTC bits.
			clrf PORTC

			bsf PORTB, 4		; Set RB4 and RB3 to inhibit charging of Cx.
			bsf PORTB, 3

			return

;------------------------------------------------------------------------------------------------------------------------
; Setup the Timer1 Module.
;------------------------------------------------------------------------------------------------------------------------

setupTMR1	
			banksel T1CON
			movlw b'00000000'	; Disable TMR1, 1:1 Prescale, Clock = Fosc/4, OSC off.
			movwf T1CON
			return

;------------------------------------------------------------------------------------------------------------------------
; Discharges Cx and (Re)Initializes Comparator.
;------------------------------------------------------------------------------------------------------------------------

dischargecap
			banksel CMCON
			movlw b'00000111'	; OFF Comparators.
			movwf CMCON

			banksel PORTB
			call DELAY20		; 10us delay for settling time.

			banksel ADCON1
			movlw b'00001110'	; pin RA0 as analog and RA3 as digital. (Maybe not needed?)
			movwf ADCON1
			
			banksel TRISA
			bcf TRISA, 3		; RA3 as output.

			banksel PORTA
			bcf PORTA, 3		; Clear RA3 to discharge Cx.

			movlw d'255'		; Delay Time to discharge Cx completely. About 255ms.
			call NDELAY
			movlw d'255'
			call NDELAY
			movlw d'255'
			call NDELAY
			movlw d'255'
			call NDELAY
			movlw d'255'
			call NDELAY

			banksel TRISA
			bsf TRISA, 3		; RA3 as input.

			banksel ADCON1
			movlw b'00000000'	; Pin RA0 and RA3 as analog. (Maybe not needed?)
			movwf ADCON1

			banksel CMCON		; Initialize Comparator Module as One Independent Comparator with Output.
			movlw b'00000001'
			movwf CMCON

			banksel PORTB
			call DELAY20		; 10us delay for settling time.

			return

;------------------------------------------------------------------------------------------------------------------------
; Initialize the LCD.
;------------------------------------------------------------------------------------------------------------------------

INITLCD		
			BANKSEL PORTB		; Select Bank for PORTB.

			MOVLW	0xE6		; Call for 46ms delay
			CALL 	NDELAY		; Wait for VCC of the LCD to reach 5V
			
			BCF		PORTB, 0	; Clear RS to select Instruction Reg.
			BCF		PORTB, 1	; Clear R/W to write
		
			MOVLW	B'00111011'	; Function Set to 8 bits, 2 lines and 5x7 dot matrix
			MOVWF 	PORTC
			CALL	ENABLEPULSE
			CALL	DELAY50
			CALL	ENABLEPULSE
			CALL	DELAY50
			CALL	ENABLEPULSE
			CALL	DELAY50		; Call 50us delay and wait for instruction completion

			MOVLW	B'00001000'	; Display OFF
			MOVWF	PORTC
			CALL	ENABLEPULSE
			CALL	DELAY50		; Call 50us delay and wait for instruction completion

			MOVLW	B'00000001'	; Clear Display
			MOVWF	PORTC
			CALL	ENABLEPULSE
			MOVLW	0x09		; Call 1.8ms delay and wait for instruction completion				
			CALL	NDELAY		

			MOVLW	B'00000010'	; Cursor Home
			MOVWF	PORTC
			CALL	ENABLEPULSE
			MOVLW	0x09		; Call 1.8ms delay and wait for instruction completion				
			CALL	NDELAY
		
			MOVLW	B'00001100'	; Display ON, Cursor OFF, Blinking OFF
			MOVWF	PORTC
			CALL	ENABLEPULSE
			CALL	DELAY50		; Call 50us delay and wait for instruction completion

			MOVLW 	B'00000110'	; Entry Mode Set, Increment & No display shift
			MOVWF	PORTC
			CALL	ENABLEPULSE
			CALL	DELAY50		; Call 50us delay and wait for instruction completion

			BSF		PORTB, 0	; Set RS to select Data Reg.
			BCF		PORTB, 1	; Clear R/W to write

			RETURN

;------------------------------------------------------------------------------------------------------------------------
; Enable Pulse for writing or reading instructions or data
;------------------------------------------------------------------------------------------------------------------------

ENABLEPULSE	BCF	PORTB, 2		; 2us LOW followed by 3us HIGH Enable Pulse and 2us LOW.
			NOP
			NOP
			BSF	PORTB, 2
			NOP
			NOP
			NOP
			BCF PORTB, 2
			NOP
			NOP
			RETURN

;------------------------------------------------------------------------------------------------------------------------
; Visual delay subroutine.
;------------------------------------------------------------------------------------------------------------------------

visualdelay movlw d'20'
			movwf visdelay

seetemp		movlw 0xFF
			call NDELAY
			decfsz visdelay, 1
			goto seetemp
			return

;------------------------------------------------------------------------------------------------------------------------
; N DELAY SUBROUTINE, delay in multiples of 200us up to 200us*255 = 51ms (or more)
;------------------------------------------------------------------------------------------------------------------------

NDELAY
			MOVWF N				; N is delay multiplier
NOTOVER		CALL DELAY200		; Call for 200us
			DECFSZ N, 1			; Decrease N by 1
			GOTO NOTOVER		; The delay isn't done
			RETURN
	
;------------------------------------------------------------------------------------------------------------------------
; FIXED 200us DELAY (Possibly more due to execution time of the DECFSZ instruction.)
;------------------------------------------------------------------------------------------------------------------------

DELAY200	
			MOVLW 0x42			; 66 LOOPS
			MOVWF FIXDELAY		; 200us fixed delay
NOTDONE200	DECFSZ FIXDELAY, 1 	; Decrement of FIXDELAY
			GOTO NOTDONE200		; If 200us isn't up go back to NOTDONE200
			RETURN				; If 200us is up then return to instruction.

;------------------------------------------------------------------------------------------------------------------------
; FIXED 50us DELAY (Possibly more due to execution time of the DECFSZ instruction.)
;------------------------------------------------------------------------------------------------------------------------

DELAY50	
			MOVLW 0x10			; 16 LOOPS
			MOVWF FIXDELAY		; 50us fixed delay
NOTDONE50	DECFSZ FIXDELAY, 1 	; Decrement of FIXDELAY
			GOTO NOTDONE50		; If 50us isn't up go back to NOTDONE50
			RETURN				; If 50us is up then return to instruction.

;------------------------------------------------------------------------------------------------------------------------
; FIXED 20us DELAY (Possibly more due to execution time of the DECFSZ instruction.)
;------------------------------------------------------------------------------------------------------------------------

DELAY20	
			MOVLW 0x7			; 7 LOOPS
			MOVWF FIXDELAY		; 20us fixed delay
NOTDONE20	DECFSZ FIXDELAY, 1 	; Decrement of FIXDELAY
			GOTO NOTDONE20		; If 50us isn't up go back to NOTDONE20
			RETURN				; If 50us is up then return to instruction.

;------------------------------------------------------------------------------------------------------------------------
; Fast Directive to write characters to LCD.
;------------------------------------------------------------------------------------------------------------------------

PUTCHAR
			MOVWF PORTC			; A quicker way of writing characters to LCD.
			CALL ENABLEPULSE
			CALL CHKBUSY
			RETURN

;------------------------------------------------------------------------------------------------------------------------
; Position Cursor to the next line.
;------------------------------------------------------------------------------------------------------------------------

nextline
			banksel PORTB
			bcf PORTB, 0	; Select Instructions Register.
			bcf PORTB, 1	; Select Write.

			movlw b'11000000'	; Shift cursor to second line at 0x40 RAM address on LCD.
			call PUTCHAR

			return

;------------------------------------------------------------------------------------------------------------------------
; Subroutine to check for the BUSY flag. Mostly used for instructions that follows up a character write.
;------------------------------------------------------------------------------------------------------------------------

CHKBUSY
			bcf	PORTB, 0		; Clear RS to select Instruction Reg.
			bsf	PORTB, 1		; Set R/W to read.

			banksel TRISC		; Select Bank for TRISC.
			movlw 0xFF			; Define all PORTC Pins as Inputs.
			movwf TRISC

			banksel PORTC		; Select Bank for PORTC.
			bsf PORTB, 2		; I tried to write my own code for this part initially but I wasn't successful.
			movf PORTC, w		; Therefore, I implemented a portion of Peter Ouwehand's LCD Code.
			bcf PORTB, 2		; Will look more into the BUSY flag of the LCD.
			andlw 0x80			; Credits to Peter Ouwehand for his code here. :)
			btfss STATUS, Z
			goto CHKBUSY

			banksel TRISC		; Select Bank for TRISC.
			movlw 0x00			; Define all PORTC Pins as Outputs.
			movwf TRISC
		
			banksel PORTB		; Select Bank for PORTA, B, and C.
			bsf PORTB, 0		; Set RS to select Data Register.
			bcf PORTB, 1		; Clear R/W to write.
			
			return

;------------------------------------------------------------------------------------------------------------------------
; Samples the capacitance charge time.
;------------------------------------------------------------------------------------------------------------------------

sampleLo	
			call dischargecap	; Discharge Cx.

			banksel TMR1H
			bcf PIR1, TMR1IF	; Clear TMR1 interrupt flag.
			clrf TMR1H			; Clear Timer1 values.
			clrf TMR1L
			
			banksel T1CON
			movlw b'00000000'	; Prescale 1:1, TMR1 Off.
			movwf T1CON

			bcf PORTB, 4		; Clear RB4 to energize Cx.
			bsf T1CON, 0		; Enable the Timer1 to measure charge time.

waitcharge	
			banksel CMCON
			btfss CMCON, C1OUT	; Check if VCx > 0.632Vdd?
			goto timeoutchk

sampleLodone	
				banksel T1CON
				bcf T1CON, 0		; Disable TMR1 to get time reading.
				bsf PORTB, 4		; Stop charging Cx.
				goto computeLo

timeoutchk	
			banksel PIR1
			btfss PIR1, TMR1IF	; Check if TMR1 has overflow?
			goto waitcharge
			bcf PIR1, TMR1IF	; Clear TMR1 interrupt flag.
			bsf PORTB, 4		; Stop charging Cx.
			goto sampleHi

computeLo
			banksel TMR1H
			movf TMR1H, w		; Math and display routines here.
			movwf DIVIDENDHI
			movf TMR1L, w
			movwf DIVIDENDLO
			
			clrf DIVISORHI		; Divides Measured time by 2.
			movlw d'2'
			movwf DIVISORLO
			call divide16

			movf offsetsub, w	; Calibration corrections.
			subwf QUOTIENTLO, f

			call displayres		; Display non-fractional result.
			call displayLofract	; Display fractional result.
			
			return

sampleHi	call dischargecap	; Discharge Cx.
			banksel T1CON
			bcf T1CON, 0		; Disable TMR1
			clrf TMR1H			; Clear TMR1 values.
			clrf TMR1L
			
			banksel T1CON
			movlw b'00110000'	; Prescale 1:8, TMR1 Off.
			movwf T1CON
			
			bcf PIR1, TMR1IF	; Clear TMR1 Interrupt flag.
			bcf PORTB, 3		; Clear RB3 to energize Cx.
			bsf T1CON, 0		; Enable Timer1 to measure charge time.

waitcharge2	
			banksel CMCON
			btfss CMCON, C1OUT	; Check if VCx > 0.632Vdd?
			goto timeoutchk2

sampleHidone
			banksel T1CON
			bcf T1CON, 0		; Stop TMR1 to get time reading.
			bsf PORTB, 3		; Stop charging Cx.
			goto computeHi

timeoutchk2
			banksel PIR1
			btfss PIR1, TMR1IF	; Check if TMR1 has overflow?
			goto waitcharge2
			bcf PIR1, TMR1IF	; If yes, clear TMR1 interrupt flag.
			bsf PORTB, 3		; Stop charging Cx.
			call disperrormsg	; Then display Error message.
			return

computeHi
			banksel TMR1H
			movf TMR1H, w		; Math and display routines here.
			movwf DIVIDENDHI
			movf TMR1L, w
			movwf DIVIDENDLO
			clrf DIVISORHI
			movlw d'25'
			movwf DIVISORLO		; Divides measured time by 25. (8us/200 Ohm = 1/25)
			call divide16

			movf REMAINDERLO, w
			movwf fractHi

			call displayres
			call displayHifract
			return

;------------------------------------------------------------------------------------------------------------------------
; Displays the default message on line 1 of LCD.
;------------------------------------------------------------------------------------------------------------------------

dispstartmsg

			movlw 'P'
			call PUTCHAR
			movlw 'I'
			call PUTCHAR
			movlw 'C'
			call PUTCHAR
			movlw 'C'
			call PUTCHAR
			movlw 'a'
			call PUTCHAR
			movlw 'P'
			call PUTCHAR
			movlw 'M'
			call PUTCHAR
			movlw 'e'
			call PUTCHAR
			movlw 't'
			call PUTCHAR
			movlw 'e'
			call PUTCHAR
			movlw 'r'
			call PUTCHAR
			movlw ' '
			call PUTCHAR
			movlw 'v'
			call PUTCHAR
			movlw '1'
			call PUTCHAR
			movlw '.'
			call PUTCHAR
			movlw '0'
			call PUTCHAR

			return

;------------------------------------------------------------------------------------------------------------------------
; Displays the error message when Cx is out of range.
;------------------------------------------------------------------------------------------------------------------------

disperrormsg
			call nextline
			movlw 'O'
			call PUTCHAR
			movlw 'u'
			call PUTCHAR
			movlw 't'
			call PUTCHAR
			movlw ' '
			call PUTCHAR
			movlw 'o'
			call PUTCHAR
			movlw 'f'
			call PUTCHAR
			movlw ' '
			call PUTCHAR
			movlw 'R'
			call PUTCHAR
			movlw 'a'
			call PUTCHAR
			movlw 'n'
			call PUTCHAR
			movlw 'g'
			call PUTCHAR
			movlw 'e'
			call PUTCHAR
			movlw '!'
			call PUTCHAR
			movlw ' '
			call PUTCHAR
			movlw ' '
			call PUTCHAR
			movlw ' '
			call PUTCHAR

			return

;------------------------------------------------------------------------------------------------------------------------
; Displays save message when RB5 button is pushed.
;------------------------------------------------------------------------------------------------------------------------

dispsavemsg
			call nextline
			movlw 'S'
			call PUTCHAR
			movlw 'a'
			call PUTCHAR
			movlw 'v'
			call PUTCHAR
			movlw 'i'
			call PUTCHAR
			movlw 'n'
			call PUTCHAR
			movlw 'g'
			call PUTCHAR
			movlw ' '
			call PUTCHAR
			movlw 'S'
			call PUTCHAR
			movlw 't'
			call PUTCHAR
			movlw 'a'
			call PUTCHAR
			movlw 't'
			call PUTCHAR
			movlw 'e'
			call PUTCHAR
			movlw '.'
			call PUTCHAR
			movlw '.'
			call PUTCHAR
			movlw '.'
			call PUTCHAR
			movlw '.'
			call PUTCHAR

			return

;------------------------------------------------------------------------------------------------------------------------
; 16 bit divide method by Andy Warren.
;------------------------------------------------------------------------------------------------------------------------

divide16	CLRF    REMAINDERLO     	;CLEAR THE REMAINDER.
            CLRF    REMAINDERHI     	;

            MOVLW   d'16'           	;WE'RE DIVIDING BY A 16-BIT DIVISOR.
            MOVWF   COUNT		     	;

DIVLOOP     RLF     DIVIDENDLO, f      ;SHIFT DIVIDEND LEFT 1 BIT INTO
            RLF     DIVIDENDHI, f      ;REMAINDERHI:REMAINDERLO.
            RLF     REMAINDERLO, f     ;
            RLF     REMAINDERHI, f     ;

            MOVF    DIVISORHI,W     	;COMPARE THE DIVISOR TO THE PORTION OF THE
            SUBWF   REMAINDERHI,W   	;DIVIDEND THAT'S BEEN SHIFTED INTO REMHI.

            BNZ     CHECKLESS       	;IF THE TWO HI-BYTES AREN'T THE SAME, JUMP
                                    	;AHEAD.

            MOVF    DIVISORLO,W     	;OTHERWISE, WE HAVE TO COMPARE THE
            SUBWF   REMAINDERLO,W   	;LO-BYTES.

CHECKLESS	BNC     NOSUB           	;IF THE SHIFTED PORTION OF THE DIVIDEND WAS
                                    	;LESS THAN THE DIVISOR, JUMP AHEAD.

            MOVF    DIVISORLO,W     	;OTHERWISE, REMAINDER = REMAINDER - DIVISOR.
            SUBWF   REMAINDERLO, f     	;
            MOVF    DIVISORHI,W     	;
            SKPC                    	;
            INCFSZ  DIVISORHI, f     	;
            SUBWF   REMAINDERHI, f     	; (CARRY'S ALWAYS SET AT THIS POINT.)

NOSUB       RLF     QUOTIENTLO, f    	;IF WE JUST SUBTRACTED, SHIFT A "1" INTO
            RLF     QUOTIENTHI, f    	;THE QUOTIENT.  OTHERWISE, SHIFT A "0".

            DECFSZ  COUNT, f        	;HAVE WE SHIFTED ENOUGH BITS?
            GOTO    DIVLOOP         	;IF NOT, LOOP BACK.

			RETURN

;------------------------------------------------------------------------------------------------------------------------
; Display non-fractional result.
;------------------------------------------------------------------------------------------------------------------------

displayres	
			call nextline		; Cursor to line 2.
			movlw A'C'			; Displays "Cx is xxxxx.xxpF or uF"
			call PUTCHAR
			movlw A'x'
			call PUTCHAR
			movlw A' '
			call PUTCHAR
			movlw A'i'
			call PUTCHAR
			movlw A's'
			call PUTCHAR
			movlw A' '
			call PUTCHAR

			call numsplit
			addlw d'48'
			movwf digit0
			call numsplit
			addlw d'48'
			movwf digit1
			call numsplit
			addlw d'48'
			movwf digit2
			call numsplit
			addlw d'48'
			movwf digit3
			call numsplit
			addlw d'48'
			movwf digit4
			call numsplit

			movf digit4, w
			call PUTCHAR
			movf digit3, w
			call PUTCHAR
			movf digit2, w
			call PUTCHAR
			movf digit1, w
			call PUTCHAR
			movf digit0, w
			call PUTCHAR

			return

;------------------------------------------------------------------------------------------------------------------------
; Display Low Cx Fractional Values.
;------------------------------------------------------------------------------------------------------------------------

displayLofract
			movlw A'.'			; Displays .00pF
			call PUTCHAR
			movlw A'0'
			call PUTCHAR
			movlw A'0'
			call PUTCHAR
			movlw b'11100110'	; pico sign.
			call PUTCHAR
			movlw A'F'
			call PUTCHAR
			return

;------------------------------------------------------------------------------------------------------------------------
; Display Hi Cx Fractional Values.
;------------------------------------------------------------------------------------------------------------------------

displayHifract
			movlw A'.'
			call PUTCHAR

			bcf STATUS, C		; Multiply the remainder of Cx Hi by 4 to convert it to fractional value.
			rlf fractHi, f
			bcf STATUS, C
			rlf fractHi, f
			clrf DIVIDENDHI
			movf fractHi, w
			movwf DIVIDENDLO
			clrf DIVISORHI
			movlw d'10'
			movwf DIVISORLO
			call divide16

			movf QUOTIENTLO, w	; Display the fractional values.
			addlw d'48'
			call PUTCHAR

			movf REMAINDERLO, w
			addlw d'48'
			call PUTCHAR

			movlw b'11100100'	; micro sign.
			call PUTCHAR
			movlw A'F'
			call PUTCHAR
			return

;------------------------------------------------------------------------------------------------------------------------
; Number splitter.
;------------------------------------------------------------------------------------------------------------------------

numsplit	movf QUOTIENTHI, w	; Get the remainder number, i.e. the first digit from the left.
			movwf DIVIDENDHI
			movf QUOTIENTLO, w
			movwf DIVIDENDLO

			clrf DIVISORHI
			movlw d'10'
			movwf DIVISORLO

			call divide16
			movf REMAINDERLO, w
			return

;------------------------------------------------------------------------------------------------------------------------
; EEPROM Reader.
;------------------------------------------------------------------------------------------------------------------------

eepromread
			banksel EEADR		; Select bank for EEADR.
			movwf EEADR			; Pass address to EEADR.
			banksel EECON1		; Select bank for EECON1.
			bcf EECON1, EEPGD	; Select data memory.
			bsf EECON1, RD		; Read the value on the specified address.
			banksel EEDATA		; Select bank for EEDATA.
			movf EEDATA, w		; Pass data to WREG.
			banksel PORTC		; Select bank 0.
			return

;------------------------------------------------------------------------------------------------------------------------
; EEPROM Writer.
;------------------------------------------------------------------------------------------------------------------------

eepromwrite
			banksel EECON1		; Select bank for EECON1 and EECON2.
			bcf EECON1, EEPGD	; Select data memory.
			bsf EECON1, WREN	; Enable EEPROM write.
			movlw 0x55			; Required sequences.
			movwf EECON2
			movlw 0xAA
			movwf EECON2
			bsf EECON1, WR		; Set WR bit to begin write.
			bcf EECON1, WREN	; Disable further writes.
			btfsc EECON1, WR	; Check if write is completed.
			goto $-1			; If no, wait up.
			return				; If yes, return.

;------------------------------------------------------------------------------------------------------------------------
; End of Programme.
;------------------------------------------------------------------------------------------------------------------------

			end
		
		 
