
#define         Nanosec         * D'1'
#define         Microsec        * D'1000'
#define         Millisec        * D'1000000'
#define         Seconds         * D'1000000000'
       

;**************************************************************
;*                       The WAIT macro                       *
;*                      * VERSION 1.01 *                      *
;*             called by Wait <time>, lesscycles              *
;**************************************************************
;History
;1.00   - Original
;1.01   - Fixed bug with small even numbers giving an error message


Wait    macro   time_ns, lesscycles         ;time_ns gives the wait time required, in ns
 radix dec
 variable instruct_time_ns =  (( 1 Seconds ) / (Clock_Freq / 4 ))
 local cycles
 variable cycles = ((time_ns) / instruct_time_ns)   ;required delay in 
                                                         ;100ths of instructions

 if (cycles < (lesscycles) )
        messg NOTE - negative delay time with lesscycles cycles (no code)
               
                exitm
 else
 variable cycles = (cycles - (lesscycles))
 endif

 if (cycles == 0) 
        messg "WARNING - delay time less than 1 instructions"
               
                nop
                exitm
 endif

 if (cycles > (255*(256*3 + 6) + 2 + 3))
        messg   "ERROR : Too long a wait for the WAIT macro at present!!"
        exitm
 endif
        
;        messg Info - calculated number of cycles = #v(cycles)


 if (cycles > ((255*3)+5))
                
                movlw   ((cycles-5)/(256*3+6))
                call    longdelay
 
 ifndef INCLONGDELAY
  #define INCLONGDELAY
 endif

 exitm
 endif

 if ((cycles > 8 ) && (cycles < (255*3 + 5)))
                
                movlw   ((cycles-5)/3)        
                call    shortdelay
 
 ifndef INCSHORTDELAY
  #define INCSHORTDELAY
 endif

 exitm
 endif

 if (cycles < 8)
 while  ( cycles > 1 )
                
                goto $+1  ;two cycle nop
        
cycles -=2
 endw
 endif
 
 if (cycles > 0)
               nop
 
 endif
 exitm
 
 messg "ERROR - got to end of WAIT.MAC"

 radix hex
 endm
