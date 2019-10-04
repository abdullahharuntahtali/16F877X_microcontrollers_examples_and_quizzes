/**
* @file mc_control.c
*
* Copyright (c) 2005 Atmel.
*
* @brief This module provide services to control speed for AT90PWM3 Only
* Type of control : PID means proportionnal, integral and derivative.
*
* @version 1.0 (CVS revision : $Revision: 1.11 $)
* @date $Date: 2005/06/27 13:45:33 $
* @author $Author: gallain $
*****************************************************************************/
#include "config.h"
#include "mc_control.h"
#include "mc_drv.h"
#include "mc_lib.h"

#include "mc_lib.h"
#include "serial.h"

U8 duty_cycle = 0;    //!<Parameter to set PWM Duty Cycle after regulation calculation
U8 BO_BF = OPEN_LOOP; //!< Define the type of regulation (OPEN_LOOP or CLOSE_LOOP)

/* Speed regulation variables */
S16 speed_error = 0;      //!<Error calculation
S16 last_speed_error = 0;  //!<Variable for the last error
S16 speed_integral = 0;
S16 speed_integ = 0;
S16 speed_proportional = 0;
S16 speed_derivative = 0;
S16 speed_der = 0;

/* Current regulation variables */
S16 cur_error = 0;      //!<Error calculation
S16 last_cur_error = 0;  //!<Variable for the last error
S16 cur_integral = 0;
S16 cur_integ = 0;
S16 cur_proportional = 0;
S16 cur_derivative = 0;
S16 cur_der = 0;

/* Position regulation variables */
S16 pos_error = 0;      //!<Error calculation
S16 last_pos_error = 0;  //!<Variable for the last error
S16 pos_integral = 0;
S16 pos_integ = 0;
S16 pos_proportional = 0;
S16 pos_derivative = 0;
S16 pos_der = 0;

/************************************************************************************************************/
/*                                  Speed Regulation                                                        */
/************************************************************************************************************/
/**
* @brief use to control speed , speed  regulation loop
* need parameter : Kp_speed, Ki_speed ,Kd_speed and K_speed_scal in config_motor.h
* need to call in Te ms
* @return value of speed, duty cycle on 8 bits
*/
U8 mc_control_speed(U8 speed_cmd)
{
  U8 Duty = 0;
  S32 increment = 0;

  // Error calculation
  speed_error = speed_cmd - mc_get_motor_measured_speed();// value -255 <=> 255

  // proportional term calculation
  speed_proportional = Kp_speed*speed_error;

  // integral term calculation
  speed_integral = speed_integral + speed_error;

  if(speed_integral >  255) speed_integral =  255;
  if(speed_integral < -255) speed_integral = -255;

  speed_integ = Ki_speed*speed_integral;

  // derivative term calculation
  /*speed_derivative = speed_error - last_speed_error;

  if(speed_derivative >  255) speed_derivative =  255;
  if(speed_derivative < -255) speed_derivative = -255;

  speed_der = Kd_speed*speed_derivative;

  last_speed_error = speed_error;*/

  // Duty Cycle calculation
  increment = speed_proportional + speed_integ;
  //increment += speed_der;
  increment = increment >> K_speed_scal;

  // Variable saturation
  if(increment >= (S16)(255)) Duty = 255;
  else
  {
    if(increment <= (S16)(0)) Duty =   0;
    else Duty = (U8)(increment);
  }

  // return Duty Cycle
  return Duty;
}

/************************************************************************************************************/
/*                                  Current Regulation                                                      */
/************************************************************************************************************/
/**
* @brief use to control current , current  regulation loop
* need parameter : Kp_cur, Ki_cur ,Kd_cur and K_cur_scal in config_motor.h
* need to call in Te ms
* @return value of current, duty cycle on 8 bits
*/
U8 mc_control_current(U8 cur_cmd)
{
  U8 Duty = 0;
  S32 increment = 0;

  // Error calculation
  cur_error = cur_cmd - (mc_get_measured_current());// value -255 <=> 255

  // proportional term calculation
  cur_proportional = Kp_cur*cur_error;

  // integral term calculation
  cur_integral = cur_integral + cur_error;

  if(cur_integral >  255) cur_integral =  255;
  if(cur_integral < -255) cur_integral = -255;

  cur_integ = Ki_cur*cur_integral;

  // derivative term calculation
  /*cur_derivative = cur_error - last_cur_error;

  if(cur_derivative >  255) cur_derivative =  255;
  if(cur_derivative < -255) cur_derivative = -255;

  cur_der = Kd_cur*cur_derivative;

  last_cur_error = cur_error;*/

  // Duty Cycle calculation
  increment = cur_proportional + cur_integ;
  //increment += cur_der;
  increment = increment >> K_cur_scal;

  // Variable saturation
  if(increment >= (S16)(255)) Duty = 255;
  else
  {
    if(increment <= (S16)(0)) Duty =   0;
    else Duty = (U8)(increment);
  }

  // return Duty Cycle
  return Duty;
}

/************************************************************************************************************/
/*                                  Position Regulation                                                     */
/************************************************************************************************************/
/**
* @brief use to control position , position  regulation loop
* need parameter : Kp, Ki ,Kd and K_scal in config_motor.h
* need to call in Te ms
* @return value of speed, duty cycle on 8 bits
*/
U8 mc_control_position(S32 Number_of_turns)
{
  U8 Duty = 0;
  S32 increment = 0;

  // Error calculation
  pos_error =  Number_of_turns - mc_get_Num_Turn();

  // proportional term calculation
  pos_proportional = Kp_pos*pos_error;

  // integral term calculation
  pos_integral = pos_integral + pos_error;

  if(pos_integral >  255) pos_integral =  255;
  if(pos_integral < -255) pos_integral = -255;

  pos_integ = Ki_pos*pos_integral;

  // derivative term calculation
  pos_derivative = pos_error - last_pos_error;

  if(pos_derivative >  255) pos_derivative =  255;
  if(pos_derivative < -255) pos_derivative = -255;

  pos_der = Kd_pos*pos_derivative;

  last_pos_error = pos_error;

  // Duty Cycle calculation
  increment = pos_proportional + pos_integ;
  increment += pos_der;
  increment = increment >> K_pos_scal;

  // Variable saturation
  if(increment >= (S16)(0))
  {
    if(increment >= (S16)(100))Duty = 100;
    else Duty = (U8)(increment);
    mc_set_motor_direction(CW);
  }
  else
  {
    if(increment <= (S16)(-100)) Duty = 100;
    else Duty = (U8)(-increment);
    mc_set_motor_direction(CCW);
  }
  // return Duty Cycle
  return Duty;
}


/************************************************************************************************************/
/*                                Selection of Regulation Loop                                              */
/************************************************************************************************************/
/**
* @brief launch speed control or no regulation
* @pre none
* @post new duty cycle on PWM
*/
void mc_regulation_loop()
{
  // measure
  Set_EXT3();

  switch(BO_BF)
  {
    case OPEN_LOOP     : duty_cycle = mc_get_motor_speed();break;
    case SPEED_LOOP    : duty_cycle = mc_control_speed(mc_get_motor_speed());break;
    case CURRENT_LOOP  : duty_cycle = mc_control_current(mc_get_potentiometer_value());break;
    case POSITION_LOOP : duty_cycle = /*mc_control_speed(*/mc_control_position(mc_get_potentiometer_value())/*)*/;break;
    default : break;
  }

  // measure
  Clear_EXT3();
}

/**
* @brief set type of regulation
* @pre none
* @post Open loop regulation Set
*/
void mc_set_Open_Loop(){BO_BF = OPEN_LOOP;}

/**
* @brief set type of regulation
* @pre none
* @post Speed loop regulation Set
*/
void mc_set_Speed_Loop(){BO_BF = SPEED_LOOP;}

/**
* @brief set type of regulation
* @pre none
* @post Position loop regulation Set
*/
void mc_set_Current_Loop(){BO_BF = CURRENT_LOOP;}

/**
* @brief set type of regulation
* @pre none
* @post Position loop regulation Set
*/
void mc_set_Position_Loop(){BO_BF = POSITION_LOOP;}

/**
* @brief set type of regulation
* @pre none
* @post Close loop regulation Set
*/
U8 mc_get_Duty_Cycle()
{
  return duty_cycle;
}

