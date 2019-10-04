;
; This program interfaces to a Hitachi (LM032L) 2 line by 20 character display
; module. The program assembles for 4-bit data interface. LCD_DATA is the port
; which supplies the data and LCD_CTRL the control lines ( E, RS, R_W ) to the
; LM032L. 
; This program only handles the data though the high nibble.
;****************************************************************************
;* This file and the resulting compiled code copyright1993-96 Steve Lawther *
;*      Use of any of this code requires Steve Lawther to have a credit     *
;*        within the source code. Commercial use of any of this code        *
;*           requires the permission of the author, Steve Lawther           *
;*   For more details read 'README.TXT' or email steve.lawther@gecm.com     *
;****************************************************************************

    include P16F628A.inc
    include tempdemo.inc
    include lm032l.inc
    include wait.inc

    errorlevel  -302            ;Eliminate bank warning

LCD_DATA         EQU     PORTB
LCD_DATA_TRIS    EQU     TRISB
LCD_CTRL         EQU     PORTB

#define LED     PORTB, 0    ; LED - clear for lit, set for off

; LCD Display Commands and Control Signal names.
#define LCD_E    LCD_CTRL,1     ; LCD Enable control line
#define LCD_R_W  LCD_CTRL,2     ; LCD Read/Write control line
#define LCD_RS   LCD_CTRL,3     ; LCD Register Select control line

    global DISPLAY_RESET, SEND_CHAR_W, SEND_CHAR, SEND_CMD_W
    global LOAD_CGRAM, LOAD_CGRAM_LOC
    extern longdelay, shortdelay    ;DELAY.ASM
    extern uchars                   ;TEMPDEMO.ASM
;
 page
;
; Initilize the LCD Display Module
;****************************************************************************
;*
;*              DISPLAY RESET
;*
;****************************************************************************

PROG CODE

DISPLAY_RESET
;needs to have full routine to initialize corrupted display
;first setup lcd port - all outputs

    bsf     STATUS, RP0     ; Bank 1
    movlw   b'00000000'
    movwf   LCD_DATA_TRIS   ;set all to output
    bcf     STATUS, RP0     ; Bank 0
    clrf    LCD_DATA        ;set all port low
    bsf LED
    ;clrf    LCDflags        ;set to cmd next etc
;have to wait 15ms here
    clrwdt
    Wait    35 Millisec, 0
    clrwdt
;clear LCD port to all low here!!!!!!!!!!!!!!!
    movlw   b'00110001'     ; Command for 8-bit interface high nibble vv-B.0=1
    movwf   LCD_DATA        ; ie 0011xxxx
    bsf     LCD_E
    nop                     ;incase the clk is >8MHz
    ;nop                     ;incase the clk is >16MHz
    bcf     LCD_E
;have to wait 4.1ms here            
    Wait    4100 Microsec, 0
    bsf     LCD_E           ;nibble is already setup
    nop                     ;incase the clk is >8MHz
    ;nop                     ;incase the clk is >16MHz
    bcf     LCD_E
;have to wait 100us here
    Wait    100 Microsec, 0
    bsf     LCD_E           ;nibble is already setup
    nop                     ;incase the clk is >8MHz
    ;nop                     ;incase the clk is >16MHz
    bcf     LCD_E
;have to wait 100us here
    Wait    100 Microsec, 0
    movlw   b'00100001'     ; Command for 4-bit interface high nibble vv-B.0=1
    movwf   LCD_DATA        ; ie 0010xxxx
    bsf     LCD_E
    nop                     ;incase the clk is >8MHz
    ;nop                     ;incase the clk is >16MHz
    bcf     LCD_E
    clrwdt
;from here interface is 4 bit and busy can be checked
                            ;          001DL NF**
    movlw   FUNC_SET        ;has to be 0010  10XX
    call    SEND_CMD_W
                            ;0000 1DCB
    movlw   DISP_OFF        ;0000 1000
    call    SEND_CMD_W

;****************************
;*                          *
;*    INITIALIZE DISPLAY    *
;*                          *
;****************************
INIT_DISPLAY
    movlw   DISP_ON         ; Display On, Cursor On
    call    SEND_CMD_W

    movlw   CLR_DISP        ; Clear the Display
    call    SEND_CMD_W
    Wait    2 Millisec, 0
                            ;0000 01IS
    movlw   ENTRY_INC       ;0000 0110
    call    SEND_CMD_W

    return
    page
;*******************************************************************
;* The LCD Module Subroutines                                      *
;*******************************************************************
;
;*******************************************************************
;*SendChar - Sends character to LCD                                *
;*This routine splits the character into the upper and lower       *
;*nibbles and sends them to the LCD, upper nibble first.           *
;*******************************************************************
;
SEND_CHAR_W
    movwf   CHARBUF         ;Character to be sent is in W so put in
                            ;local CHARBUF
SEND_CHAR
    call    BUSY_CHECK      ;Wait for LCD to be ready
    movf    CHARBUF, W
    andlw   0x0F0           ;Get upper nibble into upper half port
    iorlw   0x01            ;vv-LED off

    movwf   LCD_DATA        ;Send data to LCD
    ;bcf     LCD_R_W         ;Set LCD to read
    bsf     LCD_RS          ;Set LCD to data mode
    call    LCDtglclk       ;saving space - sod readability thou
    ;bsf     LCD_E           ;toggle E for LCD
    ;nop                     ;incase the clk is >8MHz
    ;;nop                     ;incase the clk is >16MHz
    ;bcf     LCD_E
    swapf   CHARBUF, w
    andlw   0x0F0           ;Get lower nibble into upper half port
    iorlw   0x01            ;vv-LED off

    movwf   LCD_DATA        ;Send data to LCD
    bsf     LCD_RS          ;Set LCD to data mode
LCDtglclk   bsf     LCD_E   ;toggle E for LCD
            nop             ;incase the clk is >8MHz
            ;nop            ;incase the clk is >16MHz
            bcf     LCD_E
            return

;*******************************************************************
;* SEND_CMD - Sends command to LCD                                 *
;* This routine splits the command into the upper and lower        *
;* nibbles and sends them to the LCD, upper nibble first.          *
;*******************************************************************

SEND_CMD_W
    movwf   CHARBUF         ; Character to be sent is in W so put in
                            ;local CHARBUF
SEND_CMD
    call    BUSY_CHECK      ; Wait for LCD to be ready
    movf    CHARBUF, W
    andlw   0x0F0           ; Get upper nibble into lower half port
    iorlw   0x01            ;vv-LED off

    movwf   LCD_DATA        ; Send data to LCD
    ;bcf     LCD_R_W         ; Set LCD to read
    ;bcf     LCD_RS          ; Set LCD to command mode
    call    LCDtglclk       ;saving space - sod readability thou
    ;bsf     LCD_E           ; toggle E for LCD
    ;nop                     ;incase the clk is >8MHz
    ;;nop                     ;incase the clk is >16MHz
    ;bcf     LCD_E
    swapf   CHARBUF,w
    andlw   0x0F0           ; Get lower nibble into lower half port
    iorlw   0x01            ;vv-LED off

    movwf   LCD_DATA        ; Send data to LCD
    goto    LCDtglclk       ;saving space - sod readability thou
    ;bsf     LCD_E           ; toggle E for LCD
    ;nop                     ;incase the clk is >8MHz
    ;;nop                     ;incase the clk is >16MHz
    ;bcf     LCD_E
    ;return

;*******************************************************************
;* This routine checks the busy flag, returns when not busy        *
;*******************************************************************
;
BUSY_CHECK
    bsf     STATUS, RP0     ; Select Register page 1
    movlw   0xF0            ; st 0xF1 Set high nibble + keep INT for input
    movwf   LCD_DATA_TRIS
    bcf     STATUS, RP0     ; Select Register page 0
    bcf     LCD_RS          ; Set LCD for Command mode
    bsf     LCD_R_W         ; Setup to read busy flag
    bsf     LCD_E           ; Set E high
    nop                     ;incase the clk is >8MHz
    ;nop                     ;incase the clk is >16MHz
    movf    LCD_DATA, W     ; Read upper nibble busy flag, DDRam address
    bcf     LCD_E           ; Set E low
    ;andlw   0x0F0           ; Mask out lower nibble ***chng 1/10/96
    andlw   0x80            ; Mask out lower nibble ***chng 1/10/96
    ;movwf   TEMP
    nop
    bsf     LCD_E           ; Toggle E to get lower nibble
    nop
    nop                     ;incase the clk is >8MHz
    ;nop                     ;incase the clk is >16MHz
    ;swapF   LCD_DATA, W     ; Read lower nibble DDRam address
    bcf     LCD_E
    ;andlw   0x0F            ; Mask out upper nibble
    ;iorwf   TEMP, F         ; Combine nibbles
    xorlw   0x80
    btfsc   STATUS, Z
    ;btfsc   TEMP, 7         ; Check busy flag, high = busy
    goto    BUSY_CHECK      ; If busy, check again
    bcf     LCD_R_W
    bsf     STATUS, RP0     ; Select Register page 1
    movlw   b'00000000'
    movwf   LCD_DATA_TRIS   ; Set for output
    bcf     STATUS, RP0     ; Select Register page 0
    return

LOAD_CGRAM
; load user defined characters
    movlw   0x40
    call    SEND_CMD_W
; start address passed in temp_lo (reuse temp_lo memory)
; running address in temp_hi (reuse temp_hi memory)
; loop counter in acc_hi (reuse acc_hi memory)
LOAD_CGRAM_LOC
    clrf    temp_hi
    movf    temp_lo, W
    addwf   temp_hi, F
    movlw   0x08
    movwf   acc_hi

load
    movf    temp_hi, W
    call    uchars
    call    SEND_CHAR_W
    incf    temp_hi, F
    decfsz  acc_hi, F
     goto    load
    return

    end
