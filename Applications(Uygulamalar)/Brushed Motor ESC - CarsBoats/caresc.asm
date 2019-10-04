;
;
; Code for the 12F675 PIC to manage a reversible ESC for brushed motors.
; SCCS: @(#) caresc.asm 1.4@(#)

	processor	12F675
	radix		dec
	errorlevel	-302

;
; This module is configurable for a number of different combinations of
; facilities. Please note that the circuit used for each of the configurations
; is different. So pay attention to the diagram below.
;
; It is *your* responsibility to ensure that the configuration parameters set
; in the code below match your circuit.
;
; The options are:
;
;	Relay or HBRIDGE mode
;		Set HBRIDGE to 0 if a relay is used for reverse
;		Set HBRIDGE to 1 if a H-Bridge is used for reverse.
;		(Note: In H-Bridge mode LVC is not possible due to input pin restrictions.)
;
;	User configuration
;		Set USERCONFIG to 0 for a non runtime configurable ESC
;		Set USERCONFIG to 1 for 'push button' configuration at run time.
;		(Note: 'push button' configuration is not possible with either
;		Alternate LVC and Glitch reporting options.)
;
;	ESC without brake (use 'BRAKE equ 0")
;	ESC with brake (use 'BRAKE equ 1,2,3")
;		Set BRAKE to 1 for brake on at full braking power whenever brake selected
;		Set BRAKE to 2 for brake on, with smooth ramp on, whenever brake selected
;		Set BRAKE to 3 for brake proportional to throttle position
;
; 	Low Voltage Cutoff (set 'LOWVOLTS' in mV)
;		*NOTE* a LOWVOLTS of 0 will disable the Low Voltage Cutoff
;
;	Alternate Low Voltage Cutoff (set 'LOWVOLTSALT' in mV)
;		The alternate LVC is used when GP3 is connected to 0 volts
;		(ie. the jumper is installed)
;		*NOTE* a LOWVOLTSALT of 0 will disable the alternate LVC
;		in which case LOWVOLTS will apply in all situations.
;
;	Default throttle positions
;		Set PULSE_IDLE, PULSE_FWDMAX, PULSE_REVMAX as required.
;		If the programmable mode is enabled then these are just
;		the initial defaults.
;
;	Conversion to use for throttle -> PWM drive.
;		Set THROTTLEMAP to 1 for 50% throttle = 50% PWM rate
;		Set THROTTLEMAP to 2 for 50% throttle = 50% motor input power
;
;	Reverse mode
;		Set REVERSE to 0 for no reverse processing.
;		Set REVERSE to 1 for reverse processing.
;
;	Slow start
;		Set SLOWSTART to 0 for fast motor (and brake) speed increases
;		Set SLOWSTART to 1 for smooth increases in power (and brake) rather
;		than instant changes.
;
;	Delay on forward/reverse changeover
;		Set FWDREVDELAY to the number of 20msec periods that the ESC must not
;		apply motor drive after switching from forward to reverse.
;		Note: This option only applies to the relay version, the H-bridge
;		will switch between reverse and forward in about 20msec.
;
;	Delay from brake to reverse
;		Set BRAKETOREV to the number of 20msec periods that the ESC will
;		stay in active braking before switching to reverse. Note that if during
;		braking the ESC is returned to idle the ESC inhibits the switchover counter
;		and the brake to reverse switchover is delayed. Thus the ESC
;		requires BRAKETOREV counts with the brake actually active.
;
USERCONFIG	equ	1	; 0 for no user config, 1 for pushbutton config
HBRIDGE		equ	0	; 0 for relay solution, 1 for H-Bridge
SLOWSTART	equ	0	; 0 for fast start, 1 for slow
BRAKE		equ	2	; 0 for no brake, 1 for a on/off, 2 for on/off s/start, 3 for proportional
REVERSE		equ	1	; 0 for no reverse, 1 for reverse
LOWVOLTS	equ	0	; 6 Volt cutoff
LOWVOLTSALT	equ	0	; 9 Volt cutoff when GP3 configured
THROTTLEMAP	equ	2	; 0/1 is linear, 2 is power
GLITCHENB	equ	0	; 0 for no glitch counter, 1 for GP3 control
FWDREVDELAY	equ	25	; *20msec to obtain delay on fwd/rev changeover
; These are overridden in config mode (if enabled)
PULSE_IDLE	equ	1500	; Idle input (Msec)
PULSE_FWDMAX	equ	1800	; Max fwd input (Msec)
PULSE_REVMAX	equ	1200	; Max rev input (Msec)
DELAYBRAKETOREV	equ	4*50	; 4 seconds of brake to switch to reverse

;
; The reason the circuit is depends on the various options is that there
; are not quite enough pins on the 12F675 to do everything if you want a brake
; (or other output pin such as reverse or the LMA).
; The main problem arises because to do accurate PWM in software while reading
; an accurate value for the throttle pulse width requires the externally gated
; TIMER1 to be used, and the gate is active low - whereas the r/c control
; signal is active high. While it is possible to use the PICs comparitor to do
; the inversion this requires 2 pins. When you have a brake or other output
; there are not enough pins available.
;
; Assumes:
;	Bandgap		as calibrated at factory
;	CPD		disabled
;	CP		disabled
;	BODEN		enabled
;	MCLR		disabled
;	PWRTE		enabled
;	WDT (Watchdog)	enabled
;	OSC		internal RC (no clockout)
;
; The basic circuit for the ESC is as follows:
;
;
; power	-----------------------
;		  |           |
;       	-----------------
;		| + (1)	  (8) - |
;		|   PIC12F675  	|
;		|		|
; rx		|	(3) GP4	|-<-
; >--XXXX-------| GP1 (6)	|  | (active low rx pulse)
;    4k7	|	(5) GP2	|->-
;		|		|
;   sense  >----| GP? (?)	|
;		|	(2) GP5	| ----------> Motor On (active high)
;Brake off >----| GP3 (4)	|
;		|       (7) GP0 | ----------> Brake On (active high)
;		-----------------
;
;
; See the full circuit diagram for further details.
;
; Features of this software are as follows:
;
; Watchdog timer ensure the software is running, this is used to ensure
; 	that the software always gets back to the main sensing code. If
;	it doesn't the chip is reset.
;
; Timer 0 is used to measure the time for the PWM drive to the motor
;	and brake.
;
;	This timer runs at 1Mhz with a 1:2 prescaler. These interrupt,
;	together with the programable interrupt routine permits PWM
;	frequencies from 8kHz at minimum throttle down to 2kHz at full
;	throttle.
;
; Timer 1 is used to measure the input pulse width. Pulse width should be
;	1.5msec nominal at central position +/- 0.5msec depending on the
;	control direction.
;	
;	At 4Mhz clock timer 1 will run at 0.001msec count rate. This gives
;	count values for 1.5msec that are well within 16-bit resolution.
;
;
; The throttle can either be auto calibrating, or operate over a fixed range.
; The auto calibration assumes that the reverse range is the same as the
; forward throttle range. If this is not the case, say reverse has only 50% range,
; then the reverse throttle will only get to 50% power (and if the proportional brake
; is enabled it will only get to 50% braking).
;
; The auto throttle calibration assumes that the first receiver input it sees
; is throttle idle. The ESC then tracks the highest, stable, pulse seen and uses 
; this as the maximum forward throttle. When the throttle again returns to idle the
; ESC enters normal operation. A stable pulse is a sequence of 'autopulse'
; pulses that are within +/- autofuzz of the first pulse.
; 
; The LOS system is based on a software timer in the code that waits for
; valid throttle pulses. This timer is part of the various loops and so
; the exact LOS time varies depending on what arrives on the input line.
;
; The power up arming delay is 'armpulse' counts from powerup, and
; 'rearmpulse' after a LOS or power-fail detection.
;
; The low supply voltage is checked every time we receive a servo pulse.
; In theory we don't want to discharge cells below 0.9V/cell, also
; we want to ensure there is sufficient battery voltage to power the LDO
; regulator for a reasonable time. The ESC uses the A/D converter in the
; PIC to measure the battery supply voltage and averages this over 4 (2^lowvavgln2)
; samples (to stop a single 'spike' in current from turning the ESC off).
; When low battery voltage is detected this is treated as identical to
; LOS, this causes the motor to stop and wait for rearming.
;
;

#include <p12f675.inc>

	__CONFIG(_BODEN_ON & _MCLRE_OFF & _PWRTE_ON & _WDT_ON & _INTRC_OSC_NOCLKOUT)

; Main parameters
autopulse	equ	5		; Required number 'same value' to program
autofuzz	equ	3		; +/- autofuzz is the same value
armpulse	equ	20		; Required throttle off to arm at start
rearmpulse	equ	4		; Rearm count after LOS/low volts
downpulse	equ	10		; Throttle decrease requires this many pulses
uppulse		equ	10		; Throttle increase requires this many pulses
revpulse	equ	3		; Switch to reverse/brake requires this many pulses
losms		equ	100		; LOS if no signal in 100ms
lowvavgln2	equ	2		; ln2(number of low volts avg)
debounce	equ	5		; Debounce on config switch

; GPIO register bits and other constants
inrxbit		equ	4		; Active low rx input always on GP4


; If both a brake and low voltage cutout are required then
; the internal comparitor cannot be used as an inverter and a separate
; transistor received inverter is required. The options at this stage
; involving moving the pins around...
		if	LOWVOLTS > 0
voltsense	equ	0		; Main battery sense voltage GP0
		if	LOWVOLTSALT > 0
altlowvolts	equ	3		; GP3 low for alternate LVC point
		endif
		endif

		if	GLITCHENB
glitchrpt	equ	3		; GP3 low to triger glitch readout
		endif

		if	USERCONFIG
cfgswitch	equ	3		; GP3 is where the switch is
		endif

; How many output signals do we need?
outputcnt	= 0
		if	HBRIDGE
outputcnt	+= 2			; H-bridge always has two extra outputs
		else
		if	(BRAKE > 0) || (USERCONFIG > 0)
outputcnt	+= 1
		endif
		if	REVERSE > 0
outputcnt	+= 1
		endif
		endif

		if	(outputcnt == 0) || ((LOWVOLTS == 0) && (outputcnt <= 1))
; In this case we can use the internal comparitor as an inverter
; because there are enough pins available
comparitorinuse	equ	1		; Comparitor is in use
inrxraw		equ	1		; Active high receiver input
outrxinv	equ	2		; Active low receiver output (--> inrxbit)
motoron		equ	5		; Motor is always controlled by GP5
		if	BRAKE > 0
brakeon		equ	0		; brake FET control on GP0
		endif
		if	REVERSE > 0
reverseon	equ	0		; Reverse relay on GP0
		endif
		else
comparitorinuse	equ	0		; Comparitor is not in use
		if	USERCONFIG
cfgLED		equ	2		; GP2 is the LED (may be shared with brake)
		endif

		if	HBRIDGE
fwdPfet		equ	0		; Drive for forward P-Fet
revPfet		equ	2		; Drive for reverse P-Fet
fwdNfet		equ	1		; Drive for forward N-Fet
revNfet		equ	5		; Drive for reverse N-Fet
		else
motoron		equ	5		; Motor is always controlled by GP5
		if	BRAKE > 0
brakeon		equ	2		; brake FET control on GP2 if both in use
		endif
		if	REVERSE > 0
reverseon	equ	1		; reverse out on GP1
		endif
		endif
		endif

; RAM Definitions
	cblock	20h
w_save					; Int save: !! Both banks used !!
sts_save				;

escstatus				; Various status bits
rearmcnt				; Count for next arm operation
armcnt					; ESC arm counter
downcnt					; Throttle decrease filter counter
upcnt					; Throttle increase filter counter (!SLOWSTART)
revreqcnt				; Throttle reverse filter
brakecnt				; Brake -> reverse counter
usrthrottle				; User's selected throttle
pwmthrottle				; PWM engine throttle position
pwmmode					; PWM Interupt offset
pwmONio					; GPIO value during phase A (on)
pwmOFFio				; GPIO value during phase B (off)
pwmONt0					; TMR0 value during phase A (on)
pwmOFFt0				; TMR0 value during phase B (off)
newpwmON				; Next PWM 'ON' time
newpwmOFF				; Next PWM 'OFF' time

fwdperth				; Forward # of 0.001 counts per throttle step
fwdthbl					; Forward throttle base in counts (LSB)
fwdthbh					; Forward throttle base in counts (MSB)
fwdrevl					; Forward -> Reverse switching point
fwdrevh

revperth				; Reverse # of counts per throttle step
revthbl					; Reverse throttle base in counts (LSB)
revthbh					; Reverse throttle base in counts (MSB)
revfwdl					; Reverse -> Forward switching point
revfwdh

braketorev				; Switching time brake -> rev, 0 -> no reverse
	endc

; The ESC status
esc_LOS		equ	0		; LOS has been detected
esc_pwmOFF	equ	1		; ESC in in phaseB (off)
esc_revreq	equ	2		; Reverse requested
esc_rxglitch	equ	3		; Glitch detected during receive
esc_inreverse	equ	4		; In reverse throttle region (brake/reverse)
esc_cfgpressed	equ	5		; Config button pressed
esc_cfg_tmp	equ	6		; Previous state of the config switch
esc_noreverse	equ	7		; Don't select reverse

;
; Macros to manage the motor/brake control and output drive
	if	HBRIDGE
hfeton	macro	fixmask, pwmmask
	movlw	fixmask
	movwf	pwmOFFio
	if	pwmmask != 0
	iorlw	pwmmask
	endif
	movwf	pwmONio
	endm
pwmon	macro	mask
	endm
	else
hfeton	macro	fixmask, pwmmask
	endm
pwmon	macro	mask
	movfw	pwmOFFio
	if	mask != 0
	iorlw	mask
	endif
	movwf	pwmONio
	endm
	endif

alloff	macro
	pwmon	0			; Turn off all FETs
	hfeton	0,0
	movwf	GPIO			; and also IO port
	clrf	pwmONt0			; interrupt every 532usec
	clrf	pwmOFFt0		; interrupt every 532usec
	movlw	int_std - int_refpoint
	movwf	pwmmode			; Use the standard interrupt
	endm

; ----------------- PWM Computed Goto Code Page ------------------------
; All computed entry points MUST reside in this 256 byte page
; Put all the PWM engine into the low memory page so that we get as much spare
; program space as we can. Otherwise the user mode configuration code will not
; fit.
pwm_page
int_refpoint

;
; Reset vector
	org	0000h
	goto	start

; Provide a return instruction for software delay timing
emptyreturn
	return

; Interupt vector
	org	0004h
; Save the state (see page 64 of PIC12F675 data)
	movwf	w_save			; Save W register
	swapf	STATUS,W		; Save status (don't touch flags)
	bcf	STATUS,RP0		; Back to bank 0
	movwf	sts_save
	movfw	pwmmode			; Where do we go?
	movwf	PCL			; Go there...
; Note that this computed goto always ends up in the PWM page at the end
; of this software. Because computed goto's are done in both the interrupt
; code and the normal code PCLATH must remain constant.

; Include the appropriate interrupt routines and data lookups for the
; variable rate PWM. You can include one of the available PWM engines.
; Set THROTTLEMAP to the appropriate value.
	if	THROTTLEMAP <= 1
#include <linear.inc>
	endif
	if	THROTTLEMAP == 2
#include <power.inc>
	endif

; check that this entry point is 'within' the page
	if	(pwm_page >> 8) != ($ >> 8)
	fatal error PWM code too large
	endif

;
; Be careful with this code, the instruction cound has been
; carefully balanced to provide symetrical paths with GPIO
; updated at the same point in each flow.
int_std
	btfsc	escstatus,esc_pwmOFF	
	goto	in_pwmOFF
; We are currently in phaseA (on), so produce phaseB (off)
	bsf	escstatus,esc_pwmOFF
	movfw	pwmOFFio
	movwf	GPIO
	movfw	pwmOFFt0
	goto	rearm

in_pwmOFF
; We are currently in phaseB
	movfw	pwmONio
	movwf	GPIO
	movfw	pwmONt0
	bcf	escstatus,esc_pwmOFF
	nop
rearm
; Clear the timer interrupt, and reload counter
	movwf	TMR0
	bcf	INTCON, T0IF	

; All done, restore status
	swapf	sts_save,w
	movwf	STATUS
	swapf	w_save,f
	swapf	w_save,w
	retfie

rearm_ONt0
	movfw	pwmONt0
	goto	rearm
rearm_OFFt0
	movfw	pwmOFFt0
	goto	rearm

; ----------------- Maths library --------------------------------------
; Maths Library Data
	cblock
					; --- Input Parameters ---
math_al					; LSB of A register
math_ah					; MSB of A register
math_b					; The B register
math_rl					; LSB of result
math_rh					; MSB of result
					; --- Internal Temporary variables
math_bex				; Top 8 bits of B
math_ml					; Mask of where we are upto
math_mh			
	endc

; Compute A:16 / B:8 and put the result:16 into R, the
; remained is left in A
; This is unsigned division, anyone dividing by zero
; will put this into an infinite loop and the watchdog
; will operate...
math_a_div_b
; Initialise
	clrf	math_bex	; Top 8 bits of B
	clrf	math_ml		; Mask of where we are upto
	clrf	math_mh
	incf	math_ml,f	; Bottom bit
	clrf	math_rl		; Result
	clrf	math_rh
; Shift up and extend B to start division
div_s1
	bcf	STATUS,C	; setup for rotate
	rlf	math_b,f
	rlf	math_bex,f
	btfsc	STATUS,C	; All done?
	goto	div_s2		; yes
	rlf	math_ml,f
	rlf	math_mh,f
	goto	div_s1
div_s2
	rrf	math_bex,f
	rrf	math_b,f
; Do the division, see if the subtraction is possible
div_l1
	movfw	math_b
	subwf	math_al,f
	movfw	math_bex
	btfss	STATUS,C
	addlw	1
	subwf	math_ah,f
	btfss	STATUS,C	; compute A-B
	goto	div_l2		; Too big, can't count this
	movfw	math_ml
	iorwf	math_rl,f
	movfw	math_mh
	iorwf	math_rh,f	; Or on the mask
div_l3
	bcf	STATUS,C	; shift down the mask then B
	rrf	math_mh,f
	rrf	math_ml,f
	btfsc	STATUS,C
	return			; All done, result is set
	rrf	math_bex,f
	rrf	math_b,f
	goto	div_l1
div_l2
	movfw	math_b		; Add back what we subtracted
	addwf	math_al,f
	btfsc	STATUS,C
	incf	math_ah,f
	movfw	math_bex
	addwf	math_ah,f
	goto	div_l3

; Compute A:16 * B:8 and put the result:16 into R, the
; This is unsigned multiplication
math_a_mul_b
	clrf	math_rl
	clrf	math_rh
	movfw	math_b
	movwf	math_bex
mul_1
	btfss	math_bex,0	; Something to add?
	goto	mul_2
	movfw	math_al
	addwf	math_rl,f
	movfw	math_ah
	btfsc	STATUS,C
	addlw	1
	addwf	math_rh,f
mul_2
	bcf	STATUS,C
	rrf	math_bex,f
	movfw	math_bex
	btfsc	STATUS,Z
	return			; run out of things to multiply
	bcf	STATUS,C
	rlf	math_al,f
	rlf	math_ah,f
	goto	mul_1


; ------------------ Glitch reporting function ---------------------
;
; Beeps out on either the piezo, or motor, the glitch counter
	if	GLITCHENB

; Define some macros that manage the production of the glitch report codes
; Report using the motor as a buzzer
beep_s	macro
	call	sound_250
	endm		
beep_l	macro
	call	sound_250
	call	sound_250
	call	sound_250
	endm
delay_s	macro
	call	delay_250
	endm
delay_l	macro
	call	delay_250
	call	delay_250
	call	delay_250
	endm

	cblock
glitchcnt			; The number of glitches so far

beep10s				; The number of 10s to beep out
beep1s				; The number of 1s to beep out
beeptmp				; countdown as things are beeped out
	endc

glitchreport
; Stop the interrupts
	alloff
	bcf	INTCON,GIE

; The user has requested that we 'beep' out the glitch counter
	movfw	glitchcnt
	sublw	99		; > 99 is too big...
	btfss	STATUS,C
	goto	beeptoobig

; How many 10's
	clrf	beep10s
	movfw	glitchcnt
count10s
	addlw	-10
	btfss	STATUS,C
	goto	got10s
	incf	beep10s,F
	goto	count10s
got10s
; The rest are ones
	addlw	10
	movwf	beep1s
	movfw	beep10s
	btfsc	STATUS,Z
	goto	no10s
	call	beepdigit
	delay_l
no10s
	movfw	beep1s
	call	beepdigit
	delay_s
	goto	endreport

beepdigit
	movwf	beeptmp
	iorlw	0			; check for zero
	btfsc	STATUS,Z
	goto	beepzero
beepdlp
	beep_s
	decfsz	beeptmp,F
	goto	beepdlp1
	return
beepdlp1
	delay_s
	goto	beepdlp
beepzero
	beep_l
	return

beeptoobig
	beep_l
	delay_s
	beep_l
	delay_s
	goto	endreport

endreport
	bsf	INTCON,GIE
	goto	offreset


; This is the code used to produce noises via the motor
; Local storage
	cblock
delaycnt1				; Delay counters
delaycnt2	
	endc
;
; Sound 800hz via the motor for 250msec
sound_250
	movlw	200
	movwf	delaycnt1
s250_1
	movlw	1<<motoron
	movwf	GPIO
	call	emptyreturn
	call	emptyreturn
	call	emptyreturn
	call	emptyreturn
	clrf	GPIO
	call	delay_800hz
	decfsz	delaycnt1,f
	goto	s250_1
	return

;
; Delay for 250msec
delay_250
	movlw	200
	movwf	delaycnt1
d250_1
	call	delay_800hz
	decfsz	delaycnt1,f
	goto	d250_1
	return

; Delay one cycle of 800hz
delay_800hz
	clrwdt			; Tell watchdog we are active
	movlw	50
	movwf	delaycnt2
d800_1
	call	emptyreturn
	decfsz	delaycnt2,f
	goto	d800_1
	return
	endif

; ----------------- PWM Table Lookup -----------------------------------
g_pwmmode
	addlw	pwmtype_tbl - int_refpoint
	movwf	PCL			; Off to the table lookup
g_pwmONt0
	addlw	pwmONt0_tbl - int_refpoint
	movwf	PCL			; Off to the table lookup
g_pwmOFFt0
	addlw	pwmOFFt0_tbl - int_refpoint
	movwf	PCL			; Off to the table lookup


; -------------------------- Main ESC code ----------------------
;
; The default throttle information
;
;      rzerobase     fzerobase
;              |     |
; .............^  |  ^_~__~__~__~___~__~__~__~__~__~__~__^  |
;                 |                                         |
;           PULSE_IDLE                                 PULSE_FWDMAX

	constant	fcounts = (PULSE_FWDMAX-PULSE_IDLE) / (throttlesteps-throttlecalidle)
	constant	fexcess = (PULSE_FWDMAX-PULSE_IDLE) - (fcounts * (throttlesteps-throttlecalidle))
	constant	fzerobase = PULSE_IDLE + fexcess/2
	constant	rcounts = (PULSE_IDLE-PULSE_REVMAX) / (throttlesteps-throttlecalidle)
	constant	rexcess = (PULSE_IDLE-PULSE_REVMAX) - (rcounts * (throttlesteps-throttlecalidle))
	constant	rzerobase = PULSE_IDLE - rexcess/2

;
; Chip reset, or similar, operation.
start
; Calibrate the internal oscilator
	bsf	STATUS,RP0
	call	3FFh
	movwf	OSCCAL
	bcf	STATUS,RP0

; Initialise PCLATH. WARNING: don't touch this register....
	movlw	int_refpoint >> 8
	movwf	PCLATH

; Default to all outputs driven low when enabled
	clrf	GPIO

; Configure the weak pullups, and analog input bits, and the comparator that
; is used as an inverter, so that the control signal can control TMR1
	if	comparitorinuse
	bsf	STATUS,RP0
	movlw	10101000b
	movwf	VRCON		; Select a 1/3 supply rail reference point
	bcf	STATUS,RP0
	movlw	00000011b	; Comparitor with internal reference
	movwf	CMCON
	endif
	bsf	STATUS,RP0
	movlw	01010000b	; 16Tosc for A/D conversion
	if	comparitorinuse
	iorlw	1<<inrxraw
	endif
	if	LOWVOLTS > 0
	iorlw	1<<voltsense
	endif
	movwf	ANSEL		; All inputs, except comparator & AtoD, are digital
	movlw	(1<<inrxbit)	; Pullup on digital inputs
	movwf	WPU
	movlw	00000000b	; Enable pullups, timer0 clk/4 with 1:2 prescale
	movwf	OPTION_REG
	if	HBRIDGE
	movlw	~((1<<fwdPfet)|(1<<fwdNfet)|(1<<revPfet)|(1<<revNfet))
	else
	movlw	~(1<<motoron)
	if	BRAKE > 0
	andlw	~(1<<brakeon)
	endif
	if	REVERSE > 0
	andlw	~(1<<reverseon)
	endif
	endif
	if	comparitorinuse
	andlw	~(1<<outrxinv)
	endif
	if	USERCONFIG > 0
	andlw	~(1<<cfgLED)
	endif
	movwf	TRISIO		; Enable outputs as required
	bcf	STATUS,RP0

; Configure Timer 0 for interrupts
	movlw	-1		; Force an immediate timer interrupt
	movwf	TMR0
	bsf	INTCON,T0IE	; enable interrupts (immediate)

; Enable the A/D for low voltage detection
	if	LOWVOLTS > 0
	movlw	00000001b | (voltsense << 2)
	movwf	ADCON0		; Enable the A/D converter
	endif
	
; Initialise RAM, start with all zeros in bank 0
	movlw	0x20
	movwf	FSR
clrlp
	clrf	INDF
	incf	FSR,F
	btfss	FSR,7
	goto	clrlp

; Then the special values
	movlw	armpulse
	movwf	rearmcnt

; Initialise PWM engine
	alloff

	if	LOWVOLTS > 0
; Initialise the low voltage averaging
	variable i
i 	= 0
	movlw	0FFh
	while i < (1<<lowvavgln2)
	movwf	lowvoltavg+i
i 	+= 1
	endw
	endif

; Allow the interrupts to start
	bsf	INTCON,GIE


; There are 2 cases here, either a fixed endpoint ESC, or a user configurable
; version.
	if	!USERCONFIG
; This is the fixed endpoint version no need for EEPROM
	movlw	fcounts
	movwf	fwdperth			; The width of each throttle step
	movlw	low fzerobase
	movwf	fwdthbl
	movlw	high fzerobase
	movwf	fwdthbh				; Base of throttle range

	movlw	rcounts
	movwf	revperth
	movlw	low rzerobase
	movwf	revthbl
	movlw	high rzerobase
	movwf	revthbh				; Base of throttle range

	movlw	DELAYBRAKETOREV
	movwf	braketorev

	else
	goto	initial_start
; User requested configuration
configure
	call	initthrottle
	call	userconfig
	clrf	pwmOFFio		; Ensure config LED is off
	clrf	pwmONio
initial_start
; Just restore all the data from the EEPROM
	call	restore
; Initialise for configuration
	call	cfgcheckinit
	endif

; Don't allow division by zero
	movf	fwdperth,F
	btfsc	STATUS,Z
	incf	fwdperth,F
	movf	revperth,F
	btfsc	STATUS,Z
	incf	revperth,F

; Now calculate the 'reversing' points:
; fwdrev:16 = fzerobase:16 - rzerobase:16 + rcounts
; revrev:16 = fzerobase:16 - rzerobase:16 + fcounts
	movfw	fwdthbl		; Copy fzerobase into fwdrev:16
	movwf	fwdrevl
	movfw	fwdthbh
	movwf	fwdrevh
	movfw	revthbl		; Subtract rzerobase and put into fwdrev:16 and revfwd:16
	subwf	fwdrevl,W
	movwf	fwdrevl
	movwf	revfwdl
	movfw	revthbh
	btfss	STATUS,C
	addlw	1
	subwf	fwdrevh,W	; Difference...
	movwf	fwdrevh
	movwf	revfwdh
	movfw	revperth	; Add the rcounts
	addwf	fwdrevl,F
	btfsc	STATUS,C
	incf	fwdrevh,F
	movfw	fwdperth	; Add the fcounts
	addwf	revfwdl,F
	btfsc	STATUS,C
	incf	revfwdh,F

; Do we support reverse?
	bcf	escstatus, esc_noreverse
	movf	braketorev,F
	btfsc	STATUS,Z
	bsf	escstatus, esc_noreverse	

; Turn off all the drivers and wait for arming
offreset
	call	initthrottle
	call	notrev

; Initialise for arming state
resettoarm
	movfw	rearmcnt
	movwf	armcnt

; Wait for valid arming state
waitforarm
	call	getthrottle
	btfsc	escstatus, esc_LOS
	goto	resettoarm			; Signal has gone away again...
	if	USERCONFIG
	btfsc	escstatus, esc_cfgpressed
	goto	configure
	endif
	btfsc	escstatus, esc_revreq
	goto	resettoarm			; Signal too far below zero...
	call	g_pwmmode			; Convert to a PWM mode
	addlw	-(int_0on-int_refpoint)		; check for idle position
	btfsc	STATUS,Z
	goto	waitiszero			; Throttle is idle
	addlw	-(int_0brake - int_0on)		; check for brake position
	btfss	STATUS,Z
	goto	resettoarm			; Throttle not idle/brake
waitiszero
	decfsz	armcnt,F
	goto	waitforarm

; Arming period has expired, adjust the rearm timer for next time
	movlw	rearmpulse
	movwf	rearmcnt

usemotorfwd
	call	initthrottle
	if	!HBRIDGE
	btfsc	pwmOFFio, reverseon
	call	togglerev	; Force the reverse output off
	endif
	pwmon	1<<motoron	; Drive the motor instead of the brake
	hfeton	1<<fwdPfet, 1<<fwdNfet

; Use the 'forward' throttle range
	bcf	escstatus, esc_inreverse
	call	notrev

; all OK now so perform the processing...
runningfwd
	if	GLITCHENB
	btfss	GPIO, glitchrpt
	goto	glitchreport
	endif
	call	getthrottle
	btfsc	escstatus, esc_LOS
	goto	offreset		; Signal lost - turn off
	if	USERCONFIG
	btfsc	escstatus, esc_cfgpressed
	goto	configure
	endif
	btfsc	escstatus, esc_revreq
	goto	usemotorbrake		; User has selected braking/reverse
; Update user'sPWM for throttle and then the PWM
	call	adjthrottle
	call	updatepwm_usr
	goto	runningfwd

; Reverse has been requested. This involves possibly braking for a while, or just going
; straight to reverse
usemotorbrake
; Switch to the 'reverse' throttle range
	bsf	escstatus, esc_inreverse
	call	notrev

	if	BRAKE != 0
; The throttle is now at 'brake', and has been for the last 20ms or so
; start the brake...
	call	initthrottle

	pwmon	1<<brakeon		; Drive the brake instead of the motor
	hfeton	1<<fwdNfet, 1<<revNfet	; Optimise for brake in fwd dir - recharge battery

; Initialse the brake counter, brake for too long forces reverse
	movfw	braketorev
	movwf	brakecnt

; Now perform braking...
runningbrk
	if	GLITCHENB
	btfss	GPIO, glitchrpt
	goto	glitchreport
	endif
	call	getthrottle
	btfsc	escstatus, esc_LOS
	goto	offreset			; lost signal, drop brake and reset
	if	USERCONFIG
	btfsc	escstatus, esc_cfgpressed
	goto	configure
	endif
	btfsc	escstatus, esc_revreq
	goto	usemotorfwd			; User has selected forward drive
	if	REVERSE
; Time to switch to reverse?
	btfsc	escstatus, esc_noreverse
	goto	stay_in_brake			; Ignore, we just stay in brake mode
	decf	brakecnt,F
	btfsc	STATUS,Z
	goto	usemotorrev
stay_in_brake
	endif
; Track the user's throttle position
	call	adjthrottle
; Then what?
	if	BRAKE < 3			; Brake is on/off only
	movfw	usrthrottle
	call	g_pwmmode
	addlw	-(int_0on-int_refpoint)
	btfsc	STATUS,Z
	goto	brakeidle			; Brake should be disabled
	addlw	-(int_0brake - int_0on)
	btfsc	STATUS,Z
	goto	brakeidle			; Brake should be disabled
; Brake should be on - but exactly how?
	movlw	throttlesteps-1			; Assume maximum braking throttle
	if	BRAKE == 2
	xorwf	pwmthrottle,W			; Apply slow start rule
	btfsc	STATUS,Z
	goto	runningbrk
	incf	pwmthrottle,W
	endif	
	call	updatepwm_a
	goto	runningbrk

brakeidle
	incf	brakecnt,F			; Don't count this as part of the reverse...
	movlw	throttlenonidle-1		; an idle position
	call	updatepwm_a
	goto	runningbrk
	else					; Proportional brake
	call	updatepwm_usr
	movfw	pwmmode
	addlw	-(int_0on-int_refpoint)
	btfsc	STATUS,Z
	goto	brakeidle			; Brake is disabled
	addlw	-(int_0brake - int_0on)
	btfss	STATUS,Z
	goto	runningbrk			; Brake is not disabled
brakeidle
	incf	brakecnt,F			; Don't count this as part of the reverse...
	goto	runningbrk
	endif
	endif

; Reverse should now be active.
usemotorrev
	if	REVERSE
	call	initthrottle
	if	!HBRIDGE
	btfss	pwmOFFio, reverseon
	call	togglerev	; Force the reverse output on
	endif
	pwmon	1<<motoron	; Drive the motor (in reverse)
	hfeton	1<<revPfet, 1<<revNfet

; all OK now so perform the processing...
runningrev
	if	GLITCHENB
	btfss	GPIO, glitchrpt
	goto	glitchreport
	endif
	call	getthrottle
	btfsc	escstatus, esc_LOS
	goto	offreset		; Signal lost - turn off
	if	USERCONFIG
	btfsc	escstatus, esc_cfgpressed
	goto	configure
	endif
	btfsc	escstatus, esc_revreq
	goto	usemotorfwd		; User has selected forward drive
; Update PWM for throttle, use slow accelerate and immediate reduction,
; although reduction is conditioned by a test to remove single pulse 'blips'
; of reduced throttle
	call	adjthrottle
	call	updatepwm_usr
	goto	runningrev
	else
; If there is no reverse mode just go forward...
	goto	usemotorfwd
	endif

	if	!HBRIDGE
; Toggle the reverse output. For relay systems a delay is required to give the relay
; time to settle.
togglerev
	movlw	1<<reverseon
	xorwf	pwmOFFio, F		; Update the output signals
	xorwf	pwmONio, F		; for the reverse status signal

	if	FWDREVDELAY > 0
	cblock
relaycnt
	endc
	movlw	FWDREVDELAY
	movwf	relaycnt
waitforrelay
	call	getthrottle
	decfsz	relaycnt,F
	goto	waitforrelay
	endif
	return
	endif
; Start again at a new throttle position
initthrottle
	if	!SLOWSTART
	movlw	-uppulse		; configure for filtering upward change
	movwf	upcnt
	endif
	clrf	downcnt			; downward is OK

	pwmon	0			; Turn off all FETs in interrupt code
	hfeton	0,0
	movwf	GPIO			; Force FETs off anyway (brake -> motor switch)
	movlw	throttlenonidle-1
	movwf	usrthrottle		; Set throttle to highest 'off' setting
	goto	updatepwm_frc		; And set the PWM system

;
; Process the throttle position in A and adjsut the throttle variable taking into
; account slow start etc. Use slow accelerate and immediate reduction,
; although reduction is conditioned by a test to remove single pulse 'blips'
; of reduced throttle
adjthrottle
	subwf	usrthrottle,W
	btfsc	STATUS,Z
	return				; There is no change in throttle
	btfsc	STATUS,C
	goto	slowdown
; Apply the slow start rule if that is required
	if	SLOWSTART
	incf	usrthrottle,F		; perform slow start
	else
	btfss	upcnt,7			; if upcnt >= 0 we are OK to increase
	goto	speedup
	incfsz	upcnt,F
	return				; No change yet
speedup
	subwf	usrthrottle,F		; perform immediate throttle change
	endif
	movlw	-downpulse
	movwf	downcnt
	return				; all done
slowdown
	btfss	downcnt,7		; if downcnt >= 0 we are OK to decrease
	goto	doslow
	incfsz	downcnt,F
	return				; decrease fltering causes delay
doslow
	subwf	usrthrottle,F		; immediate drop in power level
	if	!SLOWSTART
	movlw	-uppulse		; configure for filtering upward change
	movwf	upcnt
	endif
	return

;
; Update the PWM with the throttle setting, this code attempts to minimise the
; time that TMR0 is disabled. Currently this is 6uS, with any luck this is
; not going to disturb the PWM too much.
updatepwm_usr
	movfw	usrthrottle
updatepwm_a
	xorwf	pwmthrottle,W
	btfsc	STATUS,Z
	return				; No change so don't disturb PWM
	xorwf	pwmthrottle,W
updatepwm_frc
	movwf	pwmthrottle
	call	g_pwmONt0	; Locate the ON time
	movwf	newpwmON
	movfw	pwmthrottle
	call	g_pwmOFFt0	; And the OFF time
	movwf	newpwmOFF
	movfw	pwmthrottle
	call	g_pwmmode	; And the PWM mode
	
	bcf	INTCON, T0IE
	movwf	pwmmode
	movfw	newpwmON
	movwf	pwmONt0
	movfw	newpwmOFF
	movwf	pwmOFFt0
	bsf	INTCON, T0IE

	return

	if	USERCONFIG
; Process receiver pulses until we see a 'stable' value for the required
; programming time.
; This main complete due to loss of signal, or low voltage...
;
; Local data storage for stable pulse detection
	cblock
stablecnt				; How many times we have seen this reading
stablel					; Value we keep on seeing
stableh			
	endc

getstablepulse
	call	cfgflash		; Do whatever on the config LED
	call	cfgcheckswitch
	call	getrxpulse
	btfsc	escstatus, esc_LOS
	goto	getstablepulse		; Just keep looking during LOS
; See if this can be made stable
	movlw	autopulse
	movwf	stablecnt
	movfw	TMR1L
	movwf	stablel
	movfw	TMR1H
	movwf	stableh
; Lets have a look...
stable_lp
	call	cfgflash
	call	getrxpulse
	btfsc	escstatus, esc_LOS
	goto	getstablepulse		; just keep going on LOS
	movfw	stablel
	addlw	-autofuzz
	movwf	math_al
	movfw	stableh
	btfss	STATUS,C
	addlw	-1
	movwf	math_ah			; math_a:16 is the minimum stable value
	movfw	math_al
	subwf	TMR1L,W
	movwf	math_al
	movfw	math_ah
	btfss	STATUS,C
	addlw	1
	subwf	TMR1H,W
	movwf	math_ah
	btfss	STATUS,Z
	goto	getstablepulse		; Too far from the last pulse...
	movlw	2*autofuzz+1
	subwf	math_al,W
	btfsc	STATUS,C
	goto	getstablepulse		; Too big a difference
	decfsz	stablecnt,f
	goto	stable_lp		; Wait for enough that are the same
	return
	endif

;
; This subroutine returns when a valid RX throttle is seen (or on LOS)
; The return value in the W register is the throttle
; setting (0..throttlesteps-1).
; Note caller must check the sts_validrx prior to proceeding, valid signal
; may have stopped.
getthrottle
	if	USERCONFIG
	call	cfgcheckswitch
	endif
	call	getrxpulse
	if	GLITCHENB
	btfss	escstatus, esc_rxglitch
	goto	noglitch
	incf	glitchcnt,F		; Count the glitchs, don't wrap to 0
	btfsc	STATUS,Z
	decf	glitchcnt,F
noglitch
	endif
	btfsc	escstatus, esc_LOS
	retlw	0			; Bail out - LOS
;
; Now we have a value between 0300h (0.768msec) and 09ffh (2.559msec)
; What we want to do is convert this into a throttle number.
;
; This is done by subtracting the base (numbers less than the base are 0)
; and then dividing by the count per throttle position. Finally limiting
; to the throttle position.
;
;
; Are we using the 'reverse' throttle region?
	btfsc	escstatus, esc_inreverse
	goto	reversecalc

forwardcalc
; Collect the timer info
	movfw	TMR1L
	movwf	math_al
	movfw	TMR1H
	movwf	math_ah
; Start the conversion into a throttle seting subtract the base value
	movfw	fwdthbl
	subwf	math_al,F
	movfw	fwdthbh
	btfss	STATUS,C
	addlw	1
	subwf	math_ah,F
	btfss	STATUS,C
	goto	isfwdthrev	; Below the base value so definitely 0 throttle (reverse?)
	movfw	fwdperth
	goto	throttle_div_limit	; Complete the calculation
; Check to see if the throttle is below the reverse point
isfwdthrev
	movfw	fwdrevl
	addwf	math_al,W
	movfw	fwdrevh
	btfsc	STATUS,C
	addlw	1
	addwf	math_ah,W
	btfsc	STATUS,C
	goto	notrev
	decfsz	revreqcnt,F
	retlw	0			; Still waiting for enough requests
	incf	revreqcnt,F		; ensure this will work next time as well...
	bsf	escstatus,esc_revreq
	retlw	0			; reverse has been requested
	goto	notrev

reversecalc
; Start the conversion into a throttle seting subtract the base value
	movfw	revthbl
	movwf	math_al
	movfw	revthbh
	movwf	math_ah

	movfw	TMR1L
	subwf	math_al,F
	movfw	TMR1H
	btfss	STATUS,C
	addlw	1
	subwf	math_ah,F
	btfss	STATUS,C
	goto	isrevthfwd	; Below the base value so definitely 0 throttle (reverse?)
	movfw	revperth

throttle_div_limit
; Now we need to divide by the count per throttle position
	movwf	math_b
	call	math_a_div_b	; compute A /= B
; Reverse is not requested, reset the reverse filter
	bcf	escstatus,esc_revreq
	movlw	revpulse
	movwf	revreqcnt
; Limit to the maximum throttle value
	movf	math_rh,F
	btfss	STATUS,Z
	retlw	throttlesteps-1	; throttle > 255 so must be at max
	movlw	throttlesteps
	subwf	math_rl,W
	btfsc	STATUS,C
	retlw	throttlesteps-1	; throttle >= throttle steps so must be max
; Between 0 and throttlesteps-1 so just return it
	movfw	math_rl
	return
; Check to see if the throttle is below the reverse point
isrevthfwd
	movfw	revfwdl
	addwf	math_al,W
	movfw	revfwdh
	btfsc	STATUS,C
	addlw	1
	addwf	math_ah,W
	btfsc	STATUS,C
	goto	notrev
	decfsz	revreqcnt,F
	retlw	0			; Still waiting for enough requests
	incf	revreqcnt,F		; ensure this will work next time as well...
	bsf	escstatus,esc_revreq
	retlw	0			; reverse has been requested
; Clear reverse request
notrev
	bcf	escstatus,esc_revreq
	movlw	revpulse
	movwf	revreqcnt
	retlw	0		; Definitely zero throttle, LMA not requested

;
; This subrouting returns when a valid RX pulse is seen.
; The return value is in the TMR1 registers....
; Note caller must check the sts_validrx prior to proceeding, valid signal
; may have stopped, or low voltage has occured - low voltage is treated
; as loss of signal for the purposes of this code.
; Return value is between 0300h (0.768msec) and 09ffh (2.559msec) and
; represents a 'valid' sort of pulse.
;
; Local data
	cblock
loscntL					; LOS counter low
loscntH					; LOS counter high
	endc

getrxpulse
; Arm the LOS information and glitch flag
	bcf	escstatus, esc_rxglitch
	bcf	escstatus, esc_LOS
	movlw	(losms * (1000/12+1)) & 0FFh
	movwf	loscntL
	movlw	((losms * (1000/12+1)) >> 8) + 1
	movwf	loscntH
pulselp
; Rearm the R/C pulse counter
	clrf	TMR1L		; start at 0
	clrf	TMR1H
; Enable Timer 1 for pulse width counting
	movlw	01000001b	; Enable
	movwf	T1CON

; While there is nothing to do just stay here and check for LOS ....
whileoff
	call	checklos
	btfsc	escstatus,esc_LOS
	retlw	0
	movfw	TMR1L
	iorwf	TMR1H,W		; Anything on the counter?
	btfsc	STATUS,Z
	goto	whileoff
; Trigger a A/D voltage check on the lowvolts signal when we see the start
; of a receiver pulse
	if	LOWVOLTS > 0
	movlw	00000011b | (voltsense << 2)
	movwf	ADCON0		; Commence operation of the A/D
	endif
; Now wait for the pulse to end
whileon
	call	checklos
	btfsc	escstatus,esc_LOS
	retlw	0
	movlw	9		; If counter >= 2.303 msec signal pulse is faulty
	subwf	TMR1H,W
	btfsc	STATUS,C
	goto	toolong
	btfss	GPIO,inrxbit
	goto	whileon

; Stop timer so we can convert things
	clrf	T1CON

; Check the A/D for low voltage...
	if	LOWVOLTS > 0
	btfsc	ADCON0,1
	goto	itislos		; No A/D completion, stop motor...
; Perform averaging if required, else just get the AD value
	if	lowvavgln2 > 0
	call	checklowv
	else
	movfw	ADRESH
	endif
; Now consider the voltage...
	if	LOWVOLTSALT > 0
	btfsc	GPIO,altlowvolts
	goto	lowvnormal
	sublw	(LOWVOLTSALT * 10 / (10+27)) / (1000/(255/5))
	goto	lowvtest
lowvnormal
	endif
	sublw	(LOWVOLTS * 10 / (10+27)) / (1000/(255/5)) 
lowvtest
	btfsc	STATUS,C
	goto	itislos		; Low voltage...
	endif

; Now the pulse has ended and we are ready to consider the outcome of this...
; First drop pulses that are too small to be valid, these must be an error...
	movlw	3
	subwf	TMR1H,W
	btfss	STATUS,C
	goto	hadglitch		; < 0.768msec
	return

; A pulse > 2.560msec is present, wait for it to end and ignore it
toolong
	call	checklos
	btfsc	escstatus,esc_LOS
	retlw	0
	btfss	GPIO,inrxbit
	goto	toolong
hadglitch
	bsf	escstatus, esc_rxglitch
	goto	pulselp

; Watch for LOS, this routine is called about once every 12 cycles,
; or every 0.012msec and if 80msec expires then LOS is detected
; this requires a count of ~8000/12...
;
; Similarly the watchdog is cleared so that if the PIC doesn't get back to
; processing the next receiver pulse in 18msec the chip resets...
; 
checklos
	clrwdt				; track software is working...
	decfsz	loscntL,F
	return
	decfsz	loscntH,F
	return
	bsf	escstatus,esc_rxglitch
itislos
	bsf	escstatus,esc_LOS	; Flag LOS	
	return	
;
; If low voltage averaging is active then compute and return the average
	if (LOWVOLTS > 0) && (lowvavgln2 > 0)
	cblock
lvt_l					; Low Voltage Total LSB
lvt_h					; Low Voltage Total MSB
lowvoltavg:1<<lowvavgln2		; Last N low volt readings
	endc

checklowv
; Shift down the averaging registers
i 	= (1<<lowvavgln2)-1
	while i >= 1
	movfw	lowvoltavg+i-1
	movwf	lowvoltavg+i
i 	-= 1
	endw
; Grab the current A/D value and put it the the most recent slot
	movfw	ADRESH
	movwf	lowvoltavg
; Add up all the values to form a total
	movwf	lvt_l
	clrf	lvt_h
i	= 1
	while i < (1<<lowvavgln2)
	movfw	lowvoltavg+i
	addwf	lvt_l,F
	btfsc	STATUS,C
	incf	lvt_h,F
i	+= 1
	endw
; Then average them
i	= 0
	while i < lowvavgln2
	rrf	lvt_h,F
	rrf	lvt_l,F
i	+= 1
	endw
	movfw	lvt_l
	return
	endif


; -------------------------- User Config code ----------------------
;
; This needs to be the last code in the file because it redefines the
; cblock base to 0 for EEPROM config	

	if	USERCONFIG
;
; Config system data
	cblock
cfgdebounce		; Debounce counter for the config switch

cfgledoncnt		; How the LED flashing should work...
cfgledoffcnt
cfgledcnt

cfgbrakerev		; Counter for # of cycles

cfgidlel		; Idle pulse seen
cfgidleh

cfgtmpl			; Last stable value used for calibration
cfgtmph

	endc

; Inititialise the values in the EEPROM when we program...
eei_16bit	macro	eep, val
	org	2100h+eep
	de	low (val)
	de	high (val)
	endm

eei_8bit	macro	eep, val
	org	2100h+eep
	de	val
	endm

; Read the 16 bit value
eer_16bit	macro	rom, ram
	movlw	rom
	call	read_ee8
	movwf	ram
	movlw	rom+1
	call	read_ee8
	movwf	ram+1
	endm

; Read the 8 bit value
eer_8bit	macro	rom, ram
	movlw	rom
	call	read_ee8
	movwf	ram
	endm

; Write the 16 bit value
eew_16bit macro	rom, ram
	movlw	rom
	call	write_eepa
	movfw	ram
	call	write_eepd
	movlw	rom+1
	call	write_eepa
	movfw	ram+1
	call	write_eepd
	endm

; Write the 8 bit value
eew_8bit macro	rom, ram
	movlw	rom
	call	write_eepa
	movfw	ram
	call	write_eepd
	endm

; Read an 8-bit value...
; W is the eeprom offset, return value is also in W
read_ee8
	banksel	EEADR
	movwf	EEADR
	bsf	EECON1,RD
	movfw	EEDATA
	banksel	w_save
	return


; Select the EEPROM address we are going to write to
; W is the address
write_eepa
	banksel	EEADR
	bsf	EECON1,WREN
	movwf	EEADR
	banksel	w_save
	return

; Write the contents of W to the EEPROM,
write_eepd
	bcf	INTCON,GIE
	banksel EEDATA
        movwf   EEDATA
        movlw   55h
        movwf   EECON2
        movlw   0AAh
        movwf   EECON2
        bsf     EECON1,WR
        banksel PIR1
eepwlp
        clrwdt
        btfss   PIR1,EEIF
        goto    eepwlp
        bcf     PIR1,EEIF
        banksel EEDATA
	bcf	EECON1,WREN
        banksel w_save
	bsf	INTCON,GIE
        return

; Restore the saved values from the EEPROM
; This should really check the error status of the data
; however there is not enough code space in the PIC to use
; the error check EEPROM library.
restore
	eer_8bit	eep_fwdperth, fwdperth
	eer_16bit	eep_fwdthb, fwdthbl
	eer_8bit	eep_revperth, revperth
	eer_16bit	eep_revthb, revthbl
	eer_8bit	eep_braketorev, braketorev
	return

; Determine the state of the configuration switch
cfgcheckswitch
	btfss	GPIO, cfgswitch
	goto	cfg_sw_on	; Switch appears to be on at present
; Switch is off now....
	btfss	escstatus, esc_cfg_tmp
	goto	cfgbounce	; If was on last time!
; The same state as last time....
	decfsz	cfgdebounce,F
	return			; Just keep waiting...
; The switch is definitely off
	bcf	escstatus, esc_cfgpressed
	return
cfg_sw_on
; Switch is currently on
	btfsc	escstatus, esc_cfg_tmp
	goto	cfgbounce	; If was off last time!
; The same state as last time....
	decfsz	cfgdebounce,F
	return			; Just keep waiting...
; The switch is definitely on
	bsf	escstatus, esc_cfgpressed
	return
cfgbounce
; Toggle the state of the saved variable to match present state
	movlw	1<<esc_cfg_tmp
	xorwf	escstatus,F
cfgcheckinit
	movlw	debounce
	movwf	cfgdebounce
	return

;
; Flash the config LED
cfgflash
	decfsz	cfgledcnt,F
	return
	movlw	1<<cfgLED
	xorwf	pwmOFFio, F		; Update the output signals
	xorwf	pwmONio, F		; for the LED
	movfw	cfgledoncnt
	btfss	pwmOFFio, cfgLED
	movfw	cfgledoffcnt
	movwf	cfgledcnt
	return

donebrakerevoff
	clrf	braketorev
	goto	savebrakerev
donebrakerevmax
	movlw	0FFh
	goto	setbrakerev
donebrakerev
	movfw	cfgbrakerev
setbrakerev
	movwf	braketorev
savebrakerev
	eew_8bit	eep_braketorev, braketorev
	return

userconfig
; Start the LED flashing
	movlw	8
	movwf	cfgledoncnt
	movwf	cfgledoffcnt
; Step one is to count pulses for the brake->rev delay
	movlw	1
	movwf	cfgbrakerev
	movwf	cfgledcnt
usercfglp1
	call	cfgflash
	call	getthrottle
	btfss	escstatus, esc_cfgpressed
	goto	donebrakerev
	incfsz	cfgbrakerev,F
	goto	usercfglp1
; Now we have reached the maximum, allow another period... to set max
	movlw	24
	movwf	cfgledoffcnt
usercfglp2
	call	cfgflash
	call	getthrottle
	btfss	escstatus, esc_cfgpressed
	goto	donebrakerevmax
	incfsz	cfgbrakerev,F
	goto	usercfglp2
; Reverse should be disabled.... (indicate with a new flash rate)
	movlw	24
	movwf	cfgledoncnt
usercfglp3
	call	cfgflash
	call	getthrottle
	btfss	escstatus, esc_cfgpressed
	goto	donebrakerevoff
	incfsz	cfgbrakerev,F
	goto	usercfglp3
; We are into throttle programming now (back to fast flash)
	movlw	8
	movwf	cfgledoncnt
	movwf	cfgledoffcnt

; Assume that what we are seeing originally is the 'min' setting,
; and then we look for the largest pulse width and that is the 'max' setting.
; Then we calculate the constants we need.
;
; The algorithm is:
;	Wait for stable pulse - this is the idle position.
;	Wait for stable pulse > previous - this is max forward position
;	Wait for stable pulse at zero throttle - this ends max
;	Wait for stable pulse < previous - this is max reverse position
;	Wait for stable pulse at zero throttle - end of sequence

	call	getstablepulse

; This is the idle point....
; get setup for minimum timing
; During calibration we want to obtain:
;	- fwdperth/revperth	- usec per throttle position
;	- fwdrev:16/revfwd:16	- the offset we eventually want
	movfw	stableh
	movwf	cfgidleh
	movwf	fwdthbh
	movwf	revthbh
	movfw	stablel
	movwf	cfgidlel			; Remember the minimum
	movwf	fwdthbl
	movwf	revthbl
	movlw	1
	movwf	fwdperth
	movwf	revperth

; Wait for the throttle to move to some new upper value
usercfglp4
	call	getstablepulse
	call	forwardcalc
	addlw	-(throttlesteps-1)
	btfss	STATUS,Z
	goto	usercfglp4
; Recalculate
	call	configforward
; Now watch the throttle, either recalculate if larger or step on if idle...
usercfglp5
	call	getstablepulse
	call	forwardcalc
	iorlw	0
	btfsc	STATUS,Z
	goto	usercfglp6			; Returned to idle....
	call	chkconfigforward		; Is this a better config value?
	goto	usercfglp5
; User has returned to idle
usercfglp6
; Switch to a slow flash for reverse
	movlw	24
	movwf	cfgledoncnt
	movwf	cfgledoffcnt

; Wait for throttle to go to initial max reverse....
usercfglp7
	call	getstablepulse
	call	reversecalc
	addlw	-(throttlesteps-1)
	btfss	STATUS,Z
	goto	usercfglp7
; Recalculate
	call	configreverse
; Now watch the throttle, either recalculate if larger or step on if idle...
usercfglp8
	call	getstablepulse
	call	reversecalc
	iorlw	0
	btfsc	STATUS,Z
	goto	usercfglp9			; Returned to idle....
	call	chkconfigreverse		; Is this a better config value?
	goto	usercfglp8
; User has returned to idle, programming complete
usercfglp9
; Conversion parameters for pulse -> throttle have now been set.
; So save the EEPROM
	eew_8bit	eep_fwdperth, fwdperth
	eew_16bit	eep_fwdthb, fwdthbl
	eew_8bit	eep_revperth, revperth
	eew_16bit	eep_revthb, revthbl
	return

;
; Calculate the forward direction constants
chkconfigforward
	movfw	cfgtmpl
	subwf	stablel,W
	movfw	cfgtmph
	btfss	STATUS,C
	addlw	1
	subwf	stableh,W
	btfss	STATUS,C
	return
configforward
	movfw	cfgidlel
	subwf	stablel,w
	movwf	math_al
	movwf	fwdthbl
	movfw	cfgidleh
	btfss	STATUS,C
	addlw	1
	subwf	stableh,w
	movwf	math_ah		; math_a:16 is the range
	movwf	fwdthbh		; So is fwdthb:16

	movfw	stablel		; Remember the value we are configuring
	movwf	cfgtmpl
	movfw	stableh
	movwf	cfgtmph

	movlw	throttlesteps-throttlecalidle
	movwf	math_b		; Divide into steps
	call	math_a_div_b

	movfw	math_rl
	movwf	fwdperth	; That is all divided up...

; add the unused
; throttle range equally to the top and bottom of the range
	movwf	math_al
	clrf	math_ah		; Multiply back up...
	call	math_a_mul_b

	movfw	math_rl		; subtract from initial range
	subwf	fwdthbl,f
	movfw	math_rh
	btfss	STATUS,C
	addlw	1
	subwf	fwdthbh,f	; cntthb is now the 'spare' range

	bcf	STATUS,C
	rrf	fwdthbh,f
	rrf	fwdthbl,f	; Halve the space (some top, some bottom)

	movfw	cfgidlel	; Add back to find the base position
	addwf	fwdthbl,F
	movfw	cfgidleh
	btfsc	STATUS,C
	addlw	1
	addwf	fwdthbh,F
	return
;
; Calculate the reverse direction constants
chkconfigreverse
	movfw	cfgtmpl
	subwf	stablel,W
	movfw	cfgtmph
	btfss	STATUS,C
	addlw	1
	subwf	stableh,W
	btfsc	STATUS,C
	return
configreverse
	movfw	cfgidlel	; math_a:16 is idle point
	movwf	math_al
	movwf	revthbl
	movfw	cfgidleh
	movwf	math_ah
	movwf	revthbh		; So is revthb:16

	movfw	stablel		; Subtract current from idle
	movwf	cfgtmpl
	subwf	math_al,w
	movwf	math_al
	movwf	stablel
	movfw	stableh
	movwf	cfgtmph
	btfss	STATUS,C
	addlw	1
	subwf	math_ah,w
	movwf	math_ah		; math_a:16 is the range
	movwf	stableh		; So is stable:16

	movlw	throttlesteps-throttlecalidle
	movwf	math_b		; Divide into steps
	call	math_a_div_b

	movfw	math_rl
	movwf	revperth	; That is all divided up...

; add the unused
; throttle range equally to the top and bottom of the range
	movwf	math_al
	clrf	math_ah		; Multiply back up...
	call	math_a_mul_b

	movfw	math_rl		; subtract from initial range
	subwf	stablel,f
	movfw	math_rh
	btfss	STATUS,C
	addlw	1
	subwf	stableh,f	; stable:16 is now the 'spare' range

	bcf	STATUS,C
	rrf	stableh,f
	rrf	stablel,f	; Halve the space (some top, some bottom)

	movfw	stablel		; Subtract from idle...
	subwf	revthbl,F
	movfw	stableh
	btfss	STATUS,C
	addlw	1
	subwf	revthbh,F
	return

; Define the EEPROM Offsets
	cblock	0
eep_fwdperth:1				; Forward # of counts per throttle step
eep_fwdthb:2				; Forward throttle base in counts

eep_revperth:1				; Reverse # of counts per throttle step
eep_revthb:2				; Reverse throttle base in counts

eep_braketorev:1			; Switching time brake -> rev, 0 -> no reverse
	endc

; And put some default 'standard' data into the EEPROM
	eei_8bit	eep_fwdperth, fcounts
	eei_16bit	eep_fwdthb, fzerobase

	eei_8bit	eep_revperth, rcounts
	eei_16bit	eep_revthb, rzerobase

	eei_8bit	eep_braketorev, DELAYBRAKETOREV

	endif

	end
