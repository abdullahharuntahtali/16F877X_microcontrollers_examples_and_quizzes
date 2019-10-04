/**
* @file mc_drv.h
*
* Copyright (c) 2005 Atmel.
*
* @brief This module provide services to define config for AT90PWM3 Only
* Describes the system dependant software configuration.
* This file is included by all source files in order to access to system wide
* configuration.
* @version 1.0 (CVS revision : $Revision: 1.4 $)
* @date $Date: 2005/06/16 07:50:58 $
* @author $Author: gallain $
*****************************************************************************/
#ifndef _MC_DRV_H_
#define _MC_DRV_H_

  // output configuration
  #define output_disconnected 0x01

 // #define Set_none() (TCCR1A=output_disconnected,TCCR3B=output_disconnected)
  #define Set_timer_data_register_to_zero() (TCNT0=0x00)

  // MACRO for PSC initialization
  #define PSC_ONE_RAMP (0<<PMODE01)|(0<<PMODE00)
  #define PSC_TWO_RAMP (0<<PMODE01)|(1<<PMODE00)
  #define PSC_FOUR_RAMP (1<<PMODE01)|(0<<PMODE00)
  #define PSC_CENTERED (1<<PMODE01)|(1<<PMODE00)

  #define RAMP_MODE_NUMBER PSC_CENTERED

  #define SET_PLOCK (1<<PLOCK0)
  #define RELEASE_PLOCK (0<<PLOCK0)

  #define PRESC_NODIV     (0<<PPRE01)|(0<<PPRE00)
  #define PRESC_DIV_BY_4  (0<<PPRE01)|(1<<PPRE00)
  #define PRESC_DIV_BY_16 (1<<PPRE01)|(0<<PPRE00)
  #define PRESC_DIV_BY_64 (1<<PPRE01)|(1<<PPRE00)

  #define OUTPUT_ACTIVE_HIGH (1<<POP0)
  #define OUTPUT_ACTIVE_LOW  (0<<POP0)

  // Comparator interruption
  #define HALL_A() (ANACOMP_0_vect)
  #define HALL_B() (ANACOMP_1_vect)
  #define HALL_C() (ANACOMP_2_vect)


  #define HALL_SENSOR_VALUE()        \
    ( (PIND & (1<<PIND7)) >> PIND7 ) \
  | ( (PINC & (1<<PINC6)) >> 5 )     \
  | ( (PIND & (1<<PIND5)) >> 3 )

  #define Clear_Port_Q1() (PORTB &= ( ~(1<<PORTB0)))
  #define Clear_Port_Q3() (PORTC &= ( ~(1<<PORTC0)))
  #define Clear_Port_Q5() (PORTD &= ( ~(1<<PORTD0)))
  #define Clear_Port_Q2() (PORTB &= ( ~(1<<PORTB1)))
  #define Clear_Port_Q4() (PORTB &= ( ~(1<<PORTB6)))
  #define Clear_Port_Q6() (PORTB &= ( ~(1<<PORTB7)))
  #define Set_Port_Q2()   (PORTB |=   (1<<PORTB1))
  #define Set_Port_Q4()   (PORTB |=   (1<<PORTB6))
  #define Set_Port_Q6()   (PORTB |=   (1<<PORTB7))

  // Six step commutation
  #define Set_none()                \
    PSOC0 = (0<<POEN0A)|(0<<POEN0B);\
    PSOC1 = (0<<POEN1A)|(0<<POEN1B);\
    PSOC2 = (0<<POEN2A)|(0<<POEN2B);\
    Clear_Port_Q2();                \
    Clear_Port_Q4();                \
    Clear_Port_Q6();                \
    Clear_Port_Q1();                \
    Clear_Port_Q3();                \
    Clear_Port_Q5();

  #define Set_Q1Q4()                \
    PSOC0 = (0<<POEN0A)|(0<<POEN0B);\
    PSOC1 = (0<<POEN1A)|(1<<POEN1B);\
    PSOC2 = (1<<POEN2A)|(0<<POEN2B);

  #define Set_Q1Q6()                \
    PSOC0 = (0<<POEN0A)|(1<<POEN0B);\
    PSOC1 = (0<<POEN1A)|(0<<POEN1B);\
    PSOC2 = (1<<POEN2A)|(0<<POEN2B);

  #define Set_Q3Q2()                \
    PSOC0 = (0<<POEN0A)|(0<<POEN0B);\
    PSOC1 = (1<<POEN1A)|(0<<POEN1B);\
    PSOC2 = (0<<POEN2A)|(1<<POEN2B);

  #define Set_Q3Q6()                \
    PSOC0 = (0<<POEN0A)|(1<<POEN0B);\
    PSOC1 = (1<<POEN1A)|(0<<POEN1B);\
    PSOC2 = (0<<POEN2A)|(0<<POEN2B);

  #define Set_Q5Q2()                \
    PSOC0 = (1<<POEN0A)|(0<<POEN0B);\
    PSOC1 = (0<<POEN1A)|(0<<POEN1B);\
    PSOC2 = (0<<POEN2A)|(1<<POEN2B);

  #define Set_Q5Q4()                \
    PSOC0 = (1<<POEN0A)|(0<<POEN0B);\
    PSOC1 = (0<<POEN1A)|(1<<POEN1B);\
    PSOC2 = (0<<POEN2A)|(0<<POEN2B);

  // Macro for LED use
  #define switch_ON_LED()   (PORTE &= ~(1<<PE2))
  #define switch_OFF_LED()  (PORTE |=  (1<<PE2))

  //EXT PORT AS OUTPUT
  #define Set_EXT1()     (PORTB |=  (1<<PB3)) // EXT1
  #define Clear_EXT1()   (PORTB &= ~(1<<PB3))
  #define Set_EXT2()     (PORTB |=  (1<<PB4)) // EXT2
  #define Clear_EXT2()   (PORTB &= ~(1<<PB4))
  #define Set_EXT3()     (PORTC |=  (1<<PC1)) // EXT3
  #define Clear_EXT3()   (PORTC &= ~(1<<PC1))
  #define Set_EXT4()     (PORTC |=  (1<<PC2)) // EXT4
  #define Clear_EXT4()   (PORTC &= ~(1<<PC2))
  #define Set_EXT5()     (PORTB |=  (1<<PB5)) // EXT5
  #define Clear_EXT5()   (PORTB &= ~(1<<PB5))
  #define Set_EXT6()     (PORTE |=  (1<<PE1)) // EXT6
  #define Clear_EXT6()   (PORTE &= ~(1<<PE1))
  #define Set_EXT7()     (PORTD |=  (1<<PD3)) // EXT7
  #define Clear_EXT7()   (PORTD &= ~(1<<PD3))
  #define Set_EXT8()     (PORTD |=  (1<<PD4)) // EXT8
  #define Clear_EXT8()   (PORTD &= ~(1<<PD4))
  #define Set_EXT9()     (PORTE |=  (1<<PE0)) // EXT9
  #define Clear_EXT9()   (PORTE &= ~(1<<PE0))
  #define Set_EXT10()     (PORTD |=  (1<<PD2)) // EXT10
  #define Clear_EXT10()   (PORTD &= ~(1<<PD2))
  //EXT PORT AS INPUT
  #define Get_EXT1()     ((PINB & (1<<PB3))>>PB3) // EXT1
  #define Get_EXT2()     ((PINB & (1<<PB4))>>PB4) // EXT2
  #define Get_EXT3()     ((PINC & (1<<PC1))>>PC1) // EXT3
  #define Get_EXT4()     ((PINC & (1<<PC2))>>PC2) // EXT4
  #define Get_EXT5()     ((PINB & (1<<PB5))>>PB5) // EXT5
  #define Get_EXT6()     ((PINE & (1<<PE1))>>PE1) // EXT6
  #define Get_EXT7()     ((PIND & (1<<PD3))>>PD3) // EXT7
  #define Get_EXT8()     ((PIND & (1<<PD4))>>PD4) // EXT8
  #define Get_EXT9()     ((PINE & (1<<PE0))>>PE0) // EXT9
  #define Get_EXT10()     ((PIND & (1<<PD2))>>PD2) // EXT10

  // MACRO for ADC scheduler
  #define CONV_INIT     0
  #define CONV_POT      1
  #define CONV_CURRENT  2

  #define FREE  0
  #define BUSY  1
  /**************************/
  /* prototypes declaration */
  /**************************/

  // Hardware initialization
  void mc_init_HW(void);
  void mc_init_SW(void);
  void mc_init_port(void);
  void mc_init_pwm(void);
  void mc_init_IT(void);
  void PSC0_Init (unsigned int OCRnRB,
                  unsigned int OCRnSB,
                  unsigned int OCRnRA,
		  unsigned int OCRnSA);

  void PSC1_Init (unsigned int OCRnRB,
                  unsigned int OCRnSB,
                  unsigned int OCRnRA,
		  unsigned int OCRnSA);

  void PSC2_Init (unsigned int OCRnRB,
                  unsigned int OCRnSB,
                  unsigned int OCRnRA,
		  unsigned int OCRnSA);

  // Phases commutation functions
  U8 mc_get_hall(void);
  void mc_duty_cycle(U8 level);
  void mc_switch_commutation(U8 position);

  // Sampling time configuration
  void mc_config_sampling_period(void);

  // Estimation speed
  void mc_config_time_estimation_speed(void);
  void mc_estimation_speed(void);

  // ADC use for current measure and potentiometer...
  void mc_ADC_Scheduler(void);
  U8 mc_Get_Current(void);
  U8 mc_Get_Potentiometer(void);

  // Over Current Detection
  void mc_set_Over_Current(U8 Level);

  // Number of turns calculation
  S32 mc_get_Num_Turn(void);
  void mc_reset_Num_Turn(void);

#endif
