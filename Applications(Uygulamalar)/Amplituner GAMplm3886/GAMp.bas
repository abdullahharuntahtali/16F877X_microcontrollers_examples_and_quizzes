'--------------------------------------------------------------------------------------------------------
'   GAMP.bas - program sterownika amplitunera GAMP
'
'   kompliator: BASCOM-AVR ver.1.11.6.7
'   wersja: 2.1 FINAL!
'   autor: Bart³omiej Gross
'   mail: audiofilek@interia.pl
'   www: audiofilek.za.pl
'   NOT FOR COMMERCIAL USAGE!
'--------------------------------------------------------------------------------------------------------

 $regfile = "8535def.dat"
 $crystal = 8000000
 Config Lcd = 16 * 1a
 Config Lcdpin = Pin , Db4 = Pina.0 , Db5 = Pina.1 , Db6 = Pina.2 , Db7 = Pina.3 , E = Pina.4 , Rs = Pina.5
 Config Timer1 = Pwm , Pwm = 8 , Prescale = 8 , Compare A Pwm = Clear Down
 Config I2cdelay = 50
 Config Sda = Porta.7
 Config Scl = Porta.6
 Config Rc5 = Portb.7
 Config Clock = Soft , Gosub = Sectic

 Config Portb = Input                                                 ' Klawisze
 Config Pind.2 = Output                                               ' Czerwona
 Config Pind.3 = Output                                               ' Zielona
 Config Pind.6 = Output                                               ' Triac
 Config Pind.7 = Input                                                ' Kana³ B impulsatora
 Config Pinc.0 = Input                                                ' Kana³ A impulsatora
 Config Pinc.1 = Input                                                ' Przycisk impulsatora
 Config Pinc.2 = Input                                                ' OM5610 - STEREO
 Config Pinc.4 = Output                                               ' OM5610 - CLK
 Config Pinc.5 = Output                                               ' OM5610 - WREN

 B Alias Pinc.0                                                       ' Kana³ B impulsatora
 A Alias Pind.7                                                       ' Kana³ A impulsatora

 Enable Interrupts
 Stop Watchdog
 Cursor Off

 Const T4 = "   Bass: "
 Const T5 = " Treble: "
 Const T6 = " SLEEP"
 Const T7 = "  OFF"
 Const T8 = " 30 min."
 Const T9 = " 60 min."
 Const T10 = " 80 min."
 Const T14 = "    Mute"
 Const T15 = "  ON"
 Const T19 = "-14dB"
 Const T20 = "-12dB"
 Const T21 = "-10dB"
 Const T22 = " -8dB"
 Const T23 = " -6dB"
 Const T24 = " -4dB"
 Const T25 = " -2dB"
 Const T26 = " flat"
 Const T27 = " +2dB"
 Const T28 = " +4dB"
 Const T29 = " +6dB"
 Const T30 = " +8dB"
 Const T31 = "+10dB"
 Const T32 = "+12dB"
 Const T33 = "+14dB"

 Deflcdchar 1 , 14 , 21 , 21 , 23 , 17 , 17 , 14 , 32                 ' Znak zegara
 Cls                                                                  ' Wybór LCD DATA RAM

 Declare Sub Init                                                     ' Inicjalizacja
 Declare Sub Power_off                                                ' "STAND-BY"
 Declare Sub Power_on                                                 ' POWER ON
 Declare Sub Set_time                                                 ' Ustawianie czasu i alarmu
 Declare Sub Toggle_alarm                                             ' Alarm ON/OFF
 Declare Sub Change_input                                             ' Zmiana wejscia
 Declare Sub Audio_function                                           ' Funkcje audio
 Declare Sub Detect_encoder                                           ' Obs³uga impulsatora
 Declare Sub Volume_up                                                ' G³oœniej
 Declare Sub Volume_down                                              ' Ciszej
 Declare Sub Tune                                                     ' Ustawia stacje i
 Declare Sub Count_frequency                                          ' wyœwietla na LCD
 Declare Sub Complet_reg                                              ' Kompletuje rejestr OM5610
 Declare Sub Tuner_function                                           ' Funkcje tunera
 Declare Sub Next_station                                             ' Nastêpna stacja
 Declare Sub Prev_station                                             ' Poprzednia stacja
 Declare Sub Tuner_check                                              ' Sprawdza czy MONO lub STEREO
 Declare Sub Write_om                                                 ' Zapisuje rejestr OM5610
 Declare Sub Write_tda                                                ' Zapisuje dane do TDA7318
 Declare Sub Get_rc5                                                  ' Odbiera komendy RC5
 Declare Sub 100ms                                                    ' OpóŸnienie 100ms
 Declare Sub 500ms                                                    ' OpóŸnienie 500ms
 Declare Sub 5ms                                                      ' OpóŸnienie 5ms
 Declare Sub Green                                                    ' Zielona LED
 Declare Sub Red                                                      ' Czerwona LED
 Declare Sub Yellow                                                   ' ¯ó³ta LED
 Declare Sub Count_bass_val                                           ' Liczy dB dla BASS
 Declare Sub Count_treble_val                                         ' Liczy dB dla TREBLE
 Declare Sub Muting_on                                                ' Wyciszenie wzmacniacza
 Declare Sub Muting_off                                               ' !Wyciszenie wzmacniacza

 Dim Sleep_f As Bit                                                   ' Sleep ON/OFF
 Dim Alarm_f As Bit                                                   ' Alarm ON/OFF
 Dim Mute_f As Bit                                                    ' Mute ON/OFF

 Dim Volume As Byte                                                   ' Wartoœæ VOLUME
 Dim Vol_cd As Byte                                                   ' Wzmocnienie CD
 Dim Vol_tuner As Byte                                                ' Wzmocnienie TUNER
 Dim Vol_in1 As Byte                                                  ' Wzmocnienie IN 1
 Dim Vol_in2 As Byte                                                  ' Wzmocnienie IN 2
 Dim Bass As Byte                                                     ' Wartoœæ BASS
 Dim Bass_cd As Byte                                                  ' BASS dla CD
 Dim Bass_tuner As Byte                                               ' BASS dla TUNER
 Dim Bass_in1 As Byte                                                 ' BASS dla IN 1
 Dim Bass_in2 As Byte                                                 ' BASS dla IN 2
 Dim Treble As Byte                                                   ' Wartoœæ TREBLE
 Dim Treble_cd As Byte                                                ' TREBLE dla CD
 Dim Treble_tuner As Byte                                             ' TREBLE dla CD
 Dim Treble_in1 As Byte                                               ' TREBLE dla CD
 Dim Treble_in2 As Byte                                               ' TREBLE dla CD
 Dim Wejscie As Byte                                                  ' Numer wejœcia

 Dim Bass_val As String * 5                                           ' Wartoœæ BASS w dB [na LCD]
 Dim Treble_val As String * 5                                         ' Wartoœæ TREBLE w dB [na LCD]

 Dim Alarm_m As Byte                                                  ' Minuty alarmu
 Dim Alarm_h As Byte                                                  ' Godziny alarmu
 Dim Alarm_h_bcd As Byte                                              ' Godziny alarmu w BCD
 Dim Alarm_m_bcd As Byte                                              ' Minuty alarmu w BCD
 Dim Alarm_nr_st As Byte                                              ' Numer stacji alarmu
 Dim Alarm_chr As String * 1                                          ' Znacznik ALARM [na LCD]
 Dim Sleep_time As Word                                               ' Wartoœæ do zliczenia
 Dim Sleep_counter As Word                                            ' Licznik czasu

 Dim Station_number As Byte                                           ' Numer aktualnej stacji
 Dim Station(9) As Eram Word                                          ' Stacje w EEPROM
 Dim Frequency As Word                                                ' Do obliczania czêstotliwoœci
 Dim Reg As Long                                                      ' Rejestr OM5610
 Dim F As Single
 Dim Freq As Integer
 Dim Tuner_nr_st As String * 1                                        ' Numer stacji [na LCD]
 Dim Tuner_freq As String * 5                                         ' Czêstotliwoœæ stacji [na LCD]
 Dim Tuner_stereo As String * 2                                       ' Znacznik STEREO [na LCD]
 Dim A_ As String * 2                                                 ' 1 znak dostrojenia [na LCD]
 Dim B_ As String * 2                                                 ' 2 znak dostrojenia [na LCD]

 Dim Adres As Byte                                                    ' Adres RC5
 Dim Komenda As Byte                                                  ' Komenda RC5
 Dim Idx As Byte                                                      ' Indeks bitów zmiennej OM_REG
 Dim Pwm As Byte
 Dim Pwm_temp As Byte
 Dim Audio_fun As Byte                                                ' Numer aktualnej funkcji audio
 Dim Sleep_nr As Byte                                                 ' Numer aktualnej wartoœci SLEEP
 Dim Eeprom As Eram Byte
 Dim St_temp As Byte
 Dim Temp_ As Byte
 Dim Temp As Byte
 Dim Temp_0 As Byte
 Dim Temp_1 As Word
 Dim Temp_2 As Byte
 Dim Temp_3 As Byte
 Dim Af As Bit
 Dim Alarm_on As Bit
 Dim Sleep_on As Bit

 Goto Init

'--------------------------------------------------------------------------------------------------------

 Sub Init:

     Portd.6 = 0
     Wejscie = 91                                                     ' IN 2
     Volume = &B00100000                                              ' -40 dB
     Vol_cd = &B00100000                                              ' -40 dB
     Vol_tuner = &B00100000                                           ' -40 dB
     Vol_in1 = &B00100000                                             ' -40 dB
     Vol_in2 = &B00100000                                             ' -40 dB
     Bass = 110                                                       ' +2 dB
     Bass_cd = 110                                                    ' +2 dB
     Bass_tuner = 110                                                 ' +2 dB
     Bass_in1 = 110                                                   ' +2 dB
     Bass_in2 = 110                                                   ' +2 dB
     Treble = 126                                                     ' +2 dB
     Treble_cd = 126                                                  ' +2 dB
     Treble_tuner = 126                                               ' +2 dB
     Treble_in2 = 126                                                 ' +2 dB
     Treble_in1 = 126                                                 ' +2 dB
     Audio_fun = 1                                                    ' VOLUME
     Station_number = 1                                               ' Stacja 1
     Alarm_h = 0
     Alarm_m = 0
     Alarm_nr_st = 1                                                  ' Alarm na 1 stacjê

     If Eeprom <> 150 Then                                            ' Zapis stacji od EEPROM
      For Temp = 1 To 9
       Station(temp) = 7856                                           ' 87.5 MHz na wszystkie stacje
       Eeprom = 150
      Next
     End If

     Call Tune
     Call Count_frequency
     Call Tuner_check
     Call Count_bass_val
     Call Count_treble_val
     Call Change_input
     Goto Power_off

 End Sub

'------------------------------------------------

 Sub Power_off:

     Call Muting_on                                                   ' Wyciszenie
     Call 100ms
     Call 100ms
     Sleep_f = 0
     Sleep_nr = 0
     Sleep_time = 0
     Sleep_counter = 0
     Sleep_on = 0
     Pwm1a = 0
     Call Red                                                         ' Czerwona LED
     Reset Portd.6                                                    ' Wy³¹czenie wzmacniacza
     Cls

     Do

       Home : Lcd "    " ; Time$ ; "  " ; Alarm_chr                   ' Wyœwietlanie czasu

       Call Get_rc5
       If Komenda = 12 Then Goto Power_on
       If Komenda = 31 Then Pwm1a = 255 Else Pwm1a = 0

       Set Portb.0
       Call 5ms
       If Pinb.0 = 1 Then Power_on                                    ' POWER

       Set Portb.6
       Call 5ms
       If Pinb.6 = 1 Then Toggle_alarm                                ' TOGGLE ALARM

       Set Portb.5
       Call 5ms
       If Pinb.5 = 1 Then Set_time                                    ' SET TIME

       If Alarm_on = 1 Then                                           ' Sprawdzanie alarmu
        Alarm_on = 0
        Wejscie = 73
        Volume = 29
        Station_number = Alarm_nr_st
        Call Tune
        Call Write_tda
        Goto Power_on
       End If

     Loop

 End Sub

'------------------------------------------------

 Sub Toggle_alarm:

     Toggle Alarm_f
     If Alarm_f = 1 Then
      Alarm_chr = Chr(1)
     Else
      Alarm_chr = " "
     End If
     Call 100ms

 End Sub

'------------------------------------------------

 Sub Set_time:

     Cls
     For Temp_2 = 0 To 20
       Home
       Lcd " Time: " ; Time$

       Set Portb.3                                                    ' PLUS [+]
       Call 5ms
       If Pinb.3 = 1 Then
        Incr _hour
        Temp_2 = 0
       End If
       If _hour = 24 Then _hour = 00
       Call 100ms

       Set Portb.4                                                    ' MINUS [-]
       Call 5ms
       If Pinb.4 = 1 Then
        Incr _min
        Temp_2 = 0
       End If
       If _min = 60 Then _min = 00
       Call 100ms

       Set Portb.5                                                    ' ENTER
       Call 5ms
       If Pinb.5 = 1 Then Goto Alarm_set
     Next

     Cls
     Exit Sub

  Alarm_set:

     Call 100ms
     Call 100ms
     Cls
     Do

       Alarm_m_bcd = Makebcd(alarm_m)
       Alarm_h_bcd = Makebcd(alarm_h)

       Home
       Lcd " Alarm: " ; Bcd(alarm_h_bcd) ; ":" ; Bcd(alarm_m_bcd)

       Set Portb.3                                                    ' PLUS [+]
       Call 5ms
       If Pinb.3 = 1 Then Incr Alarm_h
       If Alarm_h = 24 Then Alarm_h = 00
       Call 100ms

       Set Portb.4                                                    ' MINUS [-]
       Call 5ms
       If Pinb.4 = 1 Then Incr Alarm_m
       If Alarm_m = 60 Then Alarm_m = 00
       Call 100ms

       Set Portb.5                                                    ' ENTER
       Call 5ms
       If Pinb.5 = 1 Then Goto Alarm_st_set

     Loop

  Alarm_st_set:

     Call 100ms
     Call 100ms
     Cls
     Do

       Home
       Lcd " Station: " ; Alarm_nr_st

       Set Portb.3                                                    ' PLUS [+]
       Call 5ms
       If Pinb.3 = 1 Then Incr Alarm_nr_st
       If Alarm_nr_st = 10 Then Alarm_nr_st = 1
       Call 100ms

       Set Portb.5                                                    ' ENTER
       Call 5ms
       If Pinb.5 = 1 Then Exit Do

     Loop
     Cls

 End Sub

'------------------------------------------------

 Sub Power_on:

     Call 100ms
     Call 100ms
     Set Portd.6                                                      ' W³¹czenie wzmacniacza
     Call Green                                                       ' Zielona LED
     Pwm1a = Pwm_temp
     If Volume < &B00010000 Then                                      ' Redukcja wzmocnienia
      Volume = 24
      Call Write_tda
     End If
     Call Muting_off
     Cls

     Do

       Call Detect_encoder

       Home                                                           ' Wyœwietlanie tekstów
       Select Case Wejscie
        Case 88 : Lcd "------ CD ------"
        Case 73 : Lcd " " ; A_ ; Station_number ; B_ ; " " ; Tuner_freq ; "MHz " ; Tuner_stereo
        Case 90 : Lcd "----- IN 1 -----"
        Case 91 : Lcd "----- IN 2 -----"
       End Select

       Call Detect_encoder                                            ' Obs³uga impulsatora

       If Wejscie = 73 Then
          Set Portb.3
          Call 5ms
          If Pinb.3 = 1 Then Next_station                             ' Przycisk PLUS [+]

          Set Portb.4
          Call 5ms
          If Pinb.4 = 1 Then Prev_station                             ' Przycisk MINUS [-]

          Call Detect_encoder

          Set Portb.5
          Call 5ms
          If Pinb.5 = 1 Then Tuner_function                           ' Przycisk ENTER / SET TIME
          Call Tuner_check
       End If

       Call Detect_encoder

       Set Portb.0
       Call 5ms
       If Pinb.0 = 1 Then Goto Power_off                              ' Przycisk POWER

       Set Portb.1
       Call 5ms
       If Pinb.1 = 1 Then Audio_function                              ' Przycisk KOREKTOR

       Call Detect_encoder

       Set Portb.2
       Call 5ms
       If Pinb.2 = 1 Then Change_input                                ' Przycisk WEJSCIE

       Call Detect_encoder                                            ' Obs³uga impulsatora

       Call Get_rc5
       Select Case Komenda
        Case 12 : Goto Power_off                                      ' POWER OFF
        Case 30 : Call Change_input                                   ' Wybór wejscia
        Case 16 : Call Volume_up                                      ' G³oœniej
        Case 17 : Call Volume_down                                    ' Ciszej
        Case 13 : Toggle Mute_f                                       ' MUTE ON/OFF
                  If Mute_f = 1 Then
                   Call Muting_on
                   Cls : Lcd T14 ; T15
                   Call 500ms
                  Else
                    If Volume < &B00010000 Then                       ' Redukcja wzmocnienia
                     Volume = 24
                     Call Write_tda
                    End If
                   Call Muting_off
                   Cls : Lcd T14 ; T7
                   Call 500ms
                  End If
        Case 63 : Incr Sleep_nr                                       ' Ustawia czas SLEEP
                 If Sleep_nr = 6 Then Sleep_nr = 0
                 Select Case Sleep_nr
                  Case 0 : Sleep_f = 0                                'Sleep OFF
                           Call Green
                           Cls : Lcd T6 ; T7
                           Call 500ms
                  Case 1 : Sleep_f = 1                                'Sleep 30 min.
                           Call Yellow
                           Sleep_time = 1800                          ' w sekundach
                           Cls : Lcd T6 ; T8
                           Call 500ms
                  Case 2 : Sleep_f = 1                                'Sleep 60 min.
                           Call Yellow
                           Sleep_time = 3600                          ' w sekundach
                           Cls : Lcd T6 ; T9
                           Call 500ms
                  Case 3 : Sleep_f = 1                                'Sleep 80 min.
                           Call Yellow
                           Sleep_time = 4800                          ' w sekundach
                           Cls : Lcd T6 ; T10
                           Call 500ms
                 End Select
        Case 33 : If Wejscie = 73 Then Call Prev_station              ' Nastêpna stacja
        Case 32 : If Wejscie = 73 Then Call Next_station              ' Poprzednia stacja
        Case 31 : Incr Pwm                                            ' Podœwietlanie ON/OFF
                  If Pwm = 4 Then Pwm = 0
                  Select Case Pwm
                   Case 0 : Pwm1a = 0
                            Call 100ms
                            Pwm_temp = 0
                   Case 1 : Pwm1a = 80
                            Pwm_temp = 80
                            Call 100ms
                   Case 2 : Pwm1a = 150
                            Pwm_temp = 150
                            Call 100ms
                   Case 3 : Pwm1a = 255
                            Pwm_temp = 255
                            Call 100ms
                  End Select
       End Select

       Call Detect_encoder                                            ' Obs³uga impulsatora

       If Sleep_on = 1 Then Goto Power_off

     Loop

 End Sub

'------------------------------------------------

 Sub Change_input:                                                    ' Zmiana wejœcia

     Call Muting_on

     Select Case Wejscie
      Case 88 : Wejscie = 73
      Case 73 : Wejscie = 90
      Case 90 : Incr Wejscie
      Case 91 : Wejscie = 88
     End Select

     Select Case Wejscie                                              ' Zapisanie wartoœci
       Case 88 : Volume = Vol_cd
                 Bass = Bass_cd
                 Treble = Treble_cd
       Case 73 : Volume = Vol_tuner
                 Bass = Bass_tuner
                 Treble = Treble_tuner
       Case 90 : Volume = Vol_in1
                 Bass = Bass_in1
                 Treble = Treble_in1
       Case 91 : Volume = Vol_in2
                 Bass = Bass_in2
                 Treble = Treble_in2
     End Select

     Call Write_tda
     Call Count_bass_val
     Call Count_treble_val
     Call Muting_off
     Call 100ms
     Cls

 End Sub

'------------------------------------------------

 Sub Audio_function:                                                  ' Funkcje audio

     Incr Audio_fun
     If Audio_fun = 4 Then Audio_fun = 2
     Cls

     If Audio_fun = 2 Then                                            ' BASS
      For Temp = 0 To 200
       Home : Lcd T4 ; Bass_val
       Call Detect_encoder
       Debounce Pinb.1 , 1 , Audio_function , Sub
      Next
     End If

     If Audio_fun = 3 Then                                            ' TREBLE
      For Temp = 0 To 200
       Home : Lcd T5 ; Treble_val
       Call Detect_encoder
       Debounce Pinb.1 , 1 , Audio_function , Sub
      Next
     End If

   Audio_fun = 1                                                      ' Na koniec aktywne VOLUME
   Cls

 End Sub

'------------------------------------------------

 Sub Volume_up:                                                       ' G³oœniej

     Decr Volume
     If Volume > 63 Then Volume = 0
     Call Write_tda
     Select Case Wejscie                                              ' Zapisanie wartoœci
      Case 88 : Vol_cd = Volume
      Case 73 : Vol_tuner = Volume
      Case 90 : Vol_in1 = Volume
      Case 91 : Vol_in2 = Volume
     End Select

 End Sub

'------------------------------------------------

 Sub Volume_down:                                                     ' Ciszej

     Incr Volume
     If Volume > 63 Then Volume = 63
     Call Write_tda
     Select Case Wejscie                                              ' Zapisanie wartoœci
      Case 88 : Vol_cd = Volume
      Case 73 : Vol_tuner = Volume
      Case 90 : Vol_in1 = Volume
      Case 91 : Vol_in2 = Volume
     End Select

 End Sub

'------------------------------------------------

 Sub Write_tda:                                                       ' Zapis do TDA7318

     I2cstart
     I2cwbyte &B10001000
     I2cwbyte Volume
     I2cwbyte Bass
     I2cwbyte Treble
     I2cwbyte Wejscie
     I2cstop

 End Sub

'------------------------------------------------

 Sub Muting_on:

     I2cstart
     I2cwbyte &B10001000
     I2cwbyte 159
     I2cwbyte 191
     I2cstop

 End Sub

'------------------------------------------------

 Sub Muting_off:

     I2cstart
     I2cwbyte &B10001000
     I2cwbyte 128
     I2cwbyte 160
     I2cstop

 End Sub

'------------------------------------------------

 Sub Tune:                                                            ' Dostraja tuner do wybranej stacji

     Frequency = Station(station_number)
     Call Complet_reg
     Call Write_om
     Call Count_frequency

 End Sub

'------------------------------------------------

 Sub Count_frequency:                                                 ' Oblicza czêstotliwoœæ tunera

     F = Frequency
     F = F - 856
     F = F * 125
     F = F / 1000
     Freq = F

     Tuner_freq = Str(freq)

     If Freq > 999 Then Tuner_freq = Format(tuner_freq , "000.0")
     If Freq < 1000 Then Tuner_freq = Format(tuner_freq , " 00.0")

 End Sub

'------------------------------------------------

 Sub Tuner_check:                                                     ' Sprawdza dostrojenie tunera

     Reset Portc.5
     Set Portc.4
     If Pinc.2 = 0 Then
      A_ = ">" : B_ = "<"
     Else
      A_ = "<" : B_ = ">"
     End If

     Reset Portc.5
     Reset Portc.4
     If Pinc.2 = 0 Then
      Tuner_stereo = "St"
     Else
      Tuner_stereo = "Mo"
     End If

 End Sub

'------------------------------------------------

 Sub Complet_reg:

     Reg = Frequency

 End Sub

'------------------------------------------------

 Sub Write_om:                                                        ' Zapis do OM5610

     Config Pinc.3 = Output
     Set Portc.5
     For Idx = 24 To 0 Step -1
      Portc.3 = Reg.idx
      Set Portc.4 : Waitus 10 : Reset Portc.4
      Waitus 20
     Next
     Reset Portc.5

 End Sub

'---------------------------------------------

 Sub Next_station:                                                    ' Nastêpna stacja

     Incr Station_number
     If Station_number = 10 Then Station_number = 1
     Call Tune
     Call 100ms

 End Sub

'------------------------------------------------

 Sub Prev_station:                                                    ' Poprzednia stacja

     Decr Station_number
     If Station_number = 0 Then Station_number = 9
     Call Tune
     Call 100ms

 End Sub

'---------------------------------------------------

 Sub Tuner_function:                                                  ' Strojenie stacji

     Cls
     Lcd "  Tuning: +/-"
     Call 500ms

 Preset:

     For Temp_3 = 222 To 0 Step -1
      Call Count_frequency
      Call Tuner_check
      Home : Lcd " " ; A_ ; Station_number ; B_ ; " " ; Tuner_freq ; "MHz " ; Tuner_stereo
      Set Portb.3
      If Pinb.3 = 1 Then Goto Up
      Set Portb.4
      If Pinb.4 = 1 Then Goto Down
      Set Portb.5
      If Pinb.5 = 1 Then Goto Save_station
     Next

     Goto Ends_1

 Down:                                                                ' Strojenie w dó³
      Frequency = Frequency - 1
      If Frequency = 7855 Then Frequency = 9497
      Call Complet_reg
      Call Write_om
      Temp_3 = 0
      Waitms 50
      Goto Preset

 Up:                                                                  ' Strojenie w górê
     Frequency = Frequency + 1
     If Frequency = 9497 Then Frequency = 7856
     Call Complet_reg
     Call Write_om
     Temp_3 = 0
     Waitms 50
     Goto Preset

 Save_station:                                                        ' Zapisywanie stacji

     St_temp = 1
     Call 100ms
     Call 100ms
     Cls

     Do

      Home : Lcd "  Save as: " ; St_temp

      Set Portb.3                                                     '
      Call 5ms
      If Pinb.3 = 1 Then Incr St_temp
      If St_temp = 10 Then St_temp = 1
      Call 100ms
      Call 100ms

      Set Portb.4
      Call 5ms
      If Pinb.4 = 1 Then Decr St_temp
      If St_temp = 0 Then St_temp = 9
      Call 100ms
      Call 100ms

      Set Portb.5
      Call 5ms
      If Pinb.5 = 1 Then Goto Ends

     Loop

 Ends:

      Station(st_temp) = Frequency
      Station_number = St_temp
      Call Tune
      Call Count_frequency
      Exit Sub

 Ends_1:

      Call Tune
      Call Count_frequency

 End Sub

'---------------------------------------------------

 Sub Detect_encoder:                                                  ' Obs³uga impulsatora

     For Temp_1 = 700 To 0 Step -1

         Set A : Set B
         If A = 1 And B = 1 Then Af = 1                               'impulsator w pozycji - zwarte
         If A = 0 And B = 0 Then Af = 0                               'impulsator w pozycji - rozwarte

         If A = 0 And B = 1 Then                                      'rozpoczety ruch impulsatora
          If Af = 1 Then                                              'jezeli byl zwarty to
           Do
            If B = 0 Then Exit Do                                     'poczekaj az B = 0
           Loop
           Goto Prawo                                                 'rozpoznany ruch w prawo
          Else                                                        'jezeli byl rozwarty to
           Do
            If A = 1 Then Exit Do                                     'poczekaj az A = 1
           Loop
           Goto Lewo                                                  'rozpoznany ruch w lewo
          End If
         End If

         If A = 1 And B = 0 Then                                      'rozpoczety ruch impulsatora
          If Af = 1 Then                                              'jezeli byl zwarty to
           Do
            If A = 0 Then Exit Do                                     'poczekaj az A = 0
           Loop
           Goto Lewo                                                  'rozpoznany ruch w lewo
          Else                                                        'jezeli byl rozwarty to
           Do
            If B = 1 Then Exit Do                                     'poczekaj az B = 1
           Loop
           Goto Prawo                                                 'rozpoznany ruch w prawo
          End If
         End If

     Next
     Exit Sub

 Prawo:                                                               ' W górê!

        Temp = 0

        Select Case Audio_fun
         Case 1 : Call Volume_up                                      ' Wzmocnienie
                  Call Volume_up
         Case 2 : Select Case Bass
                   Case Is < 103 : Incr Bass
                                   If Bass = 103 Then Bass = 111
                   Case Is > 103 : Decr Bass
                                   If Bass = 103 Then Bass = 104
                  End Select
                  Select Case Wejscie                                 ' Zapisanie wartoœci
                   Case 88 : Bass_cd = Bass
                   Case 73 : Bass_tuner = Bass
                   Case 90 : Bass_in1 = Bass
                   Case 91 : Bass_in2 = Bass
                  End Select
                  Call Count_bass_val
          Case 3 : Select Case Treble
                    Case Is < 119 : Incr Treble
                                    If Treble = 119 Then Treble = 127
                    Case Is > 119 : Decr Treble
                                    If Treble = 119 Then Treble = 120
                   End Select
                   Select Case Wejscie                                ' Zapisanie wartoœci
                    Case 88 : Treble_cd = Treble
                    Case 73 : Treble_tuner = Treble
                    Case 90 : Treble_in1 = Treble
                    Case 91 : Treble_in2 = Treble
                   End Select
                   Call Count_treble_val
        End Select
        Call Write_tda
        Exit Sub                                                      ' Zapis do TDA7318

 Lewo:                                                                ' W dó³!

       Temp = 0

        Select Case Audio_fun
         Case 1 : Call Volume_down                                    ' Wzmocnienie
                  Call Volume_down
         Case 2 : If Bass > 103 Then Incr Bass
                  If Bass < 103 Then Decr Bass
                  If Bass = 112 Then Bass = 102
                  If Bass = 95 Then Bass = 96
                  Select Case Wejscie                                 ' Zapisanie wartoœci
                   Case 88 : Bass_cd = Bass
                   Case 73 : Bass_tuner = Bass
                   Case 90 : Bass_in1 = Bass
                   Case 91 : Bass_in2 = Bass
                  End Select
                  Call Count_bass_val
         Case 3 : If Treble > 119 Then Incr Treble
                  If Treble < 119 Then Decr Treble
                  If Treble = 128 Then Treble = 118
                  If Treble = 111 Then Treble = 112
                  Select Case Wejscie                                 ' Zapisanie wartoœci
                   Case 88 : Treble_cd = Treble
                   Case 73 : Treble_tuner = Treble
                   Case 90 : Treble_in1 = Treble
                   Case 91 : Treble_in2 = Treble
                  End Select
                  Call Count_treble_val
        End Select
        Call Write_tda

 End Sub

'---------------------------------------------------

  Sub Count_bass_val:

      Select Case Bass
       Case 96 : Bass_val = T19                                       ' -14
       Case 97 : Bass_val = T20
       Case 98 : Bass_val = T21
       Case 99 : Bass_val = T22
       Case 100 : Bass_val = T23
       Case 101 : Bass_val = T24
       Case 102 : Bass_val = T25
       Case 111 : Bass_val = T26                                      ' flat
       Case 110 : Bass_val = T27
       Case 109 : Bass_val = T28
       Case 108 : Bass_val = T29
       Case 107 : Bass_val = T30
       Case 106 : Bass_val = T31
       Case 105 : Bass_val = T32
       Case 104 : Bass_val = T33                                      ' +14
      End Select

 End Sub

'---------------------------------------------------

 Sub Count_treble_val:

     Select Case Treble
      Case 112 : Treble_val = T19                                     ' -14
      Case 113 : Treble_val = T20
      Case 114 : Treble_val = T21
      Case 115 : Treble_val = T22
      Case 116 : Treble_val = T23
      Case 117 : Treble_val = T24
      Case 118 : Treble_val = T25
      Case 127 : Treble_val = T26                                     ' flat
      Case 126 : Treble_val = T27
      Case 125 : Treble_val = T28
      Case 124 : Treble_val = T29
      Case 123 : Treble_val = T30
      Case 122 : Treble_val = T31
      Case 121 : Treble_val = T32
      Case 120 : Treble_val = T33                                     ' +14
     End Select

 End Sub

'---------------------------------------------------

 Sub 100ms:

     Waitms 100

 End Sub

'---------------------------------------------------

 Sub 500ms:

     Waitms 500

 End Sub

'---------------------------------------------------

 Sub 5ms:

     Waitms 5

 End Sub

'---------------------------------------------------

 Sub Green:                                                           ' LED na zielono

     Set Portd.3 : Reset Portd.2

 End Sub

'---------------------------------------------------

 Sub Red:                                                             ' LED na czerwono

     Set Portd.2 : Reset Portd.3

 End Sub

'---------------------------------------------------

 Sub Yellow:                                                          ' LED na ¿ó³to

     Set Portd.2 : Set Portd.3

 End Sub

'---------------------------------------------------

 Sub Get_rc5:                                                         ' Odbiera kod z pilota

     Getrc5(adres , Komenda)                                          ' Odbiór RC5
     Komenda = Komenda And &B10111111

 End Sub

'---------------------------------------------------

 Sectic:

        If Alarm_f = 1 Then                                           ' Sprawdzanie alarmu
         If Alarm_h = _hour And Alarm_m = _min Then Alarm_on = 1 Else Alarm_on = 0
        End If

        If Sleep_f = 1 Then                                           ' Sprawdzanie czasu SLEEP
         Incr Sleep_counter
         If Sleep_counter = Sleep_time Then Sleep_on = 1
        End If

 Return

'---------------------------------------------------