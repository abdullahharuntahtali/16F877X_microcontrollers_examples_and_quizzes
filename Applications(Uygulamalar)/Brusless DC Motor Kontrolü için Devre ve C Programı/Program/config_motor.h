/**
* @file config_motor.h
*
* Copyright (c) 2005 Atmel.
*
* @brief This module provide services to define config for motor control.
* This file is included by config.h in order to access to system wide
* configuration.
* @version 1.0 (CVS revision : $Revision: 1.11 $)
* @date $Date: 2005/06/30 09:17:18 $
* @author $Author: gallain $

*****************************************************************************/

/*_____ I N C L U D E S ____________________________________________________*/
#include "compiler.h"
#include "mcu.h"
#include "inavr.h"

#ifndef _CONFIG_H_
#define _CONFIG_H_

/**
 * @brief  This enumeration contains the 6 differents values for the Hall Sensors
 * See design document. In this application, just 3 hall sensor are used
 * Hall Sensor : position 1 to 6
 */
enum {HS_001=1,HS_010=2,HS_011=3,HS_100=4,HS_101=5,HS_110=6};


// Define Direction of rotor : CounterClockWise
#define CCW 0

// Define Direction of rotor : ClockWise
#define CW 1

// Define Type of Pulse Width Modulation
//#define HIGH_AND_LOW_PWM

// Define type of speed measure and number of samples
//#define AVERAGE_SPEED_MEASURE
#define n_SAMPLE  8

// Define macro for motor control
#define OPEN_LOOP 0
#define SPEED_LOOP 1
#define CURRENT_LOOP 2
#define POSITION_LOOP 3

// Here you have to define your control coefficients
// Kp for the proportionnal coef
// Ki for the integral coef
// Kd for the derivative coef

// Speed regulation coefficients
#define Kp_speed 8//1 MMT motor//8 MAXON moto
#define Ki_speed 8//10 MMT motor//8 MAXON motor
#define Kd_speed 0

// Current regulation coefficients
#define Kp_cur 1
#define Ki_cur 3
#define Kd_cur 0

// Position regulation coefficients
#define Kp_pos 9 //8
#define Ki_pos 3 //1
#define Kd_pos 20 //5

// All PID coef are multiplied by 2^Kmul
// For exemple : kp = 1 => Kp = 1 * 2^K_scal = 1 * 2^4 = 16
// To get the right result you have to divide the number by 2^K_scal
// So execute a K_scal right shift
#define K_speed_scal 4 // 4 MMT motor//5 MAXON motor
#define K_cur_scal 4
#define K_pos_scal 5

// Speed measurement
// K_SPEED = (60 * 255)/(n * t_timer0 * speed_max(rpm))
// with n : number of pairs of poles.
// and t_timer0 : 8us
#define K_SPEED 61694 // Maxon : 61694 // MMT : 27321

#endif
