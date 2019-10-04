/**
* @file config.h
*
* Copyright (c) 2005 Atmel.
*
* @brief This module provide services to define config for AT90PWM3 only
* Describes the system dependant software configuration.
* This file is included by all source files in order to access to system wide
* configuration.
* @version 1.0 (CVS revision : $Revision: 1.11 $)
* @date $Date: 2005/06/27 13:45:33 $
* @author $Author: gallain $

*****************************************************************************/



/*_____ I N C L U D E S ____________________________________________________*/
#include "compiler.h"
#include "mcu.h"
#include "inavr.h"
#include "config_motor.h"


#ifndef _CONFIG_H_
#define _CONFIG_H_
#endif
/*-------------- UART LIB CONFIGURATION ---------------*/


/* baud rate register value calculation */		
#define	BRREG_VALUE	12 //!<  BRREG_VALUE = (fclkio/(16*BAUDRATE))-1. 12 <=> 38400 bauds 8MHz  25 <=> 19200 bauds 8MHz

/* definitions for UART control */		
#define	BAUD_RATE_LOW_REG	  UBRRL
#define	UART_CONTROL_REG	  UCSRB
#define	ENABLE_TRANSMITTER_BIT	  TXEN
#define	ENABLE_RECEIVER_BIT	  RXEN
#define	UART_STATUS_REG	          UCSRA
#define	TRANSMIT_COMPLETE_BIT	  TXC
#define	RECEIVE_COMPLETE_BIT	  RXC
#define	UART_DATA_REG	          UDR

//! @defgroup ADC_defines_configuration_values ADC Defines Configuration Values
//! Defines allowing to init the ADC with the wanted configuration
//! @{
#define USE_ADC

#define ADC_RIGHT_ADJUST_RESULT                 0 //!< 0: Result left adjusted  1: Result right adjusted
#define ADC_HIGH_SPEED_MODE                     1 //
#define ADC_INTERNAL_VREF                       1 //!< 0: External Vref         1: Internal Vref  2: Vref is connected to Vcc
#define ADC_IT                                  1 //!< 0: No ADC End of Conv IT 1: ADC End of conversion generates an IT
#define ADC_PRESCALER                           4 //!< 2, 4, 8, 16, 32, 64, 128  : The input ADC frequency is the system clock frequency divided by the const value

//! @defgroup DAC_defines_configuration_values DAC Defines Configuration Values
//! Defines allowing to init the DAC with the wanted configuration
//! @{
#define USE_DAC

#define DAC_INPUT_RIGHT_ADJUST                  0 //!< 0: Result left adjusted  1: Result right adjusted
#define DAC_INTERNAL_VREF                       1 //!<
#define DAC_OUTPUT_DRIVER                       1 //!<

//! @defgroup AMP1_defines_configuration_values AMP1 Defines Configuration Values
//! Defines allowing to init the AMP1 with the wanted configuration
//! @{
#define USE_AMP1

#define AMP1_INPUT_SHUNT                        0 //!< 0: Disable Input Shunt   1: Enable Input Shunt
#define AMP1_GAIN                               20 //!< 5: Gain 5    10: Gain 10     20: Gain 20     40: Gain 40
#define AMP1_CLOCK                              1 //!< 0: Internal Clock            1: PSC0 Clock     2: PSC1 Clock     3: PSC2 Clock

//! @defgroup COMPARATORs_defines_configuration_values COMPARATORs Defines Configuration Values
//! Defines allowing to init the COMPARATORs with the wanted configuration
//! @{
#define USE_COMP0
#define COMPARATOR0_IT                          1 //!< 0: Disable Comparator Interrupt    1: Enable Comparator Interrupt
#define COMPARATOR0_IT_EVENT                    0 //!< Comparator Interrupt on outut => 0: toggle     2: falling edge     3: rising edge
#define COMPARATOR0_NEGATIVE_INPUT              4 //!< Comparator negative input selection => 0: vref/6.40  1: vref/3.20  2: vref/2.13  3: vref/1.60  4: ACMPM  5: DAC result

#define USE_COMP1
#define COMPARATOR1_IT                          1 //!< 0: Disable Comparator Interrupt    1: Enable Comparator Interrupt
#define COMPARATOR1_IT_EVENT                    0 //!< Comparator Interrupt on outut => 0: toggle     2: falling edge     3: rising edge
#define COMPARATOR1_NEGATIVE_INPUT              4 //!< Comparator negative input selection => 0: vref/6.40  1: vref/3.20  2: vref/2.13  3: vref/1.60  4: ACMPM  5: DAC result

#define USE_COMP2
#define COMPARATOR2_IT                          1 //!< 0: Disable Comparator Interrupt    1: Enable Comparator Interrupt
#define COMPARATOR2_IT_EVENT                    0 //!< Comparator Interrupt on outut => 0: toggle     2: falling edge     3: rising edge
#define COMPARATOR2_NEGATIVE_INPUT              4 //!< Comparator negative input selection => 0: vref/6.40  1: vref/3.20  2: vref/2.13  3: vref/1.60  4: ACMPM  5: DAC result

