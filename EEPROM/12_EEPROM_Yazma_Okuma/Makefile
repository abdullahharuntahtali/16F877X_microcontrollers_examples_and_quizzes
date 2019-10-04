# MPLAB IDE generated this makefile for use with GNU make.
# Project: ODEV_7A.mcp
# Date: Sat Dec 18 21:50:53 2010

AS = MPASMWIN.exe
CC = 
LD = mplink.exe
AR = mplib.exe
RM = rm

ODEV_7A.cof : ODEV_7A.o
	$(CC) /p16F877A "ODEV_7A.o" /u_DEBUG /z__MPLAB_BUILD=1 /z__MPLAB_DEBUG=1 /o"ODEV_7A.cof" /M"ODEV_7A.map" /W /x

ODEV_7A.o : ODEV_7A.asm ../../../../Program\ Files/Microchip/MPASM\ Suite/p16F877A.inc
	$(AS) /q /p16F877A "ODEV_7A.asm" /l"ODEV_7A.lst" /e"ODEV_7A.err" /d__DEBUG=1

clean : 
	$(CC) "ODEV_7A.o" "ODEV_7A.hex" "ODEV_7A.err" "ODEV_7A.lst" "ODEV_7A.cof"

