/**
* @file mc_control.h
*
* Copyright (c) 2005 Atmel.
*
* @brief This module provide services to define config for AT90PWM3 Only
* This file need to be include in all files using speed regulation.
* @version 1.0 (CVS revision : $Revision: 1.1 $)
* @date $Date: 2005/06/27 13:45:34 $
* @author $Author: gallain $
*****************************************************************************/
#ifndef _MC_CONTROL_H_
#define _MC_CONTROL_H_

U8 mc_control_speed(U8 speed_cmd);
U8 mc_control_current(U8 cur_cmd);
U8 mc_control_position(S32 Number_of_turns);

void mc_regulation_loop();

void mc_set_Open_Loop();
void mc_set_Speed_Loop();
void mc_set_Current_Loop();
void mc_set_Position_Loop();

U8 mc_get_Duty_Cycle();

#endif
