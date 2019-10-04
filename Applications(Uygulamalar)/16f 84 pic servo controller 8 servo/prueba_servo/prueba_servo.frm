VERSION 5.00
Object = "{648A5603-2C6E-101B-82B6-000000000014}#1.1#0"; "MSCOMM32.OCX"
Begin VB.Form prueba_servo 
   Caption         =   "Form1"
   ClientHeight    =   5145
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   10545
   LinkTopic       =   "Form1"
   ScaleHeight     =   5145
   ScaleWidth      =   10545
   StartUpPosition =   3  'Windows Default
   Begin VB.OptionButton Option8 
      Caption         =   "Salida 3 OFF"
      Height          =   375
      Left            =   7800
      TabIndex        =   21
      Top             =   2760
      Width           =   1215
   End
   Begin VB.OptionButton Option7 
      Caption         =   "Salida 3 ON"
      Height          =   375
      Left            =   6360
      TabIndex        =   20
      Top             =   2760
      Width           =   1335
   End
   Begin VB.OptionButton Option6 
      Caption         =   "Salida 2 OFF"
      Height          =   495
      Left            =   7800
      TabIndex        =   19
      Top             =   2160
      Width           =   1215
   End
   Begin VB.OptionButton Option5 
      Caption         =   "Salida 2 ON"
      Height          =   495
      Left            =   6360
      TabIndex        =   18
      Top             =   2160
      Width           =   1455
   End
   Begin VB.OptionButton Option4 
      Caption         =   "Salida 1 OFF"
      Height          =   495
      Left            =   7800
      TabIndex        =   17
      Top             =   1680
      Width           =   1215
   End
   Begin VB.OptionButton Option3 
      Caption         =   "Salida 1 ON"
      Height          =   495
      Left            =   6360
      TabIndex        =   16
      Top             =   1680
      Width           =   1335
   End
   Begin VB.OptionButton Option2 
      Caption         =   "Salida 0 OFF"
      Height          =   375
      Index           =   0
      Left            =   7800
      TabIndex        =   15
      Top             =   1200
      Width           =   1335
   End
   Begin VB.CommandButton Command3 
      Caption         =   "Deshabilita"
      Height          =   255
      Left            =   3000
      TabIndex        =   14
      Top             =   360
      Width           =   975
   End
   Begin VB.HScrollBar HScroll8 
      Height          =   255
      Left            =   3000
      Max             =   255
      TabIndex        =   13
      Top             =   2760
      Width           =   2655
   End
   Begin VB.HScrollBar HScroll7 
      Height          =   255
      Left            =   3000
      Max             =   255
      TabIndex        =   12
      Top             =   2280
      Width           =   2655
   End
   Begin VB.HScrollBar HScroll6 
      Height          =   255
      Left            =   3000
      Max             =   255
      TabIndex        =   11
      Top             =   1800
      Width           =   2655
   End
   Begin VB.HScrollBar HScroll5 
      Height          =   255
      Left            =   3000
      Max             =   255
      TabIndex        =   10
      Top             =   1320
      Width           =   2655
   End
   Begin VB.OptionButton Option1 
      Caption         =   "Salida 0 ON"
      Height          =   375
      Index           =   0
      Left            =   6360
      TabIndex        =   9
      Top             =   1200
      Width           =   1215
   End
   Begin VB.Timer Timer1 
      Enabled         =   0   'False
      Interval        =   500
      Left            =   5400
      Top             =   4560
   End
   Begin VB.TextBox Text4 
      Height          =   375
      Left            =   6600
      TabIndex        =   8
      Top             =   240
      Width           =   855
   End
   Begin VB.HScrollBar HScroll4 
      Height          =   255
      Index           =   0
      Left            =   360
      Max             =   255
      Min             =   50
      TabIndex        =   7
      Top             =   2760
      Value           =   50
      Width           =   2535
   End
   Begin VB.HScrollBar HScroll3 
      Height          =   255
      Index           =   0
      Left            =   360
      Max             =   255
      Min             =   50
      TabIndex        =   6
      Top             =   2280
      Value           =   50
      Width           =   2535
   End
   Begin VB.HScrollBar HScroll2 
      Height          =   255
      Index           =   0
      Left            =   360
      Max             =   255
      Min             =   50
      SmallChange     =   16
      TabIndex        =   5
      Top             =   1800
      Value           =   50
      Width           =   2535
   End
   Begin VB.HScrollBar HScroll1 
      Height          =   255
      Index           =   0
      Left            =   360
      Max             =   255
      Min             =   50
      TabIndex        =   4
      Top             =   1320
      Value           =   50
      Width           =   2535
   End
   Begin VB.CommandButton Command2 
      Caption         =   "Habilita"
      Height          =   255
      Left            =   1800
      TabIndex        =   3
      Top             =   360
      Width           =   1095
   End
   Begin VB.TextBox Text1 
      Height          =   285
      Left            =   960
      TabIndex        =   1
      Text            =   "0"
      Top             =   330
      Width           =   735
   End
   Begin VB.CommandButton Command1 
      Caption         =   "(Re-)Comienza"
      Height          =   375
      Left            =   4200
      TabIndex        =   0
      Top             =   240
      Width           =   1215
   End
   Begin MSCommLib.MSComm MSComm1 
      Left            =   6120
      Top             =   3480
      _ExtentX        =   1005
      _ExtentY        =   1005
      _Version        =   393216
      DTREnable       =   -1  'True
      Handshaking     =   2
      BaudRate        =   2400
   End
   Begin VB.Label Label8 
      Caption         =   "0"
      Height          =   255
      Left            =   0
      TabIndex        =   28
      Top             =   1320
      Width           =   375
   End
   Begin VB.Label Label7 
      Caption         =   "3"
      Height          =   375
      Left            =   0
      TabIndex        =   27
      Top             =   2760
      Width           =   375
   End
   Begin VB.Label Label6 
      Caption         =   "2"
      Height          =   255
      Left            =   0
      TabIndex        =   26
      Top             =   2280
      Width           =   375
   End
   Begin VB.Label Label5 
      Caption         =   "1"
      Height          =   255
      Left            =   0
      TabIndex        =   25
      Top             =   1800
      Width           =   375
   End
   Begin VB.Label Label4 
      Caption         =   "Offset"
      Height          =   375
      Left            =   4200
      TabIndex        =   24
      Top             =   960
      Width           =   1095
   End
   Begin VB.Label Label3 
      Caption         =   "Posicion"
      Height          =   255
      Left            =   1320
      TabIndex        =   23
      Top             =   960
      Width           =   735
   End
   Begin VB.Label Label2 
      Caption         =   "Lectura"
      Height          =   255
      Left            =   5880
      TabIndex        =   22
      Top             =   360
      Width           =   855
   End
   Begin VB.Label Label1 
      Caption         =   "Servo #"
      Height          =   375
      Left            =   240
      TabIndex        =   2
      Top             =   360
      Width           =   735
   End
End
Attribute VB_Name = "prueba_servo"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
' Programa para la demostracion de las utilidades de la tarjeta
' de control de servos con un pic 16f84 desarrollada por Ashley
' Roll. Su programa estaba desarrollado para QBASIC y esta es su
' adaptacion para Visual Basic 6.0, escrita por JoseMaria
' DiazdelaCruz.

' El programa que corre en el PIC solo difiere del original en
' la adicion de una respuesta a la orden de posicionamiento
' consistente en el byte de posicion. Los caracteres recibidos
' se visualizan en la parte superior derecha del formulario.

' Se ha probado este programa en sistemas Windows 98,2K, XP y no
' se encuentra optimizado, teniendo algunas variables innecesarias
' que no he suprimido tras la depuracion.

' Tambien se dispone de un control ActiveX que realiza todas las
' funciones y puede ser transportado e incluido en páginas HTML,
' ASP, etc.

' JoseMaria DiazdelaCruz e-mail: jmdiaz@etsii.upm.es
' Madrid, 19 de octubre de 2002.

Dim position, fallos, positiona, aciertos As Integer

Private Sub Command1_Click()


MSComm1.Output = Chr(0)

For i = 1 To 30000
j = 100000 / i
Next i
MSComm1.Output = Chr(0)

For i = 1 To 30000
j = 100000 / i
Next i
MSComm1.Output = Chr(0)

For i = 1 To 30000
j = 100000 / i
Next i


End Sub

Private Sub Command2_Click()
Dim ServoNum As Integer
ServoNum = 0 + Text1.Text
If ServoNum >= 0 And ServoNum <= 3 Then
              

        ' Send the command to the Controller
        MSComm1.Output = Chr$(48 + ServoNum)
Else
    MsgBox ("fuera de rango")
End If
    
End Sub

Private Sub Command3_Click()
Dim ServoNum, valor As Integer

ServoNum = 0 + Text1.Text
If ServoNum >= 0 And ServoNum <= 3 Then
        ' Send the command to the Controller
        MSComm1.Output = Chr$(64 + ServoNum)
       
Else
    MsgBox ("fuera de rango")
End If
End Sub

Private Sub Command4_Click()
Dim ServoNum, valor As Integer
valor = 0 + Text2.Text
ServoNum = 0 + Text1.Text
If ServoNum >= 0 And ServoNum <= 3 And valor < 256 Then
        ' Send the command to the Controller
        MSComm1.Output = Chr$(32 + ServoNum)
        For i = 1 To 1000
        j = i
        Next i
        MSComm1.Output = Chr$(valor)
Else
    MsgBox ("fuera de rango")
End If
End Sub

Private Sub Command5_Click()
Text3.Text = Text3.Text + MSComm1.Input

End Sub

Private Sub Command6_Click()
Timer1.Enabled = True

End Sub

Private Sub Command7_Click()
MSComm1.Output = Chr$(80 + 3)
End Sub

Private Sub Command8_Click()
MSComm1.Output = Chr$(96 + 3)

End Sub

Private Sub Form_Load()
position = 50
positiona = 50
fallos = 0
aciertos = 0
Timer1.Enabled = False

MSComm1.PortOpen = True
MSComm1.Settings = "2400,n,8,1"
'MSComm1.PortOpen = True
'MSComm1.Settings = "2400,n,8,1"
'MSComm1.Output = Chr(0)
'MSComm1.Output = Chr(0)
'MSComm1.Output = Chr(0)
'For i = 0 To 3
'MSComm1.Output = Chr$(48 + i)
'Next i
End Sub
Private Sub HScroll1_Change(Index As Integer)
        MSComm1.Output = Chr$(16 + 0)
        


        MSComm1.Output = Chr$(HScroll1(0).Value)
End Sub

Private Sub HScroll2_Change(Index As Integer)
MSComm1.Output = Chr$(16 + 1)
        
        MSComm1.Output = Chr$(HScroll2(0).Value)
End Sub

Private Sub HScroll3_Change(Index As Integer)
MSComm1.Output = Chr$(16 + 2)
        
        MSComm1.Output = Chr$(HScroll3(0).Value)
End Sub

Private Sub HScroll4_Change(Index As Integer)
MSComm1.Output = Chr$(16 + 3)
        
        MSComm1.Output = Chr$(HScroll4(0).Value)
End Sub

Private Sub HScroll5_Change()
MSComm1.Output = Chr$(32 + 0)
MSComm1.Output = Chr$(HScroll5.Value)

End Sub

Private Sub HScroll6_Change()
MSComm1.Output = Chr$(32 + 1)
MSComm1.Output = Chr$(HScroll6.Value)
End Sub

Private Sub HScroll7_Change()
MSComm1.Output = Chr$(32 + 2)
MSComm1.Output = Chr$(HScroll7.Value)
End Sub

Private Sub HScroll8_Change()
MSComm1.Output = Chr$(32 + 3)
MSComm1.Output = Chr$(HScroll8.Value)
End Sub

Private Sub MSComm1_OnComm()
' DTR Enable= True
' Handshaking = 2 - comRTS

    s = MSComm1.Input
   
    If s <> "" Then
   
    Text4.Text = Asc(s)
    If positiona - Val(Asc(s)) <> 0 Then
    fallos = fallos + 1
    Else
    aciertos = aciertos + 1
    End If
    
    End If
End Sub

Private Sub Option1_Click(Index As Integer)
MSComm1.Output = Chr$(80)
Option2(0).Value = False

End Sub

Private Sub Option2_Click(Index As Integer)
MSComm1.Output = Chr$(96)
Option1(0).Value = False

End Sub

Private Sub Option3_Click()
MSComm1.Output = Chr$(80 + 1)
Option4.Value = False
End Sub

Private Sub Option4_Click()
MSComm1.Output = Chr$(96 + 1)
Option3.Value = False

End Sub

Private Sub Option5_Click()
MSComm1.Output = Chr$(80 + 2)
Option6.Value = False
End Sub

Private Sub Option6_Click()
MSComm1.Output = Chr$(96 + 2)
Option5.Value = False

End Sub

Private Sub Option7_Click()
MSComm1.Output = Chr$(80 + 3)
Option8.Value = False
End Sub

Private Sub Option8_Click()
MSComm1.Output = Chr$(96 + 3)
Option7.Value = False

End Sub

Private Sub Timer1_Timer()

positiona = position
MSComm1.Output = Chr$(16 + 0)
        
        MSComm1.Output = Chr$(position)
        
        If position < 255 Then
        position = position + 1
        Else
        position = 50
        End If
End Sub
