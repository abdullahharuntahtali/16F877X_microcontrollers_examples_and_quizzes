        nolist
;******************************************************************************
;
;  This is the custom Header File for Dalas 1 wire bus MASTER
;       PROGRAM:        DAS_BUS.H
;       Revision:       21-09-97
;
;******************************************************************************

;Dallas Bus ROM function Commands

DSReadROM       equ     0x33
DSMatchROM      equ     0x55
DSSkipROM       equ     0xCC
DSSearchROM     equ     0xF0
DSAlarmSearch   equ     0xEC
     
;Dallas Bus Memory function Commands

DSWriteScratch  equ     0x4E
DSReadScratch   equ     0xBE
DSCopyScratch   equ     0x48
DSRecallE2      equ     0xB8
DSReadPS        equ     0xB4

;Dallas Bus Temp Conversion Command

DSConvertTemp   equ     0x44



        list
