//--------------------------------------------------------------------------------------//
// Project file name:     pic_agc.PJT                                                   //
// Assembly file name:    pic_agc.ASM                                                   //
// HEX file name:         pic_agc.HEX                                                   //
//////////////////////////////////////////////////////////////////////////////////////////
//----------------------------------------------------------------------------------------------
//Attenuation control settings:     RB0=2dB on input.  RB0=2dB on output.
//                                  RB1=4dB on input.  RB1=4dB on output.
//                                  RB2=8dB on input.  RB2=8dB on output.
//                                  RB3=10dB on input. RB3=10dB on output.
//                                  RB4=20dB on input. RB4=20dB on output.
// Will initially set attenuators as follows:
//                                  Input Attenuator set for 0dB of attenuation. PORTB=0x00
//                                  Output Attenuator set for 0dB of attenuation. PORTB=0x00
//----------------------------------------------------------------------------------------------

#include <16F876.H>           // PIC16F876 is processor selected.
#include <STDIO.H>            // Standard IO library is included.

//Set MCU options and configuration.
//       HS    =  high speed XTAL.
//       NOWDT =  Disable Watchdog Timer.
//       NOPROTECT   =  No Code Protect.
//       PUT   =  Power Up Timer is ACTIVE.
//       NOBROWNOUT  =  No Brownout (DISABLED).

#fuses HS, NOWDT, NOPROTECT, PUT, NOBROWNOUT

//Tell compiler that clock is 20MHz for use in DELAY routines.

#use DELAY(clock=20000000)
#byte PORT_A=5                                     //PORTA File Register=05.
#byte PORT_B=6                                     //PORTB File Register=06.
#byte PORT_C=7                                     //PORTC File Register=07.
int loop_num;
int flag;
long dc_level, min, max;                           //FLAG helps to keep track of routines.
                         			   //Declare "dc_level" to be a 16 bit unsigned number. Used for A/D conversion.
                                                   // '---> MIN=minimum level DC can be before attenuation is removed.
                                                   //    '---> MAX=maximum level DC can be before attenuation is applied.
main()
   {
      SET_TRIS_A(0xFF);                            //Set PORTA to all INPUTS.
      SET_TRIS_B(0x00);                            //Set PORTB to all OUTPUTS.
      SET_TRIS_C(0x00);                            //Set PORTC to all OUTPUTS.
      setup_adc_ports( RA0_RA1_ANALOG_RA3_REF );   //Sets PORTA for RA0 & RA1 for ANALOG, RA3 for VREF.
      setup_adc( ADC_CLOCK_DIV_32 );               //Sets A/D conversion clock for a divide by 32 (for 20MHz).

      min = 0x010E;        //Lower threshold of desired output power.
                           //For 10-bit A/D, stepsize of 1024.  VREF=4.096VDC (4.096V/1024=4mV) giving you a step size of 4mV per DIV.
                           //For 1.08VDC (1.08VDC=-32dBM) 1.08VDC/.004V= decimal 270. HEX=0x010E

      max = 0x0120;        //Upper threshold of desired output power.
                           //For 10-bit A/D, stepsize of 1024.  VREF=4.096VDC (4.096V/1024=4mV) giving you a step size of 4mV per DIV.
                           //For 1.15VDC (1.15VDC=-28dBM) 1.15VDC/.004V= decimal 288. HEX=0x0120
      PORT_B=0x00;         //Initially set PORTB attenuators OFF!!
      PORT_C=0x00;         //Initially set PORTC to 0x00 (Both LED's are OFF!!).
      loop_num = 1;	   //Number so "WHILE" loop will always be "looping".

while (loop_num == 1)	   //As long as loop_num is 1, will keep testing signal.
      {
      DELAY_US(10);                                //DELAY for 10uS so A/D converter can settle.
      flag=1;
         do
         {
           set_adc_channel(0);                     //Use RA0 for ANALOG input into A/D.
           delay_ms(10);                           //Lets A/D stabilize.
           dc_level = read_adc();              	   //Set variable "dc_level" to equal A/D conversion result.
           delay_ms(10);                       	   //Lets A/D stabilize.

            if (dc_level<min)                      //If power output is low, decrease attenuation and turn on RED LED.
	       {
               output_high(PIN_C6);                //Turn on RED LED.
               output_low(PIN_C7);                 //Turn off GREEN LED.
               PORT_B = PORT_B - 0x01;             //POWER still too low, decrease attenuation.
	       }

                  if (dc_level>max)                //If power output is high, increase attenuation and turn on GREEN LED.
                     {
                     output_high(PIN_C7);          //Turn on GREEN LED.
                     output_low(PIN_C6);           //Turn off RED LED.
                     PORT_B = PORT_B + 0x01;       //POWER still too high, increase attenuation.
                     }

                        if ((min<dc_level) && (dc_level<max))            //If power output is within window, hold attenuation.
               		    {
                            output_low(PIN_C7);    //Turn off GREEN LED.
                            output_low(PIN_C6);    //Turn off RED LED.
                            flag=0;                //FLAG==0!
			    }

         else
           flag=1;
         }

         while (flag==1);

      }

   }
