; ****************************************************************************
; * Direct Digital Synthesiser Controller		                     *
; *  Version 877_2f	                                                     *
; *  March 2003  	                                                     *
; *  					                           	     *      												     *
; ****************************************************************************
; Description:
; This is the control program for a DDS VFO controller to drive an AD9850 
; DDS chip, a 512 step/rev shaft encoder, hardware is minimal.
; It is adapted from software written by NJ-QRP 
; Club members. See author details below.
; 
;
; BAND MEMORIES an external push button switch allows the frequency to be 
; cycled around the HF ham bands.
;
; CALIBRATE MODE is entered if band change function is selected during
; power on. The display is set to 10,000.000 CAL and remains fixed, even as
; adjustments are being made. Turning the shaft encoder will increase or 
; decrease the value "osc" used to calculate the DDS control word. 
; On deselecting banbd change, the calibrated value of "osc" will then be 
; stored in EEPROM memory.
;
; IF OFFSET is added or subtracted depending upon state of RC4. This operates 
; on the DDS data to shift the frequency leaving the display frequency constant.
; Two offset values, IF_Add and IF_Sub allow a BFO offset to be programmed.
; This feature was originally intended for use with ladder filters which
; favour LSB operation. By switching the LO injection USB and LSB operation
; is possible. Ron Taylor G4GXO October 1999
;
; An S-Meter feature provides a linear bar graph on line 2 representing an
; analogue voltage input (0-5v max) to the A to D.
;
; RIT function
;
; 2b changes;	Band select outputs for filter selection
;	 	Store last used band and use on start up
;		DDS Data and Clock commoned to save pins
;		Port changes for more efficient use of pins *Note Pin Connections!!*
;
; 2c Changes;   Correct T/R comment on pin-out and port bit assignmentto show 
;		correct logic.
;		Added start up delay to allow control line states to settle before
;		main progrsm entry.
;		Added version number, displayed during start up delay. 
;		Inserted 64mSec 'debounce' delay infront of calls to control functions
;		in Main. This allows any transients to settle before switch states
;		are read preventing unreliable operation.
;
; 2d Changes;	Config word changed to allow non Bootloader programming.
;		See comment in band_table header about removal of nop's for
; 		programming without a Bootloader.
;
; 2e Changes; 	Fix to enable IF Offset in Calibrate mode (calibrate routine). 
;		Fix to enable operation	with no IF Offset (IF_Offset).
;		Fix to enable DDS on power on before encoder change.
;		Calibrate and Saved messages added.
;
; 2f Changes;	Fix Calibrate routine, bank select problems.
;		WDT set to OFF in control word.
;		 	 		
;
;******************************************************************************
;
; Original Author details
; Author - Curtis W. Preuss - WB2V
;		Bruce Stough, AA0ED
;		Craig Johnson, AA0ZZ
;
;
; Contributions from - 
;	Rob Koop		 VE7EVX
;	Yves Nassens		 ON1KNY
;	Bernhard Baumgaertl	 DL1RAP
; 	Hubertus Kraemer	 Programmer
;	Jean-Baptiste Jacquemard F8DQL
;	Adrian Fretwell 	 G0TGD
;	Bob Innes    		 ZS6RZ
;
; 
;                            
;*****************************************************************************
;
; Target Controller -      PIC16F877
;                          
;Note. Port B inputs (except encoder) require 10K pull up resistors to +5v.
;
;
; Shaft Encoder: HP Agilent HEDS 9100 optical sensor 
;		 HEDS 5120-A06 2 Channel Code Wheel
;		 (Farnell)
; 
; Mounting made from PCB stock, shaft is 1/4" brass tube from model shop carefully
; rubbed down to make an interference fit into two 1/4" instrumentation bearings
; epoxy'd into PCB frame.
;
; Processor Port Connections
;
; *Note 10k Pull Up Resistors on switch control inputs only
; A to D, Shaft Encoder input and Ports B and C left open   
;
;	USART based Bootloader Port C6,7
;
;
;	Port A	0	S-Meter Analogue Input (0 - 5V)
;		1	AGC Threshold Reference (0 - 5V)
;		2	
;		3	Spare Analogue Input for later Tx Power feature
;		4	
;		5	
;
;	Port B	0	D0	
;		1	D1
;		2	D2
;		3	D3	LCD Data Word
;		4	D4
;		5	D5
;		6	D6
;		7	D7
;
;	Port C	0	*RIT Line, Active Low
;		1	*TX (Low) RX (High) Line
;		2	*Fine Tune, High 10Hz, Low 1Hz
;		3	*Band Change/Cal Switch		
;		4	*IF Offset (High) No IF Offset (Low)
;		5	*High/Low LO (LSB/USB Feature)
;		6	Bootloader Rx (Keep Free)
;		7	Bootloader Tx (Keep Free)
;
;	Port D	0	LCD_rs/DDS_clk  ; LCD 0=instruction, 1=data/AD9850 write clock
;		1	LCD_rw/DDS_dat  ; LCD 0=write, 1=read/AD9850 serial data input
;		2	LCD_e           ; LCD 0=disable, 1=enable
;		3	DDS_load equ    ; Update pin on AD9850
;		4	Out A - To control band filter selection               
;		5	Out B - To control band filter selection                
;		6	Out C - To control band filter selection
;		7	Out D - To control band filter selection
;
;	Port E	0	Shaft Encoder A
;		1	Shaft Encoder B
;		2	*Tuning Lock
;
;	Band Frequencies and associated output codes on Port D 4..7
;
;	160M 1.800,000Hz.  to 2.000,000Hz  (b"0001")Port D -  out
; 	80M  3.500,000Hz.  to 4.000,000Hz  (b"0010")Port D - 2,3,4 out
; 	40M  7.000,000Hz.  to 7.300,000Hz  (b"0011")Port D - 2,3,4 out
; 	30M  10.100,000Hz. to 10.150,000Hz (b"0100")Port D - 2,3,4 out
; 	20M  14.000,000Hz. to 14.350,000Hz (b"0101")Port D - 2,3,4 out  To Filter decode
; 	17M  18.068,000Hz. to 18.168,000Hz (b"0110")Port D - 2,3,4 out
; 	15M  21.000,000Hz. to 21.450,000Hz (b"0111")Port D - 2,3,4 out
; 	12M  24.890,000Hz. to 24.990,000Hz (b"1000")Port D - 2,3,4 out
; 	10M  28.000,000Hz. to 29.700,000Hz (b"1001")Port D - 2,3,4 out
; ****************************************************************************
; * General equates.  These may be changed to accommodate the reference clock* 
; * frequency, the desired upper frequency limit, and the default startup    *
; * frequency.                                                               *
; ****************************************************************************
;
; ref_osc represents the change in the frequency control word which results 
; in a 1 Hz change in output frequency.  It is interpreted as a fixed point
; integer in the format <ref_osc_3>.<ref_osc_2><ref_osc_1><ref_osc_0>
;
; The values for common oscillator frequencies are as follows:
;
; Frequency    ref_osc_3    ref_osc_2    ref_osc_1    ref_osc_0
; 125.00 MHz     0x22         0x5C         0x17         0xD0
; 120.00 MHz     0x23         0xCA         0x98         0xCE                  
; 100.00 MHz     0x2A         0xF3         0x1D         0xC4                  
;  90.70 MHz     0x2F         0x5A         0x82         0x7A                  
;  66.66 MHz     0x40         0x6E         0x52         0xE7                  
;  66.00 MHz     0x41         0x13         0x44         0x5F                  
;  50.00 MHz     0x55         0xE6         0x3B         0x88                  
;
; To calculate other values: 
;    ref_osc_3 = (2^32 / oscillator_freq_in_Hertz).                           
;    ref_osc_2, ref_osc_1, and ref_osc_0 are the fractional part of           
;     (2^32 / oscillator_freq_in_Hertz) times 2^24.                           
;    Note:   2^32 = 4294967296 and 2^24 = 16777216
;
; For example, for a 120 MHz clock:
;    ref_osc_3 is (2^32 / 120 x 10^6) = 35.791394133 truncated to 35 (0x23)  
;    ref_osc_2 is the high byte of (.791394133 x 2^24) = 13277390.32         
;      13277390.32 = 0xCA98CE, so high byte is CA.                           
;    ref_osc_1 is the next byte of 0xCA98CE, or 98
;    ref_osc_0 is the last byte of 0xCA98CE, or CE
;
;==== Currently set for 125 MHz Oscillator =======
ref_osc_3   equ 0x22              ; Most significant osc byte
ref_osc_2   equ 0x5C              ; Next byte
ref_osc_1   equ 0x17              ; Next byte
ref_osc_0   equ 0xD0              ; Least significant byte
;
; Limit contains the upper limit frequency as a 32 bit integer.
; This should not be set to more than one third of the reference oscillator
; frequency.  The output filter of the DDS board must be designed to pass
; frequencies up to the maximum.
;
limit_3   equ 0x01                ; Most significant byte for 30 MHz
limit_2   equ 0xC9                ; Next byte
limit_1   equ 0xC3                ; Next byte
limit_0   equ 0x80                ; Least significant byte
;
;
band_end equ    0x28              ; The offset to the last band table entry 
;
; ****************************************************************************
; *                    IF Offset Frequencies                                 *
; ****************************************************************************
; Two offsets are used to allow incorporation of a BFO offset typically 3kHz
; If BFO offset not needed set both offsets the same. For IF systems with 
; switchable carrier oscillators the IF Offset feature should normally be
; operated with the output frequency on the high side of the IF.
;
; Offset Frequencies set for 10MHz Ladder Filter 10,000 kHz and 9,997kHz
;
; IF Frequency used when adding offset
;
IF_Add_3 equ 0x00	;MSb
IF_Add_2 equ 0x98
IF_Add_1 equ 0x96
IF_Add_0 equ 0x80	;LSb
;
; IF Frequency used when subtracting offset
;
IF_Sub_3 equ 0x00	;MSb
IF_Sub_2 equ 0x98
IF_Sub_1 equ 0x8A
IF_Sub_0 equ 0xC8	;LSb
;
;

; ****************************************************************************
; * Device type and options.                                                 *
; ****************************************************************************
;
;        processor       PIC16F877
        LIST            P=16F877
        radix           dec
;
; ****************************************************************************
; * Configuration fuse information:                                          *
; ****************************************************************************

_CP_ALL                      EQU     H'0FCF'
_CP_HALF                     EQU     H'1FDF'
_CP_UPPER_256                EQU     H'2FEF'
_CP_OFF                      EQU     H'3FFF'
_DEBUG_ON                    EQU     H'37FF'
_DEBUG_OFF                   EQU     H'3FFF'
_WRT_ENABLE_ON               EQU     H'3FFF'
_WRT_ENABLE_OFF              EQU     H'3DFF'
_CPD_ON                      EQU     H'3EFF'
_CPD_OFF                     EQU     H'3FFF'
_LVP_ON                      EQU     H'3FFF'
_LVP_OFF                     EQU     H'3F7F'
_BODEN_ON                    EQU     H'3FFF'
_BODEN_OFF                   EQU     H'3FBF'
_PWRTE_OFF                   EQU     H'3FFF'
_PWRTE_ON                    EQU     H'3FF7'
_WDT_ON                      EQU     H'3FFF'
_WDT_OFF                     EQU     H'3FFB'
_LP_OSC                      EQU     H'3FFC'
_XT_OSC                      EQU     H'3FFD'
_HS_OSC                      EQU     H'3FFE'
_RC_OSC                      EQU     H'3FFF'


	__config (_CP_OFF & _PWRTE_ON & _DEBUG_OFF & _WDT_OFF & _LVP_OFF & _HS_OSC)


;
; ****************************************************************************
; * General equates.  These may be changed to accommodate the reference clock* 
; * frequency, the desired upper frequency limit, and the default startup    *
; * frequency.                                                               *
; ****************************************************************************
;


PortA   equ     0x05
PortB   equ     0x06
PortC	equ	0x07
PortD	equ	0x08
PortE	equ	0x09
TRISA   equ     0x05
TRISB   equ     0x06
TRISC	equ	0x07
TRISD	equ	0x08
TRISE	equ	0x09
EEdata  equ     0x10C
EEadr   equ     0x10D
EEdath  equ	0x10E
EEadrh	equ	0x10F
EEcon1  equ	0x18C
EEcon2	equ	0x18D
RCSTA	equ	0x18

; EEcon bits

EEPGD	equ	0x07
WREN    equ     0x02
WR      equ     0x01
RD      equ     0x00
;
; 
;
; ****************************************************************************
; * RAM page independent file registers:                                     *
; ****************************************************************************
;
INDF    	EQU     0x00
OPTION_REG	EQU	0x01
PCL     	EQU     0x02
STATUS  	EQU     0x03
FSR     	EQU     0x04
PCLATH  	EQU     0x0A
INTCON  	EQU     0x0B
PIR1		EQU	0x0C
PIE1		EQU	0x8C
ADRESH		EQU	0x1E
ADCON0		EQU	0x1F
ADCON1		EQU	0x9F
;
; *****************************************************************************
; * Bit numbers for the STATUS file register:                                 *
; *****************************************************************************
;
B_RP1	EQU	6
B_RP0   EQU     5
B_NTO   EQU     4
B_NPD   EQU     3
B_Z     EQU     2
B_DC    EQU     1
B_C     EQU     0
;
; ****************************************************************************
; * Bit numbers for other file registers:                                    *
; ****************************************************************************
GIE		EQU	7	; INTCON
PIE		EQU	6	; INTCON
T0IF		EQU	2	; INTCON
GO		EQU	2	; ADCON
ADIF		EQU	5	; PIR1
ADIE		EQU	6	; PIE1
tune_flag	EQU	0 	; Flag	Used to indicate if tuning step needed	
RIT_flag  	EQU	1	; Flag	Used to mark RIT operation state
RIT_tx_flag	EQU	2  	; Flag	Used to indicate if Tx freq enabled under RIT
rs_flag		EQU  	3	; Flag 	Used in LCD comms routine
bar_flag	EQU	4	; Flag	Used in bar graph routine
band_flag	EQU	5	; Flag used to mark state of band change routine




; ****************************************************************************
; * Assign names to IO pins.                                                 *
; ****************************************************************************
;
;	USART Based Bootloader
;
; Port C6 and C7 reserved for Bootloader comms
;
; Port A bits:
;




; Port B 	LCD Data



; Port C	Controls

RIT_State	equ	0x00		  ; RIT High Off Low on
TR_Line		equ	0x01		  ; Tx (Low) Rx (High) Line
Tune_Rate	equ	0x02		  ; High 10Hz, Low 1Hz
band_ch 	equ 	0x03              ; Band/Power on calibrate, (Active Low)
IF_Offset_Use	equ	0x04		  ; Use IF Offset High Yes, Low No
IF_add_sub	equ	0x05		  ; IF Add/Sub High Add, Low Sub

; Port D Bits	Processor driven outputs

LCD_rs  	equ     0x00              ; 0=instruction, 1=data
LCD_rw  	equ     0x01              ; 0=write, 1=read
LCD_e   	equ     0x02              ; 0=disable, 1=enable
DDS_load 	equ     0x03              ; Update pin on AD9850
DDS_clk 	equ     0x00              ; AD9850 write clock
DDS_data 	equ     0x01              ; AD9850 serial data input

; Port E

Tune_Lock	equ	0x02		  ; Disable tuning routine (Active Low)
 

; ****************************************************************************
; * ID location information:                                                 *
; * (MPASM warns about DW here, don't worry)                                 *
; ****************************************************************************
;
        ORG     0x2000
        DATA    0x007F
        DATA    0x007F
        DATA    0x007F
        DATA    0x007F
;	
;
; ****************************************************************************
; * Setup the initial constant, based on the frequency of the reference      *
; * oscillator.  This can be tweaked with the calibrate function.            *
; ****************************************************************************
; 
        ORG     0x2100
        DATA    ref_osc_0
        DATA    ref_osc_1
        DATA    ref_osc_2
        DATA    ref_osc_3
	DATA	0x14		; Initial post programming default freq of 14MHz
				; Position 20 (14h) in the band list

;       Clear unused EEPROM bytes.

        DATA    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DATA    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; ****************************************************************************
; *           Allocate variables in general purpose register space           *
; ****************************************************************************
;
        CBLOCK  0x20              ; Start Data Block
; DDS Variables
        freq_0                    ; Base frequency (hex) 
          freq_1                  ;  (4 bytes) 
          freq_2
          freq_3
	ftemp_0			  ; Temp storage used
	  ftemp_1		  ; for freq during RIT offset
	  ftemp_2
	  ftemp_3
	frxtemp_0		  ; Temp storage used
	  frxtemp_1		  ; for RIT offset during Tx
	  frxtemp_2
	  frxtemp_3       
        DDS_freq_0		  ; Freq input to Calc_DDS
	  DDS_freq_1		  ; After IF offset
	  DDS_freq_2		  ; (4 bytes)
	  DDS_freq_3
 	AD9850_0                  ; AD9850 control word 
          AD9850_1                ;  (5 bytes)
          AD9850_2
          AD9850_3
          AD9850_4
        fstep_0                   ; Frequency inc/dec 
          fstep_1                 ;  (4 bytes)
          fstep_2
          fstep_3
        mult_count                ; Used in calc_dds_word 
        bit_count                 ;   "
        byte2send                 ;
        osc_0                     ; Current oscillator 
          osc_1                   ;  (4 bytes)
          osc_2
          osc_3
        osc_temp_0                ; Oscillator frequency 
          osc_temp_1              ;  (4 bytes)
          osc_temp_2        
          osc_temp_3
        ren_timer_0               ; For variable rate tuning 
        ren_timer_1               ;  (2 bytes)
        ren_new                   ; New value of encoder pins A and B
        ren_old                   ; Old value of encoder pins A and B
        ren_read                  ; Encoder pins A and B and switch pin
	step_divider		  ; Counter used to slow tuning rate when changing band
	cntl_read		  ; PortC switch state 
	cntl_new		  ; PortC switch new state
	cntl_old		  ; PortC switch old state	
        last_dir                  ; Indicates last direction of encoder
        next_dir                  ; Indicates expected direction
        count                     ; loop counter  (gets reused)
        band                      ; Used to index a table of frequencies
	Flag			  ; General flags to mark routine states
;		bit 0	tune_flag 	  ; Used to indicate if tuning step needed	
;		bit 1	RIT_flag  	  ; Used to mark RIT operation state
;		bit 2	RIT_tx_flag	  ; Used to indicate if Tx freq enabled under RIT
;		bit 3   rs_flag		  ; Used to mark LCD rs line state
;		bit 4   bar_flag	  ; Used in bar graph routine
;		bit 5	band_flag	  ; Used to mark exit from band change
	msgflag			  ; Used for tracking display messages
;		bit 0 RIT message 	  ; Mark Display of message
;		bit 1 |LO + IF|
;	 	bit 2 |LO - IF|	
	RIT_read
	RIT_new
	RIT_old
;
; LCD Variables
;
	BCD_0                     ; Display frequency (BCD) 
        BCD_1                     ;  (5 bytes)
        BCD_2
        BCD_3
        BCD_4     
	BCD_count
	BCD_temp
	main_LCD_counter	  ; Update counter in main subroutine 
	main_S_counter		  ; Update counter in main subroutine	
        LCD_char                  ; Character being sent to the LCD
        LCD_read                  ; Character read from the LCD
        timer1                    ; Used in delay routines
        timer2                    ;   "
	timer3			
	S_point			  ; S-Meter 
	AGC_level
	AGC_BIAS
        ENDC                      ; End of Data Block

; ****************************************************************************

; Macro Area

; Bank Select Macros to simplify bank changes

Bank0	MACRO
	bcf	STATUS,B_RP0	; Select Bank 0
	bcf	STATUS,B_RP1	;
	ENDM

Bank1	MACRO
	bsf	STATUS,B_RP0	; Select Bank 1
	bcf	STATUS,B_RP1	;
	ENDM

Bank2	MACRO
	bcf	STATUS,B_RP0	; Select Bank 2
	bsf	STATUS,B_RP1	;
	ENDM

Bank3	MACRO
	bsf	STATUS,B_RP0	; Select Bank 3
	bsf	STATUS,B_RP1	;
	ENDM

; ****************************************************************************


	ORG	0x0000		  	  
reset_entry
        goto    Start             ; Jump around the band table to main program

;
; ****************************************************************************  
; This is the band table.  Each entry is four instructions long, with each 
; group of four literals representing the frequency as a 32 bit integer.   
; New entries can be added to the end of the table or between existing     
; entries.  The constant band_end must be incremented by 4 for each entry  
; added.                                                                   
;                                                                          
; This table is placed near the top of the program to allow as large a     
; a table as possible to be indexed with the eight bit value in W.         
;
; Note that a Bootloader uses the first few bytes of memory, typically 4 bytes 
; starting at 0000h, to store a jump routine that points to the main Bootloader 
; program in upper memory. This is to enable the Bootloader on power on or reset. 
; The Downloader program will place the first corresponding few bytes of the user
; program at a high address under the control of the Bootloader to prevent 
; overwrite of the reset boot code at 000h. If a table function immediately 
; follows the user start code (as here) the first few bytres will be relocated 
; corrupting the table operation. This will typically force a reset operation 
; causing the program to malfunction. 
;
; To prevent this the table is kept in a contiguous range of memory by placing 
; some "nop" commands in the area that will be relocated. The nop's are moved
; and the table remains intact. 
;
; The nop's have no effect on direct programming and can be left in place
;
; The Band Selection outputs on Port D are intneded to be used to drive relays
; or PIN diode switches for filter selection.                                                                      
;
; ****************************************************************************
;
	nop
	nop
	nop
	nop

band_table			  ; 		Band Selection (Port D4..7)
        addwf   PCL,f             ; 		
        retlw   0x00              ; 0 Hz	Band	0000
        retlw   0x00              ; 
        retlw   0x00              ;
        retlw   0x00              ;
        retlw   0x00              ; 160 meters	Band	0001
        retlw   0x1B              ; 
        retlw   0x77              ; 
        retlw   0x40              ; 
        retlw   0x00              ; 80 meters	Band	0010
        retlw   0x35              ; 
        retlw   0x67              ; 
        retlw   0xE0              ; 
        retlw   0x00              ; 40 meters	Band	0011
        retlw   0x6A              ; 
        retlw   0xCF              ; 
        retlw   0xC0              ; 
        retlw   0x00              ; 30 meters	Band	0100
        retlw   0x9A              ; 
        retlw   0x1D              ; 
        retlw   0x20              ; 
        retlw   0x00              ; 20 meters	Band	0101
        retlw   0xD5              ; 
        retlw   0x9F              ; 
        retlw   0x80              ; 
        retlw   0x01              ; 17 meters	Band	0110
        retlw   0x13              ; 
        retlw   0xB2              ;
        retlw   0x20              ; 
        retlw   0x01              ; 15 meters	Band	0111
        retlw   0x40              ; 
        retlw   0x6F              ; 
        retlw   0x40              ; 
        retlw   0x01              ; 12 meters	Band	1000
        retlw   0x7B              ; 
        retlw   0xCA              ; 
        retlw   0x90              ; 
        retlw   0x01              ; 10 meters	Band	1001
        retlw   0xAB              ; 
        retlw   0x3F              ; 
        retlw   0x00              ;
        retlw   0x01              ; 30 MHz	Band	1010
        retlw   0xC9              ;
        retlw   0xC3              ;
        retlw   0x80              ; 
        retlw   0x00              ; CAL 	Band	1011
        retlw   0x98              ;
        retlw   0x96              ; 10MHz Adjust this to suit Cal freq
        retlw   0x80              ; 



	return

; ****************************************************************************  
; S Meter increments
;
; The 6dB S Meter steps are mapped as a linear range of values from 0 to 90 
; (0 to 5Eh) over a 1 volt range. Each increment is 1dB, 90dB = S9+40. 
; Set AGC input to the A/D with a pot to suit.
; The steps are used to compare the analogue input samples and compute magnitude.
; Note that the linear law assumes that the IF AGC characteristics are also 
; linear. If they are not an alternative set of values can be programmed here
; by measuring AGC voltage against a calibrated input signal and normalising
; 6dB steps against 0 - 90 (00 - 5Eh).
;
; ****************************************************************************  

S_Table
	addwf	PCL,f	; Add S_point offset
	retlw	0x06	;S1
	retlw	0x0C	;S2
	retlw	0x12	;S3
	retlw	0x18	;S4
	retlw	0x1E	;S5
	retlw	0x24	;S6
	retlw	0x2A	;S7
	retlw	0x30	;S8
	retlw	0x36	;S9
	retlw	0x40	;S910
	retlw	0x4A	;S920
	retlw	0x54	;S930 
	retlw	0x5E	;S940 Limit
	return	
;
;==============================================================================
;
;	SECTION 1
;	
;	MAIN PROGRAM INITIALISATION AND CONTROL LOOP
;
;==============================================================================

; *****************************************************************************
; *                                                                           *
; * Purpose:  This is the start of the program.  It initializes the LCD and   *
; *           detects whether to enter calibrate mode.  If so, it calls the   *
; *           Calibrate routine.  Otherwise, it sets the power-on frequency   *
; *           and enters the loop to poll the encoder.                        *
; *                                                                           *
; *   Input:  The start up frequency is defined in the default_3 ...          *
; *           definitions above, and relies on the reference oscillator       *
; *           constant defined in ref_osc_3 ... ref_osc_0.                    *
; *                                                                           *
; *  Output:  Normal VFO operation.                                           *
; *                                                                           *
; *****************************************************************************
;

Start

; Configure Ports
        clrf    INTCON            ; No interrupts for now
	clrf	PortA		  ; Initialise Port A
	clrf	PortB		  ; Initialise Port B
	clrf	PortC		  ; Initialise Port C
	clrf	PortD		  ; Initialise Port D
	clrf 	PortE		  ; Initialise Port E

	Bank1			  ; Switch to bank 1
        bsf     0x01,7            ; Disable weak pullups
        movlw 	b'00111111'	  ; Set Port C 0..5 as inputs
	movwf   TRISC		  ; 
	movlw	0x00		  ; Set Port D as outputs
	movwf	TRISD		  ;
	movlw	0x07		  ; Set Port E as inputs
	movwf	TRISE		  ;
	Bank0
	bcf	RCSTA,7		  ; Disable USART
        call    init_LCD          ; Initialize the LCD
;
; Start up message
;
	call	Start_msg	  ; Display Software version
	call	Long_delay	  ; Show message for 1 Sec to allow control lines to settle
;
; A to D set up
;
	Bank1			  ; Switch to bank 1
	movlw	b'00000100'	  ; Left justify, 3 analog channel, no Vref
	movwf	ADCON1
	movlw	b'00000011'
	movwf	TRISA		  ; PortA 0..1 Inputs for A to D
	Bank0			  ; Switch back to bank 0
	movlw	b'01000001'	  ; Fosc/8, A/D enabled
	movwf	ADCON0
;
;       Get the power on encoder value.
;
        movf    PortE,w           ; Read port E
        movwf   ren_read          ; Save it in ren_read
        movlw   0x03              ; Get encoder mask
        andwf   ren_read,w        ; Get encoder bits
        movwf   ren_old           ; Save in ren_old
;
;       Initialize variables.
;
        clrf    last_dir          ; Clear the knob direction indicator
	clrf	Flag		  ; Reset Tuning/RIT/LCD status flags
	clrf	msgflag		  ; Clear message flag
	movlw	0xFF		  ; Load LCD frequency update loop counter
	movwf	main_LCD_counter
	movlw	0xFF		  ; Load LCD S-Meter update loop counter
	movwf	main_S_counter

;
;       Get the reference oscillator constant and band from the EEPROM.
;

read_EEocs

	Bank2
      	clrf    EEadr             ; Reset the EEPROM read address
 	call    read_EEPROM       ; Read EEPROM
      	movf    EEdata,w          ; Get the first osc byte
	Bank0			  ; On return we are in Bank2 for EEdata instruction, set to Bank0
        movwf   osc_0             ; Save osc frequency
        call    read_EEPROM       ; Get next byte, on return from this instruction we are in Bank2
        movf    EEdata,w          ;
	Bank0
       	movwf   osc_1             ; Save it
        call    read_EEPROM       ; Get the third byte, on return from this instruction we are in Bank2
        movf    EEdata,w          ; 
	Bank0
        movwf   osc_2             ; Save it
        call    read_EEPROM       ; Get the fourth byte, on return from this instruction we are in Bank2
	movf    EEdata,w          ;
	Bank0
        movwf   osc_3             ; Save it
        call    read_EEPROM       ; Get last used band word,on return from this instruction we are in Bank2
	movf    EEdata,w          ;
	Bank0
        movwf   band              ; Save it

;	
;       Enter Calibrate Mode if band change switch is operated during 
;       power on.

        btfss   PortC,band_ch	  ; Is the calibrate function selected?
        call    calibrate         ; Yes, calibrate

;
;       Set the power on frequency to the defined value.
;	display it and send to DDS (get_band routine)

	call	get_band	   ; Load Band Table data for last used band stored in EEPROM

;	Capture Port C Switch State
;
	movf    PortC,w           ; Get the current Port C value
	movwf   cntl_read         ; Save it
        movlw   b'00111111'       ; Get switch mask
        andwf   cntl_read,w       ; Isolate control switch bits
	movwf	cntl_old  	  ; Save condition. (No change on first pass)

;	Set up operational state to match switch settings

	call	RIT		  ; Check RIT state and adjust if Tx/Rx change
	call	IF_Offset	  ; Recalculate IF Offset and send to DDS
	call    calc_dds_word     ; Find the control word for the DDS chip
        call    send_dds_word     ; Send the control word to the DDS chip

; Fall into the Main Program Loop
;
; *****************************************************************************
; *                                                                           *
; * Purpose:  This is the Main Program Loop. All associated rountines are     *                  
; *           called from here.                                               *
; *           The fixed incremental frequency fstep is added or subtracted    *
; *	      from the current VFO frequency stored in freq. The IF offset    *
; *	      is added or subtracted depending upon RA5 state. The            *
; *           subroutine calc_dds_word is used to calculate the DDS           *
; *           frequency control word from the values in freq and osc.         *
; *           The result is stored in AD9850.  This data is transferred to    *
; *           the AD9850 DDS chip by calling the subroutine send_dds_word.    *	
; *	      The LCD Frequency and S-Meter are not updated on every	      *
; * 	      polling cycle. This speeds up the tuning rate.                  *
; *           If the band change switch is operated then freq is loaded       *
; *	      with a constant stored in band_table.  The variable "band"      *
; *	      is used as an index into the table.  Band is incremented        *
; *	      or decremented based on the encoder direction. 		      *
; *                                                                           *
; *****************************************************************************
;
main				; Start of main loop
	movlw	0xFF		; Load step divider with 255 for band change routine
	movwf	step_divider	; to give slow band change rate

read_controls
        clrwdt                  ; Reset the watchdog timer
; *****************************************************************************
; Determine whether we need to update the LCD frequency and S-Meter, this decision
; is based upon the state of counters which decrement with each polling loop cycle.
; The principle is that the LCD does not need to be updated on every polling cycle 
; or frequency step. If the software were configured this way the tuning rate would 
; be slow and the user would not be able to process visual information from the LCD
; fast enough to notice any benefit. The S-Meter is updated fewer times than the
; frequency display because the time constant of a typical agc system makes a high
; update rate unnecessary.
; *****************************************************************************

; LCD Updates

; Frequency Display Update

	decfsz	main_LCD_counter,f; Count loop cycles and call LCD update
	goto	check_controls	  ; Not time to update LCD Freq, move on
	movlw	0xFF		  ; Re-load loop counter
	movwf	main_LCD_counter
	call	bin2BCD		  ; Update LCD Frequency
	call	show_freq

; S-Meter Update

	decfsz	main_S_counter,f  ; Count loop cycles and call S-Meter update
	goto	check_controls	  ; Not time to update S-Meter, move onto control checks
	movlw	0x20		  ; Re-load loop counter (Nested counter within LCD Updates
	movwf	main_S_counter	  ; routine S-Meter rate =polling rate/(main_LCD_Counter*main_S_Counter)
	call	S_Meter	  	  ; Update LCD S-Meter

check_controls			  ; Check state of Port C Controls

	movf    PortC,w           ; Get the current Port C value
	movwf   cntl_read         ; Save it
        movlw   b'00111111'       ; Get switch mask
        andwf   cntl_read,w       ; Isolate control switch bits
        movwf   cntl_new          ; Save new value
        xorwf   cntl_old,w        ; Has it changed?
        btfsc   STATUS,B_Z        ;
	goto	tuning_step	  ; No, jump to tuning routine	
	movf	cntl_new,w	  ; Yes, update historic control status
	movwf	cntl_old
;		RIT_State	equ	0x00		  ; RIT High Off Low on
;		TR_Line		equ	0x01		  ; Tx Low Rx High Line
;		Tune_Rate	equ	0x02		  ; High 10Hz, Low 1Hz
;		band_ch 	equ 	0x03              ; Band/Power on calibrate, (Active Low)
;		IF_Offset_Use	equ	0x04		  ; Use IF Offset High Yes, Low No
;		IF_add_sub	equ	0x05		  ; IF Add/Sub High Add, Low Sub
	call	wait_64ms	  ; Debounce control lines before individual testing
	call	RIT		  ; Check RIT state and adjust if Tx/Rx change
	call	change_band	  ; Change band
	call	IF_Offset	  ; Recalculate IF Offset and send to DDS
	call    calc_dds_word     ; Find the control word for the DDS chip
        call    send_dds_word     ; Send the control word to the DDS chip
	call	bin2BCD		  ; Display new freq value
	call	show_freq
; 
; Tuning step routine, 
;
; Determine step size to use (10 Hz or 1 Hz) and apply it to step word.
;

tuning_step
	call	read_encoder	
	btfss	Flag,tune_flag	  ; Step needed?
	goto	read_controls	  ; No, go to start of loop
        clrf    fstep_3           ; Set tuning rate to 10 Hz steps by 
        clrf    fstep_2           ; setting fstep to 0Ah (10).
        clrf    fstep_1           ; 
        movlw   0x0A              ;
        movwf   fstep_0           ;

; Fine tuning routine

	btfsc	Flag,RIT_flag	  ; Is RIT on?
	goto	Fine_tune	  ; Yes select Fine Tune
        btfsc   PortC,Tune_Rate	  ; Is fine tune selected?
        goto    go_step           ; No, use the 10 Hz step
Fine_tune     
	movlw   0x01              ; Yes, set the step value to 1 Hz
        movwf   fstep_0           ; by setting fstep_0 to 0x01

go_step

; Based on the knob direction, either add or subtract the increment 
 
        btfsc   last_dir,1        ; Is the knob going up?
        goto    up                ; Yes, then add the increment
down
        call    sub_step          ; Subtract fstep from freq
        goto    send_freq	  ; Update LCD and DDS
up
        call    add_step          ; Add fstep to freq
        call    check_add         ; Make sure we did not exceed the maximum
send_freq
	call	IF_Offset	  ; Recalculate IF Offset and send to DDS
        call    calc_dds_word     ; Find the control word for the DDS chip
        call    send_dds_word     ; Send the control word to the DDS chip
	goto	read_controls	  ; Continuous Loop


; *****************************************************************************
;  Band change routine							      
;                                                                            
; Purpose:  This routine increments through the band table each time the    
;           encoder moves 255 steps updating the LCD and DDS, until the     
;           band switch is no longer operated.                              
;           On de-selection of band change, new value of band word is 
;           written to EEPROM for power on configuration.                   
; *****************************************************************************
change_band
	btfsc   PortC,band_ch     ; Band Change function selected?
	goto	band_exit
	call	read_encoder
	btfss	Flag,tune_flag	  ; Has the encoder moved?
	goto	change_band	  ; No, re-test
	bsf	Flag,band_flag	  ; Set band select mode flag
	decfsz	step_divider,f	  ; Yes, decrement step counter (pre-loaded with 255) to 0
	goto	change_band	  ; to slow down band change rate with 500 position
	movlw	0xFF		  ; Re-load step divider with 255 for band change routine
	movwf	step_divider	  ; to give slow band change rate

        btfsc   last_dir,1        ; Are we going up in the band list? 
        goto    band_up           ; Yes, increment band address
        movlw   0x04              ; No, get 4 bytes to subtract
        subwf   band,f            ; Move down in band list
        movlw   0xFF-band_end     ; Check to see if we have fallen off the
        addwf   band,w            ; bottom of the table.
        btfss   STATUS,B_C        ; Off the bottom?
        goto    valid             ; No, continue
        movlw   band_end          ; Yes, go to highest entry
        movwf   band              ; 
valid
        call    get_band          ; Get the new band frequency
	goto	change_band    	  ; 
band_up
        movlw   0x04              ; Table entries are 4 bytes apart
        addwf   band,f            ; Increment the band pointer
        movlw   0xFF-band_end     ; Check to see if we have gone over the
        addwf   band,w            ; top of the table.
        btfsc   STATUS,B_C        ; Did we go over the top of the table?
        clrf    band              ; Yes, go to the bottom entry
        call    get_band          ; Get the new band frequency
	goto	change_band

band_exit
	btfss	Flag,band_flag	  ; First exit from band select mode?
	return		 	  ; No, don't save
	movf	band,w		  ; Yes, save new value of band in EEPROM
	Bank2
	movwf	EEdata		  ; Place band value in EEdata 
	movlw	0x04		  ; 	
	movwf	EEadr		  ; Point to byte 4
	call	write_EEPROM	  ; Write new value of band
	bcf	Flag,band_flag	  ; Reset band_flag	
	return			  ; Return to main

; *****************************************************************************
;
; Encoder sub routine called by main tuning loop and by calibrate sub routine
;                             
; *****************************************************************************

read_encoder  
	btfss	PortE,Tune_Lock   ; Check Tuning Lock state
	goto	no_tune		  ; Locked, skip tuning step and update LCD
	movf    PortE,w    	  ; Get the current encoder value
        movwf   ren_read          ; Save it
        movlw   0x03              ; Get encoder mask
        andwf   ren_read,w        ; Isolate encoder bits
        movwf   ren_new           ; Save new value
        xorwf   ren_old,w         ; Has it changed?
        btfss   STATUS,B_Z        ; 
	goto	direction	  ; Yes	
no_tune
	bcf	Flag,tune_flag	
	return		          ; No, return to main loop

; Determine which direction the encoder turned.
direction
        bcf     STATUS,B_C        ; Clear the carry bit
        rlf     ren_old,f         ; 
        movf    ren_new,w         ; 
        xorwf   ren_old,f         ; 
        movf    ren_old,w         ; 
        andlw   0x02              ; 
        movwf   next_dir          ; 
        xorwf   last_dir,w        ; 

; Prevent encoder slip from giving a false change in direction.

        btfsc   STATUS,B_Z        ; Zero?
        goto    pe_continue       ; No slip; keep going
        movf    next_dir,w        ; Yes, update direction
        movwf   last_dir          ; 
        movf    ren_new,w         ; Save the current encoder bits for next time
        movwf   ren_old           ; 
	bcf	Flag,tune_flag	  ;	
        return		          ; Try again
pe_continue
        btfsc   ren_old,1         ; Are we going down?
        goto    up2               ; No, indicate we are going up
        clrf    last_dir          ; Yes, clear last_dir
        goto    exit3             ; Finish and return
up2 
        movlw   0x02              ; Set UP value in last_dir
        movwf   last_dir          ; 
exit3 
        movf    ren_new,w         ; Get the current encoder bits
        movwf   ren_old           ; Save them in ren_old for the next time
	bsf	Flag,tune_flag	  ; Tuning step needed
	return

; *****************************************************************************
; *                                                                           *
; * Purpose:  This routine reads the frequency value of a band table entry    *
; *           pointed to by band and returns it in freq_3...freq_0.           *
; *                                                                           *
; *   Input:  band must contain the index of the desired band entry * 4       *
; *           (with the entries numbered from zero).                          *
; *                                                                           *
; *  Output:  The band frequency in freq.                                     *
; *                                                                           *
; *****************************************************************************

get_band
        movf    band,w            ; Get the index of the high byte 
        call    band_table        ; Get the value into W
        movwf   freq_3            ; Save it in freq_3
        incf    band,f            ; Increment index to next byte
        movf    band,w            ; Get the index of the next byte
        call    band_table        ; Get the value into W
        movwf   freq_2            ; Save it in freq_2
        incf    band,f            ; Increment index to the next byte
        movf    band,w            ; Get the index to the next byte
        call    band_table        ; Get the value into W
        movwf   freq_1            ; Save it in freq_1
        incf    band,f            ; Increment index to the low byte
        movf    band,w            ; Get the index to the low byte
        call    band_table        ; Get the value into W
        movwf   freq_0            ; Save it in freq_0
        movlw   0x03              ; Get a constant three
        subwf   band,f            ; Restore original value of band

; Display and DDS update	

	call	IF_Offset	  ; Recalculate IF Offset and send to DDS
        call    calc_dds_word     ; Find the control word for the DDS chip
        call    send_dds_word     ; Send the control word to the DDS chip
	call	bin2BCD		  ; Display new freq value
	call	show_freq

; Filter selection

; Filter selection on Port D
; Note that band increments in steps of 4 to address band table
; Bits 0 and 1 are always zero, ( 00NNNN00). To allow this to be mapped onto 
; Port D bits 4..7 we need to shift the word left two bits (NNNN0000).

	rlf	band,f		  ; Shift left
	rlf	band,f		  ; Shift left

; Filter word now aligns with Port D bits 4..7   

	movf 	band,w		  ; Set up filter selection on Port D
	movwf	PortD		  ; Send to Port D
	rrf	band,f		  ; Restore original value of band
	rrf	band,f
	return                    ; Return to the caller 

;
; *****************************************************************************
;
; RIT Routine, operates Rx state to modify Freq word, on change to Tx
; original base frequency word is restored.
;
; *****************************************************************************

RIT	
	btfss	PortC,0		  ; Is RIT Line low?
	goto	RIT_on		  ; Yes, select RIT Mode
	btfss	Flag,RIT_flag	  ; No, is the RIT Flag set? (first pass after RIT deselect)
	return			  ; No, continue
	movf	ftemp_0,w	  ; Yes, restore pre RIT base frequency
	movwf	freq_0
	movf	ftemp_1,w
	movwf	freq_1
	movf	ftemp_2,w
	movwf	freq_2	
	movf	ftemp_3,w
	movwf	freq_3
	clrf	ftemp_0
	clrf	ftemp_1
	clrf	ftemp_2
	clrf	ftemp_3
	bcf	Flag,RIT_flag	  ; Reset RIT Flag
	bcf	msgflag,0	  ; Clear RIT message flag
	call	Clear_msg	  ; Clear Display
	return
RIT_on
	btfsc	Flag,RIT_flag	  ; Test RIT Flag
	goto	RIT_Tx		  ; Already set, don't perform freq save operation
	call	RIT_msg
	movf	freq_0,w	  ; Save current base frequency
	movwf	ftemp_0
	movf	freq_1,w
	movwf	ftemp_1
	movf	freq_2,w
	movwf	ftemp_2	
	movf	freq_3,w
	movwf	ftemp_3
	bsf	Flag,RIT_flag	  ; Set RIT flag to mark freq save operation
RIT_Tx				  ; Save RIT freq and Restore base freq during Tx
	btfss	PortC,TR_Line	  ; Are we in Tx mode? (0=Tx)
	goto	RIT_Tx_Save	  ; Yes, initiate save of RIT and reload of base Tx freq
	btfss	Flag,RIT_tx_flag  ; No, test Tx flag bit
	return			  ; Clear, return
	movf	frxtemp_0,w	  ; Restore current RIT frequency
	movwf	freq_0
	movf	frxtemp_1,w
	movwf	freq_1
	movf	frxtemp_2,w
	movwf	freq_2	
	movf	frxtemp_3,w
	movwf	freq_3		  ; 
	bcf	Flag,RIT_tx_flag
	return 
RIT_Tx_Save
	btfsc	Flag,RIT_tx_flag  ; Test RIT Flag Tx bit 
	return			  ; Already set, don't perform Rx freq save operation
	movf	freq_0,w	  ; Save current RIT frequency
	movwf	frxtemp_0
	movf	freq_1,w
	movwf	frxtemp_1
	movf	freq_2,w
	movwf	frxtemp_2	
	movf	freq_3,w
	movwf	frxtemp_3
	movf	ftemp_0,w	  ; Restore original base frequency for Tx
	movwf	freq_0		  ; Save current base frequency
	movf	ftemp_1,w
	movwf	freq_1
	movf	ftemp_2,w
	movwf	freq_2	
	movf	ftemp_3,w
	movwf	freq_3
	bsf	Flag,RIT_tx_flag	  ; Set RIT flag to mark freq save operation	
	return

; *****************************************************************************
; *                                                                           *
; * Purpose:  This routine adds the 32 bit value of fstep to the 32 bit       *
; *           value in freq.  When incrementing, the fstep value is a         *
; *           positive integer.  When decrementing, fstep is the complement   *
; *           of the value being subtracted.                                  *
; *                                                                           *
; *   Input:  The 32 bit values in fstep and freq                             *
; *                                                                           *
; *  Output:  The sum of fstep and freq is stored in freq.  When incrementing *
; *           this value may exceed the maximum.  When decrementing, it may   *
; *           go negative.                                                    *
; *                                                                           *
; *****************************************************************************
add_step
        movf    fstep_0,w         ; Get low byte of the increment
        addwf   freq_0,f          ; Add it to the low byte of freq
        btfss   STATUS,B_C        ; Any carry?
        goto    add1              ; No, add next byte
        incfsz  freq_1,f          ; Ripple carry up to the next byte
        goto    add1              ; No new carry, add next byte
        incfsz  freq_2,f          ; Ripple carry up to the next byte
        goto    add1              ; No new carry, add next byte
        incf    freq_3,f          ; Ripple carry up to the highest byte
add1
        movf    fstep_1,w         ; Get the next increment byte
        addwf   freq_1,f          ; Add it to the next higher byte
        btfss   STATUS,B_C        ; Any carry?
        goto    add2              ; No, add next byte
        incfsz  freq_2,f          ; Ripple carry up to the next byte
        goto    add2              ; No new carry, add next byte
        incf    freq_3,f          ; Ripple carry up to the highest byte
add2
        movf    fstep_2,w         ; Get the next to most significant increment
        addwf   freq_2,f          ; Add it to the freq byte
        btfss   STATUS,B_C        ; Any carry?
        goto    add3              ; No, add last byte
        incf    freq_3,f          ; Ripple carry up to the highest byte
add3
        movf    fstep_3,w         ; Get the most significant increment byte
        addwf   freq_3,f          ; Add it to the most significant freq
        return                    ; Return to the caller
;
; *****************************************************************************
; *                                                                           *
; * Purpose:  Check if freq exceeds the upper limit.                          *
; *                                                                           *
; *   Input:  The 32 bit values in freq                                       *
; *                                                                           *
; *  Output:  If freq is below the limit, it is unchanged.  Otherwise, it is  *
; *           set to equal the upper limit.                                   *
; *                                                                           *
; *****************************************************************************
;
check_add

; Check the most significant byte.

        movlw   0xFF-limit_3      ; Get (FF - limit of high byte)
        addwf   freq_3,w          ; Add it to the current high byte
        btfsc   STATUS,B_C        ; Was high byte too large?
        goto    set_max           ; Yes, apply limit
        movlw   limit_3           ; Get high limit value
        subwf   freq_3,w          ; Subtract the limit value
        btfss   STATUS,B_C        ; Are we at the limit for the byte?
        goto    exit1             ; No, below.  Checks are done.

; Check the second most significant byte.

        movlw   0xFF-limit_2      ; Get (FF - limit of next byte)
        addwf   freq_2,w          ; Add it to the current byte
        btfsc   STATUS,B_C        ; Is the current value too high?
        goto    set_max           ; Yes, apply the limit
        movlw   limit_2           ; Second limit byte
        subwf   freq_2,w          ; Subtract limit value
        btfss   STATUS,B_C        ; Are we at the limit for the byte?
        goto    exit1             ; No, below.  Checks are done.

; Check the third most significant byte.
 
        movlw   0xFF-limit_1      ; Get (FF - limit of next byte)
        addwf   freq_1,w          ; Add it to the current byte
        btfsc   STATUS,B_C        ; Is the current value too high?
        goto    set_max           ; Yes, apply the limit
        movlw   limit_1           ; Third limit byte
        subwf   freq_1,w          ; Subtract limit value
        btfss   STATUS,B_C        ; Are we at the limit for the byte?
        goto    exit1             ; No, below.  Checks are done.
 
; Check the least significant byte.

        movlw   limit_0           ; Fourth limit byte
        subwf   freq_0,w          ; Subtract limit value
        btfss   STATUS,B_C        ; Are we at the limit for the byte?
        goto    exit1             ; No, below.  Checks are done.
set_max
        movlw   limit_0           ; Get least significant limit
        movwf   freq_0            ; Set it in freq
        movlw   limit_1           ; Get the next byte limit
        movwf   freq_1            ; Set it in freq_1
        movlw   limit_2           ; Get the next byte limit
        movwf   freq_2            ; Set it in freq_2
        movlw   limit_3           ; Get the most significant limit
        movwf   freq_3            ; Set it in freq_3
exit1
        return                    ; Return to the caller
;
; *****************************************************************************
; *                                                                           *
; * Purpose:  Subtract the increment step from freq, checking that it does    *
; *           not go below zero.                                              *
; *                                                                           *
; *   Input:  The values in fstep and freq.                                   *
; *                                                                           *
; *  Output:  The updated value in freq.                                      *
; *                                                                           *
; *****************************************************************************
;
sub_step
        comf    fstep_0,f         ; Subtraction of fstep from
        comf    fstep_1,f         ; freq is done by adding the
        comf    fstep_2,f         ; twos compliment of fstep to
        comf    fstep_3,f         ; freq.
        incfsz  fstep_0,f         ; Increment last byte
        goto    comp_done         ; Non-zero, continue
        incfsz  fstep_1,f         ; Increment next byte
        goto    comp_done         ; Non-zero, continue
        incfsz  fstep_2,f         ; Increment next byte
        goto    comp_done         ; Non-zero, continue
        incf    fstep_3,f         ; Increment the high byte
comp_done
        call    add_step          ; Add the compliment to do the subtraction
;
;       If the frequency has gone negative, clear it to zero.
;
        btfss   freq_3,7          ; Is high order frequency byte "negative"?   
        goto    exit2             ; No, keep going
set_min
        clrf    freq_0            ; Yes, set the frequency to zero
        clrf    freq_1            ; 
        clrf    freq_2            ; 
        clrf    freq_3            ; 
exit2
        return                    ; Return to the caller


;==============================================================================
;
;	SECTION 2
;	
;	DDS WORD CALCULATION AND COMMUNICATION ROUTINES
;
;==============================================================================


; *****************************************************************************
; *                                                                           *
; * Purpose:  Multiply the 32 bit number for oscillator frequency times the   *
; *           32 bit number for the displayed frequency (after IF Offset).    *
; *                                                                           *
; *                                                                           *
; *   Input:  The reference oscillator value in osc_3 ... osc_0 and the       *
; *           current frequency stored in freq_3 ... freq_0.  The reference   *
; *           oscillator value is treated as a fixed point real, with a 24    *
; *           bit mantissa.                                                   *
; *                                                                           *
; *  Output:  The result is stored in AD9850_3 ... AD9850_0.                  *
; *                                                                           *
; *****************************************************************************
;
calc_dds_word
        clrf    AD9850_0          ; Clear the AD9850 control word bytes
        clrf    AD9850_1          ; 
        clrf    AD9850_2          ; 
        clrf    AD9850_3          ; 
        clrf    AD9850_4          ; 
        movlw   0x20              ; Set count  to 32   (4 osc bytes of 8 bits)
        movwf   mult_count        ; Keep running count
        movf    osc_0,w           ; Move the four osc bytes
        movwf   osc_temp_0        ; to temporary storage for this multiply
        movf    osc_1,w           ; (Don't disturb original osc bytes)
        movwf   osc_temp_1        ; 
        movf    osc_2,w           ; 
        movwf   osc_temp_2        ; 
        movf    osc_3,w           ; 
        movwf   osc_temp_3        ; 
mult_loop
        bcf     STATUS,B_C        ; Start with Carry clear
        btfss   osc_temp_0,0      ; Is bit 0 (Least Significant bit) set?
        goto    noAdd             ; No, don't need to add freq term to total
        movf    DDS_freq_0,w      ; Yes, get the freq_0 term
        addwf   AD9850_1,f        ; and add it in to total
        btfss   STATUS,B_C        ; Does this addition result in a carry?
        goto    add7              ; No, continue with next freq term
        incfsz  AD9850_2,f        ; Yes, add one and check for another carry
        goto    add7              ; No, continue with next freq term
        incfsz  AD9850_3,f        ; Yes, add one and check for another carry
        goto    add7              ; No, continue with next freq term
        incf    AD9850_4,f        ; Yes, add one and continue
add7
        movf    DDS_freq_1,w      ; Use the freq_1 term
        addwf   AD9850_2,f        ; Add freq term to total in correct position
        btfss   STATUS,B_C        ; Does this addition result in a carry?
        goto    add8              ; No, continue with next freq term
        incfsz  AD9850_3,f        ; Yes, add one and check for another carry
        goto    add8              ; No, continue with next freq term
        incf    AD9850_4,f        ; Yes, add one and continue
add8
        movf    DDS_freq_2,w          ; Use the freq_2 term
        addwf   AD9850_3,f        ; Add freq term to total in correct position
        btfss   STATUS,B_C        ; Does this addition result in a carry?
        goto    add9              ; No, continue with next freq term
        incf    AD9850_4,f        ; Yes, add one and continue
add9
        movf    DDS_freq_3,w          ; Use the freq_3 term
        addwf   AD9850_4,f        ; Add freq term to total in correct position
noAdd
        rrf     AD9850_4,f        ; Shift next multiplier bit into position
        rrf     AD9850_3,f        ; Rotate bits to right from byte to byte
        rrf     AD9850_2,f        ; 
        rrf     AD9850_1,f        ; 
        rrf     AD9850_0,f        ; 
        rrf     osc_temp_3,f      ; Shift next multiplicand bit into position
        rrf     osc_temp_2,f      ; Rotate bits to right from byte to byte
        rrf     osc_temp_1,f      ; 
        rrf     osc_temp_0,f      ; 
        decfsz  mult_count,f      ; One more bit has been done.  Are we done?
        goto    mult_loop         ; No, go back to use this bit
        clrf    AD9850_4          ; Yes, clear _4.  Answer is in bytes _3 .. _0
        return                    ; Done.
;
; *****************************************************************************
; *                                                                           *
; * Purpose:  This routine sends the AD9850 control word to the DDS chip      *
; *           using a serial data transfer.                                   *
; *                                                                           *
; *   Input:  AD9850_4 ... AD9850_0                                           *
; *                                                                           *
; *  Output:  The DDS chip register is updated.                               *
; *                                                                           *
; *									      *
; *									      *
; *****************************************************************************

send_dds_word
        movlw   AD9850_0          ; Point FSR at AD9850
        movwf   FSR               ; 
next_byte
        movf    INDF,w            ; 
        movwf   byte2send         ; 
;
;Send the byte bit by bit
;bit 0        	
		rrf     byte2send,f       ; Test if next bit is 1 or 0
        	btfss   STATUS,B_C        ; Was it zero?
        	goto    set00             ; Yes, send zero
        	bsf     PortD,DDS_data    ; No, send one
		goto	sendbit0
set00   	bcf     PortD,DDS_data    ; Send zero
sendbit0        bsf     PortD,DDS_clk     ; Toggle write clock
        	bcf     PortD,DDS_clk     ;
;bit 1
        	rrf     byte2send,f       ; Test if next bit is 1 or 0
        	btfss   STATUS,B_C        ; Was it zero?
        	goto    set01             ; Yes, send zero
        	bsf     PortD,DDS_data    ; No, send one
		goto	sendbit1
set01   	bcf     PortD,DDS_data    ; Send zero
sendbit1        bsf     PortD,DDS_clk     ; Toggle write clock
        	bcf     PortD,DDS_clk     ;
;bit 2
        	rrf     byte2send,f       ; Test if next bit is 1 or 0
        	btfss   STATUS,B_C        ; Was it zero?
        	goto    set02             ; Yes, send zero
        	bsf     PortD,DDS_data    ; No, send one
		goto	sendbit2
set02   	bcf     PortD,DDS_data    ; Send zero
sendbit2        bsf     PortD,DDS_clk     ; Toggle write clock
        	bcf     PortD,DDS_clk     ;
;bit 3
        	rrf     byte2send,f       ; Test if next bit is 1 or 0
        	btfss   STATUS,B_C        ; Was it zero?
        	goto    set03             ; Yes, send zero
        	bsf     PortD,DDS_data    ; No, send one
		goto	sendbit3
set03   	bcf     PortD,DDS_data    ; Send zero
sendbit3        bsf     PortD,DDS_clk     ; Toggle write clock
        	bcf     PortD,DDS_clk     ;
;bit 4
        	rrf     byte2send,f       ; Test if next bit is 1 or 0
        	btfss   STATUS,B_C        ; Was it zero?
        	goto    set04             ; Yes, send zero
        	bsf     PortD,DDS_data    ; No, send one
		goto	sendbit4
set04	  	bcf     PortD,DDS_data    ; Send zero
sendbit4        bsf     PortD,DDS_clk     ; Toggle write clock
        	bcf     PortD,DDS_clk     ;
;bit 5
        	rrf     byte2send,f       ; Test if next bit is 1 or 0
        	btfss   STATUS,B_C        ; Was it zero?
        	goto    set05             ; Yes, send zero
        	bsf     PortD,DDS_data    ; No, send one
		goto	sendbit5
set05    	bcf     PortD,DDS_data    ; Send zero
sendbit5        bsf     PortD,DDS_clk     ; Toggle write clock
        	bcf     PortD,DDS_clk     ;
;bit 6
        	rrf     byte2send,f       ; Test if next bit is 1 or 0
        	btfss   STATUS,B_C        ; Was it zero?
        	goto    set06             ; Yes, send zero
        	bsf     PortD,DDS_data    ; No, send one
		goto	sendbit6
set06   	bcf     PortD,DDS_data    ; Send zero
sendbit6        bsf     PortD,DDS_clk     ; Toggle write clock
        	bcf     PortD,DDS_clk     ;
;bit 7
        	rrf     byte2send,f       ; Test if next bit is 1 or 0
        	btfss   STATUS,B_C        ; Was it zero?
        	goto    set07             ; Yes, send zero
        	bsf     PortD,DDS_data    ; No, send one
		goto	sendbit7
set07   	bcf     PortD,DDS_data    ; Send zero
sendbit7        bsf     PortD,DDS_clk     ; Toggle write clock
        	bcf     PortD,DDS_clk     ;

        incf    FSR,f             ; Start the next byte unless finished
        movlw   AD9850_4+1        ; Next byte (past the end)
        subwf   FSR,w             ; 
        btfss   STATUS,B_C        ;
        goto    next_byte         ;
        bsf     PortD,DDS_load    ; Send load signal to the AD9850
        bcf     PortD,DDS_load    ; 
        return                    ;

;==============================================================================
;
;	SECTION 3
;	
;	NUMERICAL CONVERSION ROUTINES FOR DDS AND LCD SECTIONS
;
;==============================================================================


; *****************************************************************************
; *                                                                           *
; * Purpose:  This subroutine converts a 32 bit binary number to a 10 digit   *
; *           BCD number.  The input value taken from freq(0 to 3) is         *
; *           preserved.  The output is in BCD(0 to 4), each byte holds =>    *
; *           (hi_digit,lo_digit), most significant digits are in BCD_4.      *
; *           This routine is a modified version of one described in          *
; *           MicroChip application note AN526.                               *
; *                                                                           *
; *   Input:  The value in freq_0 ... freq_3                                  *
; *                                                                           *
; *  Output:  The BCD number in BCD_0 ... BCD_4                               *
; *                                                                           *
; *****************************************************************************
;
bin2BCD
        movlw   0x20              ; Set loop counter
        movwf   BCD_count         ;   to 32
        clrf    BCD_0             ; Clear output
        clrf    BCD_1             ;   "     "
        clrf    BCD_2             ;   "     "
        clrf    BCD_3             ;   "     "
        clrf    BCD_4             ;   "     "
bin_loop
        bcf     STATUS,B_C        ; Clear carry bit in STATUS
;
; Rotate bits in freq bytes.  Move from LS byte (freq_0) to next byte (freq_1).
; Likewise, move from freq_1 to freq_2 and from freq_2 to freq_3.
;
        rlf     freq_0,f          ; Rotate left, 0 -> LS bit, MS bit -> Carry
        rlf     freq_1,f          ; Rotate left, Carry->LS bit, MS bit->Carry
        rlf     freq_2,f          ; Rotate left, Carry->LS bit, MS bit->Carry
        rlf     freq_3,f          ; Rotate left, Carry->LS bit, MS bit->Carry
        btfsc   STATUS,B_C        ; Is Carry clear? If so, skip next instruction
        bsf     freq_0,0          ; Carry is set so wrap and set bit 0 in freq_0
;
; Build BCD bytes. Move into LS bit of BCD bytes (LS of BCD_0) from MS bit of
; freq_3 via the Carry bit.  
;
        rlf     BCD_0,f           ; Rotate left, Carry->LS bit, MS bit->Carry
        rlf     BCD_1,f           ; Rotate left, Carry->LS bit, MS bit->Carry
        rlf     BCD_2,f           ; Rotate left, Carry->LS bit, MS bit->Carry
        rlf     BCD_3,f           ; Rotate left, Carry->LS bit, MS bit->Carry
        rlf     BCD_4,f           ; Rotate left, Carry->LS bit, MS bit->Carry
        decf    BCD_count,f       ; Decrement loop count
        btfss   STATUS,B_Z        ; Is loop count now zero?
        goto    adjust            ; No, go to adjust
        return                    ; Yes, EXIT 
; ============================================================================
adjust  ; Internal subroutine, called by bin2BCD main loop only
; 
; As BCD bytes are being built, make sure the nibbles do not grow larger than 9. 
; If a nibble gets larger than 9, increment to next higher nibble.  
; (If the LS nibble of a byte overflows, increment the MS nibble of that byte.)
; (If the MS nibble of a byte overflows, increment the LS nibble of next byte.)
;
        movlw   BCD_0             ; Get pointer to BCD_0
        movwf   FSR               ; Put pointer in FSR for indirect addressing
        call    adj_BCD           ; 
        incf    FSR,f             ; Move indirect addressing pointer to BCD_1
        call    adj_BCD           ; 
        incf    FSR,f             ; Move indirect addressing pointer to BCD_2
        call    adj_BCD           ; 
        incf    FSR,f             ; Move indirect addressing pointer to BCD_3
        call    adj_BCD           ; 
        incf    FSR,f             ; Move indirect addressing pointer to BCD_4
        call    adj_BCD           ; 
        goto    bin_loop          ; Back to main loop of bin2BCD
; ============================================================================
adj_BCD  ; Internal subroutine, called by adjust only
        movlw   3                 ; Add 3
        addwf   INDF,w            ;   to LS digit
        movwf   BCD_temp          ; Save in temp
        btfsc   BCD_temp,3        ; Is LS digit + 3 > 7  (Bit 3 set)
        movwf   INDF              ; Yes, save incremented value as LS digit
        movlw   0x30              ; Add 3
        addwf   INDF,w            ;   to MS digit
        movwf   BCD_temp          ; Save as temp
        btfsc   BCD_temp,7        ; Is MS digit + 3 > 7  (Bit 7 set)
        movwf   INDF              ; Yes, save incremented value as MS digit
        return                    ; Return to adjust subroutine


;
; *****************************************************************************
; IF Offset Routine
; 
; This uses modified versions of the 32 bit add and subtract routines to shift
; the DDS frequency data by the value held if the IF_Add and IF_Sub constants.
; Negative results in the subtraction process are made positive by a 
; two's compliment subtroutine. This produces a positive value which is 
; the difference between the displayed frequency and the IF frequency.
;
; *****************************************************************************
;
;
;
IF_Offset			

	movf 	freq_0,w		; Copy current "freq" into "DDS_freq" variables
	movwf	DDS_freq_0		; to allow offset to be added without
	movf 	freq_1,w		; affecting display value which is based
	movwf	DDS_freq_1		; upon content of "freq"
	movf 	freq_2,w		
	movwf	DDS_freq_2		
	movf 	freq_3,w		; If IF Offset not needed the unmodified
	movwf	DDS_freq_3		; value of DDS_freq will provide a direct output

	btfss	PortC,IF_Offset_Use	; Test Offset Enable line
	return 				; IF Offset not required, load unmodified freq
					; and return

	; IF Offset required, commence conversion

		btfss 	PortC,5		; Test state of IF offset switch
		goto 	sub_IF		; Low so subtract
		goto	add_IF		; High so add 

; *****************************************************************************
; *                                                                           *
; * Purpose:  This routine adds the 32 bit value of fstep to the 32 bit       *
; *           value in freq.  When incrementing, the fstep value is a         *
; *           positive integer.  When decrementing, fstep is the complement   *
; *           of the value being subtracted.                                  *
; *                                                                           *
; *   Input:  The 32 bit values in fstep and freq                             *
; *                                                                           *
; *  Output:  The sum of fstep and freq is stored in DDS_freq.                *
; *                                                                           *
; *****************************************************************************


add_IF
        movlw   IF_Add_0           ; Get low byte of the IF_Add increment
        addwf   DDS_freq_0,f       ; Add it to the low byte of freq
        btfss   STATUS,B_C         ; Any carry?
        goto    IFadd1             ; No, add next byte
        incfsz  DDS_freq_1,f       ; Ripple carry up to the next byte
        goto    IFadd1             ; No new carry, add next byte
        incfsz  DDS_freq_2,f       ; Ripple carry up to the next byte
        goto    IFadd1             ; No new carry, add next byte
        incf    DDS_freq_3,f       ; Ripple carry up to the highest byte
IFadd1
        movlw   IF_Add_1           ; Get the next increment byte
        addwf   DDS_freq_1,f       ; Add it to the next higher byte
        btfss   STATUS,B_C         ; Any carry?
        goto    IFadd2             ; No, add next byte
        incfsz  DDS_freq_2,f       ; Ripple carry up to the next byte
        goto    IFadd2             ; No new carry, add next byte
        incf    DDS_freq_3,f       ; Ripple carry up to the highest byte
IFadd2
        movlw   IF_Add_2           ; Get the next to most significant increment
        addwf   DDS_freq_2,f       ; Add it to the freq byte
        btfss   STATUS,B_C         ; Any carry?
        goto    IFadd3             ; No, add last byte
        incf    DDS_freq_3,f       ; Ripple carry up to the highest byte
IFadd3
        movlw   IF_Add_3           ; Get the most significant increment byte
        addwf   DDS_freq_3,f       ; Add it to the most significant freq
        return		           ; Finished

; *****************************************************************************
; *                                                                           *
; * Purpose:  Subtract the IF from freq, checking that it does                *
; *           not go below zero.                                              *
; *                                                                           *
; *   Input:  The values in IF and DDS_freq.                                  *
; *                                                                           *
; *  Output:  The updated value in DDS_freq.                                  *
; *                                                                           *
; *****************************************************************************

sub_IF
        comf    DDS_freq_0,f         ; Subtraction of fstep from
        comf    DDS_freq_1,f         ; freq is done by adding the
        comf    DDS_freq_2,f         ; twos compliment of freq
        comf    DDS_freq_3,f         ; to IF
        incfsz  DDS_freq_0,f         ; Increment last byte
        goto    IF_comp_done         ; Non-zero, continue
        incfsz  DDS_freq_1,f         ; Increment next byte
        goto    IF_comp_done         ; Non-zero, continue
        incfsz  DDS_freq_2,f         ; Increment next byte
        goto    IF_comp_done         ; Non-zero, continue
        incf    DDS_freq_3,f         ; Increment the high byte
IF_comp_done
;
;	Now add the compliment of DDS_freq and IF_Sub
;
	movlw   IF_Sub_0           ; Get low byte of the increment
        addwf   DDS_freq_0,f       ; Add it to the low byte of freq
        btfss   STATUS,B_C         ; Any carry?
        goto    IFSadd1            ; No, add next byte
        incfsz  DDS_freq_1,f       ; Ripple carry up to the next byte
        goto    IFSadd1             ; No new carry, add next byte
        incfsz  DDS_freq_2,f       ; Ripple carry up to the next byte
        goto    IFSadd1             ; No new carry, add next byte
        incf    DDS_freq_3,f       ; Ripple carry up to the highest byte
IFSadd1
        movlw   IF_Sub_1           ; Get the next increment byte
        addwf   DDS_freq_1,f       ; Add it to the next higher byte
        btfss   STATUS,B_C         ; Any carry?
        goto    IFSadd2            ; No, add next byte
        incfsz  DDS_freq_2,f       ; Ripple carry up to the next byte
        goto    IFSadd2             ; No new carry, add next byte
        incf    DDS_freq_3,f       ; Ripple carry up to the highest byte
IFSadd2
        movlw   IF_Sub_2           ; Get the next to most significant increment
        addwf   DDS_freq_2,f       ; Add it to the freq byte
        btfss   STATUS,B_C         ; Any carry?
        goto    IFSadd3            ; No, add last byte
        incf    DDS_freq_3,f       ; Ripple carry up to the highest byte
IFSadd3
        movlw   IF_Sub_3           ; Get the most significant increment byte
        addwf   DDS_freq_3,f       ; Add it to the most significant freq
;
;       If the frequency has gone negative, two's compliment it.
;
        btfss   DDS_freq_3,7      ; Is high order frequency byte "negative"?   
        return		          ; No, exit
IF_comp
        comf    DDS_freq_0,f          ; Yes, two's compliment result
        comf    DDS_freq_1,f          ; to make positive difference
        comf    DDS_freq_2,f          ; 
        comf    DDS_freq_3,f          ; 
	incfsz  DDS_freq_0,f          ; Increment last byte
        return		              ; Non-zero, subtract finished
        incfsz  DDS_freq_1,f          ; Increment next byte
        return  	              ; Non-zero, subtract finished
        incfsz  DDS_freq_2,f          ; Increment next byte
        return  	              ; Non-zero, subtract finished
        incf    DDS_freq_3,f          ; Increment the high byte
	return			      ; Subtract finished

               

;==============================================================================
;
;	SECTION 4
;	
;	LCD CONTROL AND COMMUNICATION ROUTINES
;
;==============================================================================

; *****************************************************************************
; *                                                                           *
; * Purpose:  Power on initialization of Liquid Crystal Display.  The LCD     *
; *           controller chip must be equivalent to an Hitachi 44780.  The    *
; *           LCD is assumed to be a 16 X 2 display.                          *
; *                                                                           *
; *   Input:  None                                                            *
; *                                                                           *
; *  Output:  None                                                            *
; *                                                                           *
; *****************************************************************************
;
init_LCD
        call    wait_64ms        ; Wait for LCD to power up
        movlw   0x30              ; LCD init instruction (First)
        bsf     PortD,LCD_e       ; Set the LCD E line high,
	nop
	nop
	nop
	nop
	movwf   PortB             ; Send to LCD via RB7..RB0
        call    wait_64ms         ;   wait a "long" time,
        bcf     PortD,LCD_e       ;   and then Clear E 
        movlw   0x30              ; LCD init instruction (Second)
        bsf     PortD,LCD_e       ; Set E high,
	nop
	nop
	nop
	nop
        movwf   PortB             ; Send to LCD via RB7..RB0
        call    wait_32ms         ;   wait a while,
        bcf     PortD,LCD_e       ;   and then Clear E 
        movlw   0x30              ; LCD init instruction (Third)
        bsf     PortD,LCD_e       ; Set E high,
	nop
	nop
	nop
	nop
	movwf   PortB             ; Send to LCD via RB7..RB0
	nop
	nop
	nop
	nop
        call    wait_32ms         ;   wait a while,
        bcf     PortD,LCD_e       ;   and then Clear E
        movlw   0x38              ; 8 bit mode instruction, 
        call    cmnd2LCD          ; Send command in w to LCD
        movlw   0x08              ; Clear and reset cursor
        call    cmnd2LCD          ; Send command in w to LCD
        movlw   0x0C              ; Set cursor to move right, no shift
        call    cmnd2LCD          ; Send command in w to LCD
        movlw   0x06 		  ; Set cursor to move right, no shift
        call    cmnd2LCD          ; Send command in w to LCD
        movlw   0x01              ; Display on, cursor and blink off
        call    cmnd2LCD          ; Send command in w to LCD
        return                    ; 
;
; *****************************************************************************
; *                                                                           *
; * Purpose:  Display the frequency setting on the LCD.                       *
; *                                                                           *
; *   Input:  The values in BCD_3 ... BCD_0                                   *
; *                                                                           *
; *  Output:  The number displayed on the LCD                                 *
; *                                                                           *
; *****************************************************************************
;
show_freq
        movlw   0x80              ; Point the LCD to first LCD digit location
        call    cmnd2LCD          ; Send starting digit location to LCD
;
; Running 8 bit mode, split BCD into bytes into nibbles and format
; with ASCII offset of 30xxxx and send as one byte.
;
; Extract and send "XXXX" from byte containing "XXXXYYYY"
;  - Swap halves to get YYYYXXXX
;  - Mask with 0x0F to get 0000XXXX
;  - Add ASCII bias (0030XXXX)
;
        swapf   BCD_3,w           ; Swap 10MHz BCD digit into lower nibble of W
        andlw   0x0F              ; Mask for lower nibble only       (0000XXXX)
	btfsc	STATUS,B_Z	  ; Is the digit zero?
	goto	D10Blank	  ; Yes
D10NoBlank
        addlw   0x30              ; Add offset for ASCII char set    (0030XXXX)
        call    data2LCD          ; Send byte in W to LCD
	goto	D1MHz		  ; Next digit
D10Blank
	movlw	' '		  ; Load code for space
	call	data2LCD
;
; Extract and send "YYYY" from byte containing "XXXXYYYY"
;   - Mask with 0x0F to get 0000YYYY
;   - Add offset for ASCII character set in LCD  (0030YYYY)
;
D1MHz
        movf    BCD_3,w           ; Put 1MHz BCD digit into lower nibble of W
        andlw   0x0F              ; Mask for lower nibble only       (0000YYYY)
        addlw   0x30              ; Add offset for ASCII char set    (0030YYYY)
        call    data2LCD          ; Send byte in W to LCD
; 
        movlw   '.'               ; Send a period
        call    data2LCD          ; Send byte in W to LCD
;
        swapf   BCD_2,w           ; Swap 100KHz BCD digit into lower nibble of W
        andlw   0x0F              ; Mask for lower nibble only       (0000XXXX)
        addlw   0x30              ; Add offset for ASCII char set    (0030XXXX)
        call    data2LCD          ; Send byte in W to LCD
;
        movf    BCD_2,w           ; Put 10KHz BCD digit into lower nibble of W
        andlw   0x0F              ; Mask for lower nibble only       (0000YYYY)
        addlw   0x30              ; Add offset for ASCII char set    (0030YYYY)
        call    data2LCD          ; Send byte in W to LCD
;
        swapf   BCD_1,w           ; Swap 1KHz BCD digit into lower nibble of W
        andlw   0x0F              ; Mask for lower nibble only       (0000XXXX)
        addlw   0x30              ; Add offset for ASCII char set    (0030XXXX)
        call    data2LCD          ; Send byte in W to LCD
;
        movlw   ','               ; Send a period
        call    data2LCD          ; Send data byte in W to LCD

        movf    BCD_1,w           ; Put 100 Hz BCD digit into lower nibble of W
        andlw   0x0F              ; Mask for lower nibble only       (0000YYYY)
        addlw   0x30              ; Add offset for ASCII char set    (0030YYYY)
        call    data2LCD          ; Send data byte in W to LCD
;
        swapf   BCD_0,w           ; Swap 10 Hz BCD digit into lower nibble of W
        andlw   0x0F              ; Mask for lower nibble only       (0000XXXX)
        addlw   0x30              ; Add offset for ASCII char set    (0030XXXX)
        call    data2LCD          ; Send data byte in W to LCD
;
;        movf    BCD_0,w           ; Put 1 Hz BCD digit into lower nibble of W
;        andlw   0x0F              ; Mask for lower nibble only       (0000YYYY)
;        addlw   0x30              ; Add offset for ASCII char set    (0030YYYY)
;        call    data2LCD          ; Send byte in W to LCD
;
;        movlw   ' '               ; Send a space
;        call    data2LCD          ;   to LCD
;
        movlw   'M'               ; Send a 'M'
        call    data2LCD          ;   to LCD
;
        movlw   'H'               ; Send an "H"
        call    data2LCD          ;   to LCD
;
        movlw   'z'               ; Send a 'z'
        call    data2LCD          ;   to LCD
;
        return                    ;


;=============================================================================
;
;	S-Meter Routine
;
;	The receiver AGC line and BIAS (Threhold voltage) is sampled by the A to D 
;	and the difference is ranged by comparison with the "S" constants. These 
; 	are user definable to allow the S-Meter to be calibrated to the AGC law, 
;	which could be non linear.
;
;	The S point value is stored in S_point. This is used to count the number
;	of blocks written to display line 2.
;
;=============================================================================

S_Meter

; Measure AGC System Bias Voltage
	movlw	b'01001001'	; Channel 1
	movwf	ADCON0
	bsf	ADCON0,GO	; Start A to D
	call	wait_1ms	; Pause
Wait_BIAS
	btfsc	ADCON0,GO 	;	
	goto	Wait_BIAS
	movf	ADRESH,w	; Save A to D result
	movwf	AGC_BIAS
; Measure AGC Voltage
	movlw	b'01000001'	; Channel 0
	movwf	ADCON0
	bsf	ADCON0,GO	; Start A to D
	call	wait_1ms	; Pause
Wait_AGC
	btfsc	ADCON0,GO 	;	
	goto	Wait_AGC
	movf	ADRESH,w	; Save A to D result
	subwf	AGC_BIAS,w	; Get difference between AGC voltage and BIAS
				; AGC Threshold voltage
	movwf	AGC_level
	clrf	S_point		; Initialise table record counter
	movlw	0xC0		; Point to start of bar graph on line 2
	call	cmnd2LCD	
	movlw	0x0D		; Load count with 13 dec (S1..S9+40)
	movwf	count
	bcf	Flag,bar_flag	
Scale
	movf 	S_point,w	; Point to value in S_Table
	call	S_Table		; Retrieve constant
	subwf	AGC_level,w	; Compare to A to D sample
	btfss	STATUS,B_C	; Is the result negative?
	goto	blank_bar	; Yes, goto write a blank
	movlw	0xFF		; No, write a block
	call	data2LCD	; Send to display
	incf	S_point,f	; Increment table address
	goto	progress_check	; 
blank_bar			
	btfsc	Flag,bar_flag	; Check flag to see if is first blank (filled with S number)
	goto	blank		; Yes, digit displayed continue with blanks
	movf	S_point,w	; No, load up current S value
	addlw   0x30		; Add ASCII offset
	bsf	Flag,bar_flag	; Set flag to mark this operation has taken place
	call	data2LCD	; Send S digit to display
	movlw	0x0A		; Are we over S9?
	subwf	S_point,w	; If < 9 answer will be negative
	btfsc	STATUS,B_C
	goto	S9_over		; Yes, Special write required
	goto	Scale		; No, go round again
blank	
	movlw	0x5F		; Move blank symbol to w
	call	data2LCD	; Send to display
	incf	S_point,f	; Increment table address

progress_check
	decfsz	count,f		; Count each write
	goto	Scale		; Go round again
	return
S9_over				; Special write case e.g. S9+40
	movlw	0xC9		; Point to S9 position
	call	cmnd2LCD	; Send address
	movlw	'9'		; Send a"9"
	call	data2LCD	
	movlw	'+'		; Send a "+"
	call	data2LCD
	movlw	0x09
	subwf	S_point,w	; Get 10dB value
	addlw	0x30		; Add ASCII offset
	call	data2LCD	; Send it
	movlw	'0'		; Send a zero
	call	data2LCD	; 
	return			; Finished, return to caller

; *****************************************************************************
; *                                                                           *
; * Purpose:  Check if LCD is done with the last operation.                   *
; *           This subroutine polls the LCD busy flag to determine if         *
; *           previous operations are completed.                              *
; *****************************************************************************
 
busy_check
	clrf	STATUS
        clrf    PortB             ; Clear all outputs on PortB
	Bank1			  ; Switch to bank 1 for Tristate operation
        movlw   0xFF	          ; Set port B to inputs
        movwf   TRISB             ; via Tristate
	Bank0			  ; Switch back to bank 0
        bcf     PortD,LCD_rs      ; Set up LCD for Read Busy Flag (RS = 0) 
        bsf     PortD,LCD_rw      ; Set up LCD for Read (RW = 1)  
	nop
	nop
LCD_is_busy
        bsf     PortD,LCD_e       ; Set E high
	nop
	nop
        btfss   PortB,7	        ; Is Busy Flag (RC7) in saved byte clear?
	goto	LCD_is_free
	nop
	nop
        bcf     PortD,LCD_e       ; Drop E again
	nop
	nop
	goto LCD_is_busy
LCD_is_free
	bcf	PortD,LCD_e
	bcf	PortD,LCD_rw
        return                    ; 

; *****************************************************************************
; * Purpose:  Send Command or Data byte to the LCD                            *
; *           Entry point cmnd2LCD:  Send a Command to the LCD                *
; *           Entry Point data2LCD:  Send a Data byte to the LCD              *
; *                                                                           *
; *   Input:  W has the command or data byte to be sent to the LCD.           *
; *                                                                           *
; *  Output:  None                                                            *
; *****************************************************************************

cmnd2LCD   ; ****** Entry point ******
        movwf   LCD_char          ; Save byte to write to LCD
        bcf    	Flag,rs_flag  ; Remember to clear RS  (clear rs_value)   
        bcf     PortD,LCD_rs      ; Set RS for Command to LCD
        goto    write2LCD         ; Go to common code
data2LCD   ; ****** Entry point ********
        movwf   LCD_char          ; Save byte to write to LCD
        bsf     Flag,rs_flag  	  ; Remember to set RS (set bit 0 of rs_value)
        bsf     PortD,LCD_rs      ; Set RS for Data to LCD
write2LCD
        call    busy_check        ; Check to see if LCD is ready for new data
        clrf    PortB             ; Clear all of Port B (inputs and outputs)
	Bank1			  ; Switch to bank 1 for Tristate operation
        movlw   0x00              ; Set up to enable PortB data pins
        movwf   TRISB             ; All pins (RB0..RB7) are back to outputs
	Bank0		          ; Switch to bank 0
        bcf     PortD,LCD_rw      ; Set LCD back to Write mode  (RW = 0)
	nop
	nop
        bcf     PortD,LCD_rs      ; Guess RS should be clear              
	nop
	nop
        btfsc   Flag,rs_flag  	  ; Should RS be clear?  (is bit 0 == 0?) 
        bsf     PortD,LCD_rs      ; No, set RS                            
;
; Transfer byte
;
	nop
	nop
        movf    LCD_char,w        ; Put byte of data into W
        bsf     PortD,LCD_e       ; Pulse the E line high,
	nop
	nop
	movwf	PortB
	nop
	nop			  ;
        bcf     PortD,LCD_e       ;   and drop it again
	return


;==============================================================================
;
;	SECTION 5
;	
;	MISCELLANEOUS EEPROM READ/WRITE, CALIBRATE AND DELAY ROUTINES
;
;==============================================================================
;
; *****************************************************************************
; *                                                                           *
; * Purpose:  This routine is entered at start up if the calibrate line is    *
; *           low.  "10,000.00 CAL" is displayed on the LCD, and the  	      *
; *           the DDS chip is programmed to produce 10 MHz, based on the      *
; *           osc value stored in the EEPROM.  As long as the button is       *
; *           pressed, the osc value is slowly altered to allow the output    *
; *           to be trimmed to exactly 10 MHz.  Once the encoder is turned    *
; *           after the button is released, the new osc value is stored in    *
; *           the EEPROM and normal operation begins.                         *
; *                                                                           *
; *   Input:  The original osc constant in EEPROM                             *
; *                                                                           *
; *  Output:  The corrected osc constant in EEPROM                            *
; *                                                                           *
; *****************************************************************************
;
calibrate

	movlw	0x2C		  ; Address CAL entry on Band Table
	movwf	band	          ; Set band table pointer to 44 (11th record)
	call	get_band	  ; Extract Cal freq and filter decode from table
	call	Cal_msg		  ; Display "Calibrate" on Line 2
	
	; freq now contains Cal freq

	; Get_band routine performs display and DDS update

cal_loop
	call	IF_Offset
        call    calc_dds_word     ; Calculate DDS value based on current osc
        call    send_dds_word     ; Update the DDS chip
        call    read_encoder      ; Wait until the encoder has moved.
	btfss	Flag,tune_flag	  ; Has encoder changed?
	goto	cal_loop	  ; No, re-test
	call	show_freq
        clrf    fstep_3           ; Yes, clear the three most significant
        clrf    fstep_2           ; bytes of fstep
        clrf    fstep_1           ; 
        movlw   0x01              ; 
        movwf   fstep_0           ; Use small increment
;
;	update_osc
;
	nop
	nop
        nop                       
        btfsc   last_dir,1        ; Are we moving down?
        goto    faster            ; No, increase the osc value
;
;       slower
;

        comf    fstep_0,f         ; Subtraction of fstep is done by
        comf    fstep_1,f         ; adding the twos compliment of fsetp
        comf    fstep_2,f         ; to osc
        comf    fstep_3,f         ; 
        incfsz  fstep_0,f         ; Increment last byte
        goto    faster            ; Non-zero, continue
        incfsz  fstep_1,f         ; Increment next byte
        goto    faster            ; Non-zero, continue
        incfsz  fstep_2,f         ; Increment next byte
        goto    faster            ; Non-zero, continue
        incf    fstep_3,f         ; Increment the high byte

faster	
        movf    fstep_0,w         ; Get the low byte increment
        addwf   osc_0,f           ; Add it to the low osc byte
        btfss   STATUS,B_C        ; Was there a carry?
        goto    add4              ; No, add the next bytes
        incfsz  osc_1,f           ; Ripple carry up to the next byte
        goto    add4              ; No new carry, add the next bytes
        incfsz  osc_2,f           ; Ripple carry up to the next byte
        goto    add4              ; No new carry, add the next bytes
        incf    osc_3,f           ; Ripple carry up to the highest byte
add4
        movf    fstep_1,w         ; Get the second byte increment
        addwf   osc_1,f           ; Add it to the second osc byte
        btfss   STATUS,B_C        ; Was there a carry?
        goto    add5              ; No, add the third bytes
        incfsz  osc_2,f           ; Ripple carry up to the next byte
        goto    add5              ; No new carry, add the third bytes
        incf    osc_3,f           ; Ripple carry up to the highest byte
add5
        movf    fstep_2,w         ; Get the third byte increment
        addwf   osc_2,f           ; Add it to the third osc byte
        btfss   STATUS,B_C        ; Was there a carry?
        goto    add6              ; No, add the fourth bytes
        incf    osc_3,f           ; Ripple carry up to the highest byte
add6
        movf    fstep_3,w         ; Get the fourth byte increment
        addwf   osc_3,f           ; Add it to the fourth byte

        btfss   osc_3,7	  	  ; Is high order frequency byte "negative"?   
        goto cal_check		  ; No, continue 

        comf    osc_0,f      ; Yes, two's compliment result
        comf    osc_1,f      ; to make positive difference
        comf    osc_2,f      ; 
        comf    osc_3,f      ; 
	incfsz  osc_0,f      ; Increment last byte
        goto cal_check	     ; Non-zero, subtract finished
        incfsz  osc_1,f      ; Increment next byte
        goto cal_check       ; Non-zero, subtract finished
        incfsz  osc_2,f      ; Increment next byte
        goto cal_check 	     ; Non-zero, subtract finished
        incf    osc_3,f      ; Increment the high byte
cal_check
        btfss   PortC,band_ch     ; Is the band change function still selected?
        goto    cal_loop          ; Yes, stay in calibrate mode
	Bank2
        clrf    EEadr             ; Write final value to EEPROM
	Bank0 
        movf    osc_0,w           ; Record the first
	Bank2
        movwf   EEdata            ;   osc
        call    write_EEPROM      ;   byte
        movf    osc_1,w           ; Record the second
	Bank2
        movwf   EEdata            ;   osc
        call    write_EEPROM      ;   byte
        movf    osc_2,w           ; Record the third
	Bank2
        movwf   EEdata            ;   osc
        call    write_EEPROM      ;   byte
        movf    osc_3,w           ; Record the fourth
	Bank2
        movwf   EEdata            ;   osc
        call    write_EEPROM      ;   byte
	call	Saved_msg	  ; Display "Saved" on Line 2
	call	Long_delay        ; Display for about 1 Sec 
        return                    ; Return to the caller

; *****************************************************************************
; *                                                                           *
; * Purpose:  Write the byte of data at EEdata to the EEPROM at address       *
; *           EEadr. Based upon 16F877 Datasheet example.                     *
; *                                                                           *
; *   Input:  The values at EEdata and EEadr.                                 *
; *                                                                           *
; *  Output:  The EEPROM value is updated.                                    *
; *                                                                           *
; *****************************************************************************
;
write_EEPROM
	Bank3
	btfsc	EEcon1,WR	  ; Wait for write to finish
	goto	$-1		  ; Jump back one
	bcf	EEcon1,EEPGD	  ; Point to Data Memory
	bsf	EEcon1,WREN	  ; Enable Write
        movlw   0x55              ; Write 0x55 and 0xAA to EEPROM
        movwf   EEcon2            ; control register2, as required
        movlw   0xAA              ; for the write
        movwf   EEcon2            ; 
        bsf     EEcon1,WR         ; Set WR to initiate write
bit_check
        btfsc   EEcon1,WR         ; Has the write completed?
        goto    bit_check         ; No, keep checking
        bcf     EEcon1,WREN       ; Clear the EEPROM write enable bit
	Bank2
        incf    EEadr,f           ; Increment the EE write address
	Bank0
        return                    ; Return to the caller 
;
; *****************************************************************************
; *                                                                           *
; * Purpose:  Read a byte of EEPROM data at address EEadr into EEdata.        *
; *                                                                           *
; *   Input:  The address EEadr.                                              *
; *                                                                           *
; *  Output:  The value in EEdata.                                            *
; *                                                                           *
; *****************************************************************************
;
read_EEPROM

	Bank3
	bcf	EEcon1,EEPGD	  ; Point to Data Memory
        bsf     EEcon1,RD         ; Request the read
	Bank2
        incf    EEadr,f           ; Increment the read address
        return                    ; Return to the caller

;==========================================================================================
; Message repository
;
; This section contains the status messages and a routine to control one off updates
; preventing display disturbances
;
;==========================================================================================


; Clear display and position cursor at start of message
; Message flags prevent cyclic clearing of display and visual strobe effect

Msg_line1				
	movlw	0x01		  ; Clear the display for new message
	call	cmnd2LCD
	clrf	msgflag		  ; Clear message flags
        movlw   0x8D              ; Point the LCD to first LCD digit location
        call    cmnd2LCD          ; Send starting digit location to LCD
	return

Msg_line2				
	movlw	0x01		  ; Clear the display for new message
	call	cmnd2LCD
	clrf	msgflag		  ; Clear message flags
        movlw   0xC2              ; Point the LCD to first LCD digit location
        call    cmnd2LCD          ; Send starting digit location to LCD
	return

; Clear Display

Clear_msg
	movlw	0x01		  ; Clear the display for new message
	call	cmnd2LCD
	clrf	msgflag		  ; Clear message flags
	return	

; RIT Message

RIT_msg
	btfsc	msgflag,0	  ; If flag zero new message needed, proceed else return
	return
	call	Msg_line1
        movlw   'R'               
        call    data2LCD   
        movlw   'I'               
        call    data2LCD   
        movlw   'T'               
        call    data2LCD
	bsf	msgflag,0	  ; Message displayed
	return
;
; Local Oscillator Sum Message

Sum_msg
	btfsc	msgflag,1	  ; If flag zero new message needed, proceed else return
	return
	call	Msg_line2
        movlw   'S'               
        call    data2LCD   
        movlw   'u'
        call    data2LCD
        movlw   'm'
        call    data2LCD               
	bsf	msgflag,1	  ; Message displayed
	return
;
; Local Oscillator Diff Message
Dif_msg
	btfsc	msgflag,2	  ; If flag zero new message needed, proceed else return
	return
	call	Msg_line2
        movlw   'D'               
        call    data2LCD   
        movlw   'i'               
        call    data2LCD   
        movlw   'f'               
        call    data2LCD
	bsf	msgflag,2	  ; Message displayed
	return

; Start Up Message
Start_msg
        movlw   0x82              ; Point the LCD to first LCD digit location
        call    cmnd2LCD          ; Send starting digit location to LCD
        movlw   'V'               
        call    data2LCD   
        movlw   'e'               
        call    data2LCD   
        movlw   'r'               
        call    data2LCD
        movlw   's'               
        call    data2LCD   
        movlw   'i'               
        call    data2LCD   
        movlw   'o'               
        call    data2LCD
        movlw   'n'               
        call    data2LCD
        movlw   0xC2              ; Point the LCD to first LCD digit location
        call    cmnd2LCD          ; Send starting digit location to LCD
        movlw   'D'               
        call    data2LCD   
        movlw   'D'               
        call    data2LCD   
        movlw   'S'               
        call    data2LCD
        movlw   '8'      		; 8 bit LCD Version         
        call    data2LCD   
        movlw   '_'               
        call    data2LCD   
        movlw   '2'               	; Version
        call    data2LCD
        movlw   'f'               	; Revision
	call	data2LCD
	Return

; Calibrate Message
Cal_msg
        movlw   0xC0              ; Point the LCD to first LCD digit location
        call    cmnd2LCD          ; Send starting digit location to LCD
        movlw   'C'               
        call    data2LCD   
        movlw   'a'               
        call    data2LCD   
        movlw   'l'               
        call    data2LCD
        movlw   'i'               
        call    data2LCD   
        movlw   'b'               
        call    data2LCD   
        movlw   'r'               
        call    data2LCD
        movlw   'a'               
        call    data2LCD
        movlw   't'               
        call    data2LCD   
        movlw   'e'               
        call    data2LCD   
        movlw   ' '               
        call    data2LCD
        movlw   'M'      		         
        call    data2LCD   
        movlw   'o'               
        call    data2LCD   
        movlw   'd'               	
        call    data2LCD
        movlw   'e'               	
	call	data2LCD
	Return

; Saved Message
Saved_msg
        movlw   0xC0              ; Point the LCD to first LCD digit location
        call    cmnd2LCD          ; Send starting digit location to LCD
        movlw   ' '               
        call    data2LCD   
        movlw   ' '               
        call    data2LCD   
        movlw   ' '               
        call    data2LCD
        movlw   ' '               
        call    data2LCD   
        movlw   ' '               
        call    data2LCD   
        movlw   'S'               
        call    data2LCD
        movlw   'a'               
        call    data2LCD
        movlw   'v'               
        call    data2LCD   
        movlw   'e'               
        call    data2LCD   
        movlw   'd'               
        call    data2LCD
        movlw   ' '      		         
        call    data2LCD   
        movlw   ' '               
        call    data2LCD   
        movlw   ' '               	
        call    data2LCD
        movlw   ' '               	
	call	data2LCD
	Return
; *****************************************************************************
; *                                                                           *
; * Purpose:  Wait for a specified number of milliseconds.                    *
; *                                                                           *
; *           Entry point wait_128ms:  Wait for 128 msec                      *
; *           Entry point wait_64ms :  Wait for 64 msec                       *
; *           Entry point wait_32ms :  Wait for 32 msec                       *
; *           Entry point wait_16ms :  Wait for 16 msec                       *
; *           Entry point wait_8ms  :  Wait for 8 msec                        *
; *                                                                           *
; *   Input:  None                                                            *
; *                                                                           *
; *  Output:  None                                                            *
; *                                                                           *
; *****************************************************************************

Long_delay		          ; Long wait (1 Sec) to allow any start up control
				  ; transients to settle.
	movlw	0x08		  ; Load counter
	movwf	count
long_d_loop
	call	wait_128ms        ; Call delay
	decfsz	count
	goto	long_d_loop
	return

wait_128ms  ; ****** Entry point ******    
        movlw   0xFF              ; Set up outer loop 
        movwf   timer1            ;   counter to 255
        goto    outer_loop        ; Go to wait loops
wait_64ms  ; ****** Entry point ******     
        movlw   0x80              ; Set up outer loop
        movwf   timer1            ;   counter to 128
        goto    outer_loop        ; Go to wait loops
wait_32ms   ; ****** Entry point ******    
        movlw   0x40              ; Set up outer loop
        movwf   timer1            ;   counter to 64
        goto    outer_loop        ; Go to wait loops
wait_16ms   ; ****** Entry point ******    
        movlw   0x20              ; Set up outer loop
        movwf   timer1            ;   counter to 32  
        goto    outer_loop        ; Go to wait loops
wait_8ms   ; ****** Entry point ******     
        movlw   0x10              ; Set up outer loop
        movwf   timer1            ;   counter to 16
        goto	outer_loop        ; Fall through into wait loops
wait_1ms   ; ****** Entry point ******     
        movlw   0x02              ; Set up outer loop
        movwf   timer1            ;   counter to 1
;
; Wait loops used by other wait routines - modified for an 20MHz clock
;  - 0.2 microsecond per instruction
;  - instructions per inner loop
;  - (Timer1 * 2500) instructions (0.5 msec) per outer loop cycle

outer_loop                        
        movlw   0xFA              ; Set up inner loop counter
        movwf   timer2            ; to 250
inner_loop
	nop			  ; 1 ; Nulls to pad out loop to 
	nop			  ; 2 ; 10 x 250 x 0.2 microseconds = 0.5 mSec
	nop			  ; 3 ;	
	nop 			  ; 4 ;
	nop			  ; 5 ;
	nop			  ; 6 ;
	nop			  ; 7 ;
        decfsz  timer2,f          ; 8 ; Decrement inner loop counter
        goto    inner_loop        ; 10; If inner loop counter not down to zero, 
                                  ; then go back to inner loop again
        decfsz  timer1,f          ; Yes, Decrement outer loop counter
        goto    outer_loop        ; If outer loop counter not down to zero,
                                  ; then go back to outer loop again
        return                    ; Yes, return to caller

;       
; *****************************************************************************



        END
