# MPLAB IDE generated this makefile for use with GNU make.
# Project: TMR1.mcp
# Date: Mon Oct 29 00:28:21 2018

AS = MPASMWIN.exe
CC = 
LD = mplink.exe
AR = mplib.exe
RM = rm

TMR1.cof : TMR1.o
	$(CC) /p16F877A "TMR1.o" /u_DEBUG /z__MPLAB_BUILD=1 /z__MPLAB_DEBUG=1 /o"TMR1.cof" /M"TMR1.map" /W /x

TMR1.o : TMR1.asm ../../../../../Program\ Files\ (x86)/Microchip/MPASM\ Suite/P16F877A.INC
	$(AS) /q /p16F877A "TMR1.asm" /l"TMR1.lst" /e"TMR1.err" /d__DEBUG=1

clean : 
	$(CC) "TMR1.o" "TMR1.hex" "TMR1.err" "TMR1.lst" "TMR1.cof"

