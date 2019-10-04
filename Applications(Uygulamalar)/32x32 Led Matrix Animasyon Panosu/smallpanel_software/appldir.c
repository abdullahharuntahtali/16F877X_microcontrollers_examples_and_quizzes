/*
 * Application directory
 * Enter your application descriptors here
 */
#include "application.h"
#include "apps/life.c"
#include "apps/clock.c"
 
struct application *appl[MAXAPPLICATIONS]=
{
	&LIFE,
	&CLOCK,
	0
};		
