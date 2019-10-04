# MPLAB IDE generated this makefile for use with GNU make.
# Project: DENEME.mcp
# Date: Tue Dec 04 10:46:18 2018

AS = MPASMWIN.exe
CC = 
LD = mplink.exe
AR = mplib.exe
RM = rm

DENEME.cof : MADEIN_TAHTA_REIS.o
	$(CC) /p16F877A "MADEIN_TAHTA_REIS.o" /u_DEBUG /z__MPLAB_BUILD=1 /z__MPLAB_DEBUG=1 /o"DENEME.cof" /M"DENEME.map" /W

MADEIN_TAHTA_REIS.o : MADEIN_TAHTA_REIS.asm ../../../../../Program\ Files\ (x86)/Microchip/MPASM\ Suite/P16F877A.INC
	$(AS) /q /p16F877A "MADEIN_TAHTA_REIS.asm" /l"MADEIN_TAHTA_REIS.lst" /e"MADEIN_TAHTA_REIS.err" /o"MADEIN_TAHTA_REIS.o" /d__DEBUG=1

clean : 
	$(CC) "MADEIN_TAHTA_REIS.o" "MADEIN_TAHTA_REIS.err" "MADEIN_TAHTA_REIS.lst" "DENEME.cof" "DENEME.hex"

