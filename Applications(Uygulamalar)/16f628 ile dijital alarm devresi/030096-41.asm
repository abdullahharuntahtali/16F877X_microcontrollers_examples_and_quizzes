;**********************************************************************
;                                                                     *
;    Filename:	    relogio.asm                                       *
;    Date: 10/05/2004                                                 *
;    File Version: 3                                                  *
;                                                                     *
;    Author: Manoel Conde de Almeida                                  *
;    Company:                                                         *
;                                                                     * 
;                                                                     *
;**********************************************************************
;                                                                     *
;    Files required:                                                  *
;                                                                     *
;                                                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;                                                                     *
;    Version 1 - 26/01/2003                                           *
;    Version 2 - 28/08/2003 - week count included, alarms may be      *
;                             triggered in one specific day of the    *
;                             week or in work days or every day.      *
;    Version 3 - 10/05/2004 - snooze delay selection included         *
;			    - time base rough adjustment included     *
;**********************************************************************


		list		p=16F628	; list directive to define processor
		#include	<p16F628.inc>	; processor specific variable definitions

	__CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _XT_OSC & _MCLRE_ON & _LVP_OFF

;**************************************************************************************************

;***** VARIABLE DEFINITIONS
w_temp		EQU	0x70	; context saving register 
status_temp	EQU	0x6F	; context saving register
st_porta	EQU	0x6E	; PORTA status register

t0fd_count	EQU	0x6D	; timer0 1st digit register
t0sd_count	EQU	0x6C	; timer0 2nd digit register

week_count	EQU	0X6B	; week day register

mnfd_count	EQU	0x6A	; minutes 1st digit (unit) register
mnsd_count	EQU	0x69	; minutes 2nd digit (tens) register
hrfd_count	EQU	0x68	; hours 1st digit (unit) register
hrsd_count	EQU	0x67	; hours 2nd digit (tens) register
mnfd_temp	EQU	0x66	; temporary value for min 1st digit adjust
mnsd_temp	EQU	0x65	; temporary value for min 2nd digit adjust
hrfd_temp	EQU	0x64	; temporary value for hr 1st digit adjust
hrsd_temp	EQU	0x63	; temporary value for hr 2nd digit adjust

al0_hrsd	EQU	0x62	; alarm	0 hours 2nd digit (tens) register
al0_hrfd	EQU	0x61	; alarm 0 hours 1st digit (unit) register
al0_mnsd	EQU	0x60	; alarm 0 minutes 2nd (tens) register
al0_mnfd	EQU	0x5F	; alarm 0 minutes 1st (unit) register
al1_hrsd	EQU	0x5E	; alarm	1 hours 2nd digit (tens) register
al1_hrfd	EQU	0x5D	; alarm 1 hours 1st digit (unit) register
al1_mnsd	EQU	0x5C	; alarm 1 minutes 2nd (tens) register
al1_mnfd	EQU	0x5B	; alarm 1 minutes 1st (unit) register
al2_hrsd	EQU	0x5A	; alarm	2 hours 2nd digit (tens) register
al2_hrfd	EQU	0x59	; alarm 2 hours 1st digit (unit) register
al2_mnsd	EQU	0x58	; alarm 2 minutes 2nd (tens) register
al2_mnfd	EQU	0x57	; alarm 2 minutes 1st (unit) register
al3_hrsd	EQU	0x56	; alarm	3 hours 2nd digit (tens) register
al3_hrfd	EQU	0x55	; alarm 3 hours 1st digit (unit) register
al3_mnsd	EQU	0x54	; alarm 3 minutes 2nd (tens) register
al3_mnfd	EQU	0x53	; alarm 3 minutes 1st (unit) register
al4_hrsd	EQU	0x52	; alarm	4 hours 2nd digit (tens) register
al4_hrfd	EQU	0x51	; alarm 4 hours 1st digit (unit) register
al4_mnsd	EQU	0x50	; alarm 4 minutes 2nd (tens) register
al4_mnfd	EQU	0x4F	; alarm 4 minutes 1st (unit) register
al5_hrsd	EQU	0x4E	; alarm	5 hours 2nd digit (tens) register
al5_hrfd	EQU	0x4D	; alarm 5 hours 1st digit (unit) register
al5_mnsd	EQU	0x4C	; alarm 5 minutes 2nd (tens) register
al5_mnfd	EQU	0x4B	; alarm 5 minutes 1st (unit) register
al6_hrsd	EQU	0x4A	; alarm	6 hours 2nd digit (tens) register
al6_hrfd	EQU	0x49	; alarm 6 hours 1st digit (unit) register
al6_mnsd	EQU	0x48	; alarm 6 minutes 2nd (tens) register
al6_mnfd	EQU	0x47	; alarm 6 minutes 1st (unit) register
al7_hrsd	EQU	0x46	; alarm	7 hours 2nd digit (tens) register
al7_hrfd	EQU	0x45	; alarm 7 hours 1st digit (unit) register
al7_mnsd	EQU	0x44	; alarm 7 minutes 2nd (tens) register
al7_mnfd	EQU	0x43	; alarm 7 minutes 1st (unit) register

alarm_ctrl	EQU	0x42	; alarm control flags register

clock_ctrl	EQU	0x41	; clock control flags register

display		EQU	0x40	; display register

counter		EQU	0x3F	; general purpose counter/indexer
counter1	EQU	0x3E	; general purpose counter/indexer
counter2	EQU	0x3D	; general purpose counter/indexer
counter3	EQU	0x3C	; general purpose counter/indexer
counter4	EQU	0x3B	; general purpose counter/indexer
counter_e1	EQU	0x3A	; eeprom write counter
counter_e2	EQU	0x39	; eeprom write counter

week_temp	EQU	0x38	; temporary week day register
clk_set		EQU	0x37	; clock adjust register
temp_val	EQU	0x36	; intermediate values register

snooze_dly	EQU	0x35	; snooze delay register
snooze_ctr	EQU	0x34	; snooze count down register

;**************************************************************************************************

;***** Registers and Ports bits description
;
;alarm_ctrl:
;             bit  7  6  5  4  3  2  1  0
;                  |  |  |  |  |  |  |  +-- Beeper stop flag
;                  |  |  |  |  |  |  +----- Master Alarm ON/OFF flag
;                  |  |  |  |  |  +-------- Alarm adjustment flag
;                  |  |  |  |  +----------- Snooze flag
;                  |  |  |  +-------------- Alarm triggered flag
;                  |  |  +----------------- Alarm Off Temp flag
;                  |  +-------------------- 
;                  +----------------------- 
;
;bit=o - flag reset
;bit=1 - flag set
;
;
;clock_ctrl:
;             bit  7  6  5  4  3  2  1  0
;                  |  |  |  |  |  |  |  +-- Time change flag
;                  |  |  |  |  |  |  +----- Time adjustment flag
;                  |  |  |  |  |  +-------- Mains Power Availability flag
;                  |  |  |  |  +----------- 
;                  |  |  |  +-------------- 
;                  |  |  +----------------- 
;                  |  +-------------------- 
;                  +----------------------- 
;
;bit=o - flag reset
;bit=1 - flag set
;
;
;PORTA:
;             bit  4  3  2  1  0
;                  |  |  |  |  +-- Time Adjustment Key
;                  |  |  |  +----- Alarm Adjustment Key
;                  |  |  +-------- + Key
;                  |  +----------- - Key
;                  +-------------- Master Alarm ON/OFF Key
;
;bit=0 - Key Closed/Pressed
;bit=1 - Key Open/Released
;
;
;PORTB:
;             bit  7  6  5  4  3  2  1  0
;                  |  |  |  |  |  |  |  +-- Output - Data output to shift registers
;                  |  |  |  |  |  |  +----- Output - Clock output to shift registers
;                  |  |  |  |  |  +-------- Output - Beeper
;                  |  |  |  |  +----------- Output - Separator LEDs (0-OFF; 1-ON)
;                  |  |  |  +-------------- Output - Shift registers master reset (0-RST; 1-RUN)
;                  |  |  +----------------- Input - AC PWR sensor (0-PWR OFF; 1-PWR ON)
;                  |  +-------------------- Input - Temporary display on Key (0=closed/pressed; 1=open/released)
;                  +----------------------- Input - Snooze Key  (0=closed/pressed; 1=open/released)
;
;alx_hrsd registers contents
;
; bits 0-1 contain tens of hour information
; bits 2-3 contain alarm setup
;	00 - alarm off
;	01 - alarm goes off on every day
;	10 - alarm goes off only on work days (monday to friday)
;	11 - alarm goes off on a specific
; bits 4-6 contain week day

;***** BIT DEFINITIONS

BIT0		EQU	0x00
BIT1		EQU	0x01
BIT2		EQU	0x02
BIT3		EQU	0x03
BIT4		EQU	0x04
BIT5		EQU	0x05
BIT6		EQU	0x06
BIT7		EQU	0x07
TAK			EQU	0x00
AAK			EQU	0x01
Kplus		EQU	0x02
Kminus		EQU	0x03
MAK			EQU	0x04

;**************************************************************************************************

;***** MACRO DEFINITIONS

CHKKU macro BIT
;**************************************************************************************************
;* This routine checks and debounces the opening of a key connected to PORTA.BIT (CHecK Key Up)   *
;**************************************************************************************************
		local	cku_1
cku_1	btfss	PORTA,BIT	; check - PORTA.BIT Key opening
		goto	cku_1		; no, wait until Key is opened
		call	delay		; key debouncing delay
		endm
;**************************************************************************************************
KCONF macro BIT
;**************************************************************************************************
;* This routine will check if a Key remains pressed for around 3sec. to proceed (Key CONFirmation)*
;**************************************************************************************************
		local	kco_1
		movlw	0x12
		movwf	counter4
kco_1	call	delay
		btfsc	PORTA,BIT
		goto	loop
		decfsz	counter4,1
		goto	kco_1
		endm
;**************************************************************************************************

		ORG     0x000           ; processor reset vector
  		goto    main            ; go to beginning of program
;**************************************************************************************************

		ORG     0x004           ; begining of interrupt routine
		
					;**********************************************************
					;* This section disables interrupts while the interrupt   *
					;* handling routine is being run and save the contents of *
					;* W and Status registers which will be restored when the *
					;* program returns to the main program stream             *
					;**********************************************************
		clrf	INTCON		; reset INTCON - disable interrupts
		movwf   w_temp          ; save off current W register contents
		movf	STATUS,w        ; move status register into W register
		movwf	status_temp     ; save off contents of STATUS register
		bcf	clock_ctrl,BIT0	; reset time change flag


					;**********************************************************
					;* This section implements the 16-bit counter that is     *
					;* incremented every 2,048ms. This counter will overflow  *
					;* every 29297 counts or 60sec.                           *
					;**********************************************************
		
		movlw	0x72		; value=0x72
		xorwf	t0sd_count,0	; check - timer0 2nd digit max count achieved
		btfsc	STATUS,Z	
		goto	last_round_t0	; yes, go to timer0 counter last count round (1st dig=0x71)
		incfsz	t0fd_count,1	; no, incr timer0 counter 1st digit, check for overflow
		goto	end_interrupt	; no, resume
		incf	t0sd_count,1	; yes, incr timer0 counter 2nd digit
		goto	end_interrupt	; resume
last_round_t0	incf	t0fd_count,1	; increment timer0 1st digit
		movf	clk_set,0	; load w with timer0 1st digit max count
		xorwf	t0fd_count,0	; check - timer0 1st digit max count achieved
		btfss	STATUS,Z	; 
		goto	end_interrupt	; no, resume
		clrf	t0fd_count	; yes, rst timer0 1st digit
		clrf	t0sd_count	; rst timer0 2nd digit
		
					;**********************************************************
					;* This section controls the four time counters.          *
					;* Min. 1st digit counter is incremented by the overflow- *
					;* ing of the 16-bit counter. It is a decade counter.     *
					;* Min. 2nd digit counter is a module 6 counter and is    *
					;* incremented by the min. 1st overflowing.               *
					;* Hour 1st digit counter is incremented by the min, 2nd  *
					;* digit counter overflowing. It behaves as a decade      *
					;* counter while the hour 2nd digit counter is at 0/1.    *
					;* When that counter goes to 2, the hour 1st digit counter*
					;* will have its module changed to 4.                     *
					;* Week Count register is incremented whenever 24:00hs    *
					;* count is reached. The routine checks maximum week count*
					;* When it's achieved the Week Count register is reset.   *
					;* Whenever time changes (minute changes) the Time Change *
					;* flag is set to guarantee that display is updated by the*
					;* monitor_change routine.                                *
					;* Cancel Alarm flag is also reset in order to allow      *
					;* correct Snooze operation                               *
					;**********************************************************

		incf	mnfd_count,1	; increment minute 1st digit
		bsf	clock_ctrl,BIT0	; set time change flag
		bcf	alarm_ctrl,BIT0	; reset cancel alarm flag
		movlw	0x0A		; value=0x0A
		xorwf	mnfd_count,0	; check - minute 1st digit max count achieved
		btfss	STATUS,Z	
		goto	end_interrupt	; no, resume
		clrf	mnfd_count	; yes, reset minute 1st digit
		incf	mnsd_count,1	; incr minute 2nd digit
		movlw	0x06		; value=0x06
		xorwf	mnsd_count,0	; check - minute 2nd digit max count achieved
		btfss	STATUS,Z
		goto	end_interrupt	; no, resume
		clrf	mnsd_count	; yes, rst minute 2nd digit
		movlw	0x02		; value=0x02
		xorwf	hrsd_count,0	; check - time above 20:00 hours
		btfsc	STATUS,Z
		goto	last_round_clk	; yes, go to last hour count round
		incf	hrfd_count,1	; no, incr hour 1st digit
		movlw	0x0A		; value=0x0A
		xorwf	hrfd_count,0	; check - hour 1st digit max count achieved
		btfss	STATUS,Z
		goto	end_interrupt	; no, resume
		clrf	hrfd_count	; yes, rst hour 1st digit
		incf	hrsd_count,1	; incr hour 2nd digit
		goto	end_interrupt	; resume
last_round_clk	incf	hrfd_count,1	; incr hour 1st digit
		movlw	0x04			; value=0x04
		xorwf	hrfd_count,0	; check - 24:00 hours reached
		btfss	STATUS,Z
		goto	end_interrupt	; no, resume
		clrf	hrfd_count	; yes, rst hour 1st digit
		clrf	hrsd_count	; rst hour 2nd digit
		incf	week_count,1	; increment week day register
		movlw	0x07
		xorwf	week_count,0	; check - week counter max count achieved
		btfss	STATUS,Z
		goto	end_interrupt	; no, resume
		clrf	week_count	; yes, reset week count register
		
					;**********************************************************
					;* This section enables interrupts and restores the       *
					;* the original values to W and Status register before    *
					;* program returns to the main stream                     *
					;**********************************************************

end_interrupt	bsf	INTCON,T0IE	; enable timer0 interrupt
		bsf	INTCON,GIE	; enable global interrupt
		movf    status_temp,w   ; retrieve copy of STATUS register
		movwf	STATUS          ; restore pre-isr STATUS register contents
		swapf   w_temp,f
		swapf   w_temp,w        ; restore pre-isr W register contents
		retfie                  ; return from interrupt

;**************************************************************************************************

					;**********************************************************
					;* This section creates a look up table to convert hex-   *
					;* format codes to 7-segment.                             *
					;* The value to be converted is place in the W register   *
					;* and the convertion subroutine is called what will set  *
					;* the PCL with the address of the starting point of the  *
					;* convertion table. The value to be converted functions  *
					;* as the offset that is added to PCL taking it to the    *
					;* position where a retlw instruction will terminate the  *
					;* convertion subroutine loading the corresponding 7-seg. *
					;* code into W register.	                			  *
					;**********************************************************

convertion	addwf	PCL,1		
		retlw	0xFC
		retlw	0x60
		retlw	0xDA
		retlw	0xF2
		retlw	0x66
		retlw	0xB6
		retlw	0x3E
		retlw	0xE0
		retlw	0xFE
		retlw	0xF6
		retlw	0xEE
		retlw	0xFE
		retlw	0x9C
		retlw	0xFC
		retlw	0x9E
		retlw	0xCE

conv_wd_d1	addwf	PCL,1
		retlw	0xB6
		retlw	0xB6
		retlw	0xEC
		retlw	0x1E
		retlw	0x7C
		retlw	0x1E
		retlw	0x8E
		
conv_wd_d2	addwf	PCL,1
		retlw	0x1E
		retlw	0x38
		retlw	0x3A
		retlw	0x38
		retlw	0x7A
		retlw	0x2E
		retlw	0x0A


;**************************************************************************************************

main					
					;**********************************************************
					;* The section below reads data from eeprom into data     *
					;* memory.                                                *
					;* Eeprom addresses from 0x7F to 0x60 keep alarms 1 to 8  *
					;* time information.                                      *
					;* Whenever the clock is turned on or after a Master Reset*
					;* this data has to be copied to the alarm registers      * 
					;* located in the data memory 0x62 to 0x43.               *
					;* If eeprom does not contain valid information (0xFF) in *
					;* the alarm time addresses the data memory will be loaded*
					;* with 0x00.                                             *
					;* That does not apply to the position 0x2F in the eeprom *
					;* because any value can be considered valid for the      *
					;* alarm_flag register.                                   *
					;**********************************************************

		bcf	INTCON,T0IE	; disable Timer0 interrupts
		bcf	INTCON,GIE	; disable global interrupts
		bcf	STATUS,RP0
		bcf	STATUS,RP1	; select bank0

					; start of PORT A initialization
		clrf	PORTA		; set port A output data latch
		movlw	0x07
		movwf	CMCON		; turn comparators of and enable pins for I/O


main_0	movlw	0x7F
		movwf	counter_e1	; counter_e1 points to top of eeprom (al_0 hour) 
		movlw	0x62
		movwf	counter_e2	; counter_e2 points to top of alarm registers in 
					;data memory (al_0 hour) 
main_1	movf	counter_e2,0
		movwf	FSR		; FSR contains the address of alarm time register

		movf	counter_e1,0; W contains new eeprom address

		bsf	STATUS,RP0	; select bank1

		movwf	EEADR		; address to read on eeprom
		bsf	EECON1,BIT0	; enable eeprom read
		movf	EEDATA,0

		bcf	STATUS,RP0	; select bank0
		
		movwf	temp_val
		movlw	0xFF
		xorwf	temp_val,0	
		btfss	STATUS,Z	; check - eeprom data = FF (not set)
		movf	temp_val,0	; no, W contains data read from eeprom, next instruction
					; will write that data to alarm time register
		movwf	INDF		; yes,W contains ZERO and alarm time register be set to ZERO

		decf	counter_e1,1	; counter_e1 points to next alarm register in eeprom
		decf	counter_e2,1	; counter_e2 points to next alarm register in data memory
		movlw	0x5F
		xorwf	counter_e1,0
		btfss	STATUS,Z	; check - all eeprom alarm registers read and copied to
					; data memory
		goto	main_1		; no, reinitiate loop
		
					;**********************************************************
					;* The section below configures microprocessor (Option and*
					;* interrupt registers, PORTB Pins), the clock and the    *
					;* alarm control registers.                               *
					;**********************************************************

		bsf	STATUS,RP0	; select bank1

					; Option Register configuration
		movlw	0x82		; W=0x82
		movwf	OPTION_REG	; clock increments TIMER0, prescaler /8; PORTB pullups
					; disabled
		
					; port B initialization
		movlw	0xE0
		movwf	TRISB		; all port B bits are outputs except bits 5 to 7
		
					; complete port A initialization		
		movlw	0x1F
		movwf	TRISA		; port A bits 0 to 4 configured as inputs

					; Configure clock control registers
					; All time counters are reset to guarantee correct couting
					; initiation.
					; Control flags are reset
					; Hour/Minute separator LEDs are turned ON
					; Shift registers are allowed to receive display updates
					
		bcf	STATUS,RP0	; select bank0

		clrf	TMR0		; rst timer0

					; rst timer0 counters
		clrf	t0fd_count	; timer0 counter 1st digit=0
		clrf	t0sd_count	; timer0 counter 2nd digit=0
		
					; rst minutes counters
		clrf	mnfd_count	; minutes 1st digit=0
		clrf	mnsd_count	; minutes 2nd digit=0
		
					; rst hours counters
		clrf	hrfd_count	; hours 1st digit=0
		clrf	hrsd_count	; hours 2nd digit=0
		
					; rst week day counter
		clrf	week_count	; week day counter = 0
		
		clrf	clock_ctrl	; clear clock_ctrl register
		clrf	alarm_ctrl	; clear alarm_ctrl register
		bsf	clock_ctrl,BIT0	; set time change flag to guarantee 1st display update
		bsf	PORTB,BIT3	; turn separator LEDs ON
		bsf	PORTB,BIT4	; shift registers MCLR disable

					;**********************************************************
					;* The section below configures the clock's time base     *
					;* offset to compensate for the quartz crystal error.     *
					;**********************************************************


		movlw	0x1A		;
		movwf	display		; W contains c character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character c to display
		movlw	0x3A		;
		movwf	display		; W contains o character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character o to display
		movlw	0x0C		;
		movwf	display		; W contains l character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character l to display
		movlw	0x1A		;
		movwf	display		; W contains c character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character c to display

main_2		movlw	0x70		; load W with minimum Timer0 1st digit max. count
		movwf	clk_set		; clear clock offset register
		btfsc	PORTA,TAK	; check - Tadj key pressed - clock OK
		goto	main_3		; no, go check another key
		bsf	clk_set,BIT0	; clock offset = 1
		CHKKU	TAK		; wait key to be released
					; send message showing setup
		movlw	0x02
		movwf	display		; W contains - character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character - to display
		movlw	0x02
		movwf	display		; W contains - character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character - to display
		movlw	0x02
		movwf	display		; W contains - character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character - to display
		movlw	0x02
		movwf	display		; W contains c character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character - to display
		call	delay		; allows time for user to check the setup
		call	delay		; allows time for user to check the setup
		call	delay		; allows time for user to check the setup
		goto	main_5		; proceed
main_3		btfsc	PORTA,Kplus	; check - + key pressed - clock too fast
		goto	main_4		; no, go check another key
		bsf	clk_set,BIT1	; clock offset = 2
		CHKKU	Kplus		; wait key to be released
					; send message showing setup
		movlw	0x80
		movwf	display		; W contains - character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character - to display
		movlw	0x80
		movwf	display		; W contains - character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character - to display
		movlw	0x80
		movwf	display		; W contains - character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character - to display
		movlw	0x80
		movwf	display		; W contains - character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character - to display
		call	delay		; allows time for user to check the setup
		call	delay		; allows time for user to check the setup
		call	delay		; allows time for user to check the setup
		goto	main_5		; proceed
main_4		btfsc	PORTA,Kminus	; check - - key pressed - clock too slow
		goto	main_2		; reinitiate clock adjust loop
		CHKKU	Kminus		; wait key to be released
					; send message showing setup
		movlw	0x10
		movwf	display		; W contains - character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character c to display
		movlw	0x10
		movwf	display		; W contains - character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character o to display
		movlw	0x10
		movwf	display		; W contains - character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character - to display
		movlw	0x10
		movwf	display		; W contains - character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character - to display
		call	delay		; allows time for user to check the setup
		call	delay		; allows time for user to check the setup
		call	delay		; allows time for user to check the setup


					;**********************************************************
					;* The section below configures the snooze delay          *
					;**********************************************************


		movlw	0x00		; select blank character
		call	sndly_msg	; send message to display

main_6		btfsc	PORTA,TAK	; check - Tadj key pressed - std delay
		goto	main_7		; no, go check another key
		movlw	0x05		; load W with standard snooze delay
		movwf	snooze_dly	; snooze delay register has standard delay
		CHKKU	TAK		; wait key to be released
					; send message showing setup
		movlw	0xB6		; select Standard Delay reference charachter S
		call	sndly_msg	; send message to display
		goto	main_5		; proceed

main_7		btfsc	PORTA,Kplus	; check - + key pressed - clock too fast
		goto	main_8		; no, go check another key
		movlw	0x0A		; load W with high snooze delay
		movwf	snooze_dly	; snooze delay register has high delay
		CHKKU	Kplus		; wait key to be released
					; send message showing setup
		movlw	0x6E		; select High Delay reference character H
		call	sndly_msg	; send message to display
		goto	main_5		; proceed

main_8		btfsc	PORTA,Kminus	; check - - key pressed - clock too slow
		goto	main_6		; reinitiate clock adjust loop
		movlw	0x01		; load W with high snooze delay
		movwf	snooze_dly	; snooze delay register has high delay
		CHKKU	Kminus		; wait key to be released
					; send message showing setup
		movlw	0x1C		; select Low Delay reference character L
		call	sndly_msg	; send message to display

main_5					; Intcon Register configuration		
		clrf	INTCON		; disable all interrupts
		bsf	INTCON,T0IE	; interrupt on TIMER0 overflow; other interrupts disabled
		bsf	INTCON,GIE	; enable all interrupts

;**************************************************************************************************		

loop					
;**************************************************************************************************			
;* This is the main loop.                                                                         *
;* The program will cycle thru this loop checking the status of keys/sensors and time change.     *
;* This checking process will trigger one of the following actions:                               *
;*                                                                                                *                                       
;* 			- alarm x current time matching verification                              * 
;*			  (whenever time changes and Master Alarm On/Off Key on)                  *
;* 			- display update (whenever time changes)                                  *
;*			- beeper activation (alarm triggering/snooze)                             *
;*			- display deactivation (power failure)                                    *
;*			- adjust time (if Tadj key pressed)                                       *
;* 			- adjust alarm (if Aadj key pressed)                                      *
;**************************************************************************************************

					;**********************************************************
					;* This section first checks the master alarm key and will*
					;* set/reset the corresponding flag in the Alarm Control  *
					;* register.                                              *
					;* Whenever the Masters Alarm On/Off flag changes state   *
					;* the Time Change flag will be set in order to allow the *
					;* display update (decimal point of first digit shows the *
					;* alarm status).                                         *
					;********************************************************** 

		bcf	PORTB,BIT2	; turn alarm off
		btfss	PORTA,MAK	; check - master alarm on/off key is open (alarm on)
		goto	rst_maoo_flg	; no, go to rst master alarm on/off flag
		btfsc	alarm_ctrl,BIT1	; check - master alarm on/off flag already set
		goto	loop_01		; yes, proceed to the next part of the loop
		bsf	alarm_ctrl,BIT1	; no, set master alarm on/off flag
		bsf	clock_ctrl,BIT0	; set time change flag to allow display update
		goto	loop_01		; proceed to the next part of the loop
rst_maoo_flg	btfss	alarm_ctrl,BIT1	; check - master alarm on/off flag already reset
		goto	loop_01		; yes, proceed to the next part of the loop
		bcf	alarm_ctrl,BIT1	; no, rst master alarm on/off flag
		bsf	clock_ctrl,BIT0	; set time change flag to allow display update

					;**********************************************************
					;* This section checks the AC PWR sensor.                 *
					;* The Mains Pwr Avail. flag will be set in accordance to *
					;* the sensor's status.                                   *
					;* The change on this flag's status also sets the Time    *
					;* Change flag to allow the display update.               *
					;**********************************************************

loop_01		btfss	PORTB,BIT5	; check - AC PWR sensor
		goto	mpa_rst		; if reset (ac pwr not available), proceed to Mains Pwr
					; Avail. flag reset routine
		btfss	clock_ctrl,BIT2	; if set (ac pwr available), check - Mains Pwr Avail. flag
					; already set
		goto	set_do_flg	; no, set flag
		goto	loop_02		; yes, proceed to the next part of the loop
mpa_rst		btfsc	clock_ctrl,BIT2	; check - Mains Pwr Avail. flag reset
		goto	rst_do_flg	; no, go reset fla
		goto	loop_02		; yes, resume
set_do_flg	bsf	clock_ctrl,BIT2	; set display on flag
		call	time_display	; update display
		goto	loop_02		; resume
rst_do_flg	bcf	clock_ctrl,BIT2	; rst display on flag
		bcf	PORTB,BIT3	; turn separator LEDs off
		bcf	PORTB,BIT4	; rst shift registers MCLR pin to turn display off

					;**********************************************************
					;* This section checks whether the Display On key is      *
					;* pressed.                                               *
					;* If yes, and the AC PWR sensor is not On (no mains pwr),*
					;* the display will be lit.				  *
					;* The display will remain lit while the key is pressed   *
					;* The pressing of this key when the mains pwr is         *
					;* available will have no effect.                         *
					;**********************************************************

loop_02		btfss	PORTB,BIT6	; check - Temp Display On Key Pressed
		btfsc	PORTB,BIT5	; yes, check - AC PWR sensor
		goto	loop_03		; if set (ac pwr on), proceed to the next part of the loop
		call	time_display	; no, update display
wait_dok_rls	btfss	PORTB,BIT6	; wait Temp Display On Key release
		goto	wait_dok_rls
		bcf	PORTB,BIT4	; rst Shift Registers MCLR pin to disable display update
		bcf	PORTB,BIT3	; turn separator LEDs off

					;**********************************************************
					;* This section checks whether the Tadj key has been      *
					;* pressed. If yes the program is deviated to the time    *
					;* adjustment routine.                                    *
					;**********************************************************

loop_03		btfsc	PORTA,TAK	; check - time adjustment key pressed
		goto	loop_04		; no, resume
		movlw	0x12		; yes, go check how long it stays pressed
		movwf	counter4	; load counter4 with count enough to allow ~2sec delay
loop_05		call	delay		; this loop checks whether TAdj Key remains pressed for
		btfsc	PORTA,TAK	; more or less than ~1sec.
		goto	display_week_day; no, display week day
		decfsz	counter4,1
		goto	loop_05
		goto	time_adjust	; if pressed go to hour adjustment routine

					;**********************************************************
					;* This section checks whether the Aadj key has been      *
					;* pressed. If yes the program is deviated to the alarm   *
					;* adjustment routine.                                    *
					;**********************************************************

loop_04		btfss	PORTA,AAK	; check - alarm adjustment key status
		goto	alarm_adjust	; if pressed go to alarm adjust routine

;**************************************************************************************************

change_monitor
;**************************************************************************************************
;* This routine monitors changes to time and time/alarm adjustments.                              *
;* Whenever changes of this sort occurr the routine verify the need to take actions like:         *
;*                                        - update display                                        *         
;*                                        - turn the display on/off                               *
;*                                        - sound the beeper                                      *			
;**************************************************************************************************

					;**********************************************************
					;* This section checks changes (time/adjustments).        *
					;*                                                        *
					;* It first checks the Alarm Adjustment flag in the Alarm *
					;* Control register.                                      *
					;* Then, it checks the Time Change and Time Adjustment    *
					;* flags in the Clock Control register                    *
					;* If none of these flags are set the program will restart*
					;* the main loop.                                         *
					;* Otherwise the program will proceed checking the need to*
					;* check alarms and sound the beeper, update display or   *
					;* turn the display off.                                  *
					;********************************************************** 

		btfsc	alarm_ctrl,BIT2	; check - alarm adjustment event occurred
		goto	cm_01		; yes, skip other events check and proceed with the routine 
		movlw	0x03		; no, check other events
		andwf	clock_ctrl,0	; w contains masked version of clock_ctrl reg. showing only
					; time change and alarm adjustment flags
		btfsc	STATUS,Z	; check - time change or time adjustment events occurred
		goto	loop		; no, return to the main loop (nothing has changed)
cm_01		bcf	clock_ctrl,BIT0	; yes, clear time change flag
		bcf	clock_ctrl,BIT1	; clear time adjustment flag
		bcf	alarm_ctrl,BIT2	; clear alarm adjustment flag
		
					;**********************************************************
					;* Change occurred.                                       *
					;* This section checks if it's necessary to check alarm   *
					;* versus current time matching by verifying the status of*
					;* the Master Alarm On/Off flag.                          *
					;* If the flag is set the program proceeds with the check.*
					;* If not, it jumps the checking step.                    *
					;**********************************************************

		btfss	alarm_ctrl,BIT1	; check - Master Alarm On/Off flag set
		goto	cm_02		; no, clear snooze flag and proceed to beeper control 
					; routine
		btfsc	alarm_ctrl,BIT0	; yes, check - Beeper Stop flag set
		goto	cm_02		; no, go to beeper control routine		
		bcf	STATUS,C	; yes, initiate alarm x current time checking cycle

					;**********************************************************
					;* This section checks if alarm and current time match.   *
					;* Each alarm setting will be checked against the current *
					;* time. The enable/disable state of each alarm is alsor  *
					;* verified. If one alarm time matches the current time   *
					;* the alarm is enabled, and the Beeper Stop flag is reset*
					;* the Alarm Triggered flag will be set.                  *
					;**********************************************************

		movlw	0x62		; 
		movwf	counter		; counter points to top of alarm register stack 
					; (Al0 hour 2nd digit/week register)
cm_08		movf	counter,0	; alarm reg. address copied to W
		movwf	FSR		; alarm reg. address copied to FSR
		movf	INDF,0		; W loaded with contents of hour 2nd digit/week register
		movwf	counter4	; counter4 loaded with the same contents
		andlw	0x0C		; mask to test bits 2&3 (alarm setup)
		btfsc	STATUS,Z	; check - alarm on
		goto	cm_03		; no, goto next alarm
		xorlw	0x04		; 
		btfss	STATUS,Z	; check - alarm to go off every day
		goto	cm_04		; no, proceed to work day verification routine
		
cm_10		movf	counter4,0	; yes, W loaded with contents of hour 2nd digit/week
					; register
		andlw	0x03		; mask to test bits 0&1 (hour second digit)
		xorwf	hrsd_count,0
		btfss	STATUS,Z	; check - matching between current time and alarm time
					; registers (tens of hours)
		goto	cm_03		; no, go to next alarm
		
		decf	counter,1	; yes,decrement counter to point to hour 1st digit register
		movf	counter,0	; alarm reg. address copied to W
		movwf	FSR		; alarm reg. address copied to FSR
		movf	INDF,0		; W loaded with contents of hour 1st digit register
		xorwf	hrfd_count,0
		btfss	STATUS,Z	; check - matching between current time and alarm time
					; (unities of hours)
		goto	cm_05		; no, go to next alarm
		
		decf	counter,1	; yes,decrement counter to point to min. 2nd digit register
		movf	counter,0	; alarm reg. address copied to W
		movwf	FSR		; alarm reg. address copied to FSR
		movf	INDF,0		; W loaded with contents of min. 2nd digit register
		xorwf	mnsd_count,0
		btfss	STATUS,Z	; check - matching between current time and alarm time
					; (tens of minutes)
		goto	cm_06		; no, go to next alarm

		decf	counter,1	; yes,decrement counter to point to min. 1st digit register
		movf	counter,0	; alarm reg. address copied to W
		movwf	FSR		; alarm reg. address copied to FSR
		movf	INDF,0		; W loaded with contents of min. 1st digit register
		xorwf	mnfd_count,0
		btfss	STATUS,Z	; check - matching between current time and alarm time
					; (tens of minutes)
		goto	cm_07		; no, go to next alarm

		bsf	alarm_ctrl,BIT4	; no, set Alarm Triggered flag
		decf	counter,1	; yes, decrement counter to point to new alarm register
		goto	cm_12		
		
cm_03		decf	counter,1	; decrement counter the necessary number of times to	
cm_05		decf	counter,1	; point to new alarm register
cm_06		decf	counter,1
cm_07		decf	counter,1
		
cm_12		movlw	0x42		
		xorwf	counter,0
		btfss	STATUS,Z	; check - all alarms verified
		goto	cm_08		; no, reinitiate checking cycle
		goto	beeper_ctrl	; yes, go to Beeper Control routine



cm_04		movf	counter4,0	; reload non-masked value of hour 2nd digit/weel register
		andlw	0x0C		; mask to check only bits 2&3
		xorlw	0x08		
		btfss	STATUS,Z	; check - alarm to go off only on work days
		goto	cm_09		; no, go check if alarm and current week day match
		movf	week_count,0	; w contains current week day
		andlw	0x0E		; mask to check wether week day != sat/sun
		btfss	STATUS,Z	; check - week day != sat/sun
		goto	cm_10		; yes, go check whether current and alarm time match
		goto	cm_03		; yes, go check next alarm

cm_09		swapf	counter4,0	; swap counter 4 and copy week day to W
		andlw	0x0F		; mask to remove hour and alarm set information
		xorwf	week_count,0
		btfss	STATUS,Z	; check - alarm and current week day match
		goto	cm_03		; no, go check next alarm
		goto	cm_10		; yes, go check whether current and alarm time match
		
cm_02		bcf	alarm_ctrl,BIT3	; clear snooze flag
		bcf	alarm_ctrl,BIT4	; clear Alarm Triggered flag

beeper_ctrl
					;**********************************************************
					;* This routine controls the beeper operation             *
					;* If the Alarm Triggered flag is set, beeper will sound. *
					;* If Snooze flag is set, beeper will sound.              *
					;* Beeper will stop sounding if:                          *
					;* 	- Snooze key is pressed (beeper is turned off     *
					;*         until next minute) - Snooze flag remains set   *
					;* 	- Aadj key is pressed (beeper is turned off       *
					;*         definitely) - Beeper Stop flag set             *
					;*	- Time changes before any of the keys are pressed *
					;*         (beeper is turned off definitely) - Time Change*
					;*         flag is set                                    *
					;**********************************************************

		btfss	alarm_ctrl,BIT4	; check - Alarm Triggered flag set (current and one of the
					; alarms time match)
		goto	snooze		; no, check - snooze
cm_11		bcf	alarm_ctrl,BIT4	; yes, clear Alarm triggered flag
		bcf	alarm_ctrl,BIT3	; clear snooze flag
		call	time_display	; update display

beep		bsf	PORTB,BIT2	; beeper on
		btfsc	clock_ctrl,BIT0	; check - Time Change flag set
		goto	loop		; yes, stop beeper and return to main loop
		btfss	PORTA,AAK	; check - Aadj Key pressed
		goto	beep_1		; yes, stop beeper and set Beeper Stop flag
		btfsc	PORTB,BIT7	; no, check - Snooze Key pressed
		goto	beep		; no, keep beeping
beep_2		btfss	PORTB,BIT7	; yes, wait snooze key release
		goto	beep_2
		bsf	alarm_ctrl,BIT3	; set snooze flag
		movf	snooze_dly,0	; w contains snooze delay
		movwf	snooze_ctr	; snooze countdown register loaded with delay
		goto	chk_dsp_on	; stop beeper and and proceed in the routine
beep_1		bsf	alarm_ctrl,BIT0	; set Beeper Stop flag
		CHKKU	AAK		; wait Aadj Key release
		goto	chk_dsp_on	; stop beeper and proceed

					;**********************************************************
					;* This section controls the snooze function and the      *
					;* display operation.                                     *
					;* If the Snooze flag is set the beeper will sound.       *
					;* If not the program moves to the verification of the    *
					;* Mains Pwr Avail. flag. If it's set the display will be *
					;* maitained at the On state (Shift Registers Master Clear*
					;* held HIGH and Separator LEDs On).                      *
					;* If the flag is reset, the display will be turned off by*
					;* holding Shift Registers Master Clear LOW and the Sepa- *
					;* rator LEDs Off.                                        *
					;**********************************************************

snooze		btfss	alarm_ctrl,BIT3	; check - snooze flag set
		goto	chk_dsp_on	; no, check - Mains Pwr Avail. flag set
		decfsz	snooze_ctr,1	; decrement snooze counter and check if zero achieved
		goto	chk_dsp_on	; no, proceed
		goto	cm_11		; yes, beep
chk_dsp_on	btfss	clock_ctrl,BIT2	; check, Mains Pwr Avaliable 
		goto	display_off	; no, turn display off
		call	time_display	; display time
		goto	loop		; return to main loop
display_off	bcf	PORTB,BIT4	; rst Shift Registers Master Clear to turn display off
		bcf	PORTB,BIT3	; turn separator LEDs off
		goto	loop		; return to main loop

display_week_day
;**************************************************************************************************
;* This routine displays the current week day whenever the TAdj Key is pressed for a short period *
;* of time.                                                                                       *
;* It uses the convertion tables (conv_wd_d1 and conv_wd_d2) to determine the correct 7-segment   *
;* codes for the 1st and 2nd digits to be displayed                                               *
;* The 7-segment codes are loaded to the Display Register and its contents is displayed by the    *
;* Display_Update routine                                                                         *
;**************************************************************************************************

		bcf	PORTB,BIT3	; turn separator LEDs off
		bsf	PORTB,BIT4	; set shift registers MCLR pin to turn display on
		movf	week_count,0	; W contais current week day
		call	conv_wd_d2	; load W with 7-segment code for week day 2nd digit
		movwf	display		; 7-segment code loaded to display register
		call	display_update	; Update display
		movf	week_count,0
		call	conv_wd_d1	; load W with 7-segment code for week day 1st digit
		movwf	display		; 7-segment code loaded to display register
		call	display_update	; Update display
		clrf	display		; Clear display register
		call	display_update	; Update display
		clrf	display		; Clear display register
		call	display_update	; Update display
		call	delay		; delay to allow week day visualization
		call	delay		; delay to allow week day visualization
		call	delay		; delay to allow week day visualization
		call	delay		; delay to allow week day visualization
		call	time_display	; Update display with current time
		bsf	clock_ctrl,BIT0	; set time change flag to reset current state
		goto	loop		; return to main loop
;**************************************************************************************************
				
time_adjust
;**************************************************************************************************
;* This routine provides the means for time and week day adjustment.                              *
;* It's initiate with the activation of the Tadj key for more than ~2sec.                         *
;* The routine will move the contents of the time/week counters to temporary registers and will,  *
;* sequentially, run routines that allow the increment or decrement of each display digit and week*
;* day separatelly.                                                                               *
;* You change from one digit to the next pressing the Tadj key. After adjusting all digits you    *
;* press Tadj again to return to the main loop.                                                   *
;* After adjustment the values in the temporary registers are transferred to the time/week        *
;* counters and the Time Adjustment flag is set.                                                  *
;* The pattern 'HHHH' is displayed for a short period when adjustment is finished.                *
;**************************************************************************************************

		bcf	INTCON,GIE	; disable global interrupts
		bcf	INTCON,T0IE	; disable Timer 0 interrupts
		bcf	PORTB,BIT3	; turn separator LEDs off
		bsf	PORTB,BIT4	; set Shift Registers MCLR pins to turn display on
		bcf	alarm_ctrl,BIT3	; reset Snooze Flag

					;**********************************************************
					;* This section transfer current value of time/week       *
					;* couners to temporary registers where adjustment will   *
					;* take place                                             *
					;**********************************************************

		movf	week_count,0	; load W with week count value
		movwf	week_temp	; transfer the value of week count to tmp variable
		movf	hrsd_count,0	; load W with hour 2nd digit counter value
		movwf	hrsd_temp	; transfer the value to hour 2nd digit tmp variable
		movf	hrfd_count,0	; load W with hour 1st digit counter value
		movwf	hrfd_temp	; transfer the value to hour 1st digit tmp variable
		movf	mnsd_count,0	; load W with min 2nd digit counter value
		movwf	mnsd_temp	; transfer the value to min 2nd digit tmp variable
		movf	mnfd_count,0	; load W with min 1st digit counter value
		movwf	mnfd_temp	; transfer the value to min 1st digit tmp variable


		bsf	PORTB,BIT3	; turn separator LEDs on
		call	dupdt_hrsd	; update display with set up mode (hour 2nd digit lit)
		CHKKU	TAK		; wait Tadj key release to proceed

		call	set_hrsd	; call subroutine to adjust hour 2nd digit
		call	set_hrfd	; call subroutine to adjust hour 1st digit
		call	set_mnsd	; call subroutine to adjust min 2nd digit
		call	set_mnfd	; call subroutine to adjust min 1st digit
		call	set_week	; call subroutine to adjust week count

		call	delay
		CHKKU	TAK		; wait Tadj key release
		
					;**********************************************************
					;* This section returns the adjusted values to the        *
					;* permanent time counters                                *
					;**********************************************************

		movf	hrsd_temp,0	; load W with updated hour 2nd digit value
		movwf	hrsd_count	; load updated value to hour 2nd digit counter
		movf	hrfd_temp,0	; load W with updated hour 1st digit value
		movwf	hrfd_count	; load updated value to hour 1st digit counter
		movf	mnsd_temp,0	; load W with updated min 2nd digit value
		movwf	mnsd_count	; load updated value to min 2nd digit counter
		movf	mnfd_temp,0	; load W with updated min 1st digit value
		movwf	mnfd_count	; load updated value to min 1st digit counter
		movf	week_temp,0	; load W with updated week day value
		movwf	week_count	; load updated value to week day counter

					;**********************************************************
					;* This section sets the Time Adjustment flag, enable     *
					;* interrupts in order to allow the time counting process *
					;* to be re-established.                                  *
					;* The Timer_0 and the 16-Bit counter registers are all   *
					;* reset.                                                 *
					;**********************************************************

		bsf	clock_ctrl,BIT1	; set Time Adjustment flag
		bsf	INTCON,GIE	; enable global interrupts
		bsf	INTCON,T0IE	; enable timer 0 interrupts
		clrf	TMR0		; rst Timer 0
		clrf	t0fd_count	; rst timer 0 1st digit counter
		clrf	t0sd_count	; rst timer 0 2nd digit counter
		
					;**********************************************************
					;* This last section sends the pattern 'HHHH" to the      *
					;* display to indicate that the adjustment process is     *
					;* finished and return to the main loop.                  *
					;**********************************************************

		movlw	0x04		; set loop counter to 4
		movwf	counter
hradj_1		movlw	0x6E		; load display register with code 0x6E (H)
		movwf	display
		bcf	STATUS,C	; clear carry flag
		call	display_update	; send code 7-seg to display
		decfsz	counter,1	; check - counter = 0
		goto	hradj_1		; no, reinitiate loop
		call	delay		; delay to allow pattern visualization
		call	delay		; delay to allow pattern visualization
		call	delay		; delay to allow pattern visualization
		clrf	display		; clear display register
		bcf	STATUS,C	; clear carry flag
		

		goto	loop

;**************************************************************************************************

alarm_adjust
;**************************************************************************************************
;* This routine provides the means for the 8 available alarms adjustment.                         *
;* It is initiated with the pressing of the Aadj key.                                             *
;* The routine's operation can be devided in two layers:                                          *
;* In the first layer the user will select the alarm he/she wants to set on/off                   *
;* This is accomplished through the pressing of the +/- and Aadj keys.                            *
;* In the secont layer the user will set the time/week day of the alarm he/she decided to set.    *
;* This is accomplished through the pressing of the +/- and Hadj Keys.                            *
;* The program will return from the 2nd to the 1st layer after the completion of the time/week    *
;* setting process.                                                                               *
;* To exit the adjustment routine the user should press the Tadj Key while in the first layer.    *
;* Any changes made at layers 1 or 2 to any of the 8 alarms will lead to the Alarm_Adjustment flag*
;* setting.                                                                                       *
;**************************************************************************************************

					;**********************************************************
					;* This initial section will reset the index that will    *
					;* point to the alarm to be set, turn the Separator       *
					;* LEDs off so that they do not interfere with the text   *
					;* messages to be displayed and reset the Snooze Flag.     *
					;**********************************************************

		KCONF	AAK		; Awaits Key pressing confirmation
					; Allow some time for user to quit
		bsf	PORTB,BIT4	; set Shift Registers MCLR pins to turn display on
		bcf	alarm_ctrl,BIT3	; reset Snooze Flag
					
		clrf	counter		; clear index pointing to the alarm being set
aladj_04	bcf	PORTB,BIT3	; turn separator LEDs off (during text messages displaying)

					;**********************************************************
					;* This section will send the message "AL_#" to the       *
					;* display.                                               *
					;* This indicates that the clock is in the alarm adj. mode*
					;* and ready to initiate the process to set the alarm #.  *
					;* At this point the program is entering its layer 1.     *
					;**********************************************************
		
		movf	counter,0	; move index to W
		call	convertion	; convert alarm # to 7-Segment format
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		movwf	display
		call	display_update	; send Alarm # to display
		clrf	display		; display register = 0
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; send code to display
		movlw	0x1C
		movwf	display		; display register = character L
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; send code to display
		movlw	0xEE
		movwf	display		; display register = character A
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; send code to display
		CHKKU	AAK		; wait Aadj key to be released
		
					;**********************************************************
					;* This section consists of a loop that waits for the     *
					;* pressing of keys that will:                            *
					;*       - lead the program to the adjustment section     *
					;*       - terminate the routine and lead the program back*
					;*         to the main loop.                              *
					;*       - select another alarm to be set                 *
					;**********************************************************

aladj_02	btfss	PORTA,AAK	; check - Alarm Adjust key pressed
		goto	set_alarm_oo	; yes, go to adjust routine
		btfss	PORTA,TAK	; check - Time Adjust key pressed
		goto	aladj_01	; terminate and go to main loop
		btfss	PORTA,Kplus	; check - key + pressed
		goto	inc_al_index	; go to alarm index increment routine
		btfss	PORTA,Kminus	; check - Key - pressed
		goto	dec_al_index	; go to alarm index decrement routine
		goto	aladj_02	; reinitiate keys polling sequence

					;**********************************************************
					;* This section controls the alarm index.                 *
					;* It increments/decrements the index based on the +/-    *
					;* keys pressing.                                         *
					;* It also checks if the index, after a decrement or      *
					;* increment operation, has gone out of the 0 to 7 range. *
					;* If that is the case the index will be reset to 7 (index*
					;* is 0xFF after a decrement) or to 0 (index is 0x08 after*
					;* an increment.                                          *
					;**********************************************************
aladj_05	movlw	0x08
		xorwf	counter,0
		btfss	STATUS,Z	; check - index = 8
		goto	aladj_03	; no, go check whether index = 0xFF
		clrf	counter		; yes, clear index
		goto	aladj_04	; reinitiate alarm adjust loop
aladj_03	movlw	0xFF
		xorwf	counter,0
		btfss	STATUS,Z	; check - index = FF
		goto	aladj_04	; no, reinitiate alarm adjust loop
		movlw	0x07
		movwf	counter		; yes, index = 7
		goto	aladj_04
inc_al_index	call	delay
		incf	counter,1	; increment index
		CHKKU	Kplus
		goto	aladj_05
dec_al_index	call	delay
		decf	counter,1	; decrement index
		CHKKU	Kminus
		goto	aladj_05

					;**********************************************************
					;* This section allows the user the individually set each *
					;* alarm On or Off.                                       *
					;* After selecting one specific alarm, the user will press*
					;* the Aadj key. After that the program will ask the user *
					;* to turn it On or Off.
					;* This is accomplished by displaying the message "turn"  *
					;* and polling the +/- keys. The + key will turn the alarm*
					;* On and the display will show the message "ON" for some *
					;* some time. The - key will turn the alarm Off and the   *
					;* display will show the message "OFF".                   *
					;* If the alarm is turned On the program will be directed *
					;* to the adjustmen routine (layer 2).                    *
					;* If the alarm is turned off the program will prompt the *
					;* customer the next alarm.				  *
					;**********************************************************
		
set_alarm_oo	CHKKU	AAK		; wait A Key release
		movlw	0x2A		;
		movwf	display		; W contains n character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character n to display
		movlw	0x0A		;
		movwf	display		; W contains r character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character r to display
		movlw	0x38		;
		movwf	display		; W contains u character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character u to display
		movlw	0x1E		;
		movwf	display		; W contains t character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character t to display
		
aladj_06	btfss	PORTA,Kplus	; check - + key pressed
		goto	set_al_on	; yes, go to set alarm on routine
		btfss	PORTA,Kminus	; no, check - - key pressed
		goto	set_al_off	; yes, go to set alarm off routine
		goto	aladj_06	; no, reinitiate check keys loop
		
set_al_off	CHKKU	Kminus		; wait - - key release
		bcf	STATUS,C	; clear carry flag to avoid spurious data
		rlf	counter,1	; rotate counter left to define correct offset
		rlf	counter,0	; rotate counter left to define correct offset
					; and place offset in W
		rrf	counter,1	; rotate counter right to restore original value
		sublw	0x62		; W contains the address of alarm hour 2nd digit/week register
		movwf	FSR		; alarm reg. address copied to FSR
		bcf	INDF,BIT2	; reset bit2 of hour 2nd digit/week register
		bcf	INDF,BIT3	; reset bit3 of hour 2nd digit/week register
		movlw	0x00		;
		movwf	display		; W contains "" character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character "" to display
		movlw	0x8E		;
		movwf	display		; W contains F character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character F to display
		movlw	0x8E		;
		movwf	display		; W contains F character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character F to display
		movlw	0xFC		;
		movwf	display		; W contains O character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character O to display
		bsf	alarm_ctrl,BIT5	; set alarm specific off flag
		
		call	delay		; delay to allow visualization of the message
		call	delay		; delay to allow visualization of the message
		call	delay		; delay to allow visualization of the message
		goto	aladj_07	; go to next alarm

set_al_on	CHKKU	Kplus		; wait - + key release
					; send message EVER
		movlw	0x0A		;
		movwf	display		; W contains r character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character r to display
		movlw	0x9E		;
		movwf	display		; W contains E character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character E to display
		movlw	0x38		;
		movwf	display		; W contains v character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character v to display
		movlw	0x9E		;
		movwf	display		; W contains E character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character E to display
		
aladj_09	call	delay		; wait some more time for + key to be released
		btfss	PORTA,Kplus	; check - + key pressed
		goto	set_al_ever	; yes, go to set alarm "every day" routine
		btfsc	PORTA,Kminus	; no, check - - key pressed
		goto	aladj_09	; yes, go to next mode

		CHKKU	Kminus		; wait - - key release
					; send message SPEC
		movlw	0x9C		;
		movwf	display		; W contains C character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character C to display
		movlw	0x9E		;
		movwf	display		; W contains E character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character E to display
		movlw	0xCE		;
		movwf	display		; W contains P character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character P to display
		movlw	0xB6		;
		movwf	display		; W contains S character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character S to display
	
aladj_11	call	delay		; allow some more time for - key to be released
		btfss	PORTA,Kplus	; check - + key pressed
		goto	set_al_spec	; yes, go to set alarm "specific" routine
		btfsc	PORTA,Kminus	; no, check - - key pressed
		goto	aladj_11	; yes, go to next mode

		CHKKU	Kminus		; no,wait - - key release
					; send message MtoF
		movlw	0x8E		;
		movwf	display		; W contains F character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character F to display
		movlw	0x3A		;
		movwf	display		; W contains o character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character o to display
		movlw	0x1E		;
		movwf	display		; W contains t character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character t to display
		movlw	0xEC		;
		movwf	display		; W contains M character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character M to display
		call	delay		; delay to allow message visualization
		call	delay		; delay to allow message visualization
		call	delay		; delay to allow message visualization
		call	delay		; delay to allow message visualization

					;**********************************************************
					;* This section is the start of the layer 2 of the alarm  * 
                                        ;* adjustment routine.                                    *                                               *
					;* If the current alarm is disabled, this section is      *
					;* skipped.                                               *
					;* If the alarm is to go off every day or on work days the*
					;* routine will set bits 2 and 3 of the hour 2nd dig/week *
					;* register of the selected alarm and, reset bits 4 to 6  *
					;* of the same register and, then, go thru the steps to   *
					;* load the alarm time.                                   *
					;* If the alarm is to go off on a specific day of the week*
					;* the routine will additionally set bits 4 and 6 of the  *
					;* hour 2nd dig/week register to reflect the week day in  *
					;* which the alarm should go off                          *
					;**********************************************************
		
		movf	counter,0	; load w with the number of the selected alarm
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		rlf	counter,1	; multiply counter by 2
		rlf	counter,0	; multiply counter by 2 again and put result on W
					; W contains the offset to reach first register of the
					; selected alarm
		sublw	0x62		; W contains the address of the selected register's first
					; register
		movwf	FSR		; load FSR register with the selected alarm first register
		bsf	INDF,BIT3	; set bit 2 of the selected alarm first register
		movlw	0x0B
		andwf	INDF,1		; reset bits 2 and 4to7 of the selected alarm first register
		goto	aladj_12	; go to alarm time adjustment routine

set_al_spec	movf	counter,0	; load w with the number of the selected alarm
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		rlf	counter,1	; multiply counter by 2
		rlf	counter,0	; multiply counter by 2 again and put result on W
					; W contains the offset to reach first register of the
					; selected alarm
		sublw	0x62		; W contains the address of the selected register's first
					; register
		movwf	FSR		; load FSR register with the selected alarm first register

		movf	INDF,0		; load W with selected alarm first register
		movwf	week_temp	; load week temporary file with W
		swapf	week_temp,1	; swap temp register to have week day in the first nible
		movlw	0x07
		andwf	week_temp,1	; reset 2nd nible

		movlw	0x0F
		andwf	INDF,1		; clear selected alarm register's 2nd nible
		movlw	0x0C
		iorwf	INDF,1		; set bits 2 & 3 of the selected alarm first register
		

		call	set_week	; call subroutine to adjust week day

		call	delay
		CHKKU	TAK		; wait Tadj button release

		swapf	week_temp,1	; swap temp file to have week day in the second nible
		movf	week_temp,0	; load W with temp file contents
		iorwf	INDF,1		; load selected alarm 1st register with new week day

		goto	aladj_12	; go to alarm time adjustment routine

set_al_ever	CHKKU	Kplus		; wait - + key release
		movf	counter,0	; load w with the number of the selected alarm
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		rlf	counter,1	; multiply counter by 2
		rlf	counter,0	; multiply counter by 2 again and put result on W
					; W contains the offset to reach first register of the
					; selected alarm
		sublw	0x62		; W contains the address of the selected register's first
					; register
		movwf	FSR		; load FSR register with the selected alarm first register
		bsf	INDF,BIT2	; set bit 2 of the selected alarm first register
		movlw	0x07
		andwf	INDF,1		; reset bits 3to7 of the selected alarm first register

aladj_12	movf	INDF,0		; load W with selected alarm first register contents
		andlw	0xFC		; mask W contents to keep only week and alarm setup status
		movwf	temp_val	; keep the result in a temporary register		
		movf	INDF,0		; load W with selected alarm first register contents again
		andlw	0x03		; reset all bits except 0 and 1 which has the tens of hours
		movwf	hrsd_temp	; hour 2nd digit temp register contains selected alarm 1st
					; register contents
		decf	FSR,1		; decrement FSR register to point to selected alarm 2nd
					; register
		movf	INDF,0		; load W with selected alarm 2nd register contents
		movwf	hrfd_temp	; hour 1st digit temp register contains selected alarm 2nd
					; register contents
		decf	FSR,1		; decrement FSR register to point to selected alarm 3rd
					; register
		movf	INDF,0		; load W with selected alarm 3rd register contents
		movwf	mnsd_temp	; min 2nd digit temp register contains selected alarm 3rd
					; register contents
		decf	FSR,1		; decrement FSR register to point to selected alarm 4th
					; register
		movf	INDF,0		; load W with selected alarm 4th register contents
		movwf	mnfd_temp	; min 1st digit temp register contains selected alarm 4th
					; register contents

		bsf	PORTB,BIT3	; turn separator LEDs on
		
		call	dupdt_hrsd	; update display with set up mode (hour 2nd digit lit)
		
		call	set_hrsd	; call subroutine to adjust hour 2nd digit
		call	set_hrfd	; call subroutine to adjust hour 1st digit
		call	set_mnsd	; call subroutine to adjust min 2nd digit
		call	set_mnfd	; call subroutine to adjust min 1st digit

		call	delay
		CHKKU	TAK		; wait Tadj button release

					;**********************************************************
					;* This section returns the adjusted values to the        *
					;* permanent time counters                                *
					;**********************************************************

		movf	mnfd_temp,0	; move new min. 1st digit value to W
		movwf	INDF		; move value to selected alarm 4th register
		incf	FSR,1		; increment FSR register to point to selected alarm 3rd
					; register
		movf	mnsd_temp,0	; move new min. 2nd digit value to W
		movwf	INDF		; move value to selected alarm 3rd register
		incf	FSR,1		; increment FSR register to point to selected alarm 2nd
					; register
		movf	hrfd_temp,0	; move new hour 1st digit value to W
		movwf	INDF		; move value to selected alarm 2nd register
		incf	FSR,1		; increment FSR register to point to selected alarm 1st
					; register
		movf	hrsd_temp,0	; move new hour 2nd digit value to W
		iorwf	temp_val,0	; restore week and alarm setup status to W
		movwf	INDF		; move value to selected alarm 1st register
		
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		rrf	counter,1	; return counter to original value

					;**********************************************************
					;* This section  will increment the alarm index so that it*
					;* points to the next alarm and set the Alarm Adjustment  *
					;* flag.                                                  *
					;* The Separator LEDs are turned off again in order to    *
					;* avoid interference with the text messages sent to the  *
					;* display in routines layer 1                            *
					;* The program returns the alarm selection loop           *
					;**********************************************************

aladj_07	incf	counter,1	; incr counter
		bsf	alarm_ctrl,BIT2	; set alarm adjustment flag
		bcf	PORTB,BIT3	; turn separator LEDs off
		goto	aladj_05

					;**********************************************************
					;* This last section  takes care of transferring the new  *
					;* alarms setting to the eeprom                           *
					;* The program execution is directed to this point when   *
					;* the Tadj key is pressed while the adjust routine is in *
					;* layer 1.                                               *
					;* Once all data has been written to the eeprom the       *
					;* program returns to the main loop.                      *
					;**********************************************************

aladj_01	CHKKU	TAK		; wait H key release
		btfss	alarm_ctrl,BIT2	; check - any alarm changed
		goto	aladj_13	; no, skip eeprom write reinitiate main loop
		movlw	0x7F		; yes, write alarm setup to eeprom
		movwf	counter_e2	; this counter has the eeprom to be writen
		movlw	0x62
		movwf	counter_e1	; this counter has the address of the register containing the data to be writen to the eeprom
aladj_14	movf	counter_e1,0
		movwf	FSR		; transfer register address to FSR (indirect addressing) 
		movf	counter_e2,0

		bsf	STATUS,RP0	; select bank1

		movwf	EEADR		; address to write on eeprom
		movf	INDF,0		; 
		movwf	EEDATA		; load EEDATA with the value to be writen to the eeprom

		bsf	EECON1,BIT2	; enable writes to eeprom
		bcf	INTCON,GIE	; disable interrupts
		movlw	0x55		; sequence necessary to perform writes to eeprom
		movwf	EECON2		; sequence necessary to perform writes to eeprom
		movlw	0xAA		; sequence necessary to perform writes to eeprom
		movwf	EECON2		; sequence necessary to perform writes to eeprom
		bsf	EECON1,BIT1	; enable next write to EEPROM
		bsf	INTCON,GIE	; enable interrupts

		bcf	STATUS,RP0	; select bank0

ee_wr_check	btfss	PIR1,EEIF	; check - write operation complete
		goto	ee_wr_check	; no, keep checking
		bcf	PIR1,EEIF	; yes, reset EEIF flag and resume

		decf	counter_e2,1	; decrement counter to access new eeprom address
		decf	counter_e1,1	; decrement counter to access new alarm time register
		movlw	0x5F
		xorwf	counter_e2,0
		btfss	STATUS,Z	; check - all registers transferred to eeprom
		goto	aladj_14	; no, restart write loop
		goto	aladj_15
aladj_13	bsf	clock_ctrl,BIT0	; set time change flag to allow display update
aladj_15	bsf	PORTB,BIT3	; turn separator LEDs on
		goto	loop
;**************************************************************************************************

;***** SUBROUTINES

display_update
;**************************************************************************************************
;* This routine serially tranfers data contained in the display register to the Shift Registers.  *
;**************************************************************************************************

		movlw	0x08		; set counter1 to 0x08
		movwf	counter1
loop_du		bcf	PORTB,BIT0	; clear PORTB.0 - data=0
		btfsc	display,0	; check - display register bit 0 status
		bsf	PORTB,BIT0	; 1 - set PORTB.0 - data=1
		nop			; data estabization delay
		bsf	PORTB,BIT1	; set PORTB.1 - clock rises
		nop			; delay
		bcf	PORTB,BIT1	; rst PORTB.1 - clock falls
		rrf	display,1	; rotate display - next bit on bit 0 position
		decfsz	counter1,1	; decrement counter1 and check if ZERO - all bits transferred
		goto	loop_du		; no, reinitiate loop
		return			; yes, return

;**************************************************************************************************
					
delay
;**************************************************************************************************
;* This routine generates ~30ms delay.                                                            *
;**************************************************************************************************

		movlw	0x61		; set counter3 to 0x61
		movwf	counter3
delay_1		movlw	0xFF		; set counter2 to 0xFF
		movwf	counter2
delay_2		nop			; delay
		decfsz	counter2,1	; decrement counter 2 and check if ZERO
		goto	delay_2		; no, reinitiate inner loop
		decfsz	counter3,1	; yes, decrement counter 3 and check if ZERO
		goto	delay_1		; no, reinitiate outer loop
		return			; yes, return

;**************************************************************************************************
					
set_week
;**************************************************************************************************
;* This routine implements the week counter adjustment.                                           *
;**************************************************************************************************

		call	delay
		CHKKU	TAK		; wait Tadj button released
		call	dupdt_week	; update display with week adjustment pattern
					; initiate adjust
swk_1		btfss	PORTA,Kplus	; check - Key + pressed
		goto	inc_wk		; yes, go to increment routine
		btfss	PORTA,Kminus	; no, check - Key - pressed
		goto	dec_wk		; yes, go to decrement routine
		btfss	PORTA,TAK	; no, check - TAK key pressed
		return			; yes, proceed with the adjustment routine
		goto	swk_1		; no, reinitiate adjust loop
		
					; digit increment routine
inc_wk		call	delay
		CHKKU	Kplus		; wait Key + release
		incf	week_temp,1	; increment week temp variable
		movlw	0x07		; check - overflowed maximum count
		xorwf	week_temp,0
		btfsc	STATUS,Z
		clrf	week_temp	; yes, reset value
		goto	wk_updt_dsp	; if yes, go to display update routine	

					; digit decrement routine
dec_wk		call	delay
		CHKKU	Kminus		; wait Key - release
		movf	week_temp,1	; check whether week count is ZERO
		btfss	STATUS,Z
		goto	dec_wk_1	; no, proceed with decrement
		movlw	0x06		; yes, reset value to 5
		movwf	week_temp
		goto	wk_updt_dsp	; and proceed	
dec_wk_1	decf	week_temp,1	; decrement week counter
wk_updt_dsp	call	dupdt_week
		goto	swk_1		; reinitiate week counter adjust loop

;**************************************************************************************************
					
set_hrsd
;**************************************************************************************************
;* This routine implements the hour 2nd digit adjustment                                          *
;**************************************************************************************************
					
shsd_1		btfss	PORTA,Kplus	; check - Key + pressed
		goto	inc_hrsd	; yes, go to increment routine
		btfss	PORTA,Kminus	; no, check - Key - pressed
		goto	dec_hrsd	; yes, go to decrement routine
		btfss	PORTA,TAK	; no, check - TAK key pressed
		return			; yes, return and go to next digit adjust routine
		goto	shsd_1		; no, reinitiate adjust loop

					; digit increment routine
inc_hrsd	call	delay
		CHKKU	Kplus		; wait key + release
		incf	hrsd_temp,1	; increment hour 2nd digit tmp variable
		movlw	0x03		; check whether overflowed maximum count
		xorwf	hrsd_temp,0
		btfsc	STATUS,Z
		clrf	hrsd_temp	; if yes, reset hour 2nd digit tmp variable
		goto	hsd_updt_dsp	; go to display update routine

					; digit decrement routine
dec_hrsd	call 	delay
		CHKKU	Kminus
		movf	hrsd_temp,1
		btfss	STATUS,Z	; check - value is ZERO
		goto	dec_hrsd_1	; no, proceed with decrement
		movlw	0x02		; yes, rst value to 2
		movwf	hrsd_temp
		goto	hsd_updt_dsp	; proceed	
dec_hrsd_1	decf	hrsd_temp,1	; decrement hour 2nd digit counter

hsd_updt_dsp	call	dupdt_hrsd	; update display
		goto	shsd_1		; reinitiate hour 2nd digit adjust loop

;**************************************************************************************************
					
set_hrfd
;**************************************************************************************************
;* This routine implements the hour 1st digit adjustment                                          *
;**************************************************************************************************

		call	delay
		CHKKU	TAK		; wait Tadj button released
		movlw	0xFC		
		andwf	hrfd_temp,0
		btfsc	STATUS,Z	; check - hour 1st digit >= 4
		goto	shfd_1		; no, proceed
		movlw	0x02		; yes, check - hour 2nd digit = 2
		xorwf	hrsd_temp,0
		btfsc	STATUS,Z
		clrf	hrfd_temp	; yes, rst hour 1st digit

shfd_1		call	dupdt_hrfd	; no, update display with hour 1st digit adjust pattern

					; initiate adjust
shfd_2		btfss	PORTA,Kplus	; check - Key + pressed
		goto	inc_hrfd	; yes, go to increment routine
		btfss	PORTA,Kminus	; no, check - Key - pressed
		goto	dec_hrfd	; yes, go to decrement routine
		btfss	PORTA,TAK	; no, check - TAK key pressed
		return			; yes, go to next digit adjust routine
		goto	shfd_2		; no, reinitiate adjust loop
		
					; digit increment routine
inc_hrfd	call	delay
		CHKKU	Kplus		; wait Key + release
		incf	hrfd_temp,1	; increment hour 1st digit tmp variable
		movlw	0x02		; check - hour 2nd digit = 2
		xorwf	hrsd_temp,0
		btfsc	STATUS,Z	
		goto	hrsd_equ_2	; yes, go to hrsd_equ_2
		movlw	0x0A		; no, check - value = 10
		xorwf	hrfd_temp,0
		btfsc	STATUS,Z
		clrf	hrfd_temp	; yes, rst value
		goto	inc_hrfd_1
hrsd_equ_2	movlw	0x04		; check - hour 1st digit = 4
		xorwf	hrfd_temp,0
		btfsc	STATUS,Z
		clrf	hrfd_temp	; yes, rst hour 1st digit
inc_hrfd_1	goto	hfd_updt_dsp	; if yes, go to display update routine

					; digit decrement routine
dec_hrfd	call	delay
		CHKKU	Kminus		; wait Key - release
		movf	hrfd_temp,1	; check - hour 1st digit value = 0
		btfss	STATUS,Z
		goto	dec_hrfd_1	; no, proceed to decrement operation
		movlw	0x02		; yes, check - hour 2nd digit = 2
		xorwf	hrsd_temp,0
		btfsc	STATUS,Z
		goto	hrsd_equ_2a	; yes, go to hrsd_equ_2a routine
		movlw	0x09		;
		movwf	hrfd_temp	; no, set value to 9
		goto	hfd_updt_dsp
hrsd_equ_2a	movlw	0x03	
		movwf	hrfd_temp	; set value to 3
		goto	hfd_updt_dsp
dec_hrfd_1	decf	hrfd_temp,1

hfd_updt_dsp	call	dupdt_hrfd
		goto	shfd_2		; reinitiate hour 1st digit adjust loop

;**************************************************************************************************
					
set_mnsd
;**************************************************************************************************
;* This routine implements the minute 2nd digit adjustment.                                       *
;**************************************************************************************************

		call	delay
		CHKKU	TAK		; wait Tadj key released
		call	dupdt_mnsd	; update display with min. 2nd digit adjustment pattern
					; initiate adjust
smsd_1		btfss	PORTA,Kplus	; check - Key + pressed
		goto	inc_mnsd	; yes, go to increment routine
		btfss	PORTA,Kminus	; no, check - Key - pressed
		goto	dec_mnsd	; yes, go to decrement routine
		btfss	PORTA,TAK	; no, check - TAK key pressed
		return			; yes, go to next digit adjust routine
		goto	smsd_1		; no, reinitiate adjust loop
		
					; digit increment routine
inc_mnsd	call	delay
		CHKKU	Kplus		; wait Key + release
		incf	mnsd_temp,1	; increment minute 2nd digit temp variable
		movlw	0x06		; check - overflowed maximum count
		xorwf	mnsd_temp,0
		btfsc	STATUS,Z
		clrf	mnsd_temp	; yes, reset value
		goto	msd_updt_dsp	; if yes, go to display update routine	

					; digit decrement routine
dec_mnsd	call	delay
		CHKKU	Kminus		; wait Key - release
		movf	mnsd_temp,1	; check whether digit count is ZERO
		btfss	STATUS,Z
		goto	dec_mnsd_1	; no, proceed with decrement
		movlw	0x05		; yes, reset value to 5
		movwf	mnsd_temp
		goto	msd_updt_dsp	; and proceed	
dec_mnsd_1	decf	mnsd_temp,1	; decrement minute 2nd digit counter
msd_updt_dsp	call	dupdt_mnsd
		goto	smsd_1		; reinitiate minute 2nd digit adjust loop

;**************************************************************************************************

set_mnfd
;**************************************************************************************************
;* This routine implements the minute 1st digit adjustment.                                       *
;**************************************************************************************************

		call	delay
		CHKKU	TAK		; wait Tadj button release
		call	dupdt_mnfd	; update display with min. 1st digit adjustment pattern
		
					; initiate adjust
					
mnfd_1		btfss	PORTA,Kplus	; check - Key + pressed
		goto	inc_mnfd	; yes, go to increment routine
		btfss	PORTA,Kminus	; no, check - Key - pressed
		goto	dec_mnfd	; yes, go to decrement routine
		btfss	PORTA,TAK	; no, check - TAK key pressed
		return			; yes, go to close routine
		goto	mnfd_1		; no, reinitiate adjust loop
		
					; digit increment routine
inc_mnfd	call delay
		CHKKU	Kplus		; wait Key + release
		incf	mnfd_temp,1	; increment min 1st digit temp variable
		movlw	0x0A		; check - overflowed maximum count
		xorwf	mnfd_temp,0
		btfsc	STATUS,Z
		clrf	mnfd_temp	; yes, reset value
		goto	mfd_updt_dsp	; if yes, go to display update routine
		
					; digit decrement routine
dec_mnfd	call delay
		CHKKU	Kminus		; wait Key - release
		movf	mnfd_temp,1	; check - min 1st digit temp variable is ZERO
		btfss	STATUS,Z
		goto	dec_mnfd_1	; no, proceed with decrement
		movlw	0x09		; yes, reset value to 9
		movwf	mnfd_temp
		goto	mfd_updt_dsp	; and proceed	
dec_mnfd_1	decf	mnfd_temp,1	; decrement minute 1st digit counter

mfd_updt_dsp	call	dupdt_mnfd
		goto	mnfd_1		; reinitiate minute 1st digit adjust loop

;**************************************************************************************************
dupdt_week
;**************************************************************************************************
;* This routine displays the current week day whenever the TAdj Key is pressed for a short period *
;* of time.                                                                                       *
;* It uses the convertion tables (conv_wd_d1 and conv_wd_d2) to determine the correct 7-segment   *
;* codes for the 1st and 2nd digits to be displayed                                               *
;* The 7-segment codes are loaded to the Display Register and its contents is displayed by the    *
;* Display_Update routine                                                                         *
;**************************************************************************************************

		movf	week_temp,0	; W contais current week day
		call	conv_wd_d2	; load W with 7-segment code for week day 2nd digit
		movwf	display		; 7-segment code loaded to display register
		call	display_update	; Update display
		movf	week_temp,0	; W contais current week day
		call	conv_wd_d1	; load W with 7-segment code for week day 1st digit
		movwf	display		; 7-segment code loaded to display register
		call	display_update	; Update display
		clrf	display		; Clear display register
		call	display_update	; Update display
		clrf	display		; Clear display register
		call	display_update	; Update display
		return

;**************************************************************************************************
					
dupdt_hrsd
;**************************************************************************************************
;* This routine updates the display during hour 2nd digit adjustment.                             *
;**************************************************************************************************

	 	clrf	display		; rst display register
		bcf		STATUS,C	; clear carry flag
		call	display_update	; send 0 for minute 1st digit
		call	display_update	; send 0 for minute 2nd digit
		call	display_update	; send 0 for hour 1st digit
		movf	hrsd_temp,0	; initiate conversion of hour 2nd digit to 7-segment
		call	convertion	; convert hex-code to 7-segment
		movwf	display		; load display register
		call	display_update	; send converted hour 2nd digit to display
		return

;**************************************************************************************************
					
dupdt_hrfd
;**************************************************************************************************
;* This routine updates the display during hour 1st digit adjustment.                             *
;**************************************************************************************************

		clrf	display		; rst display register
		bcf	STATUS,C	; rst carry flag
		call	display_update	; send 0 for minute 1st digit
		call	display_update	; send 0 for minute 2nd digit
		movf	hrfd_temp,0	; initiate conversion of hour 1st digit to 7-segment
		call	convertion	; convert hex-code to 7-segment
		movwf	display		; load display register
		call	display_update	; send converted hour 1st digit to display
		movf	hrsd_temp,0	; initiate conversion of hour 2nd digit to 7-segment
		call	convertion	; convert hex-code to 7-segment
		movwf	display		; load display register
		call	display_update	; send converted hour 2nd digit to display
		return
		
;**************************************************************************************************
					
dupdt_mnsd
;**************************************************************************************************
;* This routine updates the display during minute 2nd digit adjustment.                           *
;**************************************************************************************************

		clrf	display		; rst display register
		bcf	STATUS,C	; rst carry flag
		call	display_update	; send 0 for minute 1st digit
		movf	mnsd_temp,0	; initiate conversion of minute 2nd digit to 7-segment
		call	convertion	; convert hex-code to 7-segment
		movwf	display		; load display register
		call	display_update	; send converted minute 2nd digit to display
		movf	hrfd_temp,0	; initiate conversion of hour 1st digit to 7-segment
		call	convertion	; convert hex-code to 7-segment
		movwf	display		; load display register
		call	display_update	; send converted hour 1st digit to display
		movf	hrsd_temp,0	; initiate conversion of hour 2nd digit to 7-segment
		call	convertion	; convert hex-code to 7-segment
		movwf	display		; load display register
		call	display_update	; send converted hour 2nd digit to display
		return

;**************************************************************************************************
					
dupdt_mnfd
;**************************************************************************************************
;* This routine updates the display during minute 1st digit adjustment.                           *
;**************************************************************************************************

		movf	mnfd_temp,0	; initiate conversion of minute 1st digit to 7-segment
		call	convertion	; convert hex-code to 7-segment
		movwf	display		; load display register
		bcf	STATUS,C	; rst carry flag
		call	display_update	; send converted minute 1st digit to display
		movf	mnsd_temp,0	; initiate conversion of minute 2nd digit to 7-segment
		call	convertion	; convert hex-code to 7-segment
		movwf	display		; load display register
		call	display_update	; send converted minute 2nd digit to display
		movf	hrfd_temp,0	; initiate conversion of hour 1st digit to 7-segment
		call	convertion	; convert hex-code to 7-segment
		movwf	display		; load display register
		call	display_update	; send converted hour 1st digit to display
		movf	hrsd_temp,0	; initiate conversion of hour 2nd digit to 7-segment
		call	convertion	; convert hex-code to 7-segment
		movwf	display		; load display register
		call	display_update	; send converted hour 2nd digit to display
		return

;**************************************************************************************************

time_display
;**************************************************************************************************
;* This routine updates the display with the current time                                         *
;* It consists of a loop that reads each time register, converts its contents to 7-segment format *
;* and sends the converted data to the display.                                                   * 
;* It also checks the Master Alarm On/Off flag and will light the decimal point of the minute 1st *
;* digit display if the flag is set.                                                              *
;**************************************************************************************************

		bsf	PORTB,BIT3	; turn separator LEDs on
		bsf	PORTB,BIT4	; set shift registers MCLR pin to turn display on
		movlw	0x6A		; load W register with minute 1st digit counter address
		movwf	counter		; load counter with the same address
td_01		movlw	0x67		; load W register with hour 2nd digit counter address 
		xorwf	counter,0	; check - initiating convertion for hour 2nd digit
		btfsc	STATUS,Z
		goto	zero_hour_ver	; yes, go to routine section that verifies if hour = 0
begin_conv	movf	counter,0	; no, initiate loop to convert digit to 7-segment code
		movwf	FSR		; FSR contains the address to be fetched
		movf	INDF,0		; Value contained in the fetched address is loaded to W
		call	convertion	; convert HEX to 7-Segment format
		movwf	display		; load display with the converted value
		movlw	0x6A		; load W register with minute 1st digit counter address
		xorwf	counter,0	; check - digit to be converted is minute 1st digit
		btfsc	STATUS,Z
		goto	malf_set_ver	; yes, go to routine that verifies if Master Alarm On/Off
					; flag is set
dsp_updt	bcf	STATUS,C
		call	display_update	; no, call display update routine
		decf	counter,1	; decr counter to point to next digit
		movlw	0x66		; 
		xorwf	counter,0	; check - all digits converted and sent to display
		btfss	STATUS,Z
		goto	td_01		; no, restart process for next digit
		return			; yes, exit subroutine
zero_hour_ver	movf	hrsd_count,1	; check - hour 2nd digit equals ZERO
		btfsc	STATUS,Z
		goto	clr_display	; yes, skip 7-segment code convertion process
		goto	begin_conv	; no, goto 7-segment code convertion process
clr_display	clrf	display		; rst display register contents
		goto	dsp_updt	; proceed to display update
malf_set_ver	btfsc	alarm_ctrl,BIT1	; check - Master Alarm On/Off flag set
		bsf	display,BIT0	; yes, set BIT0 (decimal point) of display before sending
					; code to display
		goto	dsp_updt	; no, proceed to display update
;**************************************************************************************************

sndly_msg

;**************************************************************************************************
;* This routine sends the Snooze Delay setup message to the clock's display                       *
;**************************************************************************************************

		movwf	display		; W contains selected delay reference character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character - to display
		movlw	0x02		;
		movwf	display		; W contains - character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character - to display
		movlw	0x2A		;
		movwf	display		; W contains n character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character - to display
		movlw	0xB6		;
		movwf	display		; W contains S character (7-seg)
		bcf	STATUS,C	; clear carry flag to eliminate spurious data
		call	display_update	; Send character - to display
		call	delay		; allows time for user to check the setup
		call	delay		; allows time for user to check the setup
		call	delay		; allows time for user to check the setup
		return
;**************************************************************************************************
		END                     ; directive 'end of program'
		


