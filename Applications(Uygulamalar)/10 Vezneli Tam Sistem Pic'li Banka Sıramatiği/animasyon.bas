'******************************************************************
'*  Ýsim    : animasyon.BAS                                       *
'*  Yazan   : Logan                                               *
'*  Duyuru  : Her hakký yazan kiþiye ait olup, üzerinde çeþitli   *
'*          : deðiþiklik yapma hakký kullanýcýya aittir.Tamamen   *
'*          : öðretme ve örnek amaçlý yazýlmýþ bir programdýr.    *
'*  Tarih   : 28.09.2006                                          *
'*  Version : 1.0                                                 *
'*  Notlar  : Ekranda dönen þekillerin ve "PiC_PrOJE_OrG  " yazan *
'*          : alt programfýr.                                     *
'******************************************************************
goto animation_devam
'******************************************************************************
'Animasyon alt programýdýr.
'******************************************************************************
animation:
for repat=1 to 4
call shape1  :  call goster1
call shape2  :  call goster1
call shape3  :  call goster1
call shape4  :  call goster1
call shape5  :  call goster1
call shape6  :  call goster1
next repat

animation_1:
for c=1 to 15
for a=1 to 6
call sec  :  call sec1  :  call goster1
next a
next c

for z=1 to 40
call goster1
next z
return

sec:
select case a
case 1
call shape1  :  return
case 2
call shape2  :  return
case 3
call shape3  :  return
case 4
call shape4  :  return
case 5
call shape5  :  return
case 6
call shape6  :  return
end select

sec1: select case c
case 1
call shape_1  :  return
case 2
call shape_1  :  call shape_2  :  return
case 3
call shape_1  :  call shape_2  :  call shape_3
return
case 4
call shape_1  :  call shape_2
call shape_3  :  call shape_4
return
case 5
call shape_1  :  call shape_2
call shape_3  :  call shape_4  :  call shape_5
return
case 6
call shape_1  :  call shape_2  :  call shape_3  
call shape_4  :  call shape_5  :  call shape_6
return
case 7
call shape_1  :  call shape_2  :  call shape_3
call shape_4  :  call shape_5  :  call shape_6  :  call shape_7
return
case 8
call shape_1  :  call shape_2  :  call shape_3  :  call shape_4  
call shape_5  :  call shape_6  :  call shape_7  :  call shape_8
return
case 9
call shape_1  :  call shape_2  :  call shape_3  :  call shape_4
call shape_5  :  call shape_6  :  call shape_7  :  call shape_8  :  call shape_9
return
case 10
call shape_1  :  call shape_2  :  call shape_3  :  call shape_4  :  call shape_5
call shape_6  :  call shape_7  :  call shape_8  :  call shape_9  :  call shape_10
return
case 11
call shape_1
call shape_2  :  call shape_3  :  call shape_4  :  call shape_5   :  call shape_6
call shape_7  :  call shape_8  :  call shape_9  :  call shape_10  :  call shape_11
return
case 12
call shape_1  :  call shape_2
call shape_3  :  call shape_4  :  call shape_5   :  call shape_6   :  call shape_7  
call shape_8  :  call shape_9  :  call shape_10  :  call shape_11  :  call shape_12
return
case 13
call shape_1  :  call shape_2   :  call shape_3
call shape_4  :  call shape_5   :  call shape_6   :  call shape_7   :  call shape_8
call shape_9  :  call shape_10  :  call shape_11  :  call shape_12  :  call shape_13
return
case 14
call shape_1   :  call shape_2   :  call shape_3   :  call shape_4
call shape_5   :  call shape_6   :  call shape_7   :  call shape_8   :  call shape_9 
call shape_10  :  call shape_11  :  call shape_12  :  call shape_13  :  call shape_14
return
case 15
call shape_1   :  call shape_2   :  call shape_3   :  call shape_4   :  call shape_5
call shape_6   :  call shape_7   :  call shape_8   :  call shape_9   :  call shape_10
call shape_11  :  call shape_12  :  call shape_13  :  call shape_14  :  call shape_15
return
end select

shape_1:
animasyon_reg=$73
vezne_Reg[29]=animasyon_reg
vezne_Reg[14]=animasyon_reg
return
shape_2:
animasyon_reg=6
vezne_Reg[28]=animasyon_reg
vezne_Reg[13]=animasyon_reg
return
shape_3:
animasyon_reg=$39
vezne_Reg[27]=animasyon_reg
vezne_Reg[12]=animasyon_reg
return
shape_4:
animasyon_reg=8
vezne_Reg[26]=animasyon_reg
vezne_Reg[11]=animasyon_reg
return
shape_5:
animasyon_reg=$73
vezne_Reg[25]=animasyon_reg
vezne_Reg[10]=animasyon_reg
return
shape_6:
animasyon_reg=$50
vezne_Reg[24]=animasyon_reg
vezne_Reg[9]=animasyon_reg
return
shape_7:
animasyon_reg=$3f
vezne_Reg[23]=animasyon_reg
vezne_Reg[8]=animasyon_reg
return
shape_8:
animasyon_reg=$0E
vezne_Reg[22]=animasyon_reg
vezne_Reg[7]=animasyon_reg
return
shape_9:
animasyon_reg=$79
vezne_Reg[21]=animasyon_reg
vezne_Reg[6]=animasyon_reg
return
shape_10:
animasyon_reg=$08
vezne_Reg[20]=animasyon_reg
vezne_Reg[5]=animasyon_reg
return
shape_11:
animasyon_reg=$3f
vezne_Reg[19]=animasyon_reg
vezne_Reg[4]=animasyon_reg
return
shape_12:
animasyon_reg=$50
vezne_Reg[18]=animasyon_reg
vezne_Reg[3]=animasyon_reg
return
shape_13:
animasyon_reg=$7d
vezne_Reg[17]=animasyon_reg
vezne_Reg[2]=animasyon_reg
return
shape_14:
animasyon_reg=0
vezne_Reg[16]=animasyon_reg
vezne_Reg[1]=animasyon_reg
return
shape_15:
animasyon_reg=0
vezne_Reg[15]=animasyon_reg
vezne_Reg[0]=animasyon_reg
return
'******************************************************************************
'Animasyon þekilleri
'******************************************************************************
shape1:
animasyon_reg=1
for z=0 to 29
vezne_reg[y]=animasyon_reg  :  y=y+1
next z
return

shape2:
animasyon_reg=2
for z=0 to 29
vezne_reg[y]=animasyon_reg  :  y=y+1
next z
return

shape3:
animasyon_reg=4
for z=0 to 29
vezne_reg[y]=animasyon_reg  :  y=y+1
next z
return

shape4:
animasyon_reg=8
for z=0 to 29
vezne_reg[y]=animasyon_reg  :  y=y+1
next z
return

shape5:
animasyon_reg=16
for z=0 to 29
vezne_reg[y]=animasyon_reg  :  y=y+1
next z
return

shape6:
animasyon_reg=32
for z=0 to 29
vezne_reg[y]=animasyon_reg  :  y=y+1
next z
return
animation_devam:
