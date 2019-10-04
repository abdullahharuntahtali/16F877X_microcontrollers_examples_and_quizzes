    list    p=16F628A
    include P16F628A.inc
    include tempdemo.inc
    include dal_bus.inc
    include wait.inc
    include lm032l.inc

;------defines for conditional assembly------
;#define round00
;#define test
;#define EEdsrom
;#define dog

    errorlevel  -302    ;Eliminate bank warning
;CONFIG CODE
#ifdef dog
    __config _BODEN_OFF & _CP_OFF& _DATA_CP_OFF & _PWRTE_ON & _WDT_ON  & _LVP_OFF & _MCLRE_ON & _XT_OSC
    messg   "W   A   T   C   H__________D   O   G"
#else
    __config _BODEN_OFF & _CP_OFF& _DATA_CP_OFF & _PWRTE_ON & _WDT_OFF & _LVP_OFF & _MCLRE_ON & _XT_OSC
#endif  ; dog

; noexpand
;****************************************************************************
;*                                                                          *
;*                   Dallas 1 Wire Bus Temperature demo                     *
;*                                                                          *
;* This file and the resulting compiled code copyright1993-97 Steve Lawther *
;*      Use of any of this code requires Steve Lawther to have a credit     *
;*        within the source code. Commercial use of any of this code        *
;*             requires permission of the author, Steve Lawther             *
;*   For more details read 'README.TXT' or email 100255.157@compuserve.com  *
;****************************************************************************
;* This outline requires IBM line draw chrs                                 *
;*                             ÚÄÄÄÄ\/ÄÄÄÄ¿                                 *
;*                   nc       Íµøra2   ra1ÆÍ  spare                   (not )*
;*                   nc       Íµra3    ra0ÆÍ  led via resistor to +5V (used)*
;*         Dallas 1 wire bus  Íµra4ck osc1ÆÍ  \ Crystal 10MHz               *
;*                  Vdd       Íµmclr  osc2ÆÍ  /                             *
;*                 ground     ÍµVss    VddÆÍ  +5V                           *
;*                   nc       Íµrb0int rb7ÆÍ LCD data bit 7                 *
;*             LCD cntrl E    Íµrb1    rb6ÆÍ LCD data bit 6                 *
;*             LCD cntrl R/W  Íµrb2    rb5ÆÍ LCD data bit 5                 *
;*             LCD cntrl RS   Íµrb3    rb4ÆÍ LCD data bit 4                 *
;*                             ÀÄÄÄÄÄÄÄÄÄÄÙ                                 *
;*                                                                          *
;****************************************************************************
;History:-
;ver 0.01 - original version - raw data output
;    0.10 - raw data + high resolution temperature
;    0.11 - corrected one line (btfsc changed to btfss)

#define LED     PORTB, 0    ; LED - clear for lit, set for off

    global uchars

    extern DISPLAY_RESET, SEND_CHAR_W, SEND_CHAR, SEND_CMD_W    ;LM032CLK.ASM
    extern LOAD_CGRAM, LOAD_CGRAM_LOC                           ;LM032CLK.ASM

    extern DSReset_Pulse, DSWriteByteW, DSReadByte, DSReadBit   ;DAL_BUS.ASM
    extern OWSearch                                             ;DAL_BUS.ASM

    extern longdelay, shortdelay                                ;DELAY.ASM

;****************************************************************************
;*
;*   Start
;*
;****************************************************************************

PROG CODE
Begin
    movlw   0x07
    movwf   CMCON

    bsf     STATUS, RP0     ; Bank 1
    movlw   0xFF
    movwf   OPTION_REG
    movlw   b'00001111'
    movwf   TRISA           ; RA0-RA3 unused
    bcf     STATUS, RP0     ; Bank 0

    clrf    PORTA           ; set all port low

    bsf     STATUS, RP0     ; Bank 1
    movlw   b'00000000'
    movwf   TRISB           ;set all to output
    bcf     STATUS, RP0     ; Bank 0

    call    DISPLAY_RESET

;    call    LOAD_CGRAM      ; load user defined characters
    clrf    bits_byte

Start
;****************************************************************************
;*
;* Main Code - get the ID and display it, then get the temp and display it
;*
;****************************************************************************

    movlw   0x10
    movwf   temp_lo
    call    LOAD_CGRAM      ; load user defined characters

    movlw   0x48
    call    SEND_CMD_W
    movlw   0x18
    movwf   temp_lo
    call    LOAD_CGRAM_LOC  ; load user defined characters
    movlw   0x50
    call    SEND_CMD_W
    movlw   0x20
    movwf   temp_lo
    call    LOAD_CGRAM_LOC  ; load user defined characters
    movlw   0x58
    call    SEND_CMD_W
    movlw   0x28
    movwf   temp_lo
    call    LOAD_CGRAM_LOC  ; load user defined characters



NextTemp
    clrf    bits_byte
; skip ID Search if EEPROM is not empty
    clrw
    call    EEread
    addlw   (0 - 0x28)
;    btfsc   STATUS, Z
;     goto   EndSearch
StartNewSearch
    clrf    id_bits_byte    ; last_device flag = 0
    clrf    LastDiscrepancy
    clrf    LastFamilyDiscr
    clrf    temp_lo         ; EEPROM counter

OWReset
    call    DSReset_Pulse
    bsf     LED
;    Wait    197 Millisec, 0
    bcf     LED
;    Wait    47 Millisec, 0
#ifndef test
    btfss   PRESENCE_bit    ; wait for a presence pulse
     goto   OWReset
    bsf LED
#endif
    btfsc   last_device     ; check last_device flag
     goto   EndSearch

    call    OWSearch        ; W = 1/W = 0 not/successful search
    andlw   0xFF            ; update STATUS, Z!
    btfss   STATUS, Z
     goto   StartNewSearch
; write ID to EEPROM
    movlw   0x08
    movwf   count
    movlw   ROM_no
    movwf   FSR
SaveROM_no
    movf    INDF, W
    call    EEwrite
    incf    FSR, F
    incf    temp_lo, F
    decfsz  count, F
     goto   SaveROM_no
    goto    OWReset

EndSearch
#ifndef test
    call    DSReset_Pulse
    btfss   PRESENCE_bit    ; wait for a presence pulse
     goto   $-2
#endif



    movlw   DSSkipROM
    call    DSWriteByteW
    movlw   DSConvertTemp   ; set all 1820s on converting
    call    DSWriteByteW

tempnotready
    call    DSReadBit
    btfss   DScommbuff, 0
     goto   tempnotready

    movlw   0x80            ; go to first line
    call    SEND_CMD_W
    movlw   0x01            ; 'lamp'
    call    SEND_CHAR_W

    clrwdt                  ; allow LCD delay variation (BUSY_CHECK)!

    bsf     STATUS, RP0     ; Bank 1
    movlw   b'11111101'
    movwf   OPTION_REG
    bcf     STATUS, RP0     ; Bank 0
#ifdef dog
    sleep
#endif  ; dog
    movlw   0x80            ; go to first line
    call    SEND_CMD_W
    movlw   0x02            ; 'house'
    call    SEND_CHAR_W

    bsf     STATUS, RP0     ; Bank 1
    movlw   0xFF
    movwf   OPTION_REG
    bcf     STATUS, RP0     ; Bank 0

#ifndef test
    call    DSReset_Pulse
    btfss   PRESENCE_bit    ; wait for a presence pulse
     goto   $-2
#endif
    movlw   DSMatchROM
    call    DSWriteByteW
;send dsrom1
    clrf    vvshift
dsload1
    movf    vvshift, W
    call    EEread
    call    DSWriteByteW
    incf    vvshift, F
    movf    vvshift, W
    addlw   (0 - .8)
    btfss   STATUS, Z
     goto   dsload1
    goto    DSGettemp

DSNext
    movlw   0xC0            ; go to second line
    call    SEND_CMD_W
    movlw   0x03            ; 'tree'
    call    SEND_CHAR_W

#ifndef test
    call    DSReset_Pulse
    btfss   PRESENCE_bit    ; wait for a presence pulse
     goto   $-2
#endif
    movlw   DSMatchROM
    call    DSWriteByteW
;send dsrom2
dsload2
    movf    vvshift, W
    call    EEread
    call    DSWriteByteW
    incf    vvshift, F
    movf    vvshift, W
    addlw   (0 - .16)
    btfss   STATUS, Z
     goto   dsload2
    bsf     DSNext_bit

DSGettemp
    movlw   DSReadScratch
    call    DSWriteByteW
    clrf    DSCRC

    call    DSReadByte
    movf    DScommbuff, W
    movwf   temp_lo
    call    DSReadByte
    movf    DScommbuff, W
    movwf   temp_hi

    call    DSReadByte      ;read TH byte and dump
    call    DSReadByte      ;read TL byte and dump
    call    DSReadByte      ;read config byte and dump
    call    DSReadByte      ;read reserved byte and dump
    call    DSReadByte      ;read reserved byte and dump
    call    DSReadByte      ;read reserved byte and dump

    call    DSReadByte      ;read CRC
    movf    DScommbuff, W
;    call    HEXtoLCD

    movf    DSCRC, F
#ifdef test
    movlw   b'01011110';
    movwf   temp_lo
    movlw   b'11111111'
    movwf   temp_hi
    bsf     STATUS, Z
#endif
;if there's a CRC error don't display temp, as gash data upsets the temp routines
    btfss   STATUS, Z       ;corrected 31/07/98 (thanks Marco)
     goto   no_displaytemp

;positive or negative temp?

    bcf     neg_temp_bit

    btfss   temp_hi,7
     goto   pos_num
;it's a negative number so complement
    comf    temp_lo, F
    comf    temp_hi, F
    incf    temp_lo, F
    btfsc   STATUS, Z
     incf   temp_hi, F
    bsf     neg_temp_bit
pos_num
;acc_lo = and(0xF0, temp_lo)
    movf    temp_lo,W
    andlw   0xF0
    movwf   acc_lo
;temp_hi = and(0x0F, temp_hi)
    movlw   0x0F
    andwf   temp_hi,F
;temp_hi = or(acc_lo, temp_hi)
    movf    acc_lo, W
    iorwf   temp_hi, F
;temp_hi = swap(temp_hi)
    swapf   temp_hi, F
;temp_lo = and(0x0F, temp_lo)
    movlw   0x0F
    andwf   temp_lo, F
;round up temp_lo
    movf    temp_lo, W
    movwf   acc_lo  ;copy of temp_lo for round to 0.0
#ifdef round00
;round up temp_lo to 0.00
    andlw   b'00000011'
    movwf   acc_lo
    sublw   b'00000010'
    btfsc   STATUS, Z
     bsf    round00_bit
    movf    acc_lo, W
    sublw   b'00000011'
    btfsc   STATUS, Z
     bsf    round00_bit
#endif
;temp_lo calculate
    clrw
    btfsc   temp_lo, 0
     addlw  d'6'
    btfsc   temp_lo, 1
     addlw  d'12'
    btfsc   temp_lo, 2
     addlw  d'25'
    btfsc   temp_lo, 3
     addlw  d'50'
    movwf   temp_lo
#ifdef round00
;round up temp_lo to 0.00
    btfsc   round00_bit
     incf   temp_lo, F
    bcf     round00_bit
#endif
#ifndef round00
;round up temp_lo to 0.0
    movf    acc_lo, W
    call    round
    addwf   temp_lo, F
#endif

    call    displaytemp

no_displaytemp
    movf    DSCRC, F        ;check that the CRC is zero
    movlw   'C'             ;'C' if ok
    btfss   STATUS, Z
    movlw   'X'             ;'cross' if not
    call    SEND_CHAR_W
;clear row
    movf    DSCRC, F        ;check that the CRC is zero
    btfsc   STATUS, Z
     goto   skip_clearRow
    movlw   0x07
    movwf   count2          ;reuse location
clearRow
    movlw   ' '
    call    SEND_CHAR_W
    decfsz  count2, F
     goto   clearRow

skip_clearRow
    btfss   DSNext_bit
     goto   DSNext

#ifndef test
    movlw   d'5' ;50 wait/5 sleep
    movwf   count2
waitloop
#ifdef dog
    sleep
#endif  ; dog
;    Wait    197 Millisec, 0
    decfsz  count2, F
     goto   waitloop
#endif
    goto    NextTemp


;*************************************************************************************
;
; Converts temp in temp_hi, lo to ASCII characters in form +XXX.xx, & send to display

;first sign bit

displaytemp
    movlw   ' '
    btfsc   neg_temp_bit
     movlw	 '-'
    call    SEND_CHAR_W

    movlw   '0'
    movwf   CHARBUF
    movf    temp_hi, W
    addlw   (0 - d'100')
    btfss   STATUS, C
     goto   end_of_hund
    incf    CHARBUF, F
    movwf   temp_hi
end_of_hund
;call    SEND_CHAR

    movlw   '0'
    movwf   CHARBUF
    movf    temp_hi, W
looptens
    addlw   (0 - d'10')
    btfss   STATUS, C
     goto   end_of_tens
    incf    CHARBUF, F
    goto    looptens

end_of_tens ;W is now 10 below units figure
    movwf   temp_hi

;skip leading zero
    movlw   '0'
    xorwf   CHARBUF, W
    btfss   STATUS, Z
     goto   noskip
    movlw   ' '
    movwf   CHARBUF
noskip

    call    SEND_CHAR

    movf    temp_hi, W
    addlw   d'58'           ;to set to ASCII & correct for being 10 too low
    call    SEND_CHAR_W     ;saves needing a return

    movlw   '.'
    call    SEND_CHAR_W

    movlw   '0'
    movwf   CHARBUF
    movf    temp_lo, W
looptenths
    addlw   (0 - d'10')
    btfss   STATUS, C
    goto    end_of_tenths
    incf    CHARBUF, F
    goto    looptenths

end_of_tenths   ;W is now 10 below hundredths figure
    movwf   temp_lo
    call    SEND_CHAR

#ifdef round00
    movf    temp_lo, W
    addlw   d'58'           ;to set to ASCII & correct for being 10 too low
    call    SEND_CHAR_W     ;saves needing a return
#endif

    movlw   0x00            ; 'deg'
    call    SEND_CHAR_W
    retlw   0

;********************************************************************
;* HEXtoLCD - Sends 2 digit hex to LCD                              *
;* This routine splits the character into the upper and lower       *
;* hex nibbles, and sends them to the LCD as ASCII characters       *
;********************************************************************
;Note that once a byte has been sent to the LCD, time is not a major factor
;as any subequent bytes sent have to wait til LCD not busy (>40us)

HEXtoLCD
;calculate the upper hex digit
    swapf   DScommbuff, W
    andlw   b'00001111'
    addlw   -10         ;is it A to F hex
    btfsc   STATUS, C
     addlw  0x07        ;gap of seven between 9 and A
    addlw   58          ;set to correct ascii including the 10 took off before
    call    SEND_CHAR_W
;calculate the lower hex digit
    movf    DScommbuff, W
    andlw   b'00001111'
    addlw   -10         ;is it A to F hex
    btfsc   STATUS, C
     addlw  0x27        ;gap of seven between 9 and a (lower case)
    addlw   58          ;set to correct ascii including the 10 took off before
    call    SEND_CHAR_W
    ;movlw   ' '
    ;call    SEND_CHAR_W
    return

EEwrite
;    movf    temp_hi, W      ; the data is in W
    bsf     STATUS, RP0
    movwf   EEDATA
    bcf     STATUS, RP0
    movf    temp_lo, W
    bsf     STATUS, RP0
    movwf   EEADR
;    bcf     EECON1, EEPGD  ; for 18Fxxxx
    bsf     EECON1, WREN
    bcf     INTCON, GIE
    movlw   0x55
    movwf   EECON2
    movlw   0xAA
    movwf   EECON2

    bsf     EECON1, WR
    bcf     EECON1, WREN
;    btfsc   EECON1, WR
    bcf     STATUS, RP0
    btfss   PIR1, EEIF
     goto   $ - 1
    bcf     PIR1, EEIF
    bsf     INTCON, GIE
    bcf     STATUS, RP0
    return

EEread
; the address is in W
    bsf     STATUS, RP0
    movwf   EEADR
;    bcf     EECON1, EEPGD  ; for 18Fxxxx
    bsf     EECON1, RD
    movf    EEDATA, W   ; read data is in W
    bcf     STATUS, RP0
    return

service                 ; Interrupt routine
    nop                 ; Interrupt code would go here
    nop
    retfie

STARTUP CODE            ; This area is defined in 16f84a.lkr,
                        ; the linker script
    goto Begin          ; Jump to main code defined in Example.asm
    nop                 ; Pad out so interrupt
    nop                 ;  service routine gets
    nop                 ;  put at address 0x0004.
    goto service        ; Points to interrupt service routine

#ifdef  EEdsrom
DEEPROM CODE
; in 286C 185F 0000 00A0
    de      0x28
    de      0x6C
    de      0x18
    de      0x5F
    de      0x00
    de      0x00
    de      0x00
    de      0xA0

; out 284C 285F 0000 0092
    de      0x28
    de      0x4C
    de      0x28
    de      0x5F
    de      0x00
    de      0x00
    de      0x00
    de      0x92
#endif  ; EEdsrom

Table CODE 0x05
uchars  addwf   PCL, F
;'4'
    retlw   0x02
    retlw   0x06
    retlw   0x0A
    retlw   0x12
    retlw   0x1F
    retlw   0x02
    retlw   0x02
    retlw   0x00
;'5'
    retlw   0x1F
    retlw   0x10
    retlw   0x1E
    retlw   0x01
    retlw   0x01
    retlw   0x11
    retlw   0x0E
    retlw   0x00
;'deg'
    retlw   0x06
    retlw   0x06
    retlw   0x00
    retlw   0x00
    retlw   0x00
    retlw   0x00
    retlw   0x00
    retlw   0x00
;'lamp'
    retlw   0x00
    retlw   0x04
    retlw   0x0A
    retlw   0x15
    retlw   0x0A
    retlw   0x04
    retlw   0x00
    retlw   0x00
;'house'
    retlw   0x04
    retlw   0x0E
    retlw   0x1F
    retlw   0x15
    retlw   0x1F
    retlw   0x15
    retlw   0x1F
    retlw   0x00
;'tree'
    retlw   0x04
    retlw   0x0A
    retlw   0x15
    retlw   0x15
    retlw   0x0E
    retlw   0x04
    retlw   0x0E
    retlw   0x00

#ifndef round00
round   addwf   PCL, F
    retlw   0x00
    retlw   0x0A
    retlw   0x00
    retlw   0x0A
    retlw   0x0A
    retlw   0x00
    retlw   0x0A
    retlw   0x00
    retlw   0x00
    retlw   0x0A
    retlw   0x00
    retlw   0x0A
    retlw   0x0A
    retlw   0x00
    retlw   0x0A
    retlw   0x00
#endif  ; round00

#ifdef  test
    messg   "T   E   S   T__________M   O   D   E"
#endif  ; test
    end
