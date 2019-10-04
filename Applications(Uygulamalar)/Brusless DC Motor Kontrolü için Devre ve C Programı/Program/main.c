/**
* @file main.c
*
* Copyright (c) 2005 Atmel.
*
* @brief This module provide services to show a simple program for  AT90PWM3 Only
* @version 1.0 (CVS revision : $Revision: 1.15 $)
* @date $Date: 2005/06/30 09:17:19 $
* @author $Author: gallain $
*****************************************************************************/
#include "config.h"

#include "mc_lib.h"
#include "mc_control.h"
#include "mc_drv.h"
#include "serial.h"

#include "adc\adc_drv.h"
#include <stdio.h>
#include "mc_test_procedure.h"

U16 g_regulation_period = 0;  //!< Define the sampling period
U16 motor_speed = 0;          //!< User Speed Order
extern Bool g_tic;            //see mc_drv.c Use for sampling time


//! Main user routine.
//!
//! The main user routine provides an UART control for the motor.
//! The mc_regulation_loop() function is launched every 80ms.
//! '0,1,2,3' are used to set the speed of the motor.
//! '&,é,",(' are used to select the regulation loop (Open loop, speed, current, position).
//! Press 'r' key to start the motor.
//! Press 's' key to stop the motor.
//! Press 'f' and 'b' keys to choose between CW and CCW rotation direction.
//! Press 'v' key to print all motor parameters.
//! Press 'i' key to initialize the motor after Over current detection.
//! Press '-' and '+' keys to decrease or increase motor speed value.
//!
void main(void)
{
  // init motor
  mc_motor_init();  // launch initialization of the motor

  // init UART
  init_uart();

  // If PB5 == 1 : Launch the test function.(Only use for Board test)
  if(Get_EXT3() == 0)mc_Board_test();

  // UART print screen
  // uncomment for UART use
  /*putstring("\033[2J");  // CLS, VT100 ANSI sequence

  putstring("ATMEL BLDC Motor Control.");
  putstring("\n\r");
  sendchar(':');*/

  // Start the motor
  mc_set_motor_speed(0);
  mc_motor_run();

  while(1)
  {
    // UART IHM
    // The code below provide an UART control for the motor
    // uncomment for UART use
    /*if(tstrx()==TRUE)
    {
      char answ = '\0';
      answ = recchar();
      sendchar(answ);
      putstring("\n\r\0");
      switch(answ)
      {
        case 'r' :  // launch the motor
                    putstring("Run\n\r\0");
                    mc_set_motor_speed(motor_speed);
                    mc_reset_Num_Turn();
                    mc_motor_run();
                    break;
        case 's' :  // stop the motor
                    putstring("Stop\n\r\0");
                    mc_motor_stop();
                    break;
        case 'f' :  // Select forward direction
                    putstring("CW\n\r\0");
                    mc_motor_stop();
                    mc_set_motor_direction(CW);
                    mc_motor_run();
                    break;
        case 'b' :  // Select backward direction
                    putstring("CCW\n\r\0");
                    mc_motor_stop();
                    mc_set_motor_direction(CCW);
                    mc_motor_run();
                    break;
        case 'v' :  // print motor information
                    putstring("Cmd :");
                    putint(mc_get_motor_speed());
                    putstring("\n\r");
                    putstring("Speed:");
                    putint(mc_get_motor_measured_speed());
                    putstring("\n\r");
                    putstring("Current:");
                    putint(mc_get_measured_current());
                    putstring("\n\r");
                    putstring("Turns:");
                    putint(mc_get_Num_Turn());
                    putstring("\n\r");
                    break;
        case '0' :  // No regulation (Open Loop)
                    motor_speed = 50;
                    break;
        case '1' :  // Set speed regulation
                    motor_speed = 100;
                    break;
        case '2' :  // Set current regulation
                    motor_speed = 150;
                    break;
        case '3' :  // Set position regulation
                    motor_speed = 255;
                    break;
        case '&' :  // No regulation (Open Loop)
                    mc_set_Open_Loop();
                    break;
        case 'é' :  // Set speed regulation
                    mc_set_Speed_Loop();
                    break;
        case '"' :  // Set current regulation
                    mc_set_Current_Loop();
                    break;
        case '(' :  // Set position regulation
                    mc_reset_Num_Turn();
                    mc_set_Position_Loop();
                    break;
        case '+' :  // Set current regulation
                    motor_speed ++;
                    break;
        case '-' :  // Set position regulation
                    motor_speed --;
                    break;
        case 'i' :  // Init PSC, Restart PSC after Over_Current detection
                    PSC0_Init(255,0,1,0);
                    PSC1_Init(255,0,1,0);
                    PSC2_Init(255,0,1,0);
                    break;
        default :   putstring("Unknown command\n\r\0"); // Unknow Command try again
      }
      sendchar(':');
    }*/

    // Show PSC state according to the Over Current information
    if(PCTL2 & (1<<PRUN2))  switch_OFF_LED();// PSC ON
    else  switch_ON_LED();//PSC OFF => Over_Current


    // Launch regulation loop
    // Timer 1 generate an IT (g_tic) all 250us
    // Sampling period = n * 250us
    if (g_tic == TRUE)
    {
      g_tic = FALSE;

      // Get Current and potentiometer value
      mc_ADC_Scheduler();

      g_regulation_period += 1;
      if ( g_regulation_period >= 320 ) //n * 250us = Te
      {
        g_regulation_period = 0;
        //mc_set_motor_speed(motor_speed); // Set User Speed Command for an UART control
        mc_set_motor_speed(mc_get_potentiometer_value()); // Set User Speed Command with potentiometer
        mc_regulation_loop(); // launch regulation loop
      }
    }
  }
}
