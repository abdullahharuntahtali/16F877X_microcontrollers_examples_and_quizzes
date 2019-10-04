'****************************************************************
'*  Name    : UNTITLED.BAS                                      *
'*  Author  : [set under view...options]                        *
'*  Notice  : Copyright (c) 2006 [set under view...options]     *
'*          : All Rights Reserved                               *
'*  Date    : 23.08.2006                                        *
'*  Version : 1.0                                               *
'*  Notes   :                                                   *
'*          :                                                   *
'****************************************************************
define OSC 20
adcon1=7  :  trisa=0  :  porta=0
trisb=0  :  portb=0
trisc=0  :  portc=0

sda var porta.4  :  scl var porta.3  :  izin var porta.5

tekrar var byte  :  lcd_reg var byte  :  veri var byte
adres_sec var byte  :  yinele var byte  :  harf_reg var byte
i var byte  :  sutun_reg var byte[320]
y var word  :  satir_reg var byte  :  w var byte
harf_sayisi var byte  :  yazi_reg var byte  :  byte_sayisi var byte
x var byte  :  z var word  :  kay_reg var word  :  b var word

tekrar=0  :  yazi_reg=0  :  satir_reg=1  :  kay_reg=0  :  y=0

main: call yazi  :  harf_sayisi=harf_reg
yazi_reg=yazi_reg+1
for i=1 to harf_sayisi
call yazi  :   call data_sec
for x=0 to yinele
call datalar  :  adres_sec=adres_sec+1
sutun_reg[y]=veri  :  y=y+1
next x
yazi_reg=yazi_reg+1
next i
yazi_reg=0  :  goto loop

loop: call logo
for b=1 to 3
call logo_goster  :  pause 1000
next b
call logo  :  goto loop1

logo_goster:
for z=1 to 10
for x=1 to 10
for i=0 to 15
portc=sutun_reg[y]  :  porta=i  :  portb=satir_reg
pauseus 50  :  portb=0
y=y+1
next i
satir_reg=satir_reg+1
next x
satir_reg=1

for x=1 to 10
for i=0 to 15
portc=sutun_reg[y]  :  porta=i  :  portb=satir_reg<<4
pauseus 50  :  portb=0
y=y+1
next i
satir_reg=satir_reg+1
next x
y=0  :  satir_reg=1
next z
satir_reg=1  :  kay_reg=0  :  return

loop1: for z=1 to 320
for x=1 to 10
for i=0 to 15 
portc=sutun_reg[y]  :  porta=i  :  portb=satir_reg
pauseus 100  :  portb=0
y=y+1
next i
satir_reg=satir_reg+1
next x
satir_reg=1

for x=1 to 10
for i=0 to 15
portc=sutun_reg[y]  :  porta=i  :  portb=satir_reg<<4
pauseus 100  :  portb=0
y=y+1
next i
satir_reg=satir_reg+1
next x
kay_reg=kay_reg+1  :  y=kay_reg  :  satir_reg=1
next z
satir_reg=1  :  kay_reg=0  :  y=0
call logo  :  goto loop

logo: for w=1 to 3
call logo_goster
next w
return

yazi:
lookup yazi_reg,[53," PiCPROJE ORG TuRKiYENiN EN   BuYuK ELEKTRONiK FORUMU"],harf_reg
return

data_sec: select case harf_reg
case "A"
adres_sec=0  :  yinele=5  :  return
case "B"
adres_sec=6  :  yinele=5  :  return
case "C"
adres_sec=12  :  yinele=5  :  return
case "D"
adres_sec=18  :  yinele=5  :  return
case "E"
adres_sec=24  :  yinele=5  :  return
case "F"
adres_sec=30  :  yinele=5  :  return
case "G"
adres_sec=36  :  yinele=5  :  return
case "H"
adres_sec=42  :  yinele=5  :  return
case "I"
adres_sec=48  :  yinele=3  :  return
case "i"
adres_sec=52  :  yinele=3  :  return
case "J"
adres_sec=56  :  yinele=5  :  return
case "K"
adres_sec=62  :  yinele=5  :  return
case "L"
adres_sec=68  :  yinele=5  :  return
case "M"
adres_sec=74  :  yinele=5  :  return
case "N"
adres_sec=80  :  yinele=5  :  return
case "O"
adres_sec=86  :  yinele=5  :  return
case "P"
adres_sec=92  :  yinele=5  :  return
case "q"
adres_sec=98  :  yinele=5  :  return
case "R"
adres_sec=104  :  yinele=5  :  return
case "S"
adres_sec=110  :  yinele=5  :  return
case "T"
adres_sec=116  :  yinele=5  :  return
case "U"
adres_sec=122  :  yinele=5  :  return
case "u"
adres_sec=128  :  yinele=5  :  return
case "V"
adres_sec=134  :  yinele=5  :  return
case "W"
adres_sec=140  :  yinele=5  :  return
case "X"
adres_sec=146  :  yinele=5  :  return
case "Y"
adres_sec=152  :  yinele=5  :  return
case "Z"
adres_sec=158  :  yinele=5  :  return
case " "
adres_sec=164  :  yinele=5  :  return
case "0"
adres_sec=170  :  yinele=5  :  return
case "1"
adres_sec=176  :  yinele=3  :  return
case "2"
adres_sec=180  :  yinele=5  :  return
case "3"
adres_sec=186  :  yinele=5  :  return
case "4"
adres_sec=192  :  yinele=5  :  return
case "5"
adres_sec=198  :  yinele=5  :  return
case "6"
adres_sec=204  :  yinele=5  :  return
case "7"
adres_sec=210  :  yinele=5  :  return
case "8"
adres_sec=216  :  yinele=5  :  return
case "9"
adres_sec=222  :  yinele=5  :  return
end select


datalar:
   lookup adres_sec,[$3F,$48,$48,$48,$3F,0_      ;A
   ,$7f,$49,$49,$49,$36,0_      ;B
   ,$3e,$41,$41,$41,$22,0_      ;C
   ,$7f,$41,$41,$41,$3e,0_      ;D
   ,$7f,$49,$49,$49,$41,0_      ;E
   ,$7f,$48,$48,$48,$40,0_      ;F
   ,$3E,$41,$49,$49,$2E,0_      ;G
   ,$7F,$08,$08,$08,$7F,0_      ;H
   ,$41,$7F,$41,0_              ;I
   ,$11,$5F,$11,0_              ;Ý
   ,$02,$01,$41,$7e,$40,0_      ;J
   ,$7f,$08,$14,$22,$41,0_      ;K
   ,$7f,$01,$01,$01,$01,0_      ;L
   ,$7f,$20,$18,$20,$7F,0_      ;M
   ,$7F,$10,$08,$04,$7F,0_      ;N
   ,$3E,$41,$41,$41,$3E,0_      ;O
   ,$7f,$48,$48,$48,$30,0_      ;P
   ,$3e,$41,$45,$42,$3d,0_      ;Q
   ,$7f,$48,$4C,$4a,$31,0_      ;R
   ,$32,$49,$49,$49,$26,0_      ;S
   ,$40,$40,$7F,$40,$40,0_      ;T
   ,$7E,$01,$01,$01,$7E,0_      ;U
   ,$1E,$41,$01,$41,$1E,0_      ;Ü
   ,$7C,$02,$01,$02,$7C,0_      ;V
   ,$7E,$01,$0E,$01,$7E,0_      ;W
   ,$63,$14,$08,$14,$63,0_      ;X
   ,$70,$08,$07,$08,$70,0_      ;Y
   ,$43,$45,$49,$51,$61,0_      ;Z
   ,$00,$00,$00,$00,$00,0_      ;Space
   ,$3E,$45,$49,$51,$3E,0_      ;0
   ,$21,$7F,$01,0_             ;1
   ,$21,$43,$45,$49,$31,0_      ;2    
   ,$42,$41,$51,$69,$46,0_      ;3
   ,$0c,$14,$24,$7f,$04,0_      ;4
   ,$72,$51,$51,$51,$4e,0_      ;5
   ,$1e,$29,$49,$49,$06,0_      ;6
   ,$40,$47,$48,$50,$60,0_      ;7
   ,$36,$49,$49,$49,$36,0_      ;8
   ,$30,$49,$49,$4a,$3c,0],veri      ;9
return

gonder: if tekrar=8 then 
 tekrar=0  :  high izin  :  pauseus 1  :  low izin  :  return
  endif
   if lcd_reg.7=1 then
    sda=1  :  scl=1  :  pauseus 1  :  scl=0
     lcd_reg=lcd_reg<<1  :  tekrar=tekrar+1  :  goto gonder
      endif
       sda=0  :  scl=1  :  pauseus 1  :  scl=0
        lcd_reg=lcd_reg<<1  :  tekrar=tekrar+1  :  goto gonder
