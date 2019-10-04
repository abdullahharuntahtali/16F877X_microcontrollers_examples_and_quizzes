; ==========================================================================================
; Gestion du temps - Quartz 4,096 MHz
; POLICE / Courier New modifiée avec 0 barré
; Doumai.Terret@Wanadoo.fr
; ==========================================================================================
            LIST      P=16F628, F=INHX8M, r=dec
            include "P16F628.inc"
            
	__CONFIG	_BODEN_OFF  & _PWRTE_OFF & _WDT_OFF & _LVP_OFF & _MCLRE_ON & _XT_OSC
	
	; Do not show warnings										
	ERRORLEVEL      -224												
			
#DEFINE L500ms	PORTB,0		; LED change d'état toutes les 500 ms
#DEFINE L1mn	PORTB,1		; LED change d'état toutes les minutes

		cblock 0x20
w_temp : 1					; Sauvegarde pour interruption
status_temp : 1				; Sauvegarde pour interruption
T100ms : 1					; Variable 100 ms - évolue de 0 à 49
T1s : 1						; Variable 1s - évolue de 0 à 9
T1mn : 1					; Variable 1mn - évolue de 0 à 59 s
SwapLed : 1					; Variable temporaire d'état des Leds
		endc
;
;============================================================================================
	ORG	0x0000	
		goto	main
	
	ORG	0x0004
		goto	inter

main:	bcf		STATUS,RP0		; Bank 0
		movlw	0x07			; Désactivation du mode comparateur et
		movwf	CMCON			; passe en mode Entrées / Sorties
;
		bsf     STATUS,RP0		; Bank 1
		movlw	B'00010000'		; 
		movwf	TRISB			; PortB en sortie sauf RB4 en entrée BP
	 	clrf    TRISA			; PortA en sortie (non utilsé)
		movlw	B'00010010'		; Interruption toutes les 2 ms
		movwf	OPTION_REG
		movlw	B'10100000'		; Autorisation générale des interruptions et
		movwf	INTCON			; autorise l'interruption Timer
		bcf		STATUS,RP0		; Bank 0
;
		clrf	PORTB
		clrf	T100ms			; Initialisation des variables
		clrf	T1s
		clrf	T1mn
		clrf	SwapLed
;
init:
		nop						; Programme principal !!!
		goto	init
;
; ====================================================================================
; Gestion de l'interruption toutes de 2 ms avec un quartz de 4.096 MHz
; ====================================================================================
inter:
; sauvegarde des registres W et STATUS
		movwf	w_temp			
		swapf	STATUS,W
		movwf	status_temp
;
		bcf		STATUS,RP0		; Bank 0
; -------------------------------------------------------------------------------------
; Gestion de la LED des secondes. T1s évolue de 0 à 9.
; Si T1s = 0, la LED sera éteinte. Si T1s = 5 la LED sera allumée.
; -------------------------------------------------------------------------------------
		movf	T1s,W			; Sauvegarde T1s dans W
		sublw	0				; Compare cette valeur à 0
		btfsc	STATUS,Z		; Skip si T1s <> 0
		bcf		SwapLed,0		; T1s est à 0, la LED sera éteinte
;
		movf	T1s,W			; Sauvegarde T1s dans W
		sublw	5				; Compare cette valeur à 5
		btfsc	STATUS,Z		; Skip si T1s <> 5
		bsf		SwapLed,0		; T1s est à 5, la LED sera allumée
; -------------------------------------------------------------------------------------
; Gestion de la LED des minutes. T1mn évolue de 0 à 59.
; Si T1mn = 0, la LED sera éteinte. Si T1mn = 30 la LED sera allumée.
; -------------------------------------------------------------------------------------
		movf	T1mn,W 			; Segment identique à celui de traitement de T1s
		sublw	0
		btfsc	STATUS,Z
		bcf		SwapLed,1
		movf	T1mn,W
		sublw	30
		btfsc	STATUS,Z
		bsf		SwapLed,1
; -------------------------------------------------------------------------------------
; Gestion de l'horloge 250 Hz. Le bit change d'état toutes les 2 ms.
; -------------------------------------------------------------------------------------
		movlw	0x20			; Charge le masque pour le bit 5
		xorwf	SwapLed,F		; Complémente le bit 5 de la variable SwapLed
; -------------------------------------------------------------------------------------
; Écriture sur le PORTB. Seuls les bits 0,1,5 sont modifiés.
; -------------------------------------------------------------------------------------
		movf	PORTB,W			; Sauvegarde l'état du PORTB dans W
		andlw	B'11011100'		; RAZ des bits 0,1 (Leds) et 5 (Horloge)
		iorwf	SwapLed,W		; Copie les bits 0,1 (Leds) et 5 (Horloge) dans SwapLed
		movwf	PORTB			; Écriture sur le PORTB
; -------------------------------------------------------------------------------------
; Incrémente la variable T100ms de 0 à 50, RAZ de cette variable toutes les 100 ms
; -------------------------------------------------------------------------------------
		incf	T100ms,F		; Incrémente la variable 100 ms
		movf	T100ms,W		; W = T100ms
		sublw	50				; 50 x 2 ms = 100 ms
		btfss	STATUS,Z		; 50 passages ?
		goto	FinT			; Fin de la gestion du temps
		clrf	T100ms			; Oui, RAZ T100ms
; -------------------------------------------------------------------------------------
; Incrémente la variable T1s de 0 à 9, RAZ de cette variable toutes les secondes
; -------------------------------------------------------------------------------------
		incf	T1s,F			; Incrémente la variable 1s
		movf	T1s,W			; W = T1s
		sublw	10				; 10 x 100 ms = 1 s
		btfss	STATUS,Z		; 10 passages ?
		goto	FinT			; Fin de la gestion du temps
		clrf	T1s				; Oui, RAZ T1s
; -------------------------------------------------------------------------------------
; Incrémente la variable T1mn de 0 à 59, RAZ de cette variable toutes les minutes
; -------------------------------------------------------------------------------------
		incf	T1mn,F			; Incrémente la variable 1mn
		movf	T1mn,W			; W = T1mn
		sublw	60				; 60 x 1 s = 1 mn
		btfss	STATUS,Z		; 60 passages ?
		goto	FinT			; Fin de la gestion du temps
		clrf	T1mn			; Oui, RAZ T1mn
;
FinT	nop						; 
; -------------------------------------------------------------------------------------
		bcf		INTCON,T0IF			; Prochaine interruption Timer prise en compte
; -------------------------------------------------------------------------------------
;
		swapf	status_temp,W		; Restauration des registres W et STATUS
		movwf	STATUS
		swapf	w_temp,F
		swapf	w_temp,W
;
		retfie

		end
