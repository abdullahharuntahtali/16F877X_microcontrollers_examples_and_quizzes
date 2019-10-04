
/*
 * This include should be included by applications
 */
#if !defined(APPLICATIONdotH)
#define APPLICATIONdotH

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <avr/pgmspace.h>
#include "led.h"
#include "serial.h"

#define MAXAPPLICATIONS 5    // maximum number of application descriptors
 
/* Application descriptor */ 
struct application
{
  PGM_P name;  // name of application
  PGM_P icon;  // bitmap of applications icon
  int (*appl_init)(void);        // application's init function
  int (*appl_demo)(void);        // application's demo function
  int (*appl_kill)(void);        // application's termination function
};

extern struct application *appl[MAXAPPLICATIONS];

#endif	
