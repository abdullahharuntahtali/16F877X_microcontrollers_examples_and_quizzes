#include "config.h"
#include "mc_test_procedure.h"

#include "mc_drv.h"
#include "serial.h"
#include "mc_lib.h"


/**
* @brief holding procedure
* @pre none
* @post wait nb_cycle
*/
void wait(U16 nb_cycle){
  U16 i = 0;
  for(i=0;i<=nb_cycle;i++);
}

/**
* @brief Board test
* @pre Ports configuration in mc_drv.c
* @post Test the UART and the motor control
*/
void mc_Board_test()
{
  U16 delay = 60000;

  Clear_EXT2(); // Switch ON the LED, the test begin

  // wait for UART test
  sendchar('a');
  if(tstrx()==TRUE)
  {
    if(recchar() == 'a') delay = 60000; // the test is positive
    else delay = 0; //the test is negative
  }
  else delay = 0; //the test is negative

  // Motor Control Test
  while(Get_EXT1() == 1); // while the user don't press the switch
  while(Get_EXT1() == 0); // Wait key release

  mc_set_motor_speed(50);
  mc_motor_run();         // start the motor

  // if the test is OK the LED is switched ON and OFF...
  // else the LED is switched ON.
  while(1)
  {
    if(Get_EXT1() == 0)mc_motor_stop();

    Clear_EXT2();
    wait(delay);
    wait(delay);
    Set_EXT2();
    wait(delay);
    wait(delay);
  }
}
