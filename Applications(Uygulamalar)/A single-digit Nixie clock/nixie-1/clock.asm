; compiler          : jal 00.04-53
; date              : 09-Apr-2004 02:30:47
; main source       : clock
; command line      : -s../jal/lib clock.jal 
; target  chip      : 16f628
;         cpu       : pic 14
;         clock     : 4000000
; input   files     : 4
;         lines     : 1318
;         chars     : 38505
; compilation nodes : 9073
;             stack : 51Kb
;              heap : 3050Kb
;           seconds : 0.470 (2804 lines/second)
; output       code :  243
;              page :    0 (0.0%)
;              bank :    0 (0.0%)
;         page+bank :    0 (0.0%)
;              file :    6
;              stack:    1 (1,0,1)

 errorlevel -306
 list p=PIC16f628

; 628 config now works (rsw)
 __CONFIG H'3F70' 
 ORG 0000
  goto    __main
 ORG 0004
  movwf   H'7F'
  swapf   H'03',w
  clrf    H'03'
  movwf   H'20'
  movf    H'0A',w
  movwf   H'21'
  clrf    H'0A'
  movf    H'04',w
  movwf   H'22'
  goto    __interrupt
 ORG 000E
__interrupt: ; 000E
_8047__vector: ; 000E
p_8047_intrh: ; 000E

;; 006 :         local checkb4clr
; const H'018' checkb4clr

;; 007 :         local checkb4
; const H'019' checkb4

;; 008 :         local dominute
; const H'021' dominute

;; 009 :         local dohour
; const H'02B' dohour

;; 010 :         local b4clrcounter
; const H'034' b4clrcounter

;; 011 :         local docounter
; const H'035' docounter

;; 012 :         local sincr
; const H'045' sincr

;; 013 :         local dodisplay
; const H'057' dodisplay

;; 014 :         local notblank
; const H'061' notblank

;; 015 :         local almostready
; const H'06F' almostready

;; 016 :         local dataready
; const H'075' dataready

;; 017 :         local writedata
; const H'082' writedata

;; 018 :         local theend
; const H'092' theend

;; 020 :         bcf status_rp1          -- in bank 0
  bcf     H'03',6

;; 021 :         bcf status_rp0          -- ...
  bcf     H'03',5

;; 027 :         btfsc pin_b7            -- if rb7 is not being pushed
  btfsc   H'06',7

;; 028 :         goto checkb4clr         -- check rb4 and clear rb7cnt
  goto    as_8054_checkb4clr

;; 029 :         incf rb7cnt,f           -- otherwise, increment rb7cnt
  incf    H'7A',f

;; 030 :         movlw 0x04              -- xor 4 with...
  movlw   H'04'

;; 031 :         xorwf rb7cnt,w          -- ...rb7cnt
  xorwf   H'7A',w

;; 032 :         btfsc status_z          -- if rb7cnt == 0x04
  btfsc   H'03',2

;; 033 :         goto dominute           -- increment the minutes
  goto    as_8060_dominute

;; 034 :         goto checkb4            -- else check on rb4
  goto    as_8057_checkb4

;; 036 :     checkb4clr:
as_8054_checkb4clr: ; 0018

;; 037 :         clrf rb7cnt             -- rb7 is not active; clear rb7cnt
  clrf    H'7A'

;; 038 :     checkb4:
as_8057_checkb4: ; 0019

;; 039 :         btfsc pin_b4            -- if rb4 is not being pushed
  btfsc   H'06',4

;; 040 :         goto b4clrcounter       -- do counter and clear rb4cnt
  goto    as_8066_b4clrcounter

;; 041 :         incf rb4cnt,f           -- otherwise, increment rb4cnt
  incf    H'7B',f

;; 042 :         movlw 0x04              -- xor 4 with...
  movlw   H'04'

;; 043 :         xorwf rb4cnt,w          -- ...rb4cnt
  xorwf   H'7B',w

;; 044 :         btfsc status_z          -- if rb4cnt == 0x04
  btfsc   H'03',2

;; 045 :         goto dohour             -- increment the hour   
  goto    as_8063_dohour

;; 046 :         goto docounter          -- else do the counter
  goto    as_8069_docounter

;; 048 :     dominute:
as_8060_dominute: ; 0021

;; 054 :         movlw 0x30              -- put 48 in...
  movlw   H'30'

;; 055 :         movwf sixtieths         -- ...sixtieths
  movwf   H'74'

;; 056 :         clrf baz                -- and clear baz
  clrf    H'72'

;; 059 :         clrf seconds            -- clear seconds
  clrf    H'75'

;; 060 :         incf minutes,f          -- increment minutes
  incf    H'76',f

;; 061 :         movlw 0x3C              -- xor 60 with...
  movlw   H'3C'

;; 062 :         xorwf minutes,w         -- minutes
  xorwf   H'76',w

;; 063 :         btfss status_z          -- if minutes != 60
  btfss   H'03',2

;; 064 :         goto docounter          -- go to the counter stuff
  goto    as_8069_docounter

;; 065 :         clrf minutes            -- clear the minutes
  clrf    H'76'

;; 067 :     dohour:
as_8063_dohour: ; 002B

;; 069 :         movlw 0x30              -- put 48 in...
  movlw   H'30'

;; 070 :         movwf sixtieths         -- ...sixtieths
  movwf   H'74'

;; 071 :         clrf baz                -- and clear baz
  clrf    H'72'

;; 073 :         incf hours,f            -- now increment hours
  incf    H'77',f

;; 074 :         movlw 0x0C              -- xor 12 with...
  movlw   H'0C'

;; 075 :         xorwf hours,w           -- hours
  xorwf   H'77',w

;; 076 :         btfsc status_z          -- if hours == 12
  btfsc   H'03',2

;; 077 :         clrf hours              -- clear hours
  clrf    H'77'

;; 078 :         goto docounter          -- don't clear rb4cnt
  goto    as_8069_docounter

;; 082 :     b4clrcounter:
as_8066_b4clrcounter: ; 0034

;; 083 :         clrf rb4cnt             -- inactive r4b or fallthrough
  clrf    H'7B'

;; 085 :     docounter:
as_8069_docounter: ; 0035

;; 086 :         btfss intcon_t0if       -- if the t0if isn't set
  btfss   H'0B',2

;; 087 :         goto theend             -- we're done
  goto    as_8090_theend

;; 089 :         bcf intcon_t0if         -- otherwise...
  bcf     H'0B',2

;; 090 :         movlw 0xFF              -- reset clkset value
  movlw   H'FF'

;; 091 :         movwf tmr0              -- put it in tmr0
  movwf   H'01'

;; 093 :         incf sixtieths,f        -- increment sixtieths
  incf    H'74',f

;; 094 :         movlw 0x3C              -- xor 60 with...
  movlw   H'3C'

;; 095 :         xorwf sixtieths,w       -- ...sixtieths
  xorwf   H'74',w

;; 096 :         btfss status_z          -- if sixtieths != 60
  btfss   H'03',2

;; 097 :         goto dodisplay          -- just update the display
  goto    as_8075_dodisplay

;; 100 :         movlw 0x01              -- if 1...
  movlw   H'01'

;; 101 :         subwf baz,f             -- ...subtracted from baz
  subwf   H'72',f

;; 102 :         btfsc status_c          -- ...is not less than 0...
  btfsc   H'03',0

;; 103 :         goto sincr              -- just increment seconds
  goto    as_8072_sincr

;; 104 :         movlw 0x02              -- otherwise
  movlw   H'02'

;; 105 :         movwf baz               -- baz = 2
  movwf   H'72'

;; 107 :     sincr:
as_8072_sincr: ; 0045

;; 108 :         clrf sixtieths          -- clear sixtieths
  clrf    H'74'

;; 109 :         incf seconds,f          -- increment seconds
  incf    H'75',f

;; 110 :         movlw 0x3C              -- xor 60 with...
  movlw   H'3C'

;; 111 :         xorwf seconds,w         -- ...seconds
  xorwf   H'75',w

;; 112 :         btfss status_z          -- if seconds != 60
  btfss   H'03',2

;; 113 :         goto dodisplay          -- just update the display
  goto    as_8075_dodisplay

;; 116 :         clrf seconds            -- clear seconds
  clrf    H'75'

;; 117 :         incf minutes,f          -- increment minutes
  incf    H'76',f

;; 118 :         movlw 0x3C              -- xor 60 with...
  movlw   H'3C'

;; 119 :         xorwf minutes,w         -- ...minutes
  xorwf   H'76',w

;; 120 :         btfss status_z          -- if seconds != 60
  btfss   H'03',2

;; 121 :         goto dodisplay          -- just update the display
  goto    as_8075_dodisplay

;; 124 :         clrf minutes            -- clear minutes
  clrf    H'76'

;; 125 :         incf hours,f            -- increment minutes
  incf    H'77',f

;; 126 :         movlw 0x0C              -- xor 12 with...
  movlw   H'0C'

;; 127 :         xorwf hours,w           -- ...hours
  xorwf   H'77',w

;; 128 :         btfsc status_z          -- if hours == 12
  btfsc   H'03',2

;; 129 :         clrf hours              -- clear hours
  clrf    H'77'

;; 131 :     dodisplay:
as_8075_dodisplay: ; 0057

;; 132 :         movf baz,f              -- if baz...
  movf    H'72',f

;; 133 :         btfss status_z          -- != 0
  btfss   H'03',2

;; 134 :         goto notblank           -- we're writing something
  goto    as_8078_notblank

;; 135 :         movlw 0x0F              -- otherwise
  movlw   H'0F'

;; 136 :         movwf port_a            -- blank the display
  movwf   H'05'

;; 137 :         movf hours,w            -- when we're blanking
  movf    H'77',w

;; 138 :         movwf tmphours          -- update tmphours
  movwf   H'79'

;; 139 :         movf minutes,w          -- and
  movf    H'76',w

;; 140 :         movwf tmpminutes        -- tmpminutes
  movwf   H'78'

;; 141 :         goto theend             -- and we're done
  goto    as_8090_theend

;; 143 :     notblank:
as_8078_notblank: ; 0061

;; 144 :         movf tmphours,w         -- load hours
  movf    H'79',w

;; 145 :         btfsc dispmin           -- if dispmin
  btfsc   H'72',0

;; 146 :         movf tmpminutes,w       -- load minutes instead
  movf    H'78',w

;; 147 :         bsf status_rp0          -- bank 1
  bsf     H'03',5

;; 148 :         movwf f628_eeaddr       -- write address into eeaddr
  movwf   H'9B'

;; 149 :         bsf f628_eecon1_rd      -- read the data
  bsf     H'9C',0

;; 150 :         btfsc dispmin           -- if dispmin
  btfsc   H'72',0

;; 151 :         goto dataready          -- goto dataready
  goto    as_8084_dataready

;; 152 :         movf tmphours,f         -- check if tmphours == 0
  movf    H'79',f

;; 153 :         btfss status_z          -- if tmphours != 0
  btfss   H'03',2

;; 154 :         goto almostready        -- data's almost ready
  goto    as_8081_almostready

;; 155 :         movlw 0x12              -- otherwise, write 0x12...
  movlw   H'12'

;; 156 :         movwf f628_eedata       -- to the eedata register
  movwf   H'9A'

;; 157 :         goto dataready          -- _now_ we're ready
  goto    as_8084_dataready

;; 159 :     almostready:
as_8081_almostready: ; 006F

;; 160 :         movlw 0x0a              -- subtract 0x0a...
  movlw   H'0A'

;; 161 :         subwf f628_eedata,w     -- ...from f628_eedata
  subwf   H'9A',w

;; 162 :         btfsc status_c          -- if c=1, we didn't borrow, so...
  btfsc   H'03',0

;; 163 :         goto dataready          -- ...just go on
  goto    as_8084_dataready

;; 164 :         movlw 0xf0              -- otherwise, OR 0xf0...
  movlw   H'F0'

;; 165 :         iorwf f628_eedata,f     -- ...with the data, turning off
  iorwf   H'9A',f

;; 167 :     dataready:
as_8084_dataready: ; 0075

;; 168 :         movlw 0x80              -- 0x80 into...
  movlw   H'80'

;; 169 :         movwf foo               -- ...foo
  movwf   H'70'

;; 170 :         movlw 0x00              -- 0x00 into...
  movlw   H'00'

;; 171 :         movwf bar               -- ...bar
  movwf   H'71'

;; 172 :         movlw 0x1E              -- subtract 30 from
  movlw   H'1E'

;; 173 :         subwf sixtieths,w       -- sixtieths
  subwf   H'74',w

;; 174 :         btfsc status_c          -- if c=1, we didn't borrow, so
  btfsc   H'03',0

;; 175 :         goto writedata          -- we're ready to write
  goto    as_8087_writedata

;; 176 :         swapf f628_eedata,f     -- otherwise swap nibbles
  swapf   H'9A',f

;; 177 :         movlw 0x00              -- mov 0x00 into...
  movlw   H'00'

;; 178 :         movwf foo               -- ...foo
  movwf   H'70'

;; 179 :         movlw 0x40              -- mov 0x40 into...
  movlw   H'40'

;; 180 :         movwf bar               -- ...bar
  movwf   H'71'

;; 182 :     writedata:
as_8087_writedata: ; 0082

;; 183 :         movlw 0x0F              -- 0x0F into w
  movlw   H'0F'

;; 184 :         andwf f628_eedata,f     -- cut off high nibble in eedata
  andwf   H'9A',f

;; 185 :         movf foo,w              -- load decimal point
  movf    H'70',w

;; 186 :         btfsc dispmin           -- if dispmin
  btfsc   H'72',0

;; 187 :         movf bar,w              -- load this one instead
  movf    H'71',w

;; 188 :         iorwf f628_eedata,w     -- now we have the byte to write
  iorwf   H'9A',w

;; 189 :         bcf status_rp0          -- bank 0
  bcf     H'03',5

;; 190 :         movwf port_a            -- write to port_a
  movwf   H'05'

;; 193 :         movlw 0x40              -- load 64 into w
  movlw   H'40'

;; 194 :         addwf sixtieths,w       -- add the sixtieths value
  addwf   H'74',w

;; 195 :         bsf status_rp0          -- bank 1
  bsf     H'03',5

;; 196 :         movwf f628_eeaddr       -- write this to the eeaddr
  movwf   H'9B'

;; 197 :         bsf f628_eecon1_rd      -- read the data
  bsf     H'9C',0

;; 198 :         movf f628_eedata,w      -- load the data into w
  movf    H'9A',w

;; 199 :         bcf status_rp0          -- bank 0
  bcf     H'03',5

;; 200 :         movwf ccpr1l            -- this is the PWM value
  movwf   H'15'

;; 202 :     theend:
as_8090_theend: ; 0092

;; 203 :         bsf intcon_t0ie         -- enable timer interrupt
  bsf     H'0B',5
e_8047_intrh: ; 0093
  movf    H'22',w
  movwf   H'04'
  movf    H'21',w
  movwf   H'0A'
  swapf   H'20',w
  movwf   H'03'
  swapf   H'7F',f
  swapf   H'7F',w
  RETFIE  
__main: ; 009C
; var H'023:000'  transfer_bit
; var H'023:000'  transfer_byte

;; 006 : var byte foo at 0x70 = 0x80
; var H'070:000' foo
  movlw   H'80'
  movwf   H'70'

;; 007 : var byte bar at 0x71 = 0x40
; var H'071:000' bar
  movlw   H'40'
  movwf   H'71'

;; 008 : var byte baz at 0x72 = 0x02
; var H'072:000' baz
  movlw   H'02'
  movwf   H'72'

;; 009 : var bit dispmin at baz : 0
; var H'072:000' dispmin

;; 010 : var byte sixtieths at 0x74 = 0
; var H'074:000' sixtieths
  clrf    H'74'

;; 011 : var byte seconds at 0x75 = 0
; var H'075:000' seconds
  clrf    H'75'

;; 012 : var byte minutes at 0x76 = 0
; var H'076:000' minutes
  clrf    H'76'

;; 013 : var byte hours at 0x77 = 0
; var H'077:000' hours
  clrf    H'77'

;; 014 : var byte tmpminutes at 0x78 = 0
; var H'078:000' tmpminutes
  clrf    H'78'

;; 015 : var byte tmphours at 0x79 = 0
; var H'079:000' tmphours
  clrf    H'79'

;; 016 : var byte rb7cnt at 0x7a = 0
; var H'07A:000' rb7cnt
  clrf    H'7A'

;; 017 : var byte rb4cnt at 0x7b = 0
; var H'07B:000' rb4cnt
  clrf    H'7B'

;; 018 : var volatile byte f628_eedata at 0x9A
; var H'09A:000' f628_eedata

;; 019 : var volatile byte f628_eeaddr at 0x9B
; var H'09B:000' f628_eeaddr

;; 020 : var volatile byte f628_eecon1 at 0x9C
; var H'09C:000' f628_eecon1

;; 024 : var volatile bit f628_eecon1_rd at f628_eecon1 : 0
; var H'09C:000' f628_eecon1_rd

;; 025 : var volatile byte ccpr1l at 0x15
; var H'015:000' ccpr1l

;; 026 : var volatile byte ccp1con at 0x17
; var H'017:000' ccp1con

;; 027 : var volatile bit cp1x at ccp1con : 5
; var H'017:005' cp1x

;; 033 : var volatile byte cmcon at 0x1f
; var H'01F:000' cmcon

;; 034 : var volatile byte pcon at 0x8e
; var H'08E:000' pcon

;; 035 : var volatile bit oscf at pcon : 3
; var H'08E:003' oscf

;; 038 : var volatile byte t2con at 0x12
; var H'012:000' t2con

;; 039 : var volatile byte pr2 at 0x92
; var H'092:000' pr2

;; 040 : var volatile byte optionreg at 0x81
; var H'081:000' optionreg

;; 038 : var volatile byte tmr0         at  1
; var H'001:000' tmr0

;; 040 : var volatile byte status       at  3
; var H'003:000' status

;; 042 : var volatile byte port_a       at  5
; var H'005:000' port_a

;; 043 : var volatile byte port_b       at  6
; var H'006:000' port_b

;; 050 : var volatile byte intcon       at 11
; var H'00B:000' intcon

;; 097 : var volatile bit  pin_b4 at port_b : 4
; var H'006:004' pin_b4

;; 100 : var volatile bit  pin_b7 at port_b : 7
; var H'006:007' pin_b7

;; 125 : var volatile bit  status_c    at status : 0
; var H'003:000' status_c

;; 127 : var volatile bit  status_z    at status : 2
; var H'003:002' status_z

;; 130 : var volatile bit  status_rp0  at status : 5
; var H'003:005' status_rp0

;; 131 : var volatile bit  status_rp1  at status : 6
; var H'003:006' status_rp1

;; 135 : var volatile bit  intcon_gie  at intcon : 7
; var H'00B:007' intcon_gie

;; 138 : var volatile bit  intcon_t0ie at intcon : 5
; var H'00B:005' intcon_t0ie

;; 141 : var volatile bit  intcon_t0if at intcon : 2
; var H'00B:002' intcon_t0if

;; 280 : var byte trisa
; var H'024:000' trisa

;; 281 : var byte trisb
; var H'025:000' trisb

;; 288 : trisa = all_input
  movlw   H'FF'
  movwf   H'24'

;; 290 :    trisb = all_input
  movlw   H'FF'
  movwf   H'25'

;; 045 : port_a_direction = 0x30
  movlw   H'30'
  call    _3274__vector

;; 046 : port_b_direction = 0x97
  movlw   H'97'
  call    _3310__vector

;; 050 :         bcf status_rp0          -- bank 0
  bcf     H'03',5

;; 051 :         bcf status_rp1          -- ...
  bcf     H'03',6

;; 052 :         movlw 0x07              -- load 0x07...
  movlw   H'07'

;; 053 :         movwf cmcon             -- ...into cmcon
  movwf   H'1F'

;; 054 :         clrwdt                  -- clear wdt
  clrwdt  

;; 055 :         clrf tmr0               -- clear tmr0 and prescaler
  clrf    H'01'

;; 056 :         bsf status_rp0          -- bank 1
  bsf     H'03',5

;; 057 :         movlw 0x6F              -- be careful about
  movlw   H'6F'

;; 058 :         movwf optionreg         -- moving the prescaler
  movwf   H'81'

;; 059 :         clrwdt                  -- into watchdog timer
  clrwdt  

;; 060 :         movlw 0x68              -- set prescaler to 0
  movlw   H'68'

;; 061 :         movwf optionreg         -- ...
  movwf   H'81'

;; 062 :         bcf status_rp0          -- bank 0
  bcf     H'03',5

;; 063 :         movlw 0xFF              -- put initial clkset value
  movlw   H'FF'

;; 064 :         movwf tmr0              -- into tmr0
  movwf   H'01'

;; 067 :         bsf status_rp0          -- bank 1
  bsf     H'03',5

;; 068 :         bsf oscf                -- OSC = 4 MHz
  bsf     H'8E',3

;; 069 :         movlw 0xFF              -- 0xFF goes into...
  movlw   H'FF'

;; 070 :         movwf pr2               -- ...pr2
  movwf   H'92'

;; 071 :         bcf status_rp0          -- bank 0
  bcf     H'03',5

;; 072 :         clrf ccpr1l             -- set duty cycle
  clrf    H'15'

;; 073 :         bcf cp1x                -- ...
  bcf     H'17',5

;; 074 :         bcf cp1x                -- ...
  bcf     H'17',5

;; 075 :         movlw 0x04              -- load config for t2con
  movlw   H'04'

;; 076 :         movwf t2con             -- write it to t2con
  movwf   H'12'

;; 077 :         movlw 0x0F              -- load config for ccp1con
  movlw   H'0F'

;; 078 :         movwf ccp1con           -- write it into ccp1con
  movwf   H'17'

;; 081 :         bcf intcon_t0if         -- clear t0if
  bcf     H'0B',2

;; 082 :         bsf intcon_t0ie         -- enable timer interrupt
  bsf     H'0B',5

;; 083 :         bsf intcon_gie          -- unmask interrupts
  bsf     H'0B',7

;; 085 :         movlw 0b_1100_1111
  movlw   H'CF'

;; 086 :         movwf port_a
  movwf   H'05'

;; 089 : forever loop
w_8701_ag: ; 00D2

;; 090 :         asm nop
  nop     
  goto    w_8701_ag

;; 003 :   idle_loop: page goto idle_loop
as_8704_idle_loop: ; 00D4
  goto    as_8704_idle_loop

;; 341 : procedure port_b_direction'put( byte in x at trisb ) is
p_3310__port_b_direction__put_t: ; 00D5
_3310__vector: ; 00D5
; var H'025:000' x
p_3310_put: ; 00D5
  movwf   H'25'

;; 342 :    _trisb_flush
  goto    _3161__vector
e_3310_put: ; 00D7

;; 336 : procedure port_a_direction'put( byte in x at trisa ) is
p_3274__port_a_direction__put_t: ; 00D7
_3274__vector: ; 00D7
; var H'024:000' x
p_3274_put: ; 00D7
  movwf   H'24'

;; 337 :    _trisa_flush
  goto    _3138__vector
e_3274_put: ; 00D9
_3161__vector: ; 00D9
p_3161__trisb_flush: ; 00D9

;; 309 :       bank movfw trisb
  movf    H'25',w

;; 310 :            tris  6
  tris    H'06'
e_3161__trisb_flush: ; 00DB
  return  
_3138__vector: ; 00DC
p_3138__trisa_flush: ; 00DC

;; 302 :       bank movfw trisa
  movf    H'24',w

;; 303 :            tris  5
  tris    H'05'
e_3138__trisa_flush: ; 00DE
  return  

 END

; ********** variable mapping
; 01:0 : ;
;   tmr0                           * 0038:19 ../jal/lib/jpic.jal 
; 03:0 : ;
;   status_c                       * 0125:19 ../jal/lib/jpic.jal 
;   status                         * 0040:19 ../jal/lib/jpic.jal 
; 03:2 : ;
;   status_z                       * 0127:19 ../jal/lib/jpic.jal 
; 03:5 : ;
;   status_rp0                     * 0130:19 ../jal/lib/jpic.jal 
; 03:6 : ;
;   status_rp1                     * 0131:19 ../jal/lib/jpic.jal 
; 05:0 : ;
;   port_a                         * 0042:19 ../jal/lib/jpic.jal 
; 06:0 : ;
;   port_b                         * 0043:19 ../jal/lib/jpic.jal 
; 06:4 : ;
;   pin_b4                         * 0097:19 ../jal/lib/jpic.jal 
; 06:7 : ;
;   pin_b7                         * 0100:19 ../jal/lib/jpic.jal 
; 0B:0 : ;
;   intcon                         * 0050:19 ../jal/lib/jpic.jal 
; 0B:2 : ;
;   intcon_t0if                    * 0141:19 ../jal/lib/jpic.jal 
; 0B:5 : ;
;   intcon_t0ie                    * 0138:19 ../jal/lib/jpic.jal 
; 0B:7 : ;
;   intcon_gie                     * 0135:19 ../jal/lib/jpic.jal 
; 12:0 : ;
;   t2con                          * 0038:19 clock.jal 
; 15:0 : ;
;   ccpr1l                         * 0025:19 clock.jal 
; 17:0 : ;
;   ccp1con                        * 0026:19 clock.jal 
; 17:5 : ;
;   cp1x                           * 0027:18 clock.jal 
; 1F:0 : ;
;   cmcon                          * 0033:19 clock.jal 
; 23:0 : ;
;    transfer_byte                   
;    transfer_bit                    
; 24:0 : ;
;   x                              * 0336:33 ../jal/lib/jpic.jal 
;   trisa                            0280:10 ../jal/lib/jpic.jal 
; 25:0 : ;
;   x                              * 0341:33 ../jal/lib/jpic.jal 
;   trisb                            0281:10 ../jal/lib/jpic.jal 
; 70:0 : ;
;   foo                            * 0006:10 clock.jal 
; 71:0 : ;
;   bar                            * 0007:10 clock.jal 
; 72:0 : ;
;   dispmin                        * 0009:09 clock.jal 
;   baz                            * 0008:10 clock.jal 
; 74:0 : ;
;   sixtieths                      * 0010:10 clock.jal 
; 75:0 : ;
;   seconds                        * 0011:10 clock.jal 
; 76:0 : ;
;   minutes                        * 0012:10 clock.jal 
; 77:0 : ;
;   hours                          * 0013:10 clock.jal 
; 78:0 : ;
;   tmpminutes                     * 0014:10 clock.jal 
; 79:0 : ;
;   tmphours                       * 0015:10 clock.jal 
; 7A:0 : ;
;   rb7cnt                         * 0016:10 clock.jal 
; 7B:0 : ;
;   rb4cnt                         * 0017:10 clock.jal 
; 81:0 : ;
;   optionreg                      * 0040:19 clock.jal 
; 8E:0 : ;
;   pcon                           * 0034:19 clock.jal 
; 8E:3 : ;
;   oscf                           * 0035:18 clock.jal 
; 92:0 : ;
;   pr2                            * 0039:19 clock.jal 
; 9A:0 : ;
;   f628_eedata                    * 0018:19 clock.jal 
; 9B:0 : ;
;   f628_eeaddr                    * 0019:19 clock.jal 
; 9C:0 : ;
;   f628_eecon1_rd                 * 0024:18 clock.jal 
;   f628_eecon1                    * 0020:19 clock.jal 

