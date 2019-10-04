/**
* @file mc_lib.c
*
* Copyright (c) 2005 Atmel.
*
* @brief This module provides High level function for the motor control
*
* @version 1.0 (CVS revision : $Revision: 1.8 $)
* @date $Date: 2005/06/27 13:45:34 $
* @author $Author: gallain $
*****************************************************************************/
#include "config.h"

#include "mc_lib.h"
#include "mc_control.h"
#include "mc_drv.h"


Bool mc_direction = CW; //!<User Input parameter to set motor direction
Bool mc_run_stop = FALSE;    //!<User Input parameter to launch or stop the motor
U8 mc_cmd_speed = 0;        //!<User Input parameter to set motor speed

U8 mc_measured_speed = 0;   //!<Motor Input parameter to get the motor speed
U16 mc_measured_current = 0; //!<Motor Input parameter to get the motor current
U8 mc_potentiometer_value = 0;//!<Motor Input to set the motor speed

/**
* @brief mc_motor_run run the motor with parameter
* @param
* @pre initialization  HW and SW
* @post New value in Hall variable
*/
void mc_motor_run(void)
{
  mc_run_stop = TRUE;
  mc_regulation_loop();
  mc_duty_cycle(mc_get_Duty_Cycle());
  mc_switch_commutation(mc_get_hall());
}

/**
* @brief get the motor state
* @param
* @pre initialization  HW and SW
* @post We know if the motor is running or not
*/
Bool mc_motor_is_running(void)
{
  return mc_run_stop;
}

/**
* @brief mc_motor_stop stop the motor
* And reset the speed measured value.
* @pre motor run (mc_motor_run executed)
* @post motor stop
*/
void mc_motor_stop(void)
{
  mc_run_stop=FALSE;
}

/**
* @brief use to init programm
* @param
* @post configuration of hardware and sotware
* @pre none
*/
void mc_motor_init()
{
  mc_init_HW();
  mc_init_SW();

  mc_motor_stop();
  mc_set_motor_direction(CW);
  mc_set_motor_speed(0);
  mc_set_motor_measured_speed(0);
}

/*
* @brief speed modification
* @pre initialization of motor
* @post new value of speed
*/
void mc_set_motor_speed(U8 speed)
{
  mc_cmd_speed = speed;
}

/*
* @brief speed visualization
* @pre initialization of motor
* @post get speed value
*/
U8 mc_get_motor_speed(void)
{
  return mc_cmd_speed;
}

/*
* @brief direction modification
* @pre initialization of motor
* @post new value of direction
*/
void mc_set_motor_direction(U8 direction)
{
  if ((mc_direction == CW) || (mc_direction == CCW)) mc_direction = direction;
}

/*
* @brief direction visualization
* @pre initialization of motor
* @post get direction value
*/
U8 mc_get_motor_direction(void)
{
  return mc_direction;
}

/**
 * @brief set Measured of speed (for initialization)
 * @pre none
 * @post mc_measured_speed initialized
*/
void mc_set_motor_measured_speed(U8 measured_speed)
{
  mc_measured_speed = measured_speed;
}

/**
 * @brief Measured of speed
 * @return return value of speed (8 bits)
 * @pre none
 * @post none
*/
U8 mc_get_motor_measured_speed(void)
{
  return mc_measured_speed;
}

/**
* @brief Get the current measured in the motor
* @pre Launch ADC scheduler
* @post Get ADC Channel 12 result (Current value on 8bits).
*/
U16 mc_get_measured_current(void)
{
  return mc_measured_current;
}

/**
* @brief Set the variable 'mc_measured_current' for initialization.
* @pre none
* @post 'mc_measured_current' set with the current value
*/
void mc_set_measured_current(U16 current)
{
  mc_measured_current = current;
}

/**
* @brief Get the potentiometer value
* @pre Launch ADC scheduler
* @post Get ADC Channel 6 result (Potentiometer value on 8bits).
*/
U8 mc_get_potentiometer_value(void)
{
  return mc_potentiometer_value;
}

/**
* @brief Set the 'mc_potentiometer_value' variable with the potentiometer value
* @pre Launch ADC scheduler
* @post 'mc_potentiometer_value' set with the potentiometer value
*/
void mc_set_potentiometer_value(U8 potentiometer)
{
  mc_potentiometer_value = potentiometer;
}
