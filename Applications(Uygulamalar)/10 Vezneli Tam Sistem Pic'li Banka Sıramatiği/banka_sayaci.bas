'*****************************************************************
'*  Ýsim     : banka_sayaci.bas                                  *
'*  Yazan    : Log@n                                             *
'*  Duyuru   : Her hakký yazan kiþiye ait olup, üzerinde çeþitli *
'*           : deðiþiklik yapma hakký kullanýcýya aittir.Tamamen *
'*           : öðretme ve örnek amaçlý yazýlmýþ bir programdýr.  *
'*  Tarih    : 27.09.2006                                        *
'*  Versiyon : 1.0                                               *
'*  Notlar   : Bu program, bankalardaki sýramatik programlarýnýn *
'*           : bir benzeri olarak çalýþýr.10 adet vezneye kadar  *
'*           : rahatlýkla kullanýlabilmektedir.                  *
'*****************************************************************
define OSC 20
adcon1=7
trisa=%00111000  :  porta=0
trisb=%11000000  :  portb=%00110000
trisc=%11111111  :  portc=0
trise=0          :  porte=3
trisd=0          :  portd=0

sda var porta.4  :  scl var porta.5  :  izin var porta.3
en1 var porte.0  :  en2 var porte.1

lcd_reg var byte        :  k var byte                :  x var byte              :  sayac_reg var byte[3]
vezne_reg var byte[30]  :  i var byte                :  y var byte              :  z var byte
b var byte              :  yinele var byte           :  vezne_bul var byte      :  numara_reg var byte[3]
vezne_no var byte       :  vezne_no_birler var byte  :  vezne_no_onlar var byte :  c var byte
animasyon_reg var byte  :  repat var byte            :  tekrar_reg var byte     :  a var byte
tasma var byte          :  vezne_enable var bit      :  sira_enable var bit

vezne1_b var portc.0    :  vezne2_b var portc.1  :  vezne3_b var portc.2
vezne4_b var portc.3    :  vezne5_b var portc.4  :  vezne6_b var portc.5
vezne7_b var portc.6    :  vezne8_b var portc.7  :  vezne9_b var porta.3
vezne10_b var porta.5   :  buzzer var porte.2    :  reset_b var porta.4

include "animasyon.bas"

y=0  :  call animation
y=0  :  vezne_no=0  : tekrar_Reg=0
vezne_no_birler=0  :  vezne_no_onlar=0
sayac_reg[0]=0  :  sayac_reg[1]=0  :  sayac_reg[2]=0
numara_reg[0]=0  :  numara_reg[1]=0  :  numara_reg[2]=0
vezne_enable=1  :  sira_enable=1
for z=0 to 29
vezne_reg[y]=0  :  y=y+1
next z
'******************************************************************************
'Timer0 kesmesinin aktif edildiði ve iþlendiði alt programdýr.
'******************************************************************************
INTCON = %10100000
t0con=%11000110
goto loop

on interrupt goto myint

myint: disable
if tasma=75 then
tasma=0
if tekrar_reg=0 then
intcon.2=0  :  goto myint_go
endif
toggle vezne_enable  :  toggle sira_enable
tekrar_reg=tekrar_reg-1  :  intcon.2=0  :  goto myint_go
endif
tasma=tasma+1
intcon.2=0
myint_go: resume
enable
'******************************************************************************
'ana program baþlangýcýdýr.
'******************************************************************************
loop: 
call goster

if reset_b=1 then
call reset_at
call buzer1  :  call buzer2
call buzer1  :  call buzer2
call buzer1  :  call buzer2
goto loop
endif

if vezne1_b=1 then
vezne_bul=0  :  vezne_no=1  :  tekrar_reg=10
vezne_enable=1  :  sira_enable=1
call vezne_art  :  call buzer  :  goto loop
endif

if vezne2_b=1 then
vezne_bul=3  :  vezne_no=2  :  tekrar_reg=10
vezne_enable=1  :  sira_enable=1
call vezne_art  :  call buzer  :  goto loop
endif

if vezne3_b=1 then
vezne_bul=6  :  vezne_no=3  :  tekrar_reg=10
vezne_enable=1  :  sira_enable=1
call vezne_art  :  call buzer  :  goto loop
endif

if vezne4_b=1 then
vezne_bul=9  :  vezne_no=4  :  tekrar_reg=10
vezne_enable=1  :  sira_enable=1
call vezne_art  :  call buzer  :  goto loop
endif

if vezne5_b=1 then
vezne_bul=12  :  vezne_no=5  :  tekrar_reg=10
vezne_enable=1  :  sira_enable=1
call vezne_art  :  call buzer  :  goto loop
endif

if vezne6_b=1 then
vezne_bul=15  :  vezne_no=6  :  tekrar_reg=10
vezne_enable=1  :  sira_enable=1
call vezne_art  :  call buzer  :  goto loop
endif

if vezne7_b=1 then
vezne_bul=18  :  vezne_no=7  :  tekrar_reg=10
vezne_enable=1  :  sira_enable=1
call vezne_art  :  call buzer  :  goto loop
endif

if vezne8_b=1 then
vezne_bul=21  :  vezne_no=8  :  tekrar_reg=10
vezne_enable=1  :  sira_enable=1
call vezne_art  :  call buzer  :  goto loop
endif

if vezne9_b=1 then
vezne_bul=24  :  vezne_no=9  :  tekrar_reg=10
vezne_enable=1  :  sira_enable=1
call vezne_art  :  call buzer  :  goto loop
endif

if vezne10_b=1 then
vezne_bul=27  :  vezne_no=10  :  tekrar_reg=10
vezne_enable=1  :  sira_enable=1
call vezne_art  :  call buzer  :  goto loop
endif
goto loop
'******************************************************************************
'Reset alt programýdýr.
'******************************************************************************
reset_at:
y=0  :  vezne_no=0
vezne_no_birler=0  :  vezne_no_onlar=0
sayac_reg[0]=0  :  sayac_reg[1]=0  :  sayac_reg[2]=0
numara_reg[0]=0  :  numara_reg[1]=0  :  numara_reg[2]=0
for z=0 to 29
vezne_reg[y]=0  :  y=y+1
next z
return
'******************************************************************************
'Vezne butonlarýna basýýdýðýnda, ilgili veznenin artmasýný saðlayan programdýr.
'******************************************************************************
vezne_art:
if sayac_reg[0]=9 then
  if sayac_reg[1]=9 then
    if sayac_reg[2]=9 then
    return
    endif
    sayac_reg[1]=0  :  sayac_reg[0]=0  :  sayac_reg[2]=sayac_reg[2]+1
    goto vezne_aktar
  endif
  sayac_reg[0]=0  :  sayac_reg[1]=sayac_reg[1]+1
  goto vezne_aktar
endif
sayac_reg[0]=sayac_reg[0]+1
goto vezne_aktar

vezne_aktar:
vezne_reg[vezne_bul]=sayac_reg[0]
vezne_reg[vezne_bul+1]=sayac_reg[1]
vezne_reg[vezne_bul+2]=sayac_reg[2]
numara_reg[0]=sayac_reg[0]
numara_reg[1]=sayac_reg[1]
numara_reg[2]=sayac_reg[2]
return
'******************************************************************************
'Genel gösterge alt programýdýr.
'******************************************************************************
goster: 
for i=1 to 15
portb=i  :  lcd_reg=vezne_reg[y]  :  y=y+1
call cevir  :  portd=lcd_reg
low en1  :  pauseus 100  :  high en1
next i
for i=1 to 15
portb=i  :  lcd_reg=vezne_reg[y]  :  y=y+1
call cevir  :  portd=lcd_reg
low en2  :  pauseus 100  :  high en2
next i
y=0

lcd_reg=numara_reg[0]  :  call cevir
portd=lcd_reg
if sira_enable=0 then portd=0
porta=3  :  pauseus 100  :  porta=0
lcd_reg=numara_reg[1]  :  call cevir
portd=lcd_reg
if sira_enable=0 then portd=0
porta=2  :  pauseus 100  :  porta=0
lcd_reg=numara_reg[2]  :  call cevir
portd=lcd_reg
if sira_enable=0 then portd=0

porta=1  :  pauseus 100  :  porta=0
call vezne_no_bul
lcd_reg=vezne_no_onlar  :  call cevir
portd=lcd_reg
if vezne_enable=0 then portd=0
porta=4  :  pauseus 100  :  porta=0
lcd_reg=vezne_no_birler  :  call cevir
portd=lcd_reg
if vezne_enable=0 then portd=0
porta=5  :  pauseus 100  :  porta=0
return

goster1: y=0
for b=1 to 20
for i=1 to 15
portb=i  :  portd=vezne_reg[y]  :  y=y+1
low en1  :  pauseus 100  :  high en1
next i
for i=1 to 15
portb=i  :  portd=vezne_reg[y]  :  y=y+1
low en2  :  pauseus 100  :  high en2
next i
y=0
next b
y=0
return
'******************************************************************************
'Vezne numaralarýnýn bulunduðu alt programdýr.
'******************************************************************************
vezne_no_bul:
select case vezne_no
case 0
vezne_no_birler=0  :  vezne_no_onlar=0  :  return
case 1
vezne_no_birler=1  :  vezne_no_onlar=0  :  return
case 2
vezne_no_birler=2  :  vezne_no_onlar=0  :  return
case 3
vezne_no_birler=3  :  vezne_no_onlar=0  :  return
case 4
vezne_no_birler=4  :  vezne_no_onlar=0  :  return
case 5
vezne_no_birler=5  :  vezne_no_onlar=0  :  return
case 6
vezne_no_birler=6  :  vezne_no_onlar=0  :  return
case 7
vezne_no_birler=7  :  vezne_no_onlar=0  :  return
case 8
vezne_no_birler=8  :  vezne_no_onlar=0  :  return
case 9
vezne_no_birler=9  :  vezne_no_onlar=0  :  return
case 10
vezne_no_birler=0  :  vezne_no_onlar=1  :  return
end select
'******************************************************************************
'Lcd_reg registerindeki bilgiyi displaylerde görülebilecek þekilde deðiþtirir.
'******************************************************************************
cevir: select case lcd_reg
case 0
 lcd_reg=%00111111  :  return
case 1
 lcd_reg=%00000110  :  return
case 2
 lcd_reg=%01011011  :  return
case 3
 lcd_reg=%01001111  :  return
case 4
 lcd_reg=%01100110  :  return
case 5
 lcd_reg=%01101101  :  return
case 6
 lcd_reg=%01111101  :  return
case 7
 lcd_reg=%00000111  :  return
case 8
 lcd_reg=%01111111  :  return
case 9
 lcd_reg=%01101111  :  return
  end select

buzer: high buzzer
for b=1 to 40
call goster
next b
low buzzer
return

buzer1: high buzzer
for b=1 to 115
call goster
next b
low buzzer
return

buzer2:
for b=1 to 150
call goster
next b
return
