; synchro tv ccir par LOIC MARTY POUR PIC HORLOGE = 2OMhz
; 64 US  = 320 CYCLES MACHINE
; 4.8 us = 24 cYCLES MACHINE  
; 2.4 US = 12 CYCLES MACHINE
; debut de la vidéo 55 cycles a partir de la synchro horizontale  11us
__CONFIG _CP_OFF & _WDT_OFF & _HS_OSC & _BODEN_OFF & _MCLRE_OFF & _LVP_OFF & _PWRTE_OFF & _CP_OFF & _BODEN_OFF

                   include "P16f628.inc"  



compteur1            equ 20h   ;compteur 1 et compteur 2    
compteur2            equ 21h   ;qui concaténés forment le compteur de ligne sur 16 bits    
compteur_demi_ecran  equ 22h   ;compteur qui sert a determiner le milieu de l'ecran , en horizontal
flag_ligne	     equ 23h   ;registre de drapeau pour les tests de numero de ligne
compteur_delai       equ 24h   ;regsitre servant pour introduire des delai en nombre de cycles machines
registre_couleur     equ 25h   ;registre qui enregistre les signaux RVB 
registre_etat_mire_h equ 26h   ;registre de l'etat de la mire 
			       ;  	 00000001 NOIR
			       ;         0000001x ROUGE    
			       ;         000001xx VERT
			       ;         00001xxx BLEU
		               ; 	 0001xxxx BLANC
			       ;         001xxxxx MIRE DE BARRE

registre_etat_mire_b equ 27h   ;registre de l'etat de la mire en partie inférieure
registre_flag_bp     equ 28h   ;registre de drapeau pour les boutons poussoirs
compteur_trame       equ 29h   ;registre utilisé pour les anti rebond des poussoirs
car_pos_1	     equ 48h
car_pos_2	     equ 49h
car_pos_3	     equ 4Ah
car_pos_4	     equ 4Bh
car_pos_5	     equ 4Ch
car_pos_6	     equ 4Dh
car_pos_7	     equ 4Eh
car_pos_8	     equ 4Fh
car_pos_9	     equ 50h
car_pos_10	     equ 51h
car_pos_11	     equ 52h
car_pos_12	     equ 53h
car_pos_13	     equ 54h
caractere	     equ 58h
offset		     equ 59h
compteur_boucle	     equ 5Bh
pointeur_BP	     equ 5Dh
flag_BP		     equ 5Eh
compteur_passage     equ 5Fh
pointeur_redef	     equ 60h
car_a_refinir        equ 61h
car_inter	     equ 62h
position_ligne       equ 63h
ligne_pixel	     equ 64h
car_a_memoriser      equ 65h
pointeur_pos_carac   equ 66h
compteur_trame_BP_1  equ 67h
compteur_trame_BP_2  equ 68h
compteur_trame_BP_3  equ 69h
compteur_trame_BP_4  equ 55h
compteur_trame_BP_5  equ 56h
	

pixel_car_pos_1      equ 70h
pixel_car_pos_2      equ 71h
pixel_car_pos_3      equ 72h
pixel_car_pos_4      equ 73h
pixel_car_pos_5      equ 74h
pixel_car_pos_6      equ 75h
pixel_car_pos_7      equ 76h
pixel_car_pos_8      equ 77h
pixel_car_pos_9      equ 78h
pixel_car_pos_10     equ 79h
pixel_car_pos_11     equ 7Ah
pixel_car_pos_12     equ 7Bh
pixel_car_pos_13     equ 7Ch
pointeur_CAR         equ 7Dh
pointeur_RAM         equ 7Eh
poubelle             equ 7Fh  ;registres qui peuvent etre lus dans toute les banques de memoires


#define sync_horizontale 1	
#define bouton_mire_h 2
#define BP_selection_car_plus 3
#define BP_selection_pos_plus 6
#define BP_selection_car_moins 5
#define BP_selection_pos_moins 4
#define rouge   b'00001010'
#define vert    b'00000011'
#define bleu    b'00000110'
#define noir    b'00000010'
#define blanc   b'00001111'
#define cyan    b'00000111'
#define magenta b'00001110'
#define jaune   b'00001011'



rotation_sur_B7     MACRO
		    movwf PORTB
		    nop
		    rlf PORTB,1
		    nop
		    rlf PORTB,1
		    nop
		    rlf PORTB,1
		    nop
		    rlf PORTB,1
		    nop
		    rlf PORTB,1
		    nop
		    rlf PORTB,1
		    nop
		    rlf PORTB,1
		    ENDM


          org h'2148'
DE 06 ;F
DE 1C ;1
DE 15 ;U
DE 02 ;B
DE 1A ;Z
DE 26 ;
DE 01 ;
DE 14 ;
DE 16 ;
DE 06 ;
DE 07 ;
DE 08 ;
DE 09 ;



                org 0
		goto debut               

		org 600

affiche_pixels  nop
		nop
		nop
		nop
		movf pixel_car_pos_1,0       
		rotation_sur_B7
		movf pixel_car_pos_2,0       
		rotation_sur_B7
		movf pixel_car_pos_3,0       
		rotation_sur_B7   
		movf pixel_car_pos_4,0       
		rotation_sur_B7
		movf pixel_car_pos_5,0       
		rotation_sur_B7 
		movf pixel_car_pos_6,0       
		rotation_sur_B7
		movf pixel_car_pos_7,0       
		rotation_sur_B7
		movf pixel_car_pos_8,0       
		rotation_sur_B7   
		movf pixel_car_pos_9,0       
		rotation_sur_B7
		movf pixel_car_pos_10,0       
		rotation_sur_B7
		movf pixel_car_pos_11,0       
		rotation_sur_B7   
		movf pixel_car_pos_12,0       
		rotation_sur_B7
		movf pixel_car_pos_13,0       
		rotation_sur_B7
		call delai_4_cycles
		call delai_4_cycles

		return 
		


		
		ORG 5
debut		clrf PORTA
		movlw d'7'
		movwf CMCON
		bsf STATUS,RP0      ;on passe en bank 1 
		clrf TRISA
		movlw b'00000001'
		movwf TRISB
		bcf STATUS,RP0      ;on repasse en bank 0
		bcf PORTB,7   
		clrf compteur1
		clrf compteur2       
		clrf registre_etat_mire_h
		clrf registre_etat_mire_b
		movlw b'00100000'
		movwf registre_etat_mire_h
		clrf registre_flag_bp 
		clrf compteur_trame	
		clrf ligne_pixel
		clrf compteur_demi_ecran
		clrf pointeur_RAM
		movlw h'48'
		movwf pointeur_pos_carac
	        clrf pixel_car_pos_1
	
                movlw 48h
		call lire_eeprom
		movwf car_pos_1
		movlw 49h
		call lire_eeprom
		movwf car_pos_2
		movlw 4Ah
		call lire_eeprom
		movwf car_pos_3
		movlw 4Bh
		call lire_eeprom
		movwf car_pos_4
		movlw 4Ch
		call lire_eeprom
		movwf car_pos_5
		movlw 4Dh
		call lire_eeprom
		movwf car_pos_6
		movlw 4Eh
		call lire_eeprom
		movwf car_pos_7
		movlw 4Fh
		call lire_eeprom
		movwf car_pos_8
		movlw 50h
		call lire_eeprom
		movwf car_pos_9
		movlw 51h
		call lire_eeprom
		movwf car_pos_10
		movlw 52h
		call lire_eeprom
		movwf car_pos_11
		movlw 53h
		call lire_eeprom
		movwf car_pos_12
		movlw 54h
		call lire_eeprom
		movwf car_pos_13
        	goto boucle_64us


delai_12_cycles call delai_4_cycles
                call delai_4_cycles
		return
		
affichage_des_caracteres bsf STATUS,RP0
			 clrf TRISB
			 bcf STATUS,RP0
		         bsf PORTA,sync_horizontale
		    	 call delai_4_cycles
			 call delai_12_cycles
			 call ligne_pixel_1
			 call delai_12_cycles
			 nop
		         call synchro_horizontale 
			 call delai_12_cycles
			 call ligne_pixel_1
			 call delai_12_cycles
			 nop
			 nop
			 nop
		         call synchro_horizontale 
			 call delai_12_cycles
			 call ligne_pixel_1
			 call delai_12_cycles
			 nop
			 nop
			 nop
			 call synchro_horizontale
			 call delai_12_cycles
			 call ligne_pixel_2
			 call delai_12_cycles
			 nop
			 nop
			 nop
			 call synchro_horizontale 
			 call delai_12_cycles
			 call ligne_pixel_2
			 call delai_12_cycles
			 nop
		         nop
		         nop
			 call synchro_horizontale 
			 call delai_12_cycles
			 call ligne_pixel_2
			 call delai_12_cycles
			 nop
			 nop 
			 nop
			 call synchro_horizontale
		         call delai_12_cycles
			 call ligne_pixel_3
			 call delai_12_cycles
			 nop
			 nop
		         nop
			 call synchro_horizontale 
			 call delai_12_cycles
			 call ligne_pixel_3
			 call delai_12_cycles
		         nop
			 nop
			 nop	
		         call synchro_horizontale 
			 call delai_12_cycles
			 call ligne_pixel_3
			 call delai_12_cycles
			 nop
			 nop
			 nop
			 call synchro_horizontale
		         call delai_12_cycles
			 call ligne_pixel_4
			 call delai_12_cycles
			 nop
			 nop
			 nop
			 call synchro_horizontale 
			 call delai_12_cycles
			 call ligne_pixel_4
			 call delai_12_cycles
		         nop
			 nop
		         nop
			 call synchro_horizontale 
			 call delai_12_cycles
			 call ligne_pixel_4
			 call delai_12_cycles
			 nop
			 nop
			 nop
			 call synchro_horizontale
                         call delai_12_cycles
			 call ligne_pixel_5
			 call delai_12_cycles
			 nop
			 nop
			 nop 
			 call synchro_horizontale 
			 call delai_12_cycles
			 call ligne_pixel_5
			 call delai_12_cycles
			 nop
			 nop
			 nop
			 call synchro_horizontale 
			 call delai_12_cycles
			 call ligne_pixel_5
			 call delai_12_cycles
			 nop	
			 nop
			 nop
			 call synchro_horizontale
                         call delai_12_cycles
			 call ligne_pixel_6
			 call delai_12_cycles
			 nop
		         nop
		         nop
			 call synchro_horizontale 
			 call delai_12_cycles
			 call ligne_pixel_6
			 call delai_12_cycles
		         nop
			 nop
			 nop
		         call synchro_horizontale 
			 call delai_12_cycles
			 call ligne_pixel_6
			 call delai_12_cycles
			 nop
			 nop
		         nop
			 call synchro_horizontale
		         call delai_12_cycles
			 call ligne_pixel_7
			 call delai_12_cycles
			 nop
	                 nop
			 nop
			 call synchro_horizontale 
			 call delai_12_cycles
			 call ligne_pixel_7
			 call delai_12_cycles
		         nop
			 nop
			 nop
		         call synchro_horizontale 
			 call delai_12_cycles
			 call ligne_pixel_7
			 call delai_12_cycles
			 nop
			 nop
			 nop
			 call synchro_horizontale
                         call delai_12_cycles
			 call ligne_pixel_8
			 call delai_12_cycles
		         nop
			 nop
			 nop
			 call synchro_horizontale 
			 call delai_12_cycles
			 call ligne_pixel_8
			 call delai_12_cycles
			 nop
			 nop
			 nop
			 call synchro_horizontale 
			 call delai_12_cycles
			 call ligne_pixel_8
			 call delai_12_cycles
			 nop
			 nop
			 nop
			 call synchro_horizontale
                         call delai_12_cycles
			 call ligne_pixel_1
			 call delai_12_cycles
		         nop
			 nop
			 nop
			 call synchro_horizontale 
			 call delai_12_cycles
			 call ligne_pixel_1
			 call delai_12_cycles
			 nop
			 nop
			 nop
			 call synchro_horizontale 
			 call delai_12_cycles			 
	  		 call ligne_pixel_1
			 call delai_12_cycles
		         nop
			 nop
			 nop
			 call delai_4_cycles
		         call delai_4_cycles
		         bcf PORTA,sync_horizontale
			 incfsz compteur1,1 
	                 decf compteur2,1   
                         incf compteur2,1  
		         call delai_12_cycles			
		         call delai_4_cycles
		         bsf STATUS,RP0
		         movlw b'11111111'
			 movwf TRISB
		         bcf STATUS,RP0
		         bsf PORTA,sync_horizontale
			 return



ligne_pixel_1   bsf STATUS,RP0
		movf h'A0',0
		movwf pixel_car_pos_1
		movf h'A1',0
		movwf pixel_car_pos_2
		movf h'A2',0
		movwf pixel_car_pos_3
		movf h'A3',0
		movwf pixel_car_pos_4
		movf h'A4',0
		movwf pixel_car_pos_5
		movf h'A5',0
		movwf pixel_car_pos_6
		movf h'A6',0
		movwf pixel_car_pos_7
		movf h'A7',0
		movwf pixel_car_pos_8
		movf h'A8',0
		movwf pixel_car_pos_9
		movf h'A9',0
		movwf pixel_car_pos_10
		bcf STATUS,RP0
		bsf STATUS,RP1
		movf h'20',0
		movwf pixel_car_pos_11
		movf h'21',0
		movwf pixel_car_pos_12
		movf h'22',0
		movwf pixel_car_pos_13
		bcf STATUS,RP1
		call affiche_pixels
		return

ligne_pixel_2   bsf STATUS,RP0
		movf h'AA',0
		movwf pixel_car_pos_1
		movf h'AB',0
		movwf pixel_car_pos_2
		movf h'AC',0
		movwf pixel_car_pos_3
		movf h'AD',0
		movwf pixel_car_pos_4
		movf h'AE',0
		movwf pixel_car_pos_5
		movf h'AF',0
		movwf pixel_car_pos_6
		movf h'B0',0
		movwf pixel_car_pos_7
		movf h'B1',0
		movwf pixel_car_pos_8
		movf h'B2',0
		movwf pixel_car_pos_9
		movf h'B3',0
		movwf pixel_car_pos_10
		bcf STATUS,RP0
		bsf STATUS,RP1
		movf h'23',0
		movwf pixel_car_pos_11
		movf h'24',0
		movwf pixel_car_pos_12
		movf h'25',0
		movwf pixel_car_pos_13
		bcf STATUS,RP1
		call affiche_pixels
		return


ligne_pixel_3   bsf STATUS,RP0
		movf h'B4',0
		movwf pixel_car_pos_1
		movf h'B5',0
		movwf pixel_car_pos_2
		movf h'B6',0
		movwf pixel_car_pos_3
		movf h'B7',0
		movwf pixel_car_pos_4
		movf h'B8',0
		movwf pixel_car_pos_5
		movf h'B9',0
		movwf pixel_car_pos_6
		movf h'BA',0
		movwf pixel_car_pos_7
		movf h'BB',0
		movwf pixel_car_pos_8
		movf h'BC',0
		movwf pixel_car_pos_9
		movf h'BD',0
		movwf pixel_car_pos_10
		bcf STATUS,RP0
		bsf STATUS,RP1
		movf h'26',0
		movwf pixel_car_pos_11
		movf h'27',0
		movwf pixel_car_pos_12
		movf h'28',0
		movwf pixel_car_pos_13
		bcf STATUS,RP1
		call affiche_pixels
		return

ligne_pixel_4   bsf STATUS,RP0
		movf h'BE',0
		movwf pixel_car_pos_1
		movf h'BF',0
		movwf pixel_car_pos_2
		movf h'C0',0
		movwf pixel_car_pos_3
		movf h'C1',0
		movwf pixel_car_pos_4
		movf h'C2',0
		movwf pixel_car_pos_5
		movf h'C3',0
		movwf pixel_car_pos_6
		movf h'C4',0
		movwf pixel_car_pos_7
		movf h'C5',0
		movwf pixel_car_pos_8
		movf h'C6',0
		movwf pixel_car_pos_9
		movf h'C7',0
		movwf pixel_car_pos_10
		bcf STATUS,RP0
		bsf STATUS,RP1
		movf h'29',0
		movwf pixel_car_pos_11
		movf h'2A',0
		movwf pixel_car_pos_12
		movf h'2B',0
		movwf pixel_car_pos_13
		bcf STATUS,RP1
		call affiche_pixels
		return

ligne_pixel_5   bsf STATUS,RP0
		movf h'C8',0
		movwf pixel_car_pos_1
		movf h'C9',0
		movwf pixel_car_pos_2
		movf h'CA',0
		movwf pixel_car_pos_3
		movf h'CB',0
		movwf pixel_car_pos_4
		movf h'CC',0
		movwf pixel_car_pos_5
		movf h'CD',0
		movwf pixel_car_pos_6
		movf h'CE',0
		movwf pixel_car_pos_7
		movf h'CF',0
		movwf pixel_car_pos_8
		movf h'D0',0
		movwf pixel_car_pos_9
		movf h'D1',0
		movwf pixel_car_pos_10
		bcf STATUS,RP0
		bsf STATUS,RP1
		movf h'2C',0
		movwf pixel_car_pos_11
		movf h'2D',0
		movwf pixel_car_pos_12
		movf h'2E',0
		movwf pixel_car_pos_13
		bcf STATUS,RP1
		call affiche_pixels
		return

ligne_pixel_6   bsf STATUS,RP0
		movf h'D2',0
		movwf pixel_car_pos_1
		movf h'D3',0
		movwf pixel_car_pos_2
		movf h'D4',0
		movwf pixel_car_pos_3
		movf h'D5',0
		movwf pixel_car_pos_4
		movf h'D6',0
		movwf pixel_car_pos_5
		movf h'D7',0
		movwf pixel_car_pos_6
		movf h'D8',0
		movwf pixel_car_pos_7
		movf h'D9',0
		movwf pixel_car_pos_8
		movf h'DA',0
		movwf pixel_car_pos_9
		movf h'DB',0
		movwf pixel_car_pos_10
		bcf STATUS,RP0
		bsf STATUS,RP1
		movf h'2F',0
		movwf pixel_car_pos_11
		movf h'30',0
		movwf pixel_car_pos_12
		movf h'31',0
		movwf pixel_car_pos_13
		bcf STATUS,RP1
		call affiche_pixels
		return

ligne_pixel_7   bsf STATUS,RP0
		movf h'DC',0
		movwf pixel_car_pos_1
		movf h'DD',0
		movwf pixel_car_pos_2
		movf h'DE',0
		movwf pixel_car_pos_3
		movf h'DF',0
		movwf pixel_car_pos_4
		movf h'E0',0
		movwf pixel_car_pos_5
		movf h'E1',0
		movwf pixel_car_pos_6
		movf h'E2',0
		movwf pixel_car_pos_7
		movf h'E3',0
		movwf pixel_car_pos_8
		movf h'E4',0
		movwf pixel_car_pos_9
		movf h'E5',0
		movwf pixel_car_pos_10
		bcf STATUS,RP0
		bsf STATUS,RP1
		movf h'32',0
		movwf pixel_car_pos_11
		movf h'33',0
		movwf pixel_car_pos_12
		movf h'34',0
		movwf pixel_car_pos_13
		bcf STATUS,RP1
		call affiche_pixels
		return

ligne_pixel_8   bsf STATUS,RP0
		movf h'E6',0
		movwf pixel_car_pos_1
		movf h'E7',0
		movwf pixel_car_pos_2
		movf h'E8',0
		movwf pixel_car_pos_3
		movf h'E9',0
		movwf pixel_car_pos_4
		movf h'EA',0
		movwf pixel_car_pos_5
		movf h'EB',0
		movwf pixel_car_pos_6
		movf h'EC',0
		movwf pixel_car_pos_7
		movf h'ED',0
		movwf pixel_car_pos_8
		movf h'EE',0
		movwf pixel_car_pos_9
		movf h'EF',0
		movwf pixel_car_pos_10
		bcf STATUS,RP0
		bsf STATUS,RP1
		movf h'35',0
		movwf pixel_car_pos_11
		movf h'36',0
		movwf pixel_car_pos_12
		movf h'37',0
		movwf pixel_car_pos_13
		bcf STATUS,RP1
		call affiche_pixels
		return

		
table_pixels    movwf caractere        ;cette routine renvoie les pixels//caracteres
		btfsc caractere,5      ;en entrée le registre W correspont au 
		goto cas_car_sup_31    ;caractere en ascii de 0 a 63, et en sortie W 

cas_car_inf_31  nop
		movlw b'00000101'
		movwf PCLATH
		bcf STATUS,C
		movf caractere,0
		movwf offset
	        rlf offset,1
		rlf offset,1
		rlf offset,1
		movf ligne_pixel,0
		xorwf offset,0
		call table_0_a_31
		return	

cas_car_sup_31  movlw b'00000111'
		movwf PCLATH
		bcf STATUS,C
		movf caractere,0
		movwf offset
	        rlf offset,1
		rlf offset,1
		rlf offset,1
		movf ligne_pixel,0
		xorwf offset,0
		call table_32_a_63
		return
	
		
boucle_64us     call synchro_horizontale  ; 32 cycles machines , incluant le compteur de lignes , et les tests sur compteur2 
	      	movlw b'00001010'    
		xorwf flag_ligne,0   
		btfsc STATUS,Z	     
		goto l_623	     
		movlw b'00000101'    
		xorwf flag_ligne,0   
		btfsc STATUS,Z	     
		goto l_310

	           bsf STATUS,C
		   btfsc registre_flag_bp,0
		   rlf registre_etat_mire_h,1
		   bcf registre_flag_bp,0
                   btfsc registre_etat_mire_h,5
		   goto mire_de_barre
		   btfsc registre_etat_mire_h,4
		   goto mire_de_blanc
		   btfsc registre_etat_mire_h,3
		   goto mire_de_bleu
	           btfsc registre_etat_mire_h,2
		   goto mire_de_vert
		   btfsc registre_etat_mire_h,1
		   goto mire_de_rouge

mire_de_noir      nop
		  call delai_4_cycles
		  movlw noir
		  movwf PORTA
		  movlw d'150'
		  call delai_cycle_machine
		  movlw d'103'
		  call delai_cycle_machine	
		  goto boucle_64us

mire_de_blanc     call delai_4_cycles
		  call delai_4_cycles   
		  nop
		  nop
		  movlw blanc
		  movwf PORTA
		  movlw d'150'
		  call delai_cycle_machine
		  movlw d'102'
		  call delai_cycle_machine
		  goto boucle_64us

mire_de_bleu      call delai_4_cycles
		  call delai_4_cycles
		  movlw bleu
		  movwf PORTA
		  movlw d'150'
		  call delai_cycle_machine
		  movlw d'103'
		  call delai_cycle_machine
		  goto boucle_64us

mire_de_vert      call delai_4_cycles
		  nop
		  nop
		  movlw vert
	  	  movwf PORTA
		  movlw d'150'
		  call delai_cycle_machine
	          movlw d'103'
		  call delai_cycle_machine
		  goto boucle_64us			

mire_de_rouge     call delai_4_cycles
		   movlw rouge
		  movwf PORTA
		  movlw d'150'
		  call delai_cycle_machine 
		  movlw d'103'
		  call delai_cycle_machine
		  goto boucle_64us


mire_de_barre       call delai_4_cycles
		    call delai_4_cycles
		    movlw b'00100000'
		    movwf registre_etat_mire_h
		    nop
		    nop	    
		
		    movlw blanc
		    movwf PORTA
		    movlw d'30'
		    call delai_cycle_machine
		    movlw jaune
		    movwf PORTA
		    movlw d'30'
		    call delai_cycle_machine
                    movlw cyan
		    movwf PORTA
		    movlw d'30'
		    call delai_cycle_machine
		    movlw vert
		    movwf PORTA
		    movlw d'30'
		    call delai_cycle_machine
		    movlw magenta
		    movwf PORTA
		    movlw d'30'
		    call delai_cycle_machine
		    movlw rouge
		    movwf PORTA
		    movlw d'30'
		    call delai_cycle_machine
                    movlw bleu
		    movwf PORTA
		    movlw d'30'
		    call delai_cycle_machine
		    movlw noir
		    movwf PORTA
		    movlw d'23'
		    call delai_cycle_machine
		    goto boucle_64us

synchro_horizontale   movlw noir     ;palier avant 1us
		      movwf PORTA	
		      nop
		      nop
		      nop
		      nop
		      bcf PORTA,sync_horizontale         ;synchro ligne 4.8us
		      clrf flag_ligne
             	      incfsz compteur1,1 
	              decf compteur2,1   
                      incf compteur2,1   
	       	      btfsc compteur2,0  
		      bsf flag_ligne,0   
		      btfsc compteur2,1  
		      bsf flag_ligne,1   
		      movlw d'54'    	     
		      xorwf compteur1,0	    
		      btfsc STATUS,Z       ;compteur1=54??
		      bsf flag_ligne,2     ;oui flag2=1 sinon flag2=0
		      movlw d'111'    	     
		      xorwf compteur1,0	    
		      btfsc STATUS,Z       ;compteur1=110??
		      bsf flag_ligne,3     ;oui flag3=1 sinon flag3=0
		      decfsz compteur_demi_ecran,1
		      goto $+2
		      goto affichage_des_caracteres
		      call delai_4_cycles		       
 		      bsf PORTA,sync_horizontale
		      return

	     
	
l_310           movlw d'119'
		call delai_cycle_machine
		movlw d'160'
		call delai_cycle_machine
		nop
		call egalisation
		movlw d'1'
		movwf compteur2
		movlw d'79'
		movwf compteur1
		movlw d'187'
		call delai_cycle_machine
		movlw d'101'
		call delai_cycle_machine
	        

maj_RAM_pixel   nop
		nop
		movlw d'238'
		movwf compteur_demi_ecran
		call delai_4_cycles
		movlw h'A0'                          ; les pixels des caracteres sont memorisé dans la memoire ram  bank 1 du pic
		movwf pointeur_RAM		     ; a partir de l'adresse AO h , cf doc du pic
		bcf PORTA,sync_horizontale           ; 8 lignes sont utilisés pour effectuer cette mise en memoire
        	clrf ligne_pixel                     ; situé juste apres la synchro , en effet les 24 1ere lignes d'un signal vidéo ne 
		Call maj_ligne                       ; se voient pas a l'ecran , normalement utilisé par le teletexte par exmple
        	bcf PORTA,sync_horizontale
        	incf ligne_pixel,1
		Call maj_ligne  
        	bcf PORTA,sync_horizontale
        	incf ligne_pixel,1
		Call maj_ligne  
         	bcf PORTA,sync_horizontale
        	incf ligne_pixel,1
		Call maj_ligne 
		bcf PORTA,sync_horizontale
        	incf ligne_pixel,1
		Call maj_ligne  
        	bcf PORTA,sync_horizontale
        	incf ligne_pixel,1
		Call maj_ligne  
         	bcf PORTA,sync_horizontale
        	incf ligne_pixel,1
		Call maj_ligne  		
		bcf PORTA,sync_horizontale
        	incf ligne_pixel,1
		Call maj_ligne 
		bcf PORTA,sync_horizontale
		bsf STATUS,IRP
		movlw h'20'
		movwf pointeur_RAM
		clrf ligne_pixel
		call delai_12_cycles
		call delai_4_cycles
		nop
		call maj_ligne_car_11_13+2
		bcf PORTA,sync_horizontale
        	incf ligne_pixel,1
		Call maj_ligne_car_11_13  
        	bcf PORTA,sync_horizontale
        	incf ligne_pixel,1
		Call maj_ligne_car_11_13  
         	bcf PORTA,sync_horizontale
        	incf ligne_pixel,1
		Call maj_ligne_car_11_13 
		bcf PORTA,sync_horizontale
        	incf ligne_pixel,1
		Call maj_ligne_car_11_13  
        	bcf PORTA,sync_horizontale
        	incf ligne_pixel,1
		Call maj_ligne_car_11_13  
         	bcf PORTA,sync_horizontale
        	incf ligne_pixel,1
		Call maj_ligne_car_11_13  		
		bcf PORTA,sync_horizontale
        	incf ligne_pixel,1
		Call maj_ligne_car_11_13
		bcf PORTA,sync_horizontale
		bcf STATUS,IRP
		clrf flag_ligne
		movlw d'20'
		call delai_cycle_machine
		nop
		bsf PORTA,sync_horizontale
 		goto boucle_64us+1

maj_ligne_car_11_13 movlw d'20'
		    call delai_cycle_machine     
		    bsf PORTA,sync_horizontale
		    nop
		    nop
	     	    nop
		    movf pointeur_RAM,0
	  	    movwf FSR		
		    movf car_pos_11,0
		    call table_pixels 
		    movwf INDF
		    incf pointeur_RAM,1
		    movf pointeur_RAM,0
		    movwf FSR		
		    movf car_pos_12,0
		    call table_pixels    
		    movwf INDF
		    incf pointeur_RAM,1
		    movf pointeur_RAM,0
		    movwf FSR		
		    movf car_pos_13,0
		    call table_pixels 
		    movwf INDF
		    incf pointeur_RAM,1
		    movlw d'203'
		    call delai_cycle_machine
		    return



  
   

maj_ligne       movlw d'20'
		call delai_cycle_machine     
		bsf PORTA,sync_horizontale
		nop
		nop
		nop
		movf pointeur_RAM,0
		movwf FSR		
		movf car_pos_1,0
		call table_pixels    
		movwf INDF
		incf pointeur_RAM,1
		movf pointeur_RAM,0
		movwf FSR		
		movf car_pos_2,0
		call table_pixels 
		movwf INDF
		incf pointeur_RAM,1
                movf pointeur_RAM,0
		movwf FSR		
		movf car_pos_3,0
		call table_pixels    
		movwf INDF
		incf pointeur_RAM,1
		movf pointeur_RAM,0
		movwf FSR		
		movf car_pos_4,0
		call table_pixels 
		movwf INDF
		incf pointeur_RAM,1
		movf pointeur_RAM,0
		movwf FSR		
		movf car_pos_5,0
		call table_pixels    
		movwf INDF
		incf pointeur_RAM,1
		movf pointeur_RAM,0
		movwf FSR		
		movf car_pos_6,0
		call table_pixels 
		movwf INDF
		incf pointeur_RAM,1
                movf pointeur_RAM,0
		movwf FSR		
		movf car_pos_7,0
		call table_pixels    
		movwf INDF
		incf pointeur_RAM,1
		movf pointeur_RAM,0
		movwf FSR		
		movf car_pos_8,0
		call table_pixels 
		movwf INDF
		incf pointeur_RAM,1
		movf pointeur_RAM,0
		movwf FSR		
		movf car_pos_9,0
		call table_pixels    
		movwf INDF
		incf pointeur_RAM,1
		movf pointeur_RAM,0
		movwf FSR		
		movf car_pos_10,0
		call table_pixels 
		movwf INDF
		incf pointeur_RAM,1
		return



		
l_623           movlw d'123'
		call delai_cycle_machine
		nop
		call egalisation
		clrf compteur2
		movlw d'5'
		movwf compteur1
		movlw d'128'
		nop
		clrf compteur_demi_ecran
		call delai_cycle_machine
		goto boucle_64us



test_des_BP        btfss PORTB,bouton_mire_h
		   goto bouton_mire_h_l
		   clrf compteur_trame
		   bcf registre_flag_bp,0
		   nop
		   nop
		   goto fin_test_poussoirs
bouton_mire_h_l    incf compteur_trame,1
	           movlw d'3' 
		   xorwf compteur_trame,0
		   btfsc STATUS,Z
		   bsf registre_flag_bp,0
fin_test_poussoirs nop

test_du_BP_pos_plus  btfss PORTB,BP_selection_pos_plus
		     goto bouton_selec_p_l
		     clrf compteur_trame_BP_1
		     bcf registre_flag_bp,1
		     nop
		     nop
		     goto fin_test_bp_sel_plus
bouton_selec_p_l     incf compteur_trame_BP_1,1
	             movlw d'3' 
		     xorwf compteur_trame_BP_1,0
		     btfsc STATUS,Z
		     bsf registre_flag_bp,1
fin_test_bp_sel_plus nop


test_du_BP_pos_moins  btfss PORTB,BP_selection_pos_moins
		      goto bouton_selec_m_l
		      clrf compteur_trame_BP_4
		      bcf registre_flag_bp,4
		      nop
		      nop
		      goto fin_test_bp_sel_moins
bouton_selec_m_l      incf compteur_trame_BP_4,1
	              movlw d'3' 
		      xorwf compteur_trame_BP_4,0
		      btfsc STATUS,Z
		      bsf registre_flag_bp,4
fin_test_bp_sel_moins nop

test_du_BP_car_moins  btfss PORTB,BP_selection_car_moins
		      goto bouton_car_m_l
		      clrf compteur_trame_BP_5
		      bcf registre_flag_bp,5
		      nop
		      nop
		      nop 	
		      goto fin_test_bp_car_m
bouton_car_m_l        incf compteur_trame_BP_5,1
	              movlw d'7' 
		      xorwf compteur_trame_BP_5,0
		      btfsc STATUS,Z
		      bsf registre_flag_bp,5
		      nop
fin_test_bp_car_m     nop




test_du_BP_car_plus  btfss PORTB,BP_selection_car_plus
		   goto bouton_car_p_l
		   clrf compteur_trame_BP_2
		   bcf registre_flag_bp,2
		   nop
		   nop
		   nop 	
		   goto fin_test_bp_car_p
bouton_car_p_l       incf compteur_trame_BP_2,1
	           movlw d'7' 
		   xorwf compteur_trame_BP_2,0
		   btfsc STATUS,Z
		   bsf registre_flag_bp,2
		   nop
fin_test_bp_car_p    nop


position_change_moins  btfss registre_flag_bp,4
                       goto fin_change_moins
		       bcf registre_flag_bp,4
		       decf pointeur_pos_carac,1
		       movlw h'47' 
		       xorwf pointeur_pos_carac,0
		       btfsc STATUS,Z
		       goto reset_pos_moins
		       call delai_4_cycles
		       nop		        	
fin_pos_change_moins   goto position_change_plus
reset_pos_moins        movlw h'54'
		       movwf pointeur_pos_carac
		       goto fin_pos_change
fin_change_moins       call delai_4_cycles
		       call delai_4_cycles
	               goto fin_pos_change_moins		

position_change_plus   btfss registre_flag_bp,1
                       goto fin_change_plus
		       bcf registre_flag_bp,1
		       incf pointeur_pos_carac,1
		       movlw h'55' 
		       xorwf pointeur_pos_carac,0
		       btfsc STATUS,Z
		       goto reset_pos_plus
		       call delai_4_cycles
		       nop		        	
fin_pos_change         goto test_si_car_plus
reset_pos_plus         movlw h'48'
		       movwf pointeur_pos_carac
		       goto fin_pos_change
fin_change_plus        call delai_4_cycles
		       call delai_4_cycles
	               goto fin_pos_change

test_si_car_plus       btfss registre_flag_bp,2
		       goto fin_car_change_p
		       bcf registre_flag_bp,2
		       movf pointeur_pos_carac,0
		       movwf FSR
		       movf INDF,0
		       movwf poubelle
		       incf poubelle,1
		       clrf compteur_trame_BP_2
		       bcf poubelle,6
		       bcf poubelle,7
		       movf poubelle,0
		       movwf INDF			
		       movf pointeur_pos_carac,0
		       nop
		       nop
                       bsf STATUS,RP0
 		       movwf EEADR
	               bcf STATUS,RP0
		       movf poubelle,0
                       bsf STATUS,RP0
		       movwf EEDATA
		       bcf STATUS,RP0		
                       bcf PIR1,EEIF
		       bsf STATUS,RP0
		       bsf EECON1,WREN
		       movlw h'55'
		       movwf EECON2
	  	       movlw h'aa'
		       movwf EECON2
		       bsf EECON1,WR
		       bcf STATUS,RP0
fin_c_p		       goto test_si_car_moins
fin_car_change_p       call delai_12_cycles
		       call delai_12_cycles
		       goto fin_c_p

test_si_car_moins      btfss registre_flag_bp,5
		       goto fin_car_change_m
		       bcf registre_flag_bp,5
		       movf pointeur_pos_carac,0
		       movwf FSR
		       movf INDF,0
		       movwf poubelle
		       decf poubelle,1
		       clrf compteur_trame_BP_5
		       bcf poubelle,6
		       bcf poubelle,7		       
		       movf poubelle,0
		       movwf INDF			
		       movf pointeur_pos_carac,0
		       nop
		       nop
                       bsf STATUS,RP0
		       movwf EEADR
	               bcf STATUS,RP0
		       movf poubelle,0
                       bsf STATUS,RP0
		       movwf EEDATA
		       bcf STATUS,RP0		
                       bcf PIR1,EEIF
		       bsf STATUS,RP0
		       bsf EECON1,WREN
		       movlw h'55'
		       movwf EECON2
	  	       movlw h'aa'
		       movwf EECON2
		       bsf EECON1,WR
		       bcf STATUS,RP0
fin		       return
fin_car_change_m       call delai_12_cycles
		       call delai_12_cycles
		       goto fin

		       
		       






egalisation		call impulsion_courte                      ;1ere impulsion_courte
			call test_des_BP
		        nop
			nop
			call impulsion_courte		           ;2eme imulsion_courte 
			movlw d'143'
			call delai_cycle_machine
			call impulsion_courte		           ;3eme impulsion_courte 
			movlw d'143'
			call delai_cycle_machine
		        call impulsion_courte		           ;4eme impulsion_courte
			movlw d'143'
			call delai_cycle_machine   
			call impulsion_courte		           ;5eme impulsion_courte
			movlw d'144'
			call delai_cycle_machine
			nop
		        bcf PORTA,sync_horizontale
			movlw d'133'
		        call delai_cycle_machine                   ;1ere impulsion_large
			call impulsion_large_reverse
			movlw d'132'
		        call delai_cycle_machine
			call impulsion_large_reverse	           ;2eme impulsion_large
			movlw d'132'
		        call delai_cycle_machine
			call impulsion_large_reverse	           ;3eme impulsion_large		
			movlw d'132'
		        call delai_cycle_machine
			call impulsion_large_reverse	           ;4eme impulsion_large
			movlw d'132'
		        call delai_cycle_machine
			call impulsion_large_reverse	           ;5eme impulsion_large
			call delai_4_cycles
			call delai_4_cycles
		        nop 
			bsf PORTA,sync_horizontale		   ;6eme impulsion courte
			movlw d'144'
			call delai_cycle_machine                   
			nop
			call impulsion_courte			   ;7eme impulsion courte
			movlw d'143'
			call delai_cycle_machine
		        call impulsion_courte		           ;8eme impulsion_courte
			movlw d'143'
			call delai_cycle_machine   
			call impulsion_courte		           ;9eme impulsion_courte
			movlw d'143'
			call delai_cycle_machine
			call impulsion_courte		           ;10eme impulsion_courte
			return



impulsion_large_reverse bsf PORTA,sync_horizontale
			movlw d'21'			 
		        call delai_cycle_machine
		        bcf PORTA,sync_horizontale
		        return	

impulsion_courte        bcf PORTA,sync_horizontale
		        call delai_4_cycles
		        call delai_4_cycles
			nop
			nop
			nop
			bsf PORTA,sync_horizontale
			return

delai_4_cycles          return

	
delai_cycle_machine   movwf compteur_delai      ;cette routine permet de consommer des cycles machines 
		      movlw d'15'		;selon la valeur contenue dans W , minimum = 19 cycles
		      subwf compteur_delai,1    ;machine max=255 
		      btfsc compteur_delai,0    ;incluant l'appel et le retour
		      goto $+1
		      btfsc compteur_delai,1
		      goto cycle_plus_2		      
decomptage	      rrf compteur_delai,1
		      rrf compteur_delai,1
		      bcf compteur_delai,7
		      bcf compteur_delai,6
		      nop			
		      decfsz compteur_delai,1    
		      goto $-2
		      return
cycle_plus_2          goto decomptage



lire_eeprom     bsf STATUS,RP0
		movwf EEADR
	        bsf EECON1,RD
		movf EEDATA,0
		bcf STATUS,RP0
          	bsf PIR1,EEIF
		return





table_0_a_31        org 4ff
		addwf PCL ,1 
		dt  h'00',h'7C',h'C6',h'DE',h'DE',h'DE',h'C0',h'7C'  ;  @ 
		dt  h'00',h'18',h'3C',h'66',h'66',h'7E',h'66',h'66'  ;  A
		dt  h'00',h'FC',h'66',h'66',h'7C',h'66',h'66',h'FC'  ;  B
		dt  h'00',h'3C',h'66',h'C0',h'C0',h'C0',h'66',h'3C'  ;  C
		dt  h'00',h'F8',h'6C',h'66',h'66',h'66',h'6C',h'F8'  ;  D
		dt  h'00',h'FE',h'62',h'68',h'78',h'68',h'62',h'FE'  ;  E
		dt  h'00',h'FE',h'62',h'68',h'78',h'68',h'60',h'F0'  ;  F
		dt  h'00',h'3C',h'66',h'C0',h'C0',h'CE',h'C6',h'7E'  ;  G
		dt  h'00',h'66',h'66',h'66',h'7E',h'66',h'66',h'66'  ;  H
		dt  h'00',h'7E',h'18',h'18',h'18',h'18',h'18',h'7E'  ;  I
		dt  h'00',h'1E',h'0C',h'0C',h'0C',h'CC',h'CC',h'78'  ;  J
		dt  h'00',h'E6',h'66',h'6C',h'78',h'6C',h'66',h'E6'  ;  K
		dt  h'00',h'F0',h'60',h'60',h'60',h'62',h'66',h'FE'  ;  L
		dt  h'00',h'C6',h'EE',h'FE',h'FE',h'D6',h'C6',h'C6'  ;  M
		dt  h'00',h'C6',h'E6',h'F6',h'DE',h'CE',h'C6',h'C6'  ;  N 
		dt  h'00',h'38',h'6C',h'C6',h'C6',h'C6',h'6C',h'38'  ;  O
		dt  h'00',h'FC',h'66',h'66',h'78',h'60',h'60',h'F0'  ;  P
		dt  h'00',h'38',h'6C',h'C6',h'C6',h'DA',h'CC',h'76'  ;  Q
		dt  h'00',h'FC',h'66',h'66',h'7C',h'6C',h'66',h'E2'  ;  R
		dt  h'00',h'3C',h'66',h'60',h'3C',h'06',h'66',h'3C'  ;  S
		dt  h'00',h'7E',h'5A',h'18',h'18',h'18',h'18',h'3C'  ;  T 
		dt  h'00',h'66',h'66',h'66',h'66',h'66',h'66',h'3C'  ;  U
		dt  h'00',h'66',h'66',h'66',h'66',h'66',h'3C',h'18'  ;  V
		dt  h'00',h'C6',h'C6',h'C6',h'D6',h'FE',h'EE',h'C6'  ;  W 
		dt  h'00',h'C6',h'6C',h'38',h'38',h'6C',h'C6',h'C6'  ;  X
		dt  h'00',h'66',h'66',h'66',h'3C',h'18',h'18',h'3C'  ;  Y
		dt  h'00',h'FE',h'C6',h'8C',h'18',h'32',h'66',h'FE'  ;  Z
		dt  h'00',h'7C',h'C6',h'CE',h'D6',h'E6',h'C6',h'7C'  ;  0
		dt  h'00',h'18',h'38',h'18',h'18',h'18',h'18',h'7E'  ;  1
		dt  h'00',h'3C',h'66',h'06',h'3C',h'60',h'66',h'7E'  ;  2
		dt  h'00',h'3C',h'46',h'06',h'1C',h'06',h'66',h'3C'  ;  3
                dt  h'00',h'18',h'38',h'58',h'98',h'FE',h'18',h'3C'  ;  4

table_32_a_63        org 6ff 
		addwf PCL ,1

	  	dt  h'00',h'7E',h'62',h'60',h'3C',h'06',h'66',h'3C'  ;  5
		dt  h'00',h'3C',h'66',h'60',h'7C',h'66',h'66',h'3C'  ;  6
		dt  h'00',h'7E',h'46',h'06',h'0C',h'18',h'18',h'18'  ;  7
		dt  h'00',h'3C',h'66',h'66',h'3C',h'66',h'66',h'3C'  ;  8
		dt  h'00',h'3C',h'66',h'66',h'3E',h'06',h'66',h'3C'  ;  9
		dt  h'00',h'C0',h'60',h'30',h'18',h'0C',h'06',h'02'  ;  \
		dt  h'00',h'06',h'0C',h'18',h'30',h'60',h'C0',h'80'  ;  /
		dt  h'00',h'0E',h'18',h'18',h'70',h'18',h'18',h'0E'  ;  {
		dt  h'00',h'70',h'18',h'18',h'0E',h'18',h'18',h'70'  ;  }
		dt  h'00',h'18',h'18',h'18',h'18',h'18',h'18',h'18'  ;  |
		dt  h'00',h'00',h'00',h'18',h'18',h'00',h'18',h'18'  ;  :
		dt  h'00',h'00',h'18',h'18',h'00',h'18',h'18',h'30'  ;  ;
		dt  h'00',h'0C',h'18',h'30',h'60',h'30',h'18',h'0C'  ;  <
		dt  h'00',h'00',h'00',h'7E',h'00',h'00',h'7E',h'00'  ;  =
		dt  h'00',h'60',h'30',h'18',h'0C',h'18',h'30',h'60'  ;  >
		dt  h'00',h'3C',h'66',h'06',h'0C',h'18',h'00',h'18'  ;  ?
		dt  h'00',h'18',h'18',h'18',h'18',h'18',h'00',h'18'  ;  !  
		dt  h'00',h'6C',h'6C',h'6C',h'00',h'00',h'00',h'00'  ;  "
		dt  h'00',h'6C',h'6C',h'FE',h'6C',h'FE',h'6C',h'6C'  ;  #
		dt  h'00',h'18',h'3E',h'58',h'3C',h'1A',h'7C',h'18'  ;  $
		dt  h'00',h'00',h'C6',h'CC',h'18',h'30',h'66',h'C6'  ;  %
		dt  h'00',h'38',h'6C',h'38',h'76',h'DC',h'CC',h'76'  ;  &
		dt  h'00',h'18',h'18',h'30',h'00',h'00',h'00',h'00'  ;  '
		dt  h'00',h'0C',h'18',h'30',h'30',h'30',h'18',h'0C'  ;  (
		dt  h'00',h'30',h'18',h'0C',h'0C',h'0C',h'18',h'30'  ;  )
		dt  h'00',h'00',h'66',h'3C',h'FE',h'3C',h'66',h'00'  ;  *
		dt  h'00',h'00',h'18',h'18',h'7E',h'18',h'18',h'00'  ;  +
		dt  h'00',h'00',h'00',h'00',h'00',h'18',h'18',h'30'  ;  ,
		dt  h'00',h'00',h'00',h'00',h'7E',h'00',h'00',h'00'  ;  -
	        dt  h'00',h'00',h'00',h'00',h'00',h'00',h'18',h'18'  ;  .
	        dt  h'00',h'00',h'00',h'00',h'00',h'00',h'00',h'FE'  ;  _
		dt  h'00',h'00',h'00',h'00',h'00',h'00',h'00',h'00'  ; <espace>




	        end 

        
