;*********************************************************
;
;	Timer for battery charger to prevent over-charge
;
;		Clock 8MHz
;
;	Toshitaka Yoshioka	Sydney, Australia
;
;*********************************************************

;**** Includes ****

.include "1200def.inc"
.include "Macros.inc"



;**** Reg Definision ****

.def	int_sreg=R1	; SREG saved for interruption
.def	TimeUp_Flag=r26	; 
.def	In_Count_Flag=r27
.def	Pre_Cnt=r4
.def	temp0 =r16
.def	temp1 =r17
.def	temp2 =r18
.def	temp3 =r19
.def	time_L=r24
.def	time_H=r25

;**** Interruption Vectors ****

	rjmp	RESET		; Reset handle
	rjmp	EXT_INT0	; External Interruption
	rjmp	TIM0_OVF	; Timer 0 overflow handle
	rjmp	ANA_COMP	; Analogue Comparator

RESET:
;**** Initialise ****
	Init_Reg
	
	; Port B Setting
	ldi	temp0,$0F
	out	PORTB,temp0		; Pull Up
	ldi	temp0,$10
	out	DDRB,temp0		; Ouptput

	; Port D Setting
	ldi	temp0,$3F
	out	PORTD,temp0		; Pull Up
	ldi	temp0,$40
	out	DDRD,temp0		; Ouptput

;**** T/C 0 Setting ****

	; T/C 0 Interruption mask
	ldi	temp0,(1<<TOIE0)
	out	TIMSK,temp0

	; T/C 0 Prescaler
	ldi	temp0,$05	; 1/1024:5, (1/1 for test:1) (1/64 for test:3, 1min=3.75Sec)
	out	TCCR0,temp0
	
	
	perm

;	inh

;****  Main Loop ****
main:

IF_TU:
	cpi	TimeUp_Flag,0
	breq	IF_TU_NO
IF_TU_YES:
	inh
LOOP_BZ:
	sbi	PORTD,PD6	; Turn on buzzer
	Delay	500,8000
	sbis	PIND,PIND5	; Reset button?
	rjmp	LOOP_BZ_END	; ON!
	cbi	PORTD,PD6	; Turn OFF Buzzer
	Delay	500,8000
	sbis	PIND,PIND5	; Reset button?
	rjmp	LOOP_BZ_END	; ON!
	rjmp	LOOP_BZ
LOOP_BZ_END:
	perm
	cpi	TimeUp_Flag,0	; Reset time up flag
	cbi	PORTD,PD6	; Turn OFF Buzzer
IF_TU_NO:
	rjmp	main	; Wait for T/C 0 interruption	

;***************************************************************************
;*
;* Interruption routine. Every 1024*256/8000000=32.768mSec
;*	TIM0_OVF 
;*
;***************************************************************************

TIM0_OVF:			; ( Timer 0 overflow handle )
	in	int_sreg,SREG	; 
IF_Start:
	sbic	PIND,PIND4	; Start button?
	rjmp	IF_Start_END	
IF_Start_ON:
	ldi		In_Count_Flag,1
	sbi		PORTB,PB4	; Turn ON relay
	cbi		PORTD,PD6	; Turn OFF Buzzer
IF_Start_END:

IF_Reset:
	sbic	PIND,PIND5	; Reset button?
	rjmp	IF_Reset_END
IF_Reset_ON:
	ldi	In_Count_Flag,0
	cbi		PORTB,PB4	; Turn OFF relay
	ldi	TimeUp_Flag,0	; Reset Time Up flag
	sub	Pre_Cnt,Pre_Cnt	; Clear counters
	sub	Time_L,Time_L
	sub	Time_H,Time_H
IF_Reset_END:



;	rjmp	TIM0_OVF_END


IF_In_Count:			; Relay ON?
	cpi		In_Count_Flag,0
	brne	IF_In_Count_Yes
	rjmp	IF_In_Count_NO
IF_In_Count_Yes:

	inc	Pre_Cnt			; Increment pre-counter

IF_Pre:					; Pre-Counter UP?
	breq	IF_Pre_UP
	rjmp	IF_Pre_END
IF_Pre_UP:				; Yes!
	ldi	temp0,1
	ldi	temp1,0
	add	Time_L,temp0		; Increment teimer counter (1 count = 8.388608 Sec)
	adc	Time_H,temp1
	
	ldi	temp1,0	
	in	temp0,PIND		; Read 1 minute SW
	com	temp0
	andi	temp0,$0F
LMT_Min:				; Limit 1 min input to 9
	cpi	temp0,10
	brlo	LMT_Min_End
LMT_Min_Yes:
	ldi	temp0,9
LMT_Min_End:
	in	temp2,PINB		; Read 10 minute SW
	com	temp2
	andi	temp2,$0F
	lsl	temp2			; * 2
	add	temp0,temp2
	lsl	temp2			; * 4
	lsl	temp2			; * 8
	add	temp0,temp2		; 10 min SW * 10 + 1 min SW (Max 159)
	
	mov	mc16uL,temp0
	ldi	mc16uH,0
	ldi	mp16uL,LOW(29297)
	ldi	mp16uH,HIGH(29297)
	rcall	mpy16u
	lsr	m16u3	; /2
	ror	m16u2	;
	ror	m16u1	;
	lsr	m16u3	; /4
	ror	m16u2	;
	ror	m16u1	;
	lsr	m16u3	; /8
	ror	m16u2	;
	ror	m16u1	;
	lsr	m16u3	; /16
	ror	m16u2	;
	ror	m16u1	;
	;	Set time in count in m16u2|m16u1

IF_Time:	
	cp	Time_L,m16u1
	cpc	Time_H,m16u2
	brsh	IF_Time_UP
	rjmp	IF_Time_END
IF_Time_UP:
	ldi	In_Count_Flag,0
	cbi	PORTB,PB4	; Turn off relay
	ldi	TimeUp_Flag,1	; Set time up flag
IF_Time_END:
IF_Pre_END:

IF_In_Count_NO:

TIM0_OVF_END:
	out	SREG,int_sreg
	reti			;

EXT_INT0:
	sbi		PORTB,PB4	; Turn ON relay
	Delay	500,8000
	cbi		PORTB,PB4
	Delay	500,8000
	rjmp	EXT_INT0

ANA_COMP:
	sbi		PORTB,PB4	; Turn ON relay
	Delay	1000,8000
	cbi		PORTB,PB4
	Delay	1000,8000
	rjmp	EXT_INT0

	
;**** End of File ****

.include	"Mul_Dev.inc"
