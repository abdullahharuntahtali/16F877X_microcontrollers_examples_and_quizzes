# MPLAB IDE generated this makefile for use with GNU make.
# Project: tus.mcp
# Date: Sun Nov 13 19:11:30 2011

AS = MPASMWIN.exe
CC = 
LD = mplink.exe
AR = mplib.exe
RM = rm

tus.cof : tus.o
	$(CC) /p16F877A "tus.o" /u_DEBUG /z__MPLAB_BUILD=1 /z__MPLAB_DEBUG=1 /o"tus.cof" /M"tus.map" /W /x

tus.o : tus.asm C:/Program\ Files/Microchip/MPASM\ Suite/P16F877A.inc
	$(AS) /q /p16F877A "tus.asm" /l"tus.lst" /e"tus.err" /d__DEBUG=1

clean : 
	$(CC) "tus.o" "tus.hex" "tus.err" "tus.lst" "tus.cof"

