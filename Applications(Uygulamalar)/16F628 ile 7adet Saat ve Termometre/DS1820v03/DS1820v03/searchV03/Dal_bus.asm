;        TITLE "Dallas 1 wire bus comms MASTER"

;****************************************************************************
;*
;*   Send Reset Pulse to all on Dallas bus,
;*   and monitor presence pulse
;* TO DO -  best of three reads, to guard against noise
;*
;****************************************************************************

    include P16F628A.inc
    include tempdemo.inc
    include dal_bus.inc
    include wait.inc

    global DSReset_Pulse, DSWriteByteW, DSReadByte, DSReadBit
    global OWSearch
    extern longdelay, shortdelay    ;DELAY.ASM

PROG CODE
DSReset_Pulse   bcf     PRESENCE_bit
                bsf     DALLAS_BUS      ;just in case it isn't
                Wait    1 Microsec,0    ; Trec
                bcf     DALLAS_BUS      ;start of reset pulse
                Wait    580 Microsec,0  ; Trstl
                bsf     DALLAS_BUS      ;end of reset pulse
                Wait    60 Microsec,0   ; Tpdh
                btfss   DALLAS_BUS      ;check for a presence pulse st:btfsC
                bsf     PRESENCE_bit    ;indicates presence
                Wait    420 Microsec,0  ; Trsth - Tpdh ( > Tpdl)
                return

;****************************************************************************
;*
;*   Write a ONE on the Dallas bus
;*
;****************************************************************************

DSWriteaOne     bsf     DALLAS_BUS      ;just in case it isn't
                nop
                bcf     DALLAS_BUS      ;start/sync edge
                Wait    2 Microsec,0    ; Tlow1
                bsf     DALLAS_BUS      ;end of low pulse
                Wait    59 Microsec,0   ; (Tslot + Trec) - Tlow1
                return

;****************************************************************************
;*
;*   Write a ZERO on the Dallas bus
;*
;****************************************************************************

DSWriteaZero    bsf     DALLAS_BUS      ;just in case it isn't
                nop
                bcf     DALLAS_BUS      ;start/sync edge
                Wait    60 Microsec,0   ; Tlow0
                bsf     DALLAS_BUS      ;end of low pulse
                Wait    1 Microsec,0    ; Trec
                return

;****************************************************************************
;*
;*   Write byte in DScommbuff or W to the Dallas bus
;*
;****************************************************************************

DSWriteByteW    movwf   DScommbuff      ;store W
DSWriteByte     bsf     DALLAS_BUS      ;just in case it isn't
                movlw   0x08            ;byte is 8 bits
                movwf   count
DSWriteLoop     bcf     DALLAS_BUS      ;start/sync edge
                Wait    2 Microsec,1    ; Tlow1
                btfsc   DScommbuff, 0
                 bsf    DALLAS_BUS      ;end of low pulse if bit was a 1
                Wait    58 Microsec,0   ; (Tslot + Trec) - Tlow1
                bsf     DALLAS_BUS      ;end of low pulse if 0 (1 no change)
                Wait    1 Microsec,4    ; Trec
                rrf     DScommbuff, F
                decfsz  count, F
                goto    DSWriteLoop
                return

;****************************************************************************
;*
;*   Read bit from the Dallas bus - puts it is bit 0 of DScommbuff
;* TO DO -  best of three reads, to guard against noise
;*
;****************************************************************************

DSReadBit       bsf     DALLAS_BUS      ;just in case it isn't
                nop
                bcf     DALLAS_BUS      ;start/sync edge
                Wait    2 Microsec,0    ; Tlowr
                bsf     DALLAS_BUS      ;end of sync low pulse
                Wait    12 Microsec, 2  ; Trdv - 2 cycles
                bsf     DScommbuff,0
                btfss   DALLAS_BUS
                bcf     DScommbuff, 0
                Wait    47 Microsec, 0
                return

;****************************************************************************
;*
;*   Read byte from the Dallas bus, and update CRC
;* TO DO -  best of three reads, to guard against noise
;*
;****************************************************************************

DSReadByte      bsf     DALLAS_BUS      ;just in case it isn't
                movlw   0x08            ;byte is 8 bits
                movwf   count

DSReadLoop      bcf     DALLAS_BUS      ;start/sync edge
                Wait    2 Microsec,0    ; Tlowr
                bsf     DALLAS_BUS      ;end of sync low pulse
                Wait    12 Microsec, 3  ; Trdv - 2 cycles
                bcf     STATUS, C
                clrw
                btfss   DALLAS_BUS
                 goto   DSread0
                movlw   b'00000001'
                bsf     STATUS, C
DSread0
                rrf     DScommbuff, F
;now for the calculating the CRC
                bcf     STATUS, C
                xorwf   DSCRC, W
                andlw   b'00000001'
                btfsc   STATUS, Z   ;changed from btfss 080298****
                 goto   DSCRCin0
                movlw   0x18
                xorwf   DSCRC, F
                bsf     STATUS, C   ;added here 080298*****

DSCRCin0        rrf     DSCRC, F
                Wait    47 Microsec, 12
                decfsz  count, F    ;end of byte?
                 goto   DSReadLoop
                return

OWSearch
    clrf    id_bit_number   ; set id_bit_number = 1
    incf    id_bit_number, F
    clrf    last_zero       ; set last_zero = 0
    clrf    rom_mask        ; set rom_mask = 1
    incf    rom_mask, F
    clrf    DSCRC           ; reset CRC check
    movlw   ROM_no
    movwf   FSR



    movlw   DSSearchROM
;    movlw   DSAlarmSearch
    call    DSWriteByteW



ReadBit                     ; read id_bit & cmp_id_bit
    call    DSReadBit
    bcf     id_bit
    btfsc   DScommbuff, 0
     bsf    id_bit
    call    DSReadBit
    bcf     cmp_id_bit
    btfsc   DScommbuff, 0
     bsf    cmp_id_bit
; check for no devices on 1-wire, id_bit = cmp_id_bit = 1?
    bsf     test_bit
    btfss   id_bit
     bcf    test_bit
    btfss   cmp_id_bit
     bcf    test_bit
; no devices on 1-wire bus, loop
     btfsc  test_bit
      goto  OWSearchErr
; Discrepancy?, id_bit = cmp_id_bit = 0?
    bcf     test_bit
    btfsc   id_bit
     bsf    test_bit        ; No discrepancy
    btfsc   cmp_id_bit
     bsf    test_bit        ; No discrepancy

    btfss   test_bit
     goto   discrepancy     ; Yes, discrepancy
; No, no discrepancy -> Direction = id_bit
    bcf     Direction
    btfsc   id_bit
     bsf    Direction
    goto    EndDiscrepancy
discrepancy
; id_bit_number = LastDiscrepancy?
    movf    LastDiscrepancy, W
    subwf   id_bit_number, W
    btfss   STATUS, Z
     goto   $ + 3           ; No
    bsf     Direction       ; Yes
    goto    EndEqual
; id_bit_number > LastDiscrepancy?
    btfss   STATUS, C
     goto   $ + 3           ; No
    bcf     Direction       ; Yes
    goto    EndEqual
; No, id_bit_number !> LastDiscrepancy
; Direction = ROM_no, id_bit_number
    bcf     Direction ; optimizable!
    movf    rom_mask, W
    andwf   INDF, W
    btfss   STATUS, Z
     bsf    Direction

EndEqual
; Direction = 0?
    btfsc   Direction
     goto   EndDiscrepancy      ; No
; Yes, last_zero = id_bit_number
    movf    id_bit_number, W    ; Yes
    movwf   last_zero
; (9 - last_zero > 0)?, last_zero < 9?
    sublw   d'9'
    btfss   STATUS, C
     goto   EndDiscrepancy  ; No
; Yes, LastFamilyDiscr = last_zero
    movf    last_zero, W    ; Yes
    movwf   LastFamilyDiscr

EndDiscrepancy
; ROM_no, id_bit_number = Direction
    btfsc   Direction
     goto   $ + 5
; Direction = 0
    comf    rom_mask, W
    andwf   INDF, F
    call    DSWriteaZero    ; send Direction bit over 1-wire bus
    goto    $ + 4
; Direction = 1
    movf    rom_mask, W
    iorwf   INDF, F
    call    DSWriteaOne     ; send Direction bit over 1-wire bus

    incf    id_bit_number, F
    bcf     STATUS, C       ; needed!
    rlf     rom_mask, F

; End of byte?
    movf    rom_mask, F
    btfss   STATUS, Z
     goto   $ + 3           ; No
    incf    FSR, F          ; Yes, end of byte
    incf    rom_mask, F

; CRC update
    clrw
    btfss   Direction
     goto   read0
    movlw   b'00000001'
read0
    bcf     STATUS, C
    xorwf   DSCRC, W
    andlw   b'00000001'
    btfsc   STATUS, Z
     goto   in0
    movlw   0x18
    xorwf   DSCRC, F
    bsf     STATUS, C
in0
    rrf     DSCRC, F

; id_bit_number = 65?
    movf    id_bit_number, W
    addlw   (0 - .65)
    btfss   STATUS, Z
     goto   ReadBit

; LastDiscrepancy = last_zero
    movf    last_zero, W
    movwf   LastDiscrepancy
; LastDiscrepancy = 0 - check for last device
    movf    LastDiscrepancy, F
    btfsc   STATUS, Z
     bsf    last_device     ; Yes, set last_device flag
; check the CRC
    movf    DSCRC, F
    btfss   STATUS, Z
     goto   OWSearchErr     ; Not successful search, reset search state
    retlw   00 ; EXIT_SUCCESS
OWSearchErr
    retlw   01 ; EXIT_FAILURE
                end
