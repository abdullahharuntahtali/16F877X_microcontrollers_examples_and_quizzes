; compiler          : jal 00.04-53
; date              : 05-Apr-2004 04:33:49
; main source       : test
; command line      : -s../jal/lib test.jal 
; target  chip      : 16f628
;         cpu       : pic 14
;         clock     : 4000000
; input   files     : 3
;         lines     : 1134
;         chars     : 30694
; compilation nodes : 8604
;             stack : 24Kb
;              heap : 2869Kb
;           seconds : 0.610 (1859 lines/second)
; output       code :  133
;              page :    0 (0.0%)
;              bank :    0 (0.0%)
;         page+bank :    0 (0.0%)
;              file :    7
;              stack:    1 (1,0,0)

 errorlevel -306
 list p=PIC16f628

; 628 config now works (rsw)
 __CONFIG H'3F70' 
 ORG 0000
  goto    __main
 ORG 0004
 ORG 0004
__interrupt: ; 0004
__main: ; 0004
; var H'020:000'  transfer_bit
; var H'020:000'  transfer_byte

;; 006 : var byte foo at 0x70
; var H'070:000' foo

;; 007 : var byte bar at 0x71
; var H'071:000' bar

;; 008 : var byte i at 0x72
; var H'072:000' i

;; 009 : var byte j at 0x73
; var H'073:000' j

;; 012 : var volatile byte ccpr1l at 0x15
; var H'015:000' ccpr1l

;; 013 : var volatile byte ccp1con at 0x17
; var H'017:000' ccp1con

;; 014 : var volatile bit cp1x at ccp1con : 5
; var H'017:005' cp1x

;; 020 : var volatile byte cmcon at 0x1f
; var H'01F:000' cmcon

;; 021 : var volatile byte pcon at 0x8e
; var H'08E:000' pcon

;; 022 : var volatile bit oscf at pcon : 3
; var H'08E:003' oscf

;; 025 : var volatile byte t2con at 0x12
; var H'012:000' t2con

;; 026 : var volatile byte pr2 at 0x92
; var H'092:000' pr2

;; 027 : var volatile byte optionreg at 0x81
; var H'081:000' optionreg

;; 028 : var volatile byte f628_eedata at 0x9A
; var H'09A:000' f628_eedata

;; 029 : var volatile byte f628_eeadr at 0x9B
; var H'09B:000' f628_eeadr

;; 030 : var volatile byte f628_eecon1 at 0x9C
; var H'09C:000' f628_eecon1

;; 035 : var volatile bit f628_eecon1_rd at f628_eecon1 : 0
; var H'09C:000' f628_eecon1_rd

;; 037 : foo = 0x80
  movlw   H'80'
  movwf   H'70'

;; 038 : bar = 0x00
  clrf    H'71'

;; 039 : i = 0x00
  clrf    H'72'

;; 040 : j = 0x00
  clrf    H'73'

;; 038 : var volatile byte tmr0         at  1
; var H'001:000' tmr0

;; 040 : var volatile byte status       at  3
; var H'003:000' status

;; 130 : var volatile bit  status_rp0  at status : 5
; var H'003:005' status_rp0

;; 131 : var volatile bit  status_rp1  at status : 6
; var H'003:006' status_rp1

;; 280 : var byte trisa
; var H'021:000' trisa

;; 281 : var byte trisb
; var H'022:000' trisb

;; 288 : trisa = all_input
  movlw   H'FF'
  movwf   H'21'

;; 290 :    trisb = all_input
  movlw   H'FF'
  movwf   H'22'

;; 584 : var byte _port_a_buffer
; var H'023:000' _port_a_buffer

;; 044 : port_a_direction = 0x00
  movlw   H'00'
  call    _3192__vector

;; 045 : port_b_direction = 0xF7
  movlw   H'F7'
  call    _3228__vector

;; 049 :         bcf status_rp0          -- bank 0
  bcf     H'03',5

;; 050 :         bcf status_rp1          -- ...
  bcf     H'03',6

;; 051 :         movlw 0x07              -- load 0x07...
  movlw   H'07'

;; 052 :         movwf cmcon             -- ...into cmcon
  movwf   H'1F'

;; 053 :         clrwdt                  -- clear wdt
  clrwdt  

;; 054 :         clrf tmr0               -- clear tmr0 and prescaler
  clrf    H'01'

;; 055 :         bsf status_rp0          -- bank 1
  bsf     H'03',5

;; 056 :         movlw 0xEF              -- be careful about
  movlw   H'EF'

;; 057 :         movwf optionreg         -- moving the prescaler
  movwf   H'81'

;; 058 :         clrwdt                  -- into watchdog timer
  clrwdt  

;; 059 :         movlw 0xE8              -- set prescaler to 0
  movlw   H'E8'

;; 060 :         movwf optionreg         -- ...
  movwf   H'81'

;; 061 :         bcf status_rp0          -- bank 0
  bcf     H'03',5

;; 062 :         movlw 0xC4              -- put initial clkset value
  movlw   H'C4'

;; 063 :         movwf tmr0              -- into tmr0
  movwf   H'01'

;; 066 :         bsf status_rp0          -- bank 1
  bsf     H'03',5

;; 067 :         bsf oscf                -- OSC = 4 MHz
  bsf     H'8E',3

;; 068 :         movlw 0xFF              -- 0xFF goes into...
  movlw   H'FF'

;; 069 :         movwf pr2               -- ...pr2
  movwf   H'92'

;; 070 :         bcf status_rp0          -- bank 0
  bcf     H'03',5

;; 071 :         clrf ccpr1l             -- set duty cycle
  clrf    H'15'

;; 072 :         bcf cp1x                -- ...
  bcf     H'17',5

;; 073 :         bcf cp1x                -- ...
  bcf     H'17',5

;; 074 :         movlw 0x04              -- load config for t2con
  movlw   H'04'

;; 075 :         movwf t2con             -- write it to t2con
  movwf   H'12'

;; 076 :         movlw 0x0F              -- load config for ccp1con
  movlw   H'0F'

;; 077 :         movwf ccp1con           -- write it into ccp1con
  movwf   H'17'

;; 081 : forever loop
w_8163_ag: ; 002C

;; 082 :         i = i + 1
  incf    H'72',f

;; 084 :         if (i == 10) then
  movf    H'72',w
  sublw   H'0A'
  btfss   H'03',2
  goto    if_8080_by
if_8080_th: ; 0031

;; 085 :                 i = 0
  clrf    H'72'
if_8080_by: ; 0032

;; 088 :         foo = foo ^ 0b_1100_0000
  movlw   H'C0'
  xorwf   H'70',f

;; 090 :         port_a = foo | i
  movf    H'70',w
  iorwf   H'72',w
  call    _5469__vector

;; 092 :         j = 95
  movlw   H'5F'
  movwf   H'73'

;; 094 :         for 30 loop
; var H'024:000' _loop_temp_8114
  movlw   H'1E'
  movwf   H'24'
f_8114_again: ; 003B

;; 095 :                 for 254 loop
; var H'025:000' _loop_temp_8120
  movlw   H'FE'
  movwf   H'25'
f_8120_again: ; 003D

;; 096 :                         for 32 loop
; var H'026:000' _loop_temp_8126
  movlw   H'20'
  movwf   H'26'
f_8126_again: ; 003F

;; 097 :                                 asm nop
  nop     

  decfsz  H'26',f
  goto    f_8126_again
  decfsz  H'25',f
  goto    f_8120_again

;; 101 :                         bsf status_rp0  -- bank 1
  bsf     H'03',5

;; 102 :                         bcf status_rp1  -- ...
  bcf     H'03',6

;; 103 :                         decf j,w        -- decrement j -> w
  decf    H'73',w

;; 104 :                         movwf j         -- save it in j
  movwf   H'73'

;; 105 :                         movwf f628_eeadr -- put the address in eeadr
  movwf   H'9B'

;; 106 :                         bsf f628_eecon1_rd -- read the data
  bsf     H'9C',0

;; 107 :                         movf f628_eedata,w -- get it in w
  movf    H'9A',w

;; 108 :                         bcf status_rp0  -- bank 0
  bcf     H'03',5

;; 109 :                         movwf ccpr1l    -- put the PWM value in ccpr1l
  movwf   H'15'

  decfsz  H'24',f
  goto    f_8114_again
  goto    w_8163_ag

;; 003 :   idle_loop: page goto idle_loop
as_8166_idle_loop: ; 0050
  goto    as_8166_idle_loop

;; 606 : procedure port_a'put( byte in x at _port_a_buffer ) is
p_5469__port_a__put_t: ; 0051
_5469__vector: ; 0051
; var H'023:000' x
p_5469_put: ; 0051
  movwf   H'23'

;; 607 :    _port_a_flush
  goto    _5354__vector
e_5469_put: ; 0053
_5354__vector: ; 0053
p_5354__port_a_flush: ; 0053

;; 591 :    var volatile byte port_a at 5 = _port_a_buffer
; var H'005:000' port_a
  movf    H'23',w
  movwf   H'05'
e_5354__port_a_flush: ; 0055
  return  

;; 341 : procedure port_b_direction'put( byte in x at trisb ) is
p_3228__port_b_direction__put_t: ; 0056
_3228__vector: ; 0056
; var H'022:000' x
p_3228_put: ; 0056
  movwf   H'22'

;; 342 :    _trisb_flush
  goto    _3079__vector
e_3228_put: ; 0058

;; 336 : procedure port_a_direction'put( byte in x at trisa ) is
p_3192__port_a_direction__put_t: ; 0058
_3192__vector: ; 0058
; var H'021:000' x
p_3192_put: ; 0058
  movwf   H'21'

;; 337 :    _trisa_flush
  goto    _3056__vector
e_3192_put: ; 005A
_3079__vector: ; 005A
p_3079__trisb_flush: ; 005A

;; 309 :       bank movfw trisb
  movf    H'22',w

;; 310 :            tris  6
  tris    H'06'
e_3079__trisb_flush: ; 005C
  return  
_3056__vector: ; 005D
p_3056__trisa_flush: ; 005D

;; 302 :       bank movfw trisa
  movf    H'21',w

;; 303 :            tris  5
  tris    H'05'
e_3056__trisa_flush: ; 005F
  return  

 END

; ********** variable mapping
; 01:0 : ;
;   tmr0                           * 0038:19 ../jal/lib/jpic.jal 
; 03:0 : ;
;   status                         * 0040:19 ../jal/lib/jpic.jal 
; 03:5 : ;
;   status_rp0                     * 0130:19 ../jal/lib/jpic.jal 
; 03:6 : ;
;   status_rp1                     * 0131:19 ../jal/lib/jpic.jal 
; 05:0 : ;
;   port_a                         * 0591:22 ../jal/lib/jpic.jal 
; 12:0 : ;
;   t2con                          * 0025:19 test.jal 
; 15:0 : ;
;   ccpr1l                         * 0012:19 test.jal 
; 17:0 : ;
;   ccp1con                        * 0013:19 test.jal 
; 17:5 : ;
;   cp1x                           * 0014:18 test.jal 
; 1F:0 : ;
;   cmcon                          * 0020:19 test.jal 
; 20:0 : ;
;    transfer_byte                   
;    transfer_bit                    
; 21:0 : ;
;   x                              * 0336:33 ../jal/lib/jpic.jal 
;   trisa                            0280:10 ../jal/lib/jpic.jal 
; 22:0 : ;
;   x                              * 0341:33 ../jal/lib/jpic.jal 
;   trisb                            0281:10 ../jal/lib/jpic.jal 
; 23:0 : ;
;   x                              * 0606:23 ../jal/lib/jpic.jal 
;   _port_a_buffer                   0584:10 ../jal/lib/jpic.jal 
; 24:0 : ;
;   _loop_temp_8114                  0094:09 test.jal 
; 25:0 : ;
;   _loop_temp_8120                  0095:17 test.jal 
; 26:0 : ;
;   _loop_temp_8126                  0096:25 test.jal 
; 70:0 : ;
;   foo                            * 0006:10 test.jal 
; 71:0 : ;
;   bar                            * 0007:10 test.jal 
; 72:0 : ;
;   i                              * 0008:10 test.jal 
; 73:0 : ;
;   j                              * 0009:10 test.jal 
; 81:0 : ;
;   optionreg                      * 0027:19 test.jal 
; 8E:0 : ;
;   pcon                           * 0021:19 test.jal 
; 8E:3 : ;
;   oscf                           * 0022:18 test.jal 
; 92:0 : ;
;   pr2                            * 0026:19 test.jal 
; 9A:0 : ;
;   f628_eedata                    * 0028:19 test.jal 
; 9B:0 : ;
;   f628_eeadr                     * 0029:19 test.jal 
; 9C:0 : ;
;   f628_eecon1_rd                 * 0035:18 test.jal 
;   f628_eecon1                    * 0030:19 test.jal 

