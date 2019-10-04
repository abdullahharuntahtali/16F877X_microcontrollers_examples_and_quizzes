/**
* @file mc_lib.h
*
* Copyright (c) 2005 Atmel.
*
* @brief This module provide prototypes declaration for AT90PWM3
* @version 1.0 (CVS revision : $Revision: 1.1 $)
* @date $Date: 2005/06/27 13:45:34 $
* @author $Author: gallain $
*****************************************************************************/

#ifndef _MC_LIB_H_
#define _MC_LIB_H_


void mc_motor_run(void);
Bool mc_motor_is_running(void);
void mc_motor_stop(void);
void mc_motor_init(void);

void mc_set_motor_speed(U8 speed);
U8 mc_get_motor_speed(void);

void mc_set_motor_direction(U8 direction);
U8 mc_get_motor_direction(void);

void mc_set_motor_measured_speed(U8 measured_speed);
U8 mc_get_motor_measured_speed(void);

U16 mc_get_measured_current(void);
void mc_set_measured_current(U16 current);

U8 mc_get_potentiometer_value(void);
void mc_set_potentiometer_value(U8 potentiometer);


#endif
