    nolist
;******************************************************************************
;
;  This is the custom Header File for LM032L LCD
;       PROGRAM:        LM032l.H
;       Revision:       9-10-95
;
;******************************************************************************
;TEMP       EQU     0x035   ; Temporary register
;CHAR       EQU     0x036   ; Temporary register, Holds value to send to LCD module.
;
;
; LCD Module commands
;
;CLR_DISP - clears all display, and cursor home to addr 0
CLR_DISP    EQU     0x001   ; Clear the Display

;RTN_HOME - cursor home and display unshifted, DDRAM unchanged
RTN_HOME    EQU     0x002

;ENTRY_... - sets entry mode, S = display shift on, INC / DEC cursor move dir
ENTRY_DEC   EQU     0x004   ;
ENTRY_DEC_S EQU     0x005   ;
ENTRY_INC   EQU     0x006   ;
ENTRY_INC_S EQU     0x007   ;

;DISP_... - Display on / off control, C = cursor ON, B = chr pos blink
DISP_OFF    EQU     0x008   ; Display off
DISP_ON     EQU     0x00C   ; Display on
DISP_ON_C   EQU     0x00E   ; Display on, Cursor on
DISP_ON_BC  EQU     0x00F   ; Display on, Cursor on, Blink cursor

;SHIFT_... - Cursor & Display shift, S = Display, C = cursor, L = Left, R = Right
SHIFT_C_L   EQU     0x010
SHIFT_C_R   EQU     0x014
SHIFT_S_L   EQU     0x018
SHIFT_S_R   EQU     0x01C

;FUNC_... - Function set, ( 4 bit, 2 lines, 5 x 7 dots) 
FUNC_SET    EQU     0x028

;
CURS_RGT    EQU     0x093
DD_RAM_ADDR EQU     0x080   ; Least Significant 7-bit are for address
DD_RAM_UL   EQU     0x080   ; Upper Left coner of the Display
;

    list
