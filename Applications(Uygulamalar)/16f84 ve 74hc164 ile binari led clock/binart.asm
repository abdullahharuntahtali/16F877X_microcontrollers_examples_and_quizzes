; **************************************************************************
; ** binclock.asm v 1.0                                
; **             
; **   Firmware for the PIC 16F84A that runs the Binary Desk Clock.          
; **             
; **   Note: The speed of the crystal used in the circuit determines how           
; **         many machine cycles are in a second.  My circuit uses a 10 MHz clock,   
; **         meaning there are 10 million cycles/second, meaning there are 
; **	     2.5 million instructions/second (4 cycles/instruction), and the PAUSE 
; **	     subroutines count time accordingly.  
; **             
; **   Pin Setup:        
; **           
; **         A0		Set/Run Switch (on == set)  
; **         A1		Hours Button  
; **         A2		Minutes Button  
; **         A3		Seconds Button  
; **         B0		Hours Output Pin  
; **         B1		Minutes Output Pin  
; **         B2		Seconds Output Pin  
; **         B7		Clocking pulse to all three serial/parallel chips  
; **           
; **           
; ** Homer J Painter  06/18/03            
; ** homer@yo.homelinux.com            
; **************************************************************************             



; **************************************************************************
; ** Header File and Preprocessing Tidbits 
; **
	processor PIC16F84A
	include   <p16f84a.inc>

	__config  _HS_OSC & _WDT_OFF & _PWRTE_ON ;crystal osc, no watchdog 
						 ;timer, pwr up timer on
 
	radix dec                                ;default num fmt is decimal


; **************************************************************************
; ** Variable Declarations
; **
HRS 	equ	20	;Hours variable location
MINS	equ	21	;Minutes variable location
SECS	equ	22	;Seconds variable location

;TIMEBIT	equ	23	;Used by DISPLAY to determine which bit of
			;the time variables to send out next

TPACKET	equ	24	;This byte holds the current "data packet" to be placed
			;on port B during the DISPLAY subroutine

RUNCYCLE equ	25	;We enter the run subroutine four times per second
			;to improve the response time to changes in the 
			;Set/Run switch.  Only when this is at 0 do we
			;perform a "tick."

FLAGS	equ	26	;Various bit flags used by this program
			;Bit 0 - exit flag for SETCLK subroutine
			;Bit 1 - tick flag for RUN subroutine
			;Bit 2 - Wrap flag for TICK subroutine
			;Bit 3 - Increment flag for TICK subroutine

COUNT1	equ	27	;Counter var for pauses
COUNT2	equ	28	;Counter var for pauses
COUNT3	equ	29	;Counter var for pauses

MYW	equ	30	;Temporary holder for W

; **************************************************************************
; ** Vector Table - Tells the chip where to begin executing on startup and
; **                when an interrupt is recieved (no interrupts used here).

	org	0     ; Reset vector
	goto	START	


; **************************************************************************
; ** Setup  - Initialize the pins for input/output, and set variables to 
; **          their defaults

SETUP	bsf	STATUS,5	;Switch to bank 1

	;movlw	B'111111'	;Set Port A pins for input	
	;movwf	TRISA

	movlw	B'00000000'	;Set Port B pins for output
	movwf	TRISB

	bcf	STATUS,5	;Switch back to bank 0

	movlw	0		;Put 0 in W register
	movwf	HRS		;Set Hours to 0
	movwf	MINS		;Set Minutes to 0
	movwf	SECS		;Set Seconds to 0
	movwf	TPACKET		;Set TPACKET to 0
	movwf	FLAGS		;Set all flags to 0	
	movwf	MYW		;Set temp w holder to 0
	movwf	PORTB		;Clear PortB pins	

	movlw	4
	movwf	RUNCYCLE	;Set RUNCYCLE to 4
	
	goto 	MAIN	
	

; **************************************************************************
; ** Run Mode  - Uses 10 instruction cycles
; **
RUN
	;For our purposes, seconds consist arbitrarily of 4 25 millisecond 
	;blocks, and so we only tick the clock up every fourth time through
	;here.

	;We check the runcycles var, and if it is at 0 we tick the clock and
	;delay for the remainder of a 25 millisecond block (SMLPAUSE).  
	;If it is not 0, we delay for a full 25 milliseconds, less current 
	;overhead (BIGPAUSE), and then return to MAIN.		
	
	bsf	FLAGS,1		;Provisionally set the tick flag
	decfsz	RUNCYCLE,1	;Notch down the run cycle counter
	bcf	FLAGS,1		;Clear the flag unless the counter reads 0

	btfss	FLAGS,1		;Check tick flag again
	call	BIGPAUSE	;Pause for 25 milliseconds

	btfsc	FLAGS,1		;Check tick flag
	call	TICK		;Tick the clock
	
	btfsc	FLAGS,1		;Check tick flag again
	call	SMLPAUSE	;Wait for the remainder of this 25 ms block
	
	RETURN

	

; **************************************************************************
; ** Tick the clock one second  -  Uses 166 instruction cycles, including 
; **                               call to DISPLAY
TICK
	;Increment the stored time values:
	
	;Increase seconds
	incf	SECS,1		;Add 1 to seconds, result into SECS
	movlw	61		;Put 61 in the W register
	xorwf	SECS,0		;XOR W with the current number of seconds.
				;If there are 60 seconds, the result in W will
				;be 1

	movwf	MYW		;Drop w to a register

	bsf	FLAGS,2		;Provisionally set the wrap flag
	decfsz	MYW,0		;Check if we are at 60 seconds, result to W
	bcf	FLAGS,2		;Clear the wrap flag if we aren't yet at 60 seconds

	movlw	0		;Provisionally move 0 to W
	btfsc	FLAGS,2		;Check wrap flag		
	movwf	SECS		;Set secs to 0 if wrap flag on

	;Increase minutes	
	bsf	FLAGS,3		;Provisionally set increment flag
	btfss	FLAGS,2		;Check for wrap flag, indicating that mins should
				;be incremented
	bcf	FLAGS,3		;Wrap flag is off, so turn off increment flag

	btfsc	FLAGS,3		;Check increment flag, skip next if flag is clear
	incf	MINS,1		;Add 1 to minutes, result into MINS

	movlw	61		;Put 61 in W register
	xorwf	MINS,0		;XOR W with the current number of minutes.

	movwf	MYW		;Drop w to a register

	bsf	FLAGS,2		;Provisionally set the wrap flag
	decfsz	MYW,0		;Check if we've come to minute 60
	bcf	FLAGS,2		;Clear the wrap flag if not

	movlw	0		;Move 0 to W
	btfsc	FLAGS,2		;Check wrap flag
	movwf	MINS		;Set mins to 0
		
	;Increase hours
	bsf	FLAGS,3		;Provisionally set increment flag
	btfss	FLAGS,2		;Check for wrap flag, indicating that mins should
				;be incremented
	bcf	FLAGS,3		;Wrap flag is off, so turn off increment flag

	btfsc	FLAGS,3		;Check increment flag, skip next if flag is clear
	incf	HRS,1		;Add 1 to hours, result into HRS

	movlw	25		;Put 25 in W register
	xorwf	HRS,0		;XOR W with the current number of hourss.

	movwf	MYW		;Drop w to a register

	bsf	FLAGS,2		;Provisionally set the wrap flag
	decfsz	MYW,0		;Check if we've come to hour 24
	bcf	FLAGS,2		;Clear the wrap flag if not

	movlw	0		;Move 0 to W
	btfsc	FLAGS,2		;Check wrap flag
	movwf	HRS		;Set hours to 0
		

	call	DISPLAY		;Output the time to the LEDs...count this line as 
				;124 instruction cycles

	movlw	4		;Reset the RUNCYCLE variable
	movwf	RUNCYCLE	

	
	RETURN


; **************************************************************************
; ** Delay routine used on cycles where we have incremented the clock time 
; **
SMLPAUSE
	;Once here, we have 182 cycles overhead already 
	;(MAIN + RUN + TICK)

	;25 milliseconds is 625,000 instruction cycles with a 10MHz clock, 
	;so we need to do nothing for 625,000-182 = 624,818 cycles, minus 
	;whatever we use here (10: 2 for RETURN, 8 to initialize COUNT vars).
	
	;10MHz waste cycles = 624,806
	;6 MHZ waste cycles = 374,806

	movlw	0
	movwf	COUNT1

	movlw	0
	movwf	COUNT2	

	movlw	230
	movwf	COUNT3

DLOOP1	decfsz	COUNT1,1
	goto	DLOOP1		;765 cycles
	decfsz	COUNT2,1
	goto	DLOOP1		;197119 cycles

;	decfsz	COUNT3,1
;	goto	DLOOP1		;591365	cycles

	;These #s are according to the MPLAB stopwatch...I'll go with them for now.
	;We need 33443 more cycles


;	movlw	43
;	movwf	COUNT2

DLOOP2	decfsz	COUNT2,1
	goto	DLOOP2		
	decfsz	COUNT3,1
	goto	DLOOP2		;178639 - 232
				;177099	- 230

	;That's another 33109 gone.  624474 wasted in total.

	;Only 332 more cycles to go
	;That means COUNT3 should be set to 332/3, 110
	movlw	194
	movwf	COUNT3

DLOOP3	decfsz	COUNT3,1
	goto	DLOOP3		;329 cycles, according to MPLAB

	RETURN


; **************************************************************************
; ** Delay routine used on cycles where we do _not_ increment the clock time  
; **
BIGPAUSE
	;Once here, we have 16 cycles of overhead already (MAIN + RUN)
	;Add 12 more for internal overhead, and we need to waste
	;624,972 cycles here

	;10 MHz waste cycles - 624972
	;6 MHz waste cycles - 374972
  
	movlw	0
	movwf	COUNT1

	movlw	0
	movwf	COUNT2

	movlw	230
	movwf	COUNT3

DLOOP4	decfsz	COUNT1,1
	goto	DLOOP4
	decfsz	COUNT2,1
	goto	DLOOP4		;197119


DLOOP5	decfsz	COUNT2,1
	goto	DLOOP5
	decfsz	COUNT3,1
	goto 	DLOOP5		;177099

	movlw	250		
	movwf	COUNT3

DLOOP6	decfsz	COUNT3,1
	goto	DLOOP6

	RETURN


; **************************************************************************
; ** Set Mode  
; **
SETCLK
	;Check the button pins and increment in memory 
	;hrs, mins, and secs appropriately
	
	btfss	PORTA,3	;Check seconds pin
	goto 	UPSEC	;A single tick will suffice for this one

	btfss	PORTA,2	;Check minutes pin
	goto	UPMIN	;Jump to our UPMIN loop

	btfss	PORTA,1	;Check hours pin
	goto	UPHR	;Jump to our UPHR loop

	goto	MAIN
	;RETURN		;If we get here, then no pins were pressed

UPSEC	
	;Increase seconds
	incf	SECS,1		;Add 1 to seconds, result into SECS
	movlw	61		;Put 61 in the W register
	xorwf	SECS,0		;XOR W with the current number of seconds.
				;If there are 60 seconds, the result in W will
				;be 1

	movwf	MYW		;Drop w to a register

	bsf	FLAGS,2		;Provisionally set the wrap flag
	decfsz	MYW,0		;Check if we are at 60 seconds, result to W
	bcf	FLAGS,2		;Clear the wrap flag if we aren't yet at 60 seconds

	movlw	0		;Provisionally move 0 to W
	btfsc	FLAGS,2		;Check wrap flag		
	movwf	SECS		;Set secs to 0 if wrap flag on
	
	goto	EOSET		;Get out of here		

UPMIN	
	;Increase minutes
	incf	MINS,1		;Add 1 to minutes, result into MINS
	movlw	61		;Put 61 in the W register
	xorwf	MINS,0		;XOR W with the current number of minutes.
				;If there are 60 minutes, the result in W will
				;be 1

	movwf	MYW		;Drop w to a register

	bsf	FLAGS,2		;Provisionally set the wrap flag
	decfsz	MYW,0		;Check if we are at 60 seconds, result to W
	bcf	FLAGS,2		;Clear the wrap flag if we aren't yet at 60 seconds

	movlw	0		;Provisionally move 0 to W
	btfsc	FLAGS,2		;Check wrap flag		
	movwf	MINS		;Set mins to 0 if wrap flag on

	goto	EOSET		;Finish up


UPHR	
	;Increase hours
	incf	HRS,1		;Add 1 to hours, result into HRS
	movlw	25		;Put 25 in the W register
	xorwf	HRS,0		;XOR W with the current number of hours.
				;If there are 24 hours, the result in W will
				;be 1

	movwf	MYW		;Drop w to a register

	bsf	FLAGS,2		;Provisionally set the wrap flag
	decfsz	MYW,0		;Check if we are at 24 hours, result to W
	bcf	FLAGS,2		;Clear the wrap flag if we aren't yet at 24

	movlw	0		;Provisionally move 0 to W
	btfsc	FLAGS,2		;Check wrap flag		
	movwf	HRS		;Set hrs to 0 if wrap flag on

	goto	EOSET

EOSET	
	call	DISPLAY		;Display the new time
	call	BIGPAUSE 	;Wait a while to let humans catch up
	goto 	MAIN


; **************************************************************************
; ** Display Time  - Uses 124 instruction cycles 
; **
DISPLAY


	;Build and send the data packet.   

	bcf	TPACKET,0		;Clear hour bit in TDATA
	btfsc	HRS,7			;Check the appropriate hour bit		
	bsf	TPACKET,0		;Set hour bit on in TDATA if needed

	bcf	TPACKET,1	 	;Clear minute bit in TDATA
	btfsc	MINS,7			;Check appropriate minute bit
	bsf	TPACKET,1		;Set minute bit on in TDATA if needed

	bcf 	TPACKET,2		;Clear seconds bit in TDATA
	btfsc	SECS,7			;Check appropriate second bit
	bsf	TPACKET,2		;Set seconds bit on in TDATA if needed

	bcf	TPACKET,7		;Swing clocking pin once to 
	movf	TPACKET,0		;transmit this packet
	movwf	PORTB

	bsf	TPACKET,7	
	movf	TPACKET,0
	movwf	PORTB


	bcf	TPACKET,0		;Clear hour bit in TDATA
	btfsc	HRS,6			;Check the appropriate hour bit		
	bsf	TPACKET,0		;Set hour bit on in TDATA if needed

	bcf	TPACKET,1	 	;Clear minute bit in TDATA
	btfsc	MINS,6			;Check appropriate minute bit
	bsf	TPACKET,1		;Set minute bit on in TDATA if needed

	bcf 	TPACKET,2		;Clear seconds bit in TDATA
	btfsc	SECS,6			;Check appropriate second bit
	bsf	TPACKET,2		;Set seconds bit on in TDATA if needed

	bcf	TPACKET,7		;Swing clocking pin once to 
	movf	TPACKET,0		;transmit this packet
	movwf	PORTB

	bsf	TPACKET,7	
	movf	TPACKET,0
	movwf	PORTB
		

	bcf	TPACKET,0		;Clear hour bit in TDATA
	btfsc	HRS,5			;Check the appropriate hour bit		
	bsf	TPACKET,0		;Set hour bit on in TDATA if needed

	bcf	TPACKET,1	 	;Clear minute bit in TDATA
	btfsc	MINS,5			;Check appropriate minute bit
	bsf	TPACKET,1		;Set minute bit on in TDATA if needed

	bcf 	TPACKET,2		;Clear seconds bit in TDATA
	btfsc	SECS,5			;Check appropriate second bit
	bsf	TPACKET,2		;Set seconds bit on in TDATA if needed

	bcf	TPACKET,7		;Swing clocking pin once to 
	movf	TPACKET,0		;transmit this packet
	movwf	PORTB

	bsf	TPACKET,7	
	movf	TPACKET,0
	movwf	PORTB


	bcf	TPACKET,0		;Clear hour bit in TDATA
	btfsc	HRS,4			;Check the appropriate hour bit		
	bsf	TPACKET,0		;Set hour bit on in TDATA if needed

	bcf	TPACKET,1	 	;Clear minute bit in TDATA
	btfsc	MINS,4			;Check appropriate minute bit
	bsf	TPACKET,1		;Set minute bit on in TDATA if needed

	bcf 	TPACKET,2		;Clear seconds bit in TDATA
	btfsc	SECS,4			;Check appropriate second bit
	bsf	TPACKET,2		;Set seconds bit on in TDATA if needed

	bcf	TPACKET,7		;Swing clocking pin once to 
	movf	TPACKET,0		;transmit this packet
	movwf	PORTB

	bsf	TPACKET,7	
	movf	TPACKET,0
	movwf	PORTB


	bcf	TPACKET,0		;Clear hour bit in TDATA
	btfsc	HRS,3			;Check the appropriate hour bit		
	bsf	TPACKET,0		;Set hour bit on in TDATA if needed

	bcf	TPACKET,1	 	;Clear minute bit in TDATA
	btfsc	MINS,3			;Check appropriate minute bit
	bsf	TPACKET,1		;Set minute bit on in TDATA if needed

	bcf 	TPACKET,2		;Clear seconds bit in TDATA
	btfsc	SECS,3			;Check appropriate second bit
	bsf	TPACKET,2		;Set seconds bit on in TDATA if needed

	bcf	TPACKET,7		;Swing clocking pin once to 
	movf	TPACKET,0		;transmit this packet
	movwf	PORTB

	bsf	TPACKET,7	
	movf	TPACKET,0
	movwf	PORTB


	bcf	TPACKET,0		;Clear hour bit in TDATA
	btfsc	HRS,2			;Check the appropriate hour bit		
	bsf	TPACKET,0		;Set hour bit on in TDATA if needed

	bcf	TPACKET,1	 	;Clear minute bit in TDATA
	btfsc	MINS,2			;Check appropriate minute bit
	bsf	TPACKET,1		;Set minute bit on in TDATA if needed

	bcf 	TPACKET,2		;Clear seconds bit in TDATA
	btfsc	SECS,2			;Check appropriate second bit
	bsf	TPACKET,2		;Set seconds bit on in TDATA if needed

	bcf	TPACKET,7		;Swing clocking pin once to 
	movf	TPACKET,0		;transmit this packet
	movwf	PORTB

	bsf	TPACKET,7	
	movf	TPACKET,0
	movwf	PORTB


	bcf	TPACKET,0		;Clear hour bit in TDATA
	btfsc	HRS,1			;Check the appropriate hour bit		
	bsf	TPACKET,0		;Set hour bit on in TDATA if needed

	bcf	TPACKET,1	 	;Clear minute bit in TDATA
	btfsc	MINS,1			;Check appropriate minute bit
	bsf	TPACKET,1		;Set minute bit on in TDATA if needed

	bcf 	TPACKET,2		;Clear seconds bit in TDATA
	btfsc	SECS,1			;Check appropriate second bit
	bsf	TPACKET,2		;Set seconds bit on in TDATA if needed

	bcf	TPACKET,7		;Swing clocking pin once to 
	movf	TPACKET,0		;transmit this packet
	movwf	PORTB

	bsf	TPACKET,7	
	movf	TPACKET,0
	movwf	PORTB


	bcf	TPACKET,0		;Clear hour bit in TDATA
	btfsc	HRS,0			;Check the appropriate hour bit		
	bsf	TPACKET,0		;Set hour bit on in TDATA if needed

	bcf	TPACKET,1	 	;Clear minute bit in TDATA
	btfsc	MINS,0			;Check appropriate minute bit
	bsf	TPACKET,1		;Set minute bit on in TDATA if needed

	bcf 	TPACKET,2		;Clear seconds bit in TDATA
	btfsc	SECS,0			;Check appropriate second bit
	bsf	TPACKET,2		;Set seconds bit on in TDATA if needed

	bcf	TPACKET,7		;Swing clocking pin once to 
	movf	TPACKET,0		;transmit this packet
	movwf	PORTB

	bsf	TPACKET,7	
	movf	TPACKET,0
	movwf	PORTB

	;Clear all PortB pins:
	movlw	0
	movwf	PORTB

	RETURN	
	

; **************************************************************************
; ** Main Program Loop - Uses 6 instruction cycles as RUN sees it    
; **
START	call SETUP	;Initial setup of pins and variables

MAIN	
	btfss	PORTA,0	;Check "mode" pin--if on call SET subroutine, otherwise call RUN
	call	SETCLK
	call 	RUN

	goto 	MAIN

END


