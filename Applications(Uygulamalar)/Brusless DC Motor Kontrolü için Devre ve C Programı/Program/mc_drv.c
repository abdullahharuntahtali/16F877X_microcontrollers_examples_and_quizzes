/**
* @file mc_drv.c
*
* Copyright (c) 2005 Atmel.
*
* @brief This module provide services to define config for AT90PWM3
* this is the core of bldc program. this module contains initialization and configuration
* It depend on hardware of components
* @version 1.0 (CVS revision : $Revision: 1.13 $)
* @date $Date: 2005/06/30 12:04:23 $
* @author $Author: gallain $
*****************************************************************************/
#include "config.h"

#include "mc_drv.h"
#include "mc_lib.h"
#include "mc_control.h"
#include "serial.h"

#include "adc\adc_drv.h"
#include "dac\dac_drv.h"
#include "amplifier\amplifier_drv.h"
#include "pll\pll_drv.h"
#include "comparator\comparator_drv.h"

#include "stdio.h"


U8 count = 1;     // variable "count" is use for calculate the "average" speed on 'n' samples
U16 average = 0;
U8 ovf_timer = 0; // variable "ovf_timer" is use to simulate a 16 bits timer with 8 bits timer

Bool g_mc_read_enable = FALSE;  // the speed can be read
Bool g_tic = FALSE;             //!< Use for control the sampling period value

Bool current_EOC = FALSE; //End Of Concersion Flag

S32 Num_turn = 0; //Used to count the number of motor revolutions
S32 Num_turn2 = 0;
U8 hall_state = 0;

char State = CONV_INIT; // State of the ADC scheduler
char ADC_State = FREE;  // ADC State : running = BUSY not running = FREE

/******************************************************************************************************************************/
/******************************************************************************************************************************/
/*                                            Hardware Initialization                                                         */
/******************************************************************************************************************************/
/******************************************************************************************************************************/

/**
* @brief init HW
* @pre set all functions mc_init_port(), mc_init_pwm()...
* @post initialization of hardware
*/
void mc_init_HW(void)
{
  mc_init_port();
  mc_init_IT();

  // Be careful : initialize DAC and Over_Current before PWM.
  init_dac();
  mc_set_Over_Current(100); // 5 => 1A ; 8 => 40A
  mc_init_pwm();

  mc_config_time_estimation_speed();
  mc_config_sampling_period();

  init_comparator0();
  init_comparator1();
  init_comparator2();
}

/**
* @brief init SW
* @pre none
* @post initialization of software
*/
void mc_init_SW(void)
{
  Enable_interrupt();
}

/**
* @brief Initialization of IO PORTS for AT90PWM3
* @pre none
* @post initialization of I/O Ports
*/
void mc_init_port(void)
{
  // Output Pin configuration
  // PD0 => H_A     PB7 => L_A
  // PC0 => H_B     PB6 => L_B
  // PB0 => H_C     PB1 => L_C

  //Do not modify PSCOUT Configuration
  // PORT B :
  DDRB = (1<<DDB7)|(1<<DDB6)|(1<<DDB1)|(1<<DDB0);
  // PORT C :
  DDRC = (1<<DDC0);
  // PORT D :
  DDRD = (1<<DDD0);


  // DDnx = 0:Input 1:Output    (n = B,C,D,E ; x = 0,1,2,3,4,5,6,7)
  // PB3 => EXT1                        PB4 => EXT2
  // PC1 => EXT3                        PC2 => EXT4
  // PB5 => EXT5/POT                    PE1 => EXT6
  // PD3 => EXT7/MOSI/LIN_TxD/TxD       PD4 => EXT8/MISO/LIN_RxD/RxD
  // PE0 => EXT9/NRES                   PD2 => EXT10/MISO

  // Modify DDnx according to your hardware implementation
  // PORT B :
  DDRB |= (0<<DDB5)|(1<<DDB4)|(0<<DDB3);
  // PORT C :
  DDRC |= (0<<DDC2)|(0<<DDC1);
    // PORT D :
  DDRD |= (0<<DDD4)|(0<<DDD3)|(0<<DDD2); // Becareful if using the UART interface or JTAGE ICE mkII.
  // PORT E :
  DDRE |= (1<<DDE2)|(0<<DDE1)|(0<<DDE0); // Becareful PE0 is you by JTAGE ICE mkII.


  // Warning Output Low for MOSFET Drivers
  PORTB &= ~(1<<PORTB7 | 1<<PORTB6 | 1<<PORTB1 | 1<<PORTB0);
  PORTC &= ~(1<<PORTC0);
  PORTD &= ~(1<<PORTD0);

  // pull up activation
  PORTC |= (1<<PORTC1);
  PORTD |= (1<<PORTD1);

  // Disable Digital Input for amplifier1
  // Digitals Inputs for comparators are not disable.
  DIDR0 = (0<<ADC6D)|(0<<ADC3D)|(0<<ADC2D);
  DIDR1 = (0<<ACMP0D)|(0<<ACMP1D)|(1<<AMP1PD)|(1<<AMP1ND);
}

/**
* @brief Initialization of PWM generators (PSC) for AT90PWM3
* @pre none
* @post initialization of PSC
*/
void mc_init_pwm()
{
  Start_pll_32_mega();
  Wait_pll_ready();

  // In Center Aligned Mode :
  // => PSCx_Init(Period_Half, Dutyx0_Half, Synchro, Dutyx1_Half)
  PSC0_Init(255,0,1,0);
  PSC1_Init(255,0,1,0);
  PSC2_Init(255,0,1,0);
}

/**
* @brief Initialization of AT90PWM3 External Interrupts
* @pre none
* @post External Interrupts (INT0, INT1, INT2, INT3) initialized
*/
void mc_init_IT(void)
{
  EICRA =(0<<ISC21)|(1<<ISC20)|(0<<ISC11)|(1<<ISC10)|(0<<ISC01)|(1<<ISC00);
  EIFR = (1<<INTF2)|(1<<INTF1)|(1<<INTF0); // clear possible IT due to config
  EIMSK=(1<<INT2)|(1<<INT1)|(1<<INT0);
}

// PSC initialization depend on the PSC mode
//  0- One ramp Mode
//  1- Two ramp Mode
//  2- Four ramp Mode
//  3- Center Aligned Mode

/**
* @brief Initialization of PWM generator PSC0
*/
void PSC0_Init ( unsigned int OCRnRB,
                 unsigned int OCRnSB,
                 unsigned int OCRnRA,
		 unsigned int OCRnSA)
{
  OCR0SAH = HIGH(OCRnSA);
  OCR0SAL = LOW(OCRnSA);
  OCR0RAH = HIGH(OCRnRA);
  OCR0RAL = LOW(OCRnRA);
  OCR0SBH = HIGH(OCRnSB);
  OCR0SBL = LOW(OCRnSB);
  OCR0RBH = HIGH(OCRnRB);
  OCR0RBL = LOW(OCRnRB);

  PCNF0 =  RAMP_MODE_NUMBER | (1<<PCLKSEL0) | OUTPUT_ACTIVE_HIGH ;
  PFRC0A = (1<<PELEV0A)|(1<<PFLTE0A)|(0<<PRFM0A3)|(1<<PRFM0A2)|(1<<PRFM0A1)|(1<<PRFM0A0);
  PFRC0B = 0;
  PSOC0 = (1<<PSYNC00); //Send signal on match with OCRnSA (during counting up of PSC)
  PCTL0 = (0<<PAOC0A)|(1<<PARUN0)|PRESC_NODIV; /* AUTORUN !! */
}

/**
* @brief Initialization of PWM generator PSC1
*/
void PSC1_Init ( unsigned int OCRnRB,
                 unsigned int OCRnSB,
                 unsigned int OCRnRA,
		 unsigned int OCRnSA)
{
  OCR1SAH = HIGH(OCRnSA);
  OCR1SAL = LOW(OCRnSA);
  OCR1RAH = HIGH(OCRnRA);
  OCR1RAL = LOW(OCRnRA);
  OCR1SBH = HIGH(OCRnSB);
  OCR1SBL = LOW(OCRnSB);
  OCR1RBH = HIGH(OCRnRB);
  OCR1RBL = LOW(OCRnRB);

  PCNF1 =  RAMP_MODE_NUMBER | (1<<PCLKSEL1) | OUTPUT_ACTIVE_HIGH ;
  PFRC1A = 0;
  PFRC1B = 0;
  PCTL1 = (0<<PAOC1A)|(1<<PARUN1)|PRESC_NODIV; /* AUTORUN !! */
}


/**
* @brief Initialization of PWM generator PSC2
*/
void PSC2_Init ( unsigned int OCRnRB,
                 unsigned int OCRnSB,
                 unsigned int OCRnRA,
		 unsigned int OCRnSA)
{
  OCR2SAH = HIGH(OCRnSA);
  OCR2SAL = LOW(OCRnSA);
  OCR2RAH = HIGH(OCRnRA);
  OCR2RAL = LOW(OCRnRA);
  OCR2SBH = HIGH(OCRnSB);
  OCR2SBL = LOW(OCRnSB);
  OCR2RBH = HIGH(OCRnRB);
  OCR2RBL = LOW(OCRnRB);

  PCNF2 =  RAMP_MODE_NUMBER | (1<<PCLKSEL2) | OUTPUT_ACTIVE_HIGH ;
  PFRC2A = 0;
  PFRC2B = 0;
  PCTL2 = (0<<PAOC2A)|(1<<PRUN2)|PRESC_NODIV; /* RUN !! */
}


/******************************************************************************************************************************/
/******************************************************************************************************************************/
/*                                    All functions for motor's phases commutation                                            */
/******************************************************************************************************************************/
/******************************************************************************************************************************/

/**
* @brief Get the value of hall sensors (1 to 6)
* @param return an unsigned char
*  value of hall sensor
* @pre configuration of port PB and PD
* @post new value of position
*/
U8 mc_get_hall(void)
{
  return HALL_SENSOR_VALUE();
}

/**
 * @brief External interruption
 *                 Sensor (A) mode toggle
 * @pre configuration of external interruption (initialization)
 * @post New value in Hall variable
 */
#pragma vector = HALL_A()
__interrupt void mc_hall_a(void)
{
  mc_switch_commutation(HALL_SENSOR_VALUE());
  //estimation speed on raising edge of Hall_A
  if (PIND&(1<<PORTD7))
  {
    mc_estimation_speed();
    g_mc_read_enable=FALSE; // Wait 1 period
  }
  else
  {
    g_mc_read_enable=TRUE;
  }


  switch(hall_state)
  {
  case 2 : Num_turn++;break;
  case 3 : Num_turn--;break;
  default: break;
  }
  hall_state = 1;
}

/**
 * @brief External interruption
 *                 Hall Sensor (B) mode toggle
 * @pre configuration of external interruption (initialization)
 * @post New value in Hall variable
 */
#pragma vector = HALL_B()
__interrupt void mc_hall_b(void)
{
  mc_switch_commutation(HALL_SENSOR_VALUE());

  switch(hall_state)
  {
  case 1 : Num_turn--;break;
  case 3 : Num_turn++;break;
  default: break;
  }
  hall_state = 2;
}

 /**
 * @brief External interruption
 *                 Hall Sensor (C) mode toggle
 * @pre configuration of external interruption (initialization)
 * @post New value in Hall variable
 */
#pragma vector = HALL_C()
__interrupt void mc_hall_c(void)
{
  mc_switch_commutation(HALL_SENSOR_VALUE());

  switch(hall_state)
  {
  case 2 : Num_turn--;break;
  case 1 : Num_turn++;break;
  default: break;
  }
  hall_state = 3;
}

/**
* @brief Set the duty cycle values in the PSC according to the value calculate by the regulation loop
*/
void mc_duty_cycle(U8 level)
{
  U8 duty;
  duty = level;

  PCNF0 = SET_PLOCK | RAMP_MODE_NUMBER |(1<<PCLKSEL0)|(1<<POP0); /* set plock */
  PCNF1 = SET_PLOCK | RAMP_MODE_NUMBER |(1<<PCLKSEL1)|(1<<POP1); /* set plock */
  PCNF2 = SET_PLOCK | RAMP_MODE_NUMBER |(1<<PCLKSEL2)|(1<<POP2); /* set plock */

  // Duty = 0   => Duty Cycle   0%
  // Duty = 255 => Duty Cycle 100%

  // Set the duty cycle for PSCn0
  OCR0SAH = 0;
  OCR0SAL = duty;

  OCR1SAH = 0;
  OCR1SAL = duty;

  OCR2SAH = 0;
  OCR2SAL = duty;

  // Set the duty cycle for PSCn1 according to the PWM strategy
  #ifdef HIGH_AND_LOW_PWM
  // apply PWM on high side and low side switches
    OCR0SBH = 0;
    OCR0SBL = duty;

    OCR1SBH = 0;
    OCR1SBL = duty;

    OCR2SBH = 0;
    OCR2SBL = duty;
  #else
  // PWM is only applied on high side switches
  // 100% duty cycle on low side switches
    OCR0SBH = 0;
    OCR0SBL = 255;

    OCR1SBH = 0;
    OCR1SBL = 255;

    OCR2SBH = 0;
    OCR2SBL = 255;
  #endif

  Disable_interrupt();
  PCNF0 = RELEASE_PLOCK | RAMP_MODE_NUMBER |(1<<PCLKSEL0)|(1<<POP0); /* release plock */
  PCNF1 = RELEASE_PLOCK | RAMP_MODE_NUMBER |(1<<PCLKSEL1)|(1<<POP1); /* release plock */
  PCNF2 = RELEASE_PLOCK | RAMP_MODE_NUMBER |(1<<PCLKSEL2)|(1<<POP2); /* release plock */
  Enable_interrupt();
}

/**
* @brief Set the Switching Commutation value on outputs
*   according to sensor or estimation position
*
* @param position (1 to 6) and direction (FORWARD or BACKWARD)
*/
void mc_switch_commutation(U8 position)
{
  // get the motor direction to commute the right switches.
  char direction = mc_get_motor_direction();

  // Switches are commuted only if the user start the motor and
  // the speed consign is different from 0.
  if ((mc_motor_is_running()) && (mc_get_motor_speed()!=0))
  {
    mc_duty_cycle(mc_get_Duty_Cycle());
    switch(position)
    {
    // cases according to rotor position
      case HS_001:  if (direction==CCW)  {Set_Q1Q6();}
                    else                      {Set_Q5Q2();}
                    break;

      case HS_101:  if (direction==CCW)  {Set_Q3Q6();}
                    else                      {Set_Q5Q4();}
                    break;

      case HS_100:  if (direction==CCW)  {Set_Q3Q2();}
                    else                      {Set_Q1Q4();}
                    break;

      case HS_110:  if (direction==CCW)  {Set_Q5Q2();}
                    else                      {Set_Q1Q6();}
                    break;

      case HS_010:  if (direction==CCW)  {Set_Q5Q4();}
                    else                      {Set_Q3Q6();}
                    break;

      case HS_011:  if (direction==CCW)  {Set_Q1Q4();}
                    else                      {Set_Q3Q2();}
                    break;
      default : break;
      }
  }
  else
  {
    Set_none(); // all switches are switched OFF
  }
}

/******************************************************************************************************************************/
/******************************************************************************************************************************/
/*                                          Sampling time configuration                                                       */
/******************************************************************************************************************************/
/******************************************************************************************************************************/

/**
 * @brief timer 1 Configuration
 * Use to generate a 250us activation  for sampling speed regulation
 * @pre None
 * @post An interrupt all 250us
*/
void mc_config_sampling_period(void)
{
  TCCR1A = 0; //Normal port operation + Mode CTC
  TCCR1B = 1<<WGM12 | 1<<CS11 | 1<<CS10 ; // Mode CTC + prescaler 64
  TCCR1C = 0;
  OCR1AH = 0;
  OCR1AL = 31;
  TIMSK1=(1<<OCIE1A); // Output compare B Match interrupt Enable
}

/**
  * @brief Launch the regulation loop (see main.c) .
  * @pre configuration of timer 1 registers
  * @post g_tic use in main.c for regulation loop
*/
#pragma vector = TIMER1_COMPA_vect
__interrupt void launch_sampling_period(void)
{
  g_tic = TRUE;
}

/******************************************************************************************************************************/
/******************************************************************************************************************************/
/*                                               Estimation speed                                                             */
/******************************************************************************************************************************/
/******************************************************************************************************************************/

/**
 * @brief Timer 0 Configuration
 * The timer 0 is used to generate an IT when an overflow occurs
 * @pre None
 * @post Timer0 initialized.
*/
void mc_config_time_estimation_speed(void)
{
  TCCR0A = 0;
  TCCR0B = (0<<CS02)|(1<<CS01)|(1<<CS00); // 64 prescaler (8us)
  TIMSK0 = (1<<TOIE0);
}

/**
  * @brief Timer0 Overflow for speed measurement
  * @pre configuration of timer 0
  * @post generate an overflow when the motor turns too slowly
*/
#pragma vector = TIMER0_OVF_vect
__interrupt void ovfl_timer(void)
{
  TCNT0=0x00;
  ovf_timer++;
  // if they are no commutation after 125 ms
  // 125 ms = (61<<8) * 8us
  if(ovf_timer >= 100)
  {
    ovf_timer = 0;
    mc_set_motor_measured_speed(0);
    //if the motor was turning and no stop order
    // was given, motor run automatically.
    if(mc_motor_is_running())mc_motor_run();
  }
}

/**
* @brief estimation speed
* @pre configuration of timer 0 and define or not AVERAGE_SPEED_MEASURE in config_motor.h
* @post new value for real speed
*/
void mc_estimation_speed(void)
{
  U16 timer_value;
  U32 new_measured_speed;

  if (g_mc_read_enable==OK)
  {
    // Two 8 bits variables are use to simulate a 16 bits timers
    timer_value = (ovf_timer<<8) + TCNT0;

    if (timer_value == 0) {timer_value += 1 ;} // warning DIV by 0
    new_measured_speed = K_SPEED / timer_value;
    if(new_measured_speed > 255) new_measured_speed = 255; // Variable saturation


    #ifdef AVERAGE_SPEED_MEASURE
      // To avoid noise an average is realized on 8 samples
      average += new_measured_speed;
      if(count >= n_SAMPLE)
      {
        count = 1;
        mc_set_motor_measured_speed(average >> 3);
        average = 0;
      }
      else count++;
    #else
      // else get the real speed
      mc_set_motor_measured_speed(new_measured_speed);
    #endif

    // Reset Timer 0 register and variables
    TCNT0=0x00;
    ovf_timer = 0;
    g_mc_read_enable=KO;
  }
}

/******************************************************************************************************************************/
/******************************************************************************************************************************/
/*                                         ADC use for current measure and potentiometer...                                   */
/******************************************************************************************************************************/
/******************************************************************************************************************************/

/**
* @brief Launch the sampling procedure to get current value
* @pre amplifier and IT initialization
* @post Set the End Of Conversion flag
*/
#pragma vector = ADC_vect
__interrupt void ADC_EOC(void)
{
  if(State == CONV_CURRENT) mc_set_potentiometer_value(Adc_get_8_bits_result());
  if(State == CONV_POT) mc_set_measured_current(Adc_get_10_bits_result());
  ADC_State = FREE;
}

/**
* @brief Launch the scheduler for the ADC
* @pre none
* @post Get Channel 6 and 12 results for Potentiometer and current values.
*/
void mc_ADC_Scheduler(void)
{
  switch(State)
  {
  case CONV_INIT :
    init_adc();
    init_amp1();
    ADC_State = FREE;
    State = CONV_POT;
    break;

  case CONV_POT :
    if(ADC_State == FREE)
    {
      ADC_State = BUSY;
      State= CONV_CURRENT;
      Left_adjust_adc_result();
      Start_conv_channel(6);
    }
    break;

  case CONV_CURRENT :
    if(ADC_State == FREE)
    {
      ADC_State = BUSY;
      State = CONV_POT;
      Right_adjust_adc_result();
      Start_amplified_conv_channel(12);
    }
    break;
  }

}
/******************************************************************************************************************************/
/******************************************************************************************************************************/
/*                                            Over Current Detection                                                          */
/******************************************************************************************************************************/
/******************************************************************************************************************************/


/**
* @brief Set the Over Current threshold
* @pre DAC initialization
* @post the Over Current threshold is set.
*/
void mc_set_Over_Current(U8 Level)
{
  Set_dac_8_bits(Level);
}


/******************************************************************************************************************************/
/******************************************************************************************************************************/
/*                                         Number of turns calculation                                                        */
/******************************************************************************************************************************/
/******************************************************************************************************************************/

/**
* @brief Get the number of rotor rotation
* @pre none
* @post Get the 32bits signed number of turns
*/
S32 mc_get_Num_Turn()
{
  return Num_turn;
}

/**
* @brief Reset the number of rotor rotation
* @pre none
* @post Number of turns = 0
*/
void mc_reset_Num_Turn()
{
  Num_turn = 0;
}
