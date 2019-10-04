	LIST   P=PIC16F84, R=DEC
	#INCLUDE "p16f84.inc"

;------------------------------------------------------------------------------
; ASSEMBLE With MPASM. available for free from http://www.microchip.com
;------------------------------------------------------------------------------
;
; Servo Controler Version 1.1
;	28/10/2001
;	- Fixed Serial receive data problem where the PIC could
;	  miss a byte by assuming that the PC isn't in the middle of 
;	  sending a byte as it deactivates CTS.
;
; This program will control 4 servos connected to PORT B of the
; PIC microcontroler.
;
; The servos work by responding to a pulse presented to them 
; approximately every 20ms. The width of the pulse controls the 
; position of the servo.
;
; In general, a pulse width of around 1520us is used as a neutral
; (centre) position indication. The pulse width is then increased
; or decreased from there. Generally it the pulse range goes from 
; 1 to 2 ms for full deflection (90 degree movement of horn).
;
; So we need to arrange timing to control the width of the output
; pulse. To do this we will run the PIC at 4MHz, this means that
; our instructions are 1us long (clock/4). We will arrange a delay
; loop to wait for a given number of clock cycles.
;
; Because servo aren't that accurate, we will divide the 1 to 2ms
; pulse range into 256 values, which if we work on a loop of 
; four instruction cycles we can get a loop between 4 and 1024 ms
; (the loop is constructed to run at least once)
;
; We then need to offset this (roughly) 0 to 1ms pulse to ensure
; that the servo is centered. We will do this by having an "offset"
; adjustment for each servo. This offset will control the width of
; the initial part of the pulse from 4 to 1024ms. This means that
; we can centre the servo using the offset and then move the servo
; +/-45 degrees from there. With careful use of the offset and
; position, it should be possible to use almost the full travel of
; the servo. 
;
; We will also need to be able to turn on and off the output of
; each servo driver. For added benefit, we will provide an 
; extra 4 digital outputs using the spare outputs of PORT B.
;
; PORT B is configured:
;
;	RB0		Digital Out 0
;	RB1		Digital Out 1
;	RB2		Digital Out 2
;	RB3		Digital Out 3
;	RB4		Servo Control 0
;	RB5		Servo Control 1
;	RB6		Servo Control 2
;	RB7		Servo Control 3
;
; PORT A is configured:
;
;	RA0		Serial TX (output)
;	RA1		Serial Request To Send (input)
;	RA2		Serial Clear To Send (output)
;	RA3		Serial RX (input)
;	RA4		LED Drive (0=on, 1=off. Used to indicate data transmission)
;
; Control Data
;
; To control the servos and outputs we need to send commands to the PIC.
; These commands will come from the serial port of a host computer running
; at 2400 baud, Hardware flow control (using CTS/RTS) with eight data bits,
; one stop bit and no parity. (2400 8-N-1).
;
; The commands take the format of one or two bytes sent sequentially 
; the first being the command to execute the second containing the data 
; for the command if needed.
;
; The command byte is split into two "nibbles". The upper 4 bits are used to
; determine the command, the lower 4 bits are used to select the output channel
;
;     +-----+-----+-----+-----+-----+-----+-----+-----+
; MSB |  7  |  6  |  5  |  4  |  3  |  2  |  1  |  0  | LSB
;     | 128 |  64 |  32 |  16 |  8  |  4  |  2  |  1  | Decimal Value
;     +-----+-----+-----+-----+-----+-----+-----+-----+
;     | Command               | Channel Select        |   
;     +-----+-----+-----+-----+-----+-----+-----+-----+
;
; Note that the value (in hex or decimal) is added to the channel number
; to generate the command byte.
; 
; The Commands are:
;
;	Hex		Decimal		Meaning
;	---------------------------------------------------------------------------
;	0x00	0			Reset Device. All outputs off, servos disabled and 
;						offset and position values set to 128 (mid range).
;						Data byte MUST BE Zero. The Channel Value MUST BE Zero.
;						Special, SHOULD be followed by another zero byte, see
;						text below.
;
;	0x10	16			Set Servo Output "Positon Value". Data byte is the
;						value (between 0 and 255). The Channel Value must be
;						set in the lower 4 bits between 0 and 3.
;
;	0x20	32			Set Servo Output "Offset Value". Data byte is the 
;						value (between 0 and 255). The Channel Value must be
;						set in the lower 4 bits between 0 and 3.
;
;	0x30	48			Enable Servo Output. This starts the PIC generating
;						servo control pulses on the given channel. The Channel 
;						Value must be set in the lower 4 bits between 0 and 3.
;						No Data byte.
;
;	0x40	64			Disable Servo Output. This stops the PIC generating
;						servo control pulses on the given channel. The Channel 
;						Value must be set in the lower 4 bits between 0 and 3.
;						No Data byte.
;
;	0x50	80			Set Digital Output On (high). The Channel Value must be
;						set in the lower 4 bits between 0 and 3.
;						No Data byte.
;
;	0x60	96			Set Digital Output Off (low). The Channel Value must be
;						set in the lower 4 bits between 0 and 3.
;						No Data byte.
;
; As you can see there is lots of room for expansion of the channels as well as
; the commands. It would be possible, for instance to, have 7 servo output and
; one digital output, all all digital outputs or all servo outputs. It would 
; also be possible to implement commands to query values from the PIC so some
; of the pins could be turned into inputs.
;
; Parser State Control.
;
; Even with the hardware flow control where the PIC uses the CTS line to inhibit
; the host from sending more data when it can't receive it, there is a chance 
; the host and PIC will get out of step with commands and data bytes. This could
; occur because of either a bug in the host software or power being lost to the 
; PIC. This may result in the PIC attempting to treat a data byte as a command or
; a command as a data byte. Therefore some scheme is needed to ensure that the
; state of both can be quickly resynchronised.
;
; This will be done in two ways, the reset command and the rejection of unknown
; commands.
;
; If the PIC receives a byte it believes to be a command but is doesn't
; recognise the command, it will discard it and start looking for another
; command byte. This means that for more values of the data bytes it will
; ignore these as commands. Unfortunately not all however. It is therefore
; possible for the PIC to execute incorrent commands until it comes accross
; one that doesn't make sense. This means that it could skip a normal reset
; reset command if it was one byte long by reading it as a data byte.
;
; The reset command is two bytes long (a command and a data byte) both being
; zeros. However to ensure that the PIC is reset EVERY TIME the resent command
; it sent, it should be sent as THREE sequential zero bytes.
;
; The reason is that if the PIC is out of step and waiting for a data byte, it 
; will comsume the first zero as a data byte, take the next one as the command
; and the last one as the data byte. But what if it isn't out of sync? The
; parser in the PIC will know that a zero command requires a zero data byte
; to be valid, therefore it will receive the first zero as the command, the 
; second as the data and execute the reset. It will then get another zero byte
; which is the command for reset and be waiting for the corresponding zero data
; byte. However the host will start sending other valid command at this time
; and the parser will not receive a zero data byte. It then knows that it must
; discard the reset command and use the new byte as a command.
;

;+=============================================================================
;| Program Beginning.
;+=============================================================================

; Set the configuration, PUT Enabled, WDT Disabled, XT Oscillator, No Code Protection
;
	__CONFIG _XT_OSC & _PWRTE_ON & _WDT_OFF & _CP_OFF    


;+-----------------------------------------------------------------------------
;| Declare Variables 
;+-----------------------------------------------------------------------------

; We will have up to 4 servos connected, each one needs to store the
; number 4us loops for the postion and the number of loops for the
; offset. The values are ordered in memory one after the other to allow 
; the use of the indirect addressing to call a routine that will process 
; all servos. Because we are using the indirect addressing to access
; all the detail for the servo, we will need an extra value to specify
; the mask to use to set and clear the correct servo output.
;
; NOTE: These are assumed to start at the Ram_Base (0Ch) by the rest of
; the program so don't put any variables before these.
;
	
; Declare the start of RAM that we can use
RamBase				EQU		0x0C

CBLOCK RamBase
	Servo0_Mask				; Mask for Servo 0 output
	Servo0_Offset			; loop count for Servo 0 offset
	Servo0_Position			; loop count for Servo 0 position

	Servo1_Mask				; Mask for Servo 1 output
	Servo1_Offset			; loop count for Servo 1 offset
	Servo1_Position			; loop count for Servo 1 position

	Servo2_Mask				; Mask for Servo 2 output
	Servo2_Offset			; loop count for Servo 2 offset
	Servo2_Position			; loop count for Servo 2 position

	Servo3_Mask				; Mask for Servo 3 output
	Servo3_Offset			; loop count for Servo 3 offset
	Servo3_Position			; loop count for Servo 3 position

	Int_W_Save				; Interrupt W register Store
	Int_STATUS_Save			; Interrupt STATUS register Store

	Flags					; eight flags, see the Flag_* macros
	Enables					; eight servo enable flags

	LED_Drive_Count			; used to count the number of 20ms blocks to keep
							; the LED on to indicate a data byte was received.

	CurrentServoMask		; the current servo mask

	DataByte				; somewhere to store a incoming data byte for processing

	Serial_CurrentByte		; the current byte being received or transmitted
	Serial_LoopCount		; the current bit loop counter

	Parser_Command			; the stored command
	Parser_Data				; the stored data byte
	Parser_Temp	
ENDC

;+-----------------------------------------------------------------------------
;| Declare MACROs
;+-----------------------------------------------------------------------------

RTCC_19msValue		EQU		107		; leaves 148 'ticks' at 1:128 before the
									; RTCC register clocks over and generates 
									; an interrupt. ~19ms

RTCC_1msValue		EQU		247		; leaves 8 'ticks' at 1:128 before the
									; RTCC register clocks over and generates
									; an interrupt. ~1mS

LED_Drive_Time		EQU		10		; leave the LED on for approx 200ms
#DEFINE LED_Drive			PORTA,4

#DEFINE Serial_TX			PORTA,0
#DEFINE Serial_RX			PORTA,3
#DEFINE Serial_CTS			PORTA,2
#DEFINE Serial_RTS			PORTA,1

Serial_BitDelay		EQU		103
Serial_HalfBitDelay	EQU		52

; Flag Access macros
#DEFINE Serial_ReceiveValid	Flags,0	; set if the current byte received was valid

#DEFINE Parser_WaitForData	Flags,1	; If set the parser is waiting for a data byte
									; for the current command

#DEFINE Flag_ServoPulseSafe Flags,2	; Set once about 2 bit times have expired since the
									; CTS line was deactivated in preperation for doing
									; the servo pulses.

#DEFINE Flag_WaitingForCTS	Flags,3	; The CTS line was deactivated and we are waiting for
									; about 2 bit times to make sure we're not going to miss
									; a data byte.

#DEFINE Serial_RestoreCTS	Flags,4	; The Serial Transmit routine needs to disable CTS when
									; transmitting so it needs to remember to restore it

; servo enable outputs. NOTE These MUST be sequential starting at bit 0 as 
; it is assumed in the parser when enabling and disabling servos
#DEFINE Flag_Servo0_Active	Enables,0
#DEFINE Flag_Servo1_Active	Enables,1
#DEFINE Flag_Servo2_Active	Enables,2
#DEFINE Flag_Servo3_Active	Enables,3


;+-----------------------------------------------------------------------------
;| Beginning of Program 
;+-----------------------------------------------------------------------------
	ORG			0
	GOTO		Main				; Jump to the main entry point

;+-----------------------------------------------------------------------------
;| Beginning of Interrupt Routine 
;| Note that we jump to the interrupt routine so that we can place all our 
;| 'lookup' table at the beginning of the program memory to ensure that when
;| we do an ADD to the PCL register we aren't going to clock over the address
;| and thus stuffing up our instruction pointer
;+-----------------------------------------------------------------------------
	ORG			4
	GOTO		Interrupt

;+-----------------------------------------------------------------------------
;| SUBROUTINE:	ParserChannelToBitMask
;| 
;| Take the channel number as a binary number in the W register and change it
;| to a bit mask so that bit 0 is set if W=0, bit 1 is set of W=1 etc.
;| This can then be used to alter output ports etc.
;| 
;| Valid range for W is 0 to 7
;+-----------------------------------------------------------------------------
ParserChannelToBitMask
	ANDLW	07h						; Ensure that there is a max of 7.
	ADDWF	PCL, f					; Jump into the commands below to return
									; the correct value
	DT		0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80

;+-----------------------------------------------------------------------------
;| SUBROUTINE: GetPWROnMsg
;| 
;| return the character at offset in the W register for the Power On Message
;| returns 0 if at the end of the string
;+-----------------------------------------------------------------------------
GetPWROnMsg
	ADDWF	PCL, f
	DT		"PIC Servo Controller\r\n", 0

;+-----------------------------------------------------------------------------
;| SUBROUTINE: GetResetMsg
;| 
;| return the character at offset in the W register for the Power On Message
;| returns 0 if at the end of the string
;+-----------------------------------------------------------------------------
GetResetMsg
	ADDWF	PCL, f
	DT		"Reset\r\n", 0

;+-----------------------------------------------------------------------------
;| Interrupt Routine.
;+-----------------------------------------------------------------------------
Interrupt
	; Save the state of the W and STATUS registers
	; Note this is the only way to do it properly
	MOVWF	Int_W_Save
	MOVF    STATUS, w
	MOVWF	Int_STATUS_Save

	; Process the interrupt. Note that the only interrupt generated is the 
	; timer overflow.
	;
	; when the timer expires from the 19ms delay, we have to disable the CTS line
	; so that the computer will not send us any more data, however we have to
	; continue listening for data for a little while so that we don't miss any if
	; it starts to send just as we deactivate the CTS line.
	;
	; Therefore we will wait for a further 2 bit times (about 1ms) before we signal
	; the main routine that it is safe to process the servo pulses.

	; Check if we have just expired the short 1ms delay
	BTFSS	Flag_WaitingForCTS
	GOTO	Int_LongDelayFinished

	; our short delay has just expired, we need to signal to the
	; main loop that it is now safe to proceed with the servo pulses
	; and disable any further timer interrupts (the main loop will
	; set them up again when it is ready)
	BCF		Flag_WaitingForCTS
	BSF		Flag_ServoPulseSafe
	BCF		INTCON, T0IF
	BCF		INTCON, T0IE		; mask the timer interrupt
	GOTO	Int_Finish
	
	; Our long delay has just expired. Disable CTS and setup for the short delay
Int_LongDelayFinished
	BSF		Serial_CTS
	BSF		Flag_WaitingForCTS
	MOVLW	RTCC_1msValue
	MOVWF	TMR0
	BCF		INTCON, T0IF
	BSF		INTCON, T0IE		; unmask the timer interrupt

Int_Finish
	; Restore the STATUS and W registers
	; Note that this is the only way to do it properly
	MOVF	Int_STATUS_Save, w
	MOVWF	STATUS
	SWAPF	Int_W_Save, f
	SWAPF	Int_W_Save, w

	RETFIE							; return from interrupt and reset GIE 


;+-----------------------------------------------------------------------------
;| SUBROUTINE:	GetAddressOfServoData
;|
;| Returns the acutal memory address of the first data byte for the given servo
;| This is the Mask value, it is then followed by the offset and position.
;|
;| Call with W between 0 and 3. This routine will ensure the value is 
;| within that range.
;+-----------------------------------------------------------------------------
GetAddressOfServoData
	ANDLW	03h						; Ensure that there is a max of 3.
	ADDWF	PCL, f					; Jump into the commands below to return
									; the correct value
	DT		Servo0_Mask, Servo1_Mask, Servo2_Mask, Servo3_Mask


;+-----------------------------------------------------------------------------
;| SUBROUTINE:	DelayWByFour
;|
;| Wait the number of 4 instruction cycles given in the W register. Note that
;| a value of zero will actually result in a delay of 256*4 instructions 
;| because the loop decrements W each iteration as the first instruction, 
;| so the zero will rollover to 255 and the loop will continue until it hits
;| zero again.
;| 
;| This version of the Delay add no extra cycles to the loop.
;| 
;| The numbers in brackets indicate the number of instructions in a normal
;| loop execution. However there are fixed costs to calling this routine which
;| need to be accounted for if accurate timing is to be generated.
;|
;| Each time the instruction pointer is adjusted (by a GOTO, CALL, RETURN etc)
;| the CPU stalls for an extra cycle resulting in an instruction taking 2 cycles.
;| Note that when the bit test results in a skip, the GOTO is effectivly treated
;| as a NOP so the loop consists of only 3 instructions before the return so 
;| we need to add an extra NOP to bring the total in the iteration up to 4
;|
;| Therefore the following are the extras that need to be accounted for:
;|		Call Entering:		2
;|		Call Return:		2
;|		---------------------
;|		Total:				4
;|
;| Meaning that one less loop is actually required to get the correct timing.
;|
;| Some timing examples, the number of cycles that "CALL DelayWByFour" takes:
;|		W		cycles
;|		--------------
;|		0		4+256*4	= 1028
;|		1		4+1*4	= 8
;|		2		4+2*4	= 12
;|		3		4+3*4	= 16
;|		...
;|		255		4+255*4	= 1024
;|
;+-----------------------------------------------------------------------------
DelayWByFour
	ADDLW	0FFh				; (1) Subtract one from the W register. 
	BTFSS	STATUS, Z			; (1) If we are at zero, then exit the loop
	GOTO	DelayWByFour			; (2) loop
	NOP					; (1) adjust final loop to be 4 instructions
	RETURN	


;+-----------------------------------------------------------------------------
;| SUBROUTINE:	DoServoControlPulse
;| 
;| Send a control pulse for a servo if it is active. This routine relies on the
;| caller setting the FSR (indirect addressing register) to the servo mask
;| for the correct server. It will then read the information it needs from it,
;| increment the FSR and access the servo's offset and position loop counts.
;|
;| Call with W between 0 and 3 indicating which servo to work with.
;+-----------------------------------------------------------------------------
DoServoControlPulse
	; convert the servo number in W to an offset for the Mask byte data for
	; the servo
	CALL	GetAddressOfServoData
	MOVWF	FSR

	; Get the Output Bit setting mask
	MOVF	INDF, w				; get the mask byte
	MOVWF	CurrentServoMask

	; Modify the FSR to point to the next byte of data which is the
	; offset loop counter, this is the number of 4 cycle
	; loops to preform.
	INCF	FSR, f

	; Set the control bit high to begin the control pulse. Note that from
	; now until it is set to low is part of the timimg pulse so instructions
	; are critical. The number in brackets is the number of EXTRA cycles each 
	; instruction uses which are not directly related to the pulse time and
	; need to be adjusted for This is easily done with the Offset value. 
	; Note that W still contains the output mask generated above.
	IORWF	PORTB, f			; bit is set, any other are left unchanged
								; pulse time starts at the end of this instruction

	; Offset Part of the Pulse 
	MOVF	INDF, w				; (1) Load the offset count
	ADDLW	1					; (1) Incremnt the count - 255->0, 0->1 because of 
								; calling convention of DelayWByFour
	CALL	DelayWByFour		; (8+) Delay 

	; Position Part of the Pulse
	INCF	FSR, f				; (1) Access the next value which is the 
								; position loop count

	MOVF	INDF, w				; (1) Load the variable loop count
	ADDLW	1					; (1) Incremnt the count - 255->0, 0->1 because of 
								; calling convention of DelayWByFour
	CALL	DelayWByFour		; (8+) Delay
	

	; Turn off the output bit to end the pulse
	MOVF	CurrentServoMask, w	; (1) Get the mask
	XORWF	PORTB, f			; (1) Turn of the pulse
		
	; and return from the call.
	RETURN


;+-----------------------------------------------------------------------------
;| SUBROUTINE: DisableInterrupts
;| 
;| Disable interrupts. This is not just as simple as BCF GIE because of the way
;| that interrupts are triggered it is possible for an interrupt to occur 
;| during the execution of the BCF GIE instruction which causes the PIC to start
;| the interrupt handler which then returns with RETFIE which sets the GIE flag
;| again!
;+-----------------------------------------------------------------------------
DisableInterrupts
	BCF		INTCON, GIE			; disable the interrupt
	BTFSC	INTCON, GIE			; check if GIE is still disabled
	GOTO	DisableInterrupts	; it isn't, so try again
	RETURN


;+-----------------------------------------------------------------------------
;| Main Program, Setup and Constantly Loop
;+-----------------------------------------------------------------------------
Main
	BCF		STATUS, RP0				; Set the lower RAM bank as the default.
	CALL	DisableInterrupts		; disable interrupts until were setup
	

	; Setup the PIC's ports, PortB is all outputs, PortA is the Serial interface
	CLRF	PORTA					; Clear the port outputs
	CLRF	PORTB				

	BSF		STATUS, RP0				; Set the Upper RAM bank while we init the ports
	MOVLW	0Ah						; All outputs except RA3 and RA1
	MOVWF	TRISA					; Set the port directional flags	
				
	MOVLW	00h						; Port B All outputs
	MOVWF	TRISB					; Set the port directional flags
	
	BCF		STATUS, RP0				; Set the lower RAM bank as the default.

	; Turn off the LED
	BSF		LED_Drive

	; initialise the serial port
	CALL	InitSerialPort

	; Transmit the power on welcome message (interrupts already disabled)
	CLRF	DataByte
PwrOnMsgLoop
	MOVF	DataByte, w
	CALL	GetPWROnMsg
	ANDLW	0ffh					; check for end of message
	BTFSC	STATUS, Z
	GOTO	EndPwrOnMsgLoop			; was 0, exit
	CALL	TransmitDataByte
	INCF	DataByte, f
	GOTO	PwrOnMsgLoop
EndPwrOnMsgLoop

	; Initialise the Servo values to resonable defaults and set their
	; mask values
	MOVLW	10h
	MOVWF	Servo0_Mask
	MOVLW	20h
	MOVWF	Servo1_Mask
	MOVLW	40h
	MOVWF	Servo2_Mask
	MOVLW	80h
	MOVWF	Servo3_Mask
	CLRF	Flags				; initialise all flags
	CALL	ResetState			; initialise all outputs and state

	; Setup the Real time counter so it runs on the instruction
	; clock and triggers and interrupt every 20ms or so. This
	; then calls the interrupt routine which serives all the servo
	; outputs. This is then enabled or disabled by the main loop when
	; it is bit banging the serial input.

	; Assign the prescaler to the timer and to 1:128 scale. This
	; also enables the PORTB pullups.
	BSF		STATUS, RP0				; Set the Upper RAM bank while we init the ports
	MOVLW	86h						; binary: 0000 0110
	MOVWF	OPTION_REG				; Set the OPTION register
	BCF		STATUS, RP0				; Set the lower RAM bank as the default.

	; Setup the RTCC for the 19ms interrupts
	MOVLW	RTCC_19msValue
	MOVWF	TMR0
	BCF		INTCON, T0IF
	
	; Enable the Timer 0 Interrupt and disable all others
	CLRF	INTCON				; mask out all interrupts
	BSF		INTCON, T0IE		; unmask the timer interrupt

	; Enable interrupts
	BSF		INTCON, GIE

	; Set the CTS signal active so the host can send us data
	BCF		Serial_CTS	

	; Wait for the start bit (a high to low transition on Serial_RX)
	; or for the servo pulse safe flag to be activated.
StartBitLoop
	BTFSS	Serial_RX
	GOTO	StartReceiveData

	; Test for servo pulse safe flag. If set, start the servo pulses, otherwise
	; go back and test for a start bit again.
	BTFSS	Flag_ServoPulseSafe
	GOTO	StartBitLoop
	GOTO	ProcessServos

StartReceiveData
	; possible start bit, receive a byte
	CALL	DisableInterrupts
	CALL	ReceiveDataByte
	MOVWF	DataByte
	BSF		INTCON, GIE

	; check if it is valid. If it is send it straight back
	BTFSS	Serial_ReceiveValid
	GOTO	StartBitLoop		; invalid, continue looking for a start bit
	
	; light the LED
	MOVLW	LED_Drive_Time
	MOVWF	LED_Drive_Count
	BCF		LED_Drive

	MOVF	DataByte, w
	CALL	ParseCommand

	GOTO	StartBitLoop

ProcessServos
	; Process each of the servos and send the control pulse if needed.
	; We move the address of the Servo's Control data into the FSR and call
	; the DoServoControlPulse subroutine.
	BCF		Flag_ServoPulseSafe

	; Check that Servo 0 is enabled, skip if it isn't
	BTFSS	Flag_Servo0_Active
	GOTO	DoServo1
	MOVLW	0						; Servo 0
	CALL	DoServoControlPulse

DoServo1
	BTFSS	Flag_Servo1_Active
	GOTO	DoServo2
	MOVLW	1						; Servo 1
	CALL	DoServoControlPulse
	
DoServo2
	BTFSS	Flag_Servo2_Active
	GOTO	DoServo3
	MOVLW	2						; Servo 2
	CALL	DoServoControlPulse

DoServo3
	BTFSS	Flag_Servo3_Active
	GOTO	DoLED
	MOVLW	3						; Servo 3
	CALL	DoServoControlPulse

DoLED
	; If the LED Drive counter is not zero, check if it has timed out so needs disabling
	MOVF	LED_Drive_Count, f
	BTFSC	STATUS, Z
	GOTO	ResetTimer

	; Decrement the LED counter and if it hits zero, turn off the LED
	DECFSZ	LED_Drive_Count, f
	GOTO	ResetTimer				; not zero, contine with next bit

	; Turn off LED
	BSF		LED_Drive

ResetTimer
	; Clear the interrupt flag so we don't interrupt again as soon as we exit
	; and reset the RTCC register to wait for another 19ms
	MOVLW	RTCC_19msValue
	MOVWF	TMR0
	BCF		INTCON, T0IF
	BSF		INTCON, T0IE		; unmask the timer interrupt

	; Reenable the CTS flag so the computer can send us more data
	BCF		Serial_CTS

	; return to looking for a start bit
	GOTO StartBitLoop

;+-----------------------------------------------------------------------------
;| SUBROUTINE: ResetState
;| 
;| Set all the outputs to the reset state. That is:
;|	1. All digital output Off
;|	2. All Servo outputs disabled
;|	3. All Servo Offsets to 128 (midrange)
;|	3. All Servo Positions to 128 (midrange)
;+-----------------------------------------------------------------------------
ResetState
	; Clear all the servo enables (all servos off)
	CLRF		Enables

	MOVLW		128
	MOVWF		Servo0_Offset
	MOVWF		Servo1_Offset
	MOVWF		Servo2_Offset
	MOVWF		Servo3_Offset
	MOVWF		Servo0_Position
	MOVWF		Servo1_Position
	MOVWF		Servo2_Position
	MOVWF		Servo3_Position

	; Turn everything off
	CLRF	PORTB

	; Transmit the power on welcome message
	CALL	DisableInterrupts
	CLRF	DataByte
ResetMsgLoop
	MOVF	DataByte, w
	CALL	GetResetMsg
	ANDLW	0ffh					; check for end of message
	BTFSC	STATUS, Z
	GOTO	EndResetLoop			; was 0, exit
	CALL	TransmitDataByte
	INCF	DataByte, f
	GOTO	ResetMsgLoop
EndResetLoop
	BSF		INTCON, GIE

	RETURN


;+=============================================================================
;| Command Parsing Routines.
;|
;| The following routines form the command parser and state machine to 
;| handle multi-byte commands.
;+=============================================================================


;+-----------------------------------------------------------------------------
;| SUBROUTINE: ParseCommand
;| 
;| Parse the given byte in W as a command. All incoming data is sent to this
;| routine to be interrupted. If the command is a single byte command it is
;| processed immediatly, if not the Parser waits for the next byte to execute
;| the command.
;+-----------------------------------------------------------------------------
ParseCommand
	; Determine if the Parser is waiting for a data byte, it is
	; store the incoming byte in the data field, if not store it
	; in the command field.
	BTFSS	Parser_WaitForData
	MOVWF	Parser_Command			; Store in command
	BTFSC	Parser_WaitForData
	MOVWF	Parser_Data				; Store in Data

	; Access the Command nibble and store it in the Parser_Temp variable
	; so we can access it and determine what the command is
	SWAPF	Parser_Command, w		; Place the upper nibble from the command
									; into the W register's lower nibble
	ANDLW	0Fh						; Mask out what was the channel select
	MOVWF	Parser_Temp				; Store in a Temp Variable.
	
	; Check for each command against the stored value and if we 
	; match one, goto the handler for that command, if we don't match
	; any command we need to discard the command.

	MOVLW	0h						; Check Reset Command
	SUBWF	Parser_Temp, w
	BTFSC	STATUS, Z				; Does it match?
	GOTO	ParseResetCmd			; Yes

	MOVLW	1h						; Check Set Servo Position
	SUBWF	Parser_Temp, w
	BTFSC	STATUS, Z				; Does it match?
	GOTO	ParseSetServoPosCmd		; Yes

	MOVLW	2h						; Check Set Servo Offset
	SUBWF	Parser_Temp, w
	BTFSC	STATUS, Z				; Does it match?
	GOTO	ParseSetServoOffsetCmd	; Yes

	MOVLW	3h						; Check Enable Servo Output
	SUBWF	Parser_Temp, w
	BTFSC	STATUS, Z				; Does it match?
	GOTO	ParseEnableServoCmd		; Yes

	MOVLW	4h						; Check Disable Servo Output
	SUBWF	Parser_Temp, w
	BTFSC	STATUS, Z				; Does it match?
	GOTO	ParseDisableServoCmd	; Yes

	MOVLW	5h						; Check Digital Out On
	SUBWF	Parser_Temp, w
	BTFSC	STATUS, Z				; Does it match?
	GOTO	ParseDigitalOutOnCmd	; Yes

	MOVLW	6h						; Check Digital Out Off
	SUBWF	Parser_Temp, w
	BTFSC	STATUS, Z				; Does it match?
	GOTO	ParseDigitalOutOffCmd	; Yes

	; We have an invalid command, reset the parser and return
	BCF		Parser_WaitForData		; next byte is a command
	RETURN							; Return to the caller

;------------------------------------------------------------------------------
; Handle the Reset Command
ParseResetCmd
	; If the Parser_WaitForData value is not set, then we need to set it and
	; get the data byte before proceeding
	BTFSS	Parser_WaitForData
	GOTO	ParserWaitForDataByte

	; We have the data byte, now lets parse the command and execute it
	; If the data byte is NOT Zero it means that this is not a valid 
	; command and are are out of sync with the host so we make the 
	; current data byte a command and restart parsing
	MOVF	Parser_Data, f
	BTFSS	STATUS, Z				; is it zero?
	GOTO	ParseResetInvalid		; No.

	; the data byte is zero so all is well,
	CALL	ResetState

	BCF		Parser_WaitForData		; next byte is a command
	RETURN

ParseResetInvalid
	BCF		Parser_WaitForData		; next byte is a command
	MOVF	Parser_Data, w			; data byte is the next command
	GOTO	ParseCommand

;------------------------------------------------------------------------------
; Handle the Set Servo Position Command
ParseSetServoPosCmd
	; If the Parser_WaitForData value is not set, then we need to set it and
	; get the data byte before proceeding
	BTFSS	Parser_WaitForData
	GOTO	ParserWaitForDataByte

	; We have the data byte, now lets parse the command and execute it

	; Get the channel number in W
	MOVF	Parser_Command, w
	ANDLW	03h						; ensure we only have 0-3 as the channel

	; Conver the channel number into the address of the Mask data byte for the
	; given servo, then add the offset to the "Position value"
	CALL	GetAddressOfServoData
	ADDLW	2

	; set the indirect address register to the RAM address of the Servos
	; Position regiter, then save the data byte into that RAM location
	MOVWF	FSR

	MOVF	Parser_Data, w
	MOVWF	INDF

	BCF		Parser_WaitForData		; next byte is a command
	RETURN

;------------------------------------------------------------------------------
; Handle the Set Servo Offset Command
ParseSetServoOffsetCmd
	; If the Parser_WaitForData value is not set, then we need to set it and
	; get the data byte before proceeding
	BTFSS	Parser_WaitForData
	GOTO	ParserWaitForDataByte

	; We have the data byte, now lets parse the command and execute it

	; Get the channel number in W
	MOVF	Parser_Command, w
	ANDLW	03h						; ensure we only have 0-3 as the channel

	; Conver the channel number into the address of the Mask data byte for the
	; given servo, then add the offset to the "Offset value"
	CALL	GetAddressOfServoData
	ADDLW	1

	; set the indirect address register to the RAM address of the Servos
	; Position regiter, then save the data byte into that RAM location
	MOVWF	FSR

	MOVF	Parser_Data, w
	MOVWF	INDF

	BCF		Parser_WaitForData		; next byte is a command
	RETURN

;------------------------------------------------------------------------------
; Handle the Enable Servo Command
ParseEnableServoCmd
	; load the command into W and convert the channel into a bit mask
	MOVF	Parser_Command, w
	ANDLW	03h						; ensure we only have 0-3 as the channel
	CALL	ParserChannelToBitMask

	; Cheat and directly manipulate the Enables byte as it matches our
	; channel mask
	IORWF	Enables, f			; bit is set, any other are left unchanged
	
	BCF		Parser_WaitForData		; next byte is a command
	RETURN

;------------------------------------------------------------------------------
; Handle the Disable Servo Command
ParseDisableServoCmd
	; load the command into W and convert the channel into a bit mask
	MOVF	Parser_Command, w
	ANDLW	03h						; ensure we only have 0-3 as the channel
	CALL	ParserChannelToBitMask

	; Cheat and directly manipulate the Enables byte as it matches our
	; channel mask
	MOVWF	Parser_Temp
	COMF	Parser_Temp, w
	ANDWF	Enables, f			; bit is cleared, any other are left unchanged
	
	BCF		Parser_WaitForData		; next byte is a command
	RETURN

;------------------------------------------------------------------------------
; Handle the Digital Out On Command
ParseDigitalOutOnCmd
	; load the command into W and convert the channel into a bit mask
	MOVF	Parser_Command, w
	ANDLW	03h						; ensure we only have 0-3 as the channel
	CALL	ParserChannelToBitMask

	; Turn on the corresponding digital out
	IORWF	PORTB, f			; bit is set, any other are left unchanged

	BCF		Parser_WaitForData		; next byte is a command
	RETURN

;------------------------------------------------------------------------------
; Handle the Digital Out Off Command
ParseDigitalOutOffCmd
	; load the command into W and convert the channel into a bit mask
	MOVF	Parser_Command, w
	ANDLW	03h						; ensure we only have 0-3 as the channel
	CALL	ParserChannelToBitMask
	
	; Turn off the corresponding digital out
	MOVWF	Parser_Temp
	COMF	Parser_Temp, w
	ANDWF	PORTB, f			; bit is cleared, any other are left unchanged

	BCF		Parser_WaitForData		; next byte is a command
	RETURN

;------------------------------------------------------------------------------
; Have the parser setup to get a data byte then return to the caller
ParserWaitForDataByte
	BSF		Parser_WaitForData		; next byte is a data byte
	RETURN


;+=============================================================================
;| RS232 Serial Interface Routines
;|
;| Out Serial interface is going to be  2400 baud, 8 data bits, no parity and
;| one stop bit. This means that a bit takes about 416us (1/2400). Therefore
;| we can use our DelayWByFour loop with a value of 103 ((416/4)-1) to delay
;| for bit samples. Note that this is not exactly accurate, but we are scanning 
;| quite offen for the beginning of the start bit an over the next 10 bits (8
;| data + start + stop) the timing isn't going to drift too much.
;|
;| We will also use Hardware flow control so the host doesn't send us anything 
;| when we're not in a position to receive it (ie, in the servo pulse loop).
;| The RS232 Request to Send line is routed to the PIC, but we won't use it
;| because it takes a little extra effort to set it to work properly on the PC.
;| and by default it is active all the time. We will be doing half duplex which
;| means that we can't send and receive at the same time so CTS is disabled
;| while we're transmitting.
;|
;| The RS232 Clear To Send line (active low) is also routed to the PIC, we will
;| enable is when we are able to receive data and disable it when we are not.
;|
;| The serial code and the interrupt routine to generate the servo pulses are
;| mutually exclusive as each will corrupt the timing of the other. Therefore
;| if we detect a start bit, we will disable the interrupts until we have 
;| received a byte.
;|
;| Receiving Data
;|
;| The Serial In line is normally high (1) but when a byte is to be sent the
;| start bit (a zero bit) brings the line low. This is our queue to start
;| reading bits. We will wait for half a bit read the input line and check that
;| the list is still low (0). If it isn't then it was a glitch so we will start
;| looking for the start bit again. If it is still low we will wait for a full
;| bit period and sample the input line again. This is the stored in bit 0 of 
;| the received data byte. We then continue sampling a bit intervals until we
;| have all 8 bits of data. Then we wait one more full bit period and sample the
;| stop bit. This should be high, it is isn't, we have a framing error and the
;| byte should be discarded. This normally happens if the sender's baud rate
;| is different from our own.
;|
;| Transmitting Data
;|
;| We will set the data output line low, wait for one bit period and the set
;| the output to the value of bit 0 in the output byte, We then wait for 
;| another bit period and send the next byte and contine until we're finished
;| all the 8 data bits, we then set the output high and wait for another bit 
;| period to send the stop bit.
;+=============================================================================

;+-----------------------------------------------------------------------------
;| SUBROUTINE: InitSerialPort
;| 
;| Initialise the serial port. Set all the lines to the apporpriate levels but
;| ensure that CTS is inactive (high).
;+-----------------------------------------------------------------------------
InitSerialPort
	; Set the output ports to the default states and disable CTS
	BSF		Serial_TX		; Output High by default
	BSF		Serial_CTS		; CTS is inactive so the host can't send us anything

	; Delay for at least one byte incase the host was sending data
	MOVLW	10
	MOVWF	Serial_LoopCount

InitSerialDelay
	MOVLW	Serial_BitDelay
	CALL	DelayWByFour

	DECFSZ	Serial_LoopCount, f		; subtract 1 from loop count
	BTFSS	STATUS, Z				; If zero, exit loop
	GOTO	InitSerialDelay

	RETURN


;+-----------------------------------------------------------------------------
;| SUBROUTINE: TransmitDataByte
;| 
;| Transmit the byte in the W register out the serial port. All interrupts 
;| need to be disabled prior to calling and reenabled after calling.
;+-----------------------------------------------------------------------------
TransmitDataByte
	MOVWF	Serial_CurrentByte		; store the byte to send

	; Check if the CTS line is active (0). if it is we need to disable it and
	; remember to restore it when we exit
	BTFSS	Serial_CTS				; if CTS is set (0), set the flag to restore it
	BSF		Serial_RestoreCTS
	BSF		Serial_CTS				; clear CTS

	; Send the Start bit
	BCF		Serial_TX
	MOVLW	Serial_BitDelay			; 1 bit delay
	CALL	DelayWByFour

	; loop through the byte sending each bit as we go
	MOVLW	8
	MOVWF	Serial_LoopCount

TxDataByteLoop
	BSF		STATUS, C
	RRF		Serial_CurrentByte, f	; get the current bit into the C flag
	BTFSS	STATUS, C
	BCF		Serial_TX				; If the bit = 0 set TX = 0
	BTFSC	STATUS, C
	BSF		Serial_TX				; If the bit = 1 set TX = 1

	MOVLW	Serial_BitDelay			; 1 bit delay
	CALL	DelayWByFour

	DECFSZ	Serial_LoopCount, f		; subtract 1 from loop count
	GOTO	TxDataByteLoop

	; Send the Stop bit
	BSF		Serial_TX
	MOVLW	Serial_BitDelay			; 1 bit delay
	CALL	DelayWByFour

	; restore CTS if needed
	BTFSC	Serial_RestoreCTS		; if flag is set, we must restore CTS
	BCF		Serial_CTS
	BCF		Serial_RestoreCTS		; Clear the flag
	RETURN


;+-----------------------------------------------------------------------------
;| SUBROUTINE: ReceiveDataByte
;| 
;| Receive a byte of data and return it in the W register. Set the flag
;| Serial_ReceiveValid if the byte was received correctly.
;| 
;| This must be called as soon as possible after detecting the falling edge
;| at the start of the start bit. All interrupts need to be disabled prior to 
;| calling and reenabled after calling.
;+-----------------------------------------------------------------------------
ReceiveDataByte
	; initialise the return valid flag and return value
	BCF		Serial_ReceiveValid		; Assume invalid
	MOVLW	0
	MOVWF	Serial_CurrentByte

	MOVLW	Serial_HalfBitDelay		; 1/2 bit delay
	CALL	DelayWByFour
	
	; Check that we are still in a start bit (Serial_RX low)
	BTFSC	Serial_RX
	RETURN							; not in start bit, return with fail
	
	; Receive the bits
	MOVLW	8
	MOVWF	Serial_LoopCount

RxDataByteLoop
	MOVLW	Serial_BitDelay			; 1 bit delay
	CALL	DelayWByFour

	; Sample the value
	BTFSS	Serial_RX
	BCF		STATUS, C				; If the bit = 0, set Carry = 0
	BTFSC	Serial_RX
	BSF		STATUS, C				; If the bit = 1, set Carry = 1

	RRF		Serial_CurrentByte, f	; Shift Carry into the output bit

	DECFSZ	Serial_LoopCount, f		; subtract 1 from loop count
	GOTO	RxDataByteLoop

	; check the stop bit is valid
	MOVLW	Serial_BitDelay			; 1 bit delay
	CALL	DelayWByFour

	BTFSC	Serial_RX
	BSF		Serial_ReceiveValid		; Stop bit != 1, invalid byte

	; load the byte to return
	MOVF	Serial_CurrentByte, w
	RETURN

; End of Code
	END
