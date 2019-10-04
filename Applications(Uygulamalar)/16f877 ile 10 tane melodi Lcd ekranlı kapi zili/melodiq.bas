'****************************************************************
'*  Name    : Melodiq.BAS                                       *
'*  Author  : Gokhan Kurt  Neptun Elektronika / BG              *
'*  Date    : 05.05.06                                          *
'*  Version : 3.0                                               *
'*  Notes   : Pic16F877(A) 4Mhz Xtal crystal                    *
'*                                                              *
'****************************************************************



DEFINE OSC 4  
DEFINE LCD_DREG	PORTB	
DEFINE LCD_DBIT		4		
DEFINE LCD_EREG	PORTB	
DEFINE LCD_EBIT		3		
define LCD RWREG    PORTB   	
define LCD_RWBIT    2       		
DEFINE LCD_RSREG	PORTB	
DEFINE LCD_RSBIT	1		
DEFINE LCD_BITS		4		
DEFINE LCD_LINES	2	
'nota kodlari alintidir.
'***********************
P  con 0
P1 con 0
P2 con 0
P3 con 0

C0  con 60 'DO
CX0 con 61
D0  con 62 'RE
DX0 con 63
E0  con 64 'MI
F0  con 65 'FA
FX0 con 66
G0  con 67 'SOL
GX0 con 68 'SOL

C1  con 82 'DO.
CX1 con 85
D1  con 87 'RE
DX1 con 89
E1  con 92 'MI
F1  con 94 'FA
FX1 con 95
G1  con 97 'SOL
GX1 con 99 'SOL
A1  con 101 'LA
AX1 con 102 'ladiyezsibemol
B1  con 104 'si
BX1 con 105
h1  con 104

C2  con 105
CX2 con 106
D2  con 108
DX2 con 109
E2  con 110
F2  con 111
FX2 con 112
G2  con 113
GX2 con 114
A2  con 115
AX2 con 116
B2  con 117
BX2 con 118
h2  con 117
'***********************


sescikisi  var Portd.2
parca var byte


Trisd = %00000011     'PortA.0,1 giris gerisi cikis
TrisB = %00000000     'Portb cikis
PortB = 0
parca = 1             'Reset halinde baslangic melodisi


Main

if portd.0 = 0 then
    parca = parca + 1
    pause 500
    endif
    if parca > 10 then 
    parca = 1
    endif
    
    
    
    lcdout $FE, 2, "  Melodi sec:",dec parca," "
    
     select case parca
        case 1:  lcdout $FE, $C0, "Parca:","adinianmay "
        case 2:  lcdout $FE, $C0, "Parca:","Tutuklu    "          
        case 3:  lcdout $FE, $C0, "Parca:","adasahille "
        case 4:  lcdout $FE, $C0, "Parca:","aglamadegz "
        case 5:  lcdout $FE, $C0, "Parca:","agorameyha  "
        case 6:  lcdout $FE, $C0, "Parca:","agridagief  "       
        case 7:  lcdout $FE, $C0, "Parca:","aradinmi    "
        case 8:  lcdout $FE, $C0, "Parca:","artiksevme  "
        case 9:  lcdout $FE, $C0, "Parca:","askinkanun   "  
        case 10: lcdout $FE, $C0, "Parca:","Atesbocegi   "
    end select
    
    
if portd.1 = 0 then    
    gosub Parca_cal
    endif
    
goto main   

Parca_cal:

    select case parca
        case 1: gosub adinianmayacagim
        case 2: gosub Tutuklu             
        case 3: gosub adasahillerinde
        case 4: gosub aglamadegmez
        case 5: gosub agorameyhanesi
        case 6: gosub agridagiefesi        
        case 7: gosub aradinmi
        case 8: gosub artiksevmeyecegim
        case 9: gosub askinkanunu       
        case 10: gosub Atesbocegi
    end select
    pause 1000
return
adinianmayacagim: 
    Sound sescikisi,[A1,29,c2,14,h1,14,A1,29,c2,_ 
    14,h1,14,A1,14,A1,29,c2,14,h1,14,A1,29,_ 
    c2,14,h1,14,A1,14,d2,29,c2,29,h1,14,A1,_ 
    14,h1,29,A1,14,g1,114,g1,29,h1,14,A1,14,_ 
    g1,29,h1,14,A1,14,g1,14,g1,29,h1,14,A1,_ 
    14,g1,29,h1,14,A1,14,g1,14,e2,29,c2,29,_ 
    A1,29,f1,14,g1,14,f1,14,e1,43,f1,8,g1,8,_ 
    A1,8,h1,8,c2,8,d2,8,e2,43] 
return 
Tutuklu: 
    Sound sescikisi,[h1,29,c2,29,d2,29,h1,29,A1,29,_
    g1,29,f1,14,e1,14,A1,114,e1,29,f1,14,g1,14,_
    A1,57,p1,29,A1,29,h1,29,c2,29,A1,29,g1,29,f1,29,_
    e1,14,f1,14,g1,114,f1,29,e1,14,f1,14,g1,57,_
    p1,29,g1,29,A1,29,h1,29,c2,14,h1,29,A1,14,g1,29,_
    f1,14,e1,14,f1,114,p1,29,g1,29,A1,29,_
    h1,29,g1,29,f1,29,A1,14,g1,14,f1,14,e1,14,e1,57] 
return  
adasahillerinde: 
    Sound sescikisi,[c2,17,d2,17,d2,34,d2,34,c2,_ 
    17,d2,9,e2,9,d2,17,c2,17,ax1,17,ax1,9,A1,_ 
    9,c2,17,c2,9,ax1,9,A1,34,A1,17,ax1,17,c2,_ 
   17,d2,17,c2,17,ax1,17,A1,17,ax1,17,A1,17,_ 
    ax1,17,A1,17,ax1,17,d2,9,c2,9,ax1,9,A1,9,g1,34] 
return 
aglamadegmez: 
    Sound sescikisi,[c2,32,h1,16,A1,16,gx1,16,_ 
    A1,16,gx1,16,A1,16,fx1,16,d1,32,e1,8,fx1,_ 
   8,g1,32,p1,32,fx1,16,e1,47,d1,32,cx1,16,_ 
   e1,16,d1,24,e1,24,fx1,16,g1,24,A1,24,h1,_ 
   16,c2,32,h1,16,A1,16,gx1,16,A1,16,gx1,16,_ 
    A1,16,fx1,16,d1,32,e1,8,fx1,8,g1,32,p1,_ 
    32,fx1,16,e1,47,d1,32,cx1,16,e1,16,d1,32] 
return 
agorameyhanesi: 
    Sound sescikisi,[e2,63,e2,4,f2,4,e2,63,d2,_ 
    8,e2,8,f2,8,e2,8,e2,8,d2,8,d2,8,c2,8,c2,_ 
    8,ax1,8,ax1,8,A1,8,A1,8,g1,8,d2,63,d2,4,_ 
    e2,4,d2,63,c2,8,d2,8,e2,8,d2,8,d2,8,c2,_ 
    8,c2,8,ax1,8,ax1,8,A1,8,A1,16,c2,16,ax1,_ 
    95,c2,16,d2,16,c2,8,ax1,8,A1,32,d2,16,c2,_ 
    16,ax1,16,A1,24] 
return 
agridagiefesi: 
    Sound sescikisi,[A1,24,e2,24,e2,48,e2,48,e2,_ 
    24,f2,24,f2,24,e2,24,e2,24,d2,24,d2,24,_ 
    c2,24,d2,48,c2,24,d2,24,d2,48,d2,48,d2,_ 
    24,g2,24,d2,48,d2,24,c2,24,c2,24,h1,24,_ 
    c2,48,h1,24,c2,24,c2,48,c2,48,h1,24,c2,_ 
   24,c2,24,h1,24,h1,24,A1,24,A1,24,g1,24,_ 
   g1,48,h1,24,c2,24,c2,24,h1,24,h1,24,A1,_ 
    24,A1,72,A1,24,A1,48,A1,48] 
return 
aradinmi: 
    Sound sescikisi,[g1,16,g1,16,c2,32,c2,32,c2,_ 
    16,d2,16,dx2,32,dx2,16,d2,16,f2,16,d2,16,_ 
    d2,16,c2,16,d2,16,c2,16,c2,16,ax1,16,ax1,_ 
    63,f1,16,f1,16,ax1,32,ax1,32,ax1,16,c2,_ 
    16,d2,32,d2,16,c2,16,dx2,16,c2,16,c2,16,_ 
    ax1,16,c2,16,ax1,16,ax1,16,gx1,16,gx1,63,_ 
    dx1,16,dx1,16,gx1,32,gx1,32,gx1,16,ax1,_ 
    16,c2,32,c2,16,h1,16,d2,32,d2,16,c2,16,_ 
    h1,95,h1,16,c2,16,d2,8,dx2,8,d2,8,c2,8,d2,63] 
return 
artiksevmeyecegim: 
    Sound sescikisi,[e1,16,f1,16,g1,16,f1,16,e1,_ 
    16,d1,16,e1,126,p1,32,e1,16,f1,16,g1,16,_ 
    A1,16,h1,16,c2,16,A1,126,p1,32,h1,16,c2,_ 
    16,d2,16,c2,16,h1,16,A1,16,g1,32,A1,16,_ 
    h1,16,c2,16,h1,16,A1,16,g1,16,f1,32,e1,_ 
    16,f1,16,g1,16,f1,16,e1,16,d1,16,e1,8,e1,_ 
    8,e1,16,f1,8,f1,8,f1,16,g1,8,g1,8,g1,16,_ 
    f1,8,f1,8,f1,16,e1,32] 
return 
askinkanunu: 
    Sound sescikisi,[e1,19,e1,19,g1,19,g1,19,A1,_ 
    19,g1,56,A1,19,A1,37,h1,10,A1,10,g1,74,_ 
    c2,19,c2,19,A1,19,g1,19,f1,19,A1,56,g1,_ 
    19,e1,19,f1,19,d1,19,e1,19,p1,37,e2,19,_ 
    f2,37,g2,19,e2,19,d2,19,c2,37,h1,19,c2,_ 
    19,A1,19,h1,19,g1,56,p1,10,c2,19,c2,19,_ 
    A1,19,g1,19,f1,19,A1,56,g1,19,e1,19,f1,_ 
   19,d1,19,e1,37] 
return 
Atesbocegi: 
    Sound sescikisi,[e2,14,e2,14,d2,14,c2,14,d2,_ 
    21,c2,8,h1,14,d2,14,p2,14,d2,8,d2,8,c2,_ 
   14,h1,14,c2,21,h1,8,A1,29,e2,14,e2,14,d2,_ 
    14,c2,14,d2,21,c2,8,h1,14,d2,14,p2,14,d2,_ 
    8,d2,8,c2,14,h1,14,c2,21,h1,8,A1,29,e1,_ 
    14,e1,14,c2,14,c2,14,h1,8,A1,8,h1,43,p2,_ 
    14,d2,8,d2,8,c2,14,h1,14,c2,21,h1,8,A1,_ 
    29,e1,14,e1,14,c2,14,c2,14,h1,21,A1,8,h1,_ 
    29,p2,14,d2,8,d2,8,c2,14,h1,14,c2,21,h1,8,A1,29] 
return

end

