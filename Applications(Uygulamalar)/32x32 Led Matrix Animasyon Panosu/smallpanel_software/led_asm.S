/*
 * LED Matrix Assembler subroutines
 */

#ifndef __tmp_reg__
#define __tmp_reg__     r0
#endif
#ifndef __zero_reg__
#define __zero_reg__    r1
#endif

BUFSIZE= 256
P0     = 24			; first incoming parameter (MSB)
P1     = 25			; 2nd incoming parameter

work1	= 18
work2	= 19
work3	= 20
loZ     = 30
hiZ     = 31

.macro load_Z p
ldi	r30, lo8(\p)
ldi	r31, hi8(\p)
.endm

.macro add_Z p
subi r30,lo8(-\p)
sbci r31,hi8(-\p)
.endm

.macro addb_Z p
add  r30,\p
adc  r31,__zero_reg__
.endm

.section .text

/*
 * void drawpixel(u_char x, u_char y, u_char color)
 */
.global drawpixel
drawpixel:
  load_Z buffer				// pointer to red buffer
  addb_Z P0           // add X
  mov    R0,P1        // get Y
  lsr    R0           // Y/8
  lsr    R0           
  lsr    R0           
  lsl    R0           // (Y/8)*MAXX
  lsl    R0
  lsl    R0
  lsl    R0
  lsl    R0
  addb_Z R0           // add Y/8*MAXX
  mov    work1,P1        // get Y
  andi   work1,0x07   // get lower three bits to adress pixel bit
//  ldi    work1,0xAA
  st     Z,work1
  add_Z  BUFSIZE>>1   // switch to green buffer
  ldi    work1,0x55
  st     Z,work1
  ret


  