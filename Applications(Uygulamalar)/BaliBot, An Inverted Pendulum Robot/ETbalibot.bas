' PicBasic Pro program 
' 10-bit A/D conversion 
' Balancing robot using ET sensor (Sharp GP2D12)
' Connect analog input to channel-0 (RA0)
' Use a 16f876 pic mcu from microchip (digikey.com)

define osc 20
' Define ADCIN parameters
Define	ADC_BITS	10	     ' Set number of bits in result was 10   
Define	ADC_CLOCK	3	     ' Set clock source (3=rc)
Define	ADC_SAMPLEUS	50	 ' Set sampling time in uS  was 50
define DEBUG_REG PORTB
define DEBUG_BIT 5
define DEBUG_BAUD 9600
define DEBUG_MODE 1
define DEBUG_PACING 500


tiltfor	var	word		' ET Sensor Forward
tiltbac var word        ' ET sensor Back
lwheel   var word       ' Left wheel zero speed
rwheel  var word        ' Right wheel zero speed
speed   var word        ' speed variable
k       con 7           ' k factor
smax     con 500        ' speed limiter

	TRISA = %11111111	' Set PORTA to all input
	ADCON1 = %10000010	' Set PORTA analog and right justify result
	

'lwheel=747     'zero calibrate left wheel
'rwheel=747     'zero calibrate right wheel

speed=0
start: 
    debug "Balbot ET"
    pause 1000   
    high portc.2
    pause 1000
    low portc.2

    adcin 1, lwheel 'read trimmer for left wheel zero speed
    
    adcin 2, rwheel 'read trimmer for right wheel zero speed
    
loop:	
    adcin 0, tiltfor  ' Read channel 0 to adval
    
    adcin 4, tiltbac

    speed = abs (tiltfor - tiltbac)* k
    
    if speed > smax then speed = smax
    
    if tiltbac > tiltfor then back
 
   
forward:
    
    low portc.0
    pulsout portc.0,(lwheel + speed)  'left wheel
    pause 5
    low portc.1
    pulsout portc.1,(rwheel - speed)   'right wheel  
    pause 5
    
goto loop    

back:
 
    low portc.0
    pulsout portc.0,(lwheel - speed)  'left wheel
    pause 5
    low portc.1
    pulsout portc.1,(rwheel + speed)   'right wheel  
    pause 5
    
goto loop

End

   

