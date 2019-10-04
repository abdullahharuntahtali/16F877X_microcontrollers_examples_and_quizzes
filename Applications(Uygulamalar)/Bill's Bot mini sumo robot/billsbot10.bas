'****************************************************************
'*  Name    : Billsbot10.BAS                                    *
'*  Author  : Bill Sherman                                      *
'*  Notice  : Copyright (c) 2004 Bill Sherman                   *
'*          : All Rights Reserved                               *
'*  Date    : 3/05/04                                           *
'*  Version : 10.0                                              *
'*  Notes   :  added voice                                      *
'*          :  added board calibration                          *
'****************************************************************
@  Device Pic16F876, HS_Osc, Wdt_Off, Pwrt_On, Bod_On, Lvp_Off, Protect_Off

Include "modedefs.bas"

DEFINE OSC 20
DEFINE	ADC_BITS	8	     ' Set number of bits in result
DEFINE	ADC_CLOCK	3	     ' Set clock source (3=rc)
DEFINE	ADC_SAMPLEUS	50	 ' Set sampling time in uS

'debug is for sending test values over the PIC-KEY to PC screen
DEFINE DEBUG_REG PORTB
DEFINE DEBUG_BIT 7
DEFINE DEBUG_BAUD 9600
DEFINE DEBUG_MODE 1          ' invert level
DEFINE DEBUG_PACING 1000

'Setting up hardware PWM for 56.8KHz operation to drive IRLEDs.

 TRISC.2 = 0            'CCP1 (PortC.2 = Output) 56.8kc output
 PR2 = 87               'Set PWM Period for approximately 56.8KHz
 CCPR1L = 44            'Set PWM Duty-Cycle to 50%  
 CCP1CON = %00001100    'Select PWM Mode
 T2CON = %00000100      'Timer2 = ON + 1:1 prescale
 TRISA = %11101111	    'Set PORTA  input/output
 TRISB = %11000101	    'Set PORTB  input/output
 TRISC = %00100000	    'Set PORTC  input/output
 ADCON1 = %00000010	    'Set PORTA analog and right justify result

 righteye   var     word    'right eye line sensors
 lefteye    var     word    'left eye line sensors
 ana2       var     word    'spare adc
 ana3       var     word    'spare adc
 ana4       var     word    'spare adc
 startled   var     portb.1 'start led
 pushstart  var     portb.0 'push button for commands
 yellowled  var     portb.4 'yellow test light
 greenled   var     portb.3 'green test light
 leftpwm    var     portc.0 'speed pwm for left
 rightpwm   var     portb.5 'speed pwm for right
 dlefta     var     portc.1 'left wheel dir logic A
 dleftb     var     portc.6 'left wheel dir logic B
 drighta    var     portc.3 'right wheel dir logic A
 drightb    var     portc.4 'right wheel dir logic B
 n          var     word    'counter byte
 ireye_r    var     portc.5 'right ir sensor
 ireye_l    var     portb.2 'left ir sensor
 flag       var     byte    'last turn a left or right turn flag
 bark       var     byte    'sound value
 reyewhite  var     byte    'right line sensor white value
 reyeblack  var     byte    'right line sensor black value
 leyewhite  var     byte    'left line sensor white value
 leyeblack  var     byte    'left line sensor black value
 rightref   var     byte    'right line sensor level ref. (calibrate value)
 leftref    var     byte    'left line sensor level ref. (calibrate value)
 
low startled 'reset all lights to off
low yellowled
low greenled
debug ,"  billsbot10.bas",10,13 'print out the name of the program at startup
'put motors in "coast"
low leftpwm
low rightpwm
low dlefta
low dleftb
low drighta
low drightb

read 0, rightref 'read last calibration values in eerom
read 1, leftref

pause 100
sound porta.4, [120,10] 'make a beep when turning on
pause 100
calmode:' hold in start button when turning on for calibrate mode
 if pushstart = 0 then 

 goto calibrate
 endif

delay5:
'delay of 5 sec. when starting match light flashs and tone beeps for countdown
 high startled
 if pushstart = 1 then delay5
 
 low startled
 sound porta.4, [90,10]
 pause 950
 high startled
 sound porta.4, [100,10]
 pause 450
 low startled
 pause 500
 high startled 
 sound porta.4, [110,10]
 pause 450
 low startled
 pause 500
 high startled
 sound porta.4, [115,10]
 pause 450
 low startled
 pause 500
 high startled 
 sound porta.4, [120,10]
 pause 450
 low startled
 pause 500
 high startled
 
bark=120 'tone value for sound generation routines
 
scanright:

gosub whiteline
gosub rturn
pause 100
gosub voice
gosub allstop

seek: 'find the opponent
low yellowled 'reset test lights
low greenled

gosub  whiteline 'avoid the white line

if (ireye_r = 0)and(ireye_l = 0) then 'if object if straight ahead,go for it
gosub fastforward

gosub voice
endif

if flag = 1 then 'if last was a right turn then check to the right
goto goright
endif

if flag = 2 then 'if last was a left turn then check to the left
goto goleft
endif

goforward:
gosub whiteline
if (ireye_r = 0)and(ireye_l = 0) then

gosub fastforward
gosub voice
endif

goright: 'if only a right sensor detects, then move right
gosub whiteline
if (ireye_r = 0) and (ireye_l = 1) then
high yellowled
gosub rturn

gosub voice
gosub fastforward
flag = 1

gosub voice
endif

goleft:'if only a left sensor detects, then move left
gosub whiteline
if (ireye_l = 0) and (ireye_r = 1) then
high greenled
gosub lturn

gosub voice
gosub fastforward
flag = 2

gosub voice
endif

nothingfound:
'if nothing is found then do a scan and find the opponent
if (ireye_r = 1) and (ireye_l = 1)  then 
goto scanright
endif

goto seek
 
fastforward: 'move the motors full speed forward

    low drighta 'right wheel dir
    high drightb
    
    low dlefta 'left wheel dir
    high dleftb

    high rightpwm 'full on right and left
    high leftpwm
    
    return 
    
allstop: 'stop and regenerative brake the motors (shorting the bridge)

    low drighta 'right wheel dir
    low drightb
    
    low dlefta 'left wheel dir
    low dleftb

    high rightpwm 'full on right and left
    high leftpwm
    return


fastbackup: 'full speed in reverse

    high drighta 'right wheel dir
    low drightb
    
    high dlefta 'left wheel dir
    low dleftb

    high rightpwm 'full on right and left
    high leftpwm   
    return
 
 
rturn: 'do a right turn

    high drighta 'right wheel dir
    low drightb
    
    low dlefta 'left wheel dir
    high dleftb

    high rightpwm 'full on right and left
    high leftpwm  

    return
 
lturn: 'do a left turn

    low drighta 'right wheel dir
    high drightb
    
    high dlefta 'left wheel dir
    low dleftb

    high rightpwm 'full on right and left
    high leftpwm  
  
    return
 
 goto scanright
 
whiteline:

'hunt for the opponent, but first
'watch for white line!

adcin 0, righteye 'enter adc values
adcin 1, lefteye

if (righteye < rightref) and (righteye < rightref)then

gosub allstop
pause 200
gosub voice

gosub fastbackup
pause 700
endif

adcin 0, righteye

if (righteye < rightref) then

gosub allstop
pause 200
gosub voice

gosub fastbackup
pause 700

gosub lturn
pause 500

flag = 0
endif

adcin 1, lefteye
if (lefteye < leftref) then

gosub allstop
pause 200
gosub voice

gosub fastbackup
pause 700

gosub rturn
pause 500
'pause 200
flag = 0
endif 

return

calibrate: 'find values of white a black surfaces to calibrate sensors
low yellowled
low greenled
low startled

black:'determine what is black

debug " calibrate black ",10,13

adcin 0, reyeblack
adcin 1, leyeblack
high startled
high yellowled
sound porta.4, [110,10]
debug, "leftblack ",dec leyeblack," rightblack ", dec reyeblack, 10,13

releasebutton:'detect when releasing the button

if pushstart = 0 then releasebutton
pause 500

checkbutton:'check for a repush of the button

if pushstart = 0 then white

goto checkbutton

white:'determine what is white

sound porta.4, [110,10]

adcin 0, reyewhite
adcin 1, leyewhite

debug, "leftwhite ",dec leyewhite," rightwhite ", dec reyewhite, 10,13
rightref = ((reyeblack - reyewhite)/2) + reyewhite
leftref = ((leyeblack - leyewhite)/2) + leyewhite

debug, "leftref ",dec leftref," rightref ", dec rightref, 10,13

if reyewhite > rightref then alarm
if leyewhite > leftref then alarm

write 0,rightref 'write values in the pic's data errom
write 1,leftref

high greenled

low startled
sound porta.4, [100,20]
pause 100
sound porta.4, [100,20]
pause 100
sound porta.4, [100,20]
pause 500
goto delay5

alarm:'bad calibrate, the order of black first then white has been volated

sound porta.4, [100,20]
sound porta.4, [80,20]
goto alarm

voice: 'sound generation routines
if pushstart = 0 then halt
bark = bark - 5
if bark = 80 then
bark = 125
endif
sound porta.4,[bark,10]
return
 
halt: 'kill button
gosub allstop
low startled 
pause 100
high startled
pause 100
goto halt
