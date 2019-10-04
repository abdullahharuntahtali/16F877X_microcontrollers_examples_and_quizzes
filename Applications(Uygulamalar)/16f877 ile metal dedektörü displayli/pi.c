#include "D:\pi_source\pi.h"
//#int_RTCC
//RTCC_isr()                    //ISR für Tongeber
//{
//   if(function&&ton)
//   {
//      if(welle)
//         output_high(BUZZER);
//      else
//         output_low(BUZZER);
//      welle=!welle;
//      set_rtcc(tbuzzer);
//   }
//}

void init()
{
   unsigned int z;
   setup_adc_ports(RA0_RA1_RA3_ANALOG);
   setup_adc(ADC_CLOCK_DIV_32);
   setup_counters(RTCC_INTERNAL,RTCC_DIV_32);  //für Buzzer
   setup_timer_1(T1_DISABLED);
   setup_timer_2(T2_DISABLED,0,1);
   setup_ccp1(CCP_OFF);
   setup_ccp2(CCP_OFF);
   disable_interrupts(INT_RTCC);
   disable_interrupts(global);
   perisleep();
   abgleich=1024;
   output_low(BUZZER);
}

void segment(unsigned int zeichen)
{
   unsigned int bits,ausgabe;
   ausgabe=char_out[zeichen];
   for(bits=0;bits<8;bits++)
   {
      if(bit_test(ausgabe,bits))
         switch(bits)
         {
            case 0:
               output_high(PIN_D0);
            break;
            case 1:
               output_high(PIN_D1);
            break;
            case 2:
               output_high(PIN_D2);
            break;
            case 3:
               output_high(PIN_D3);
            break;
            case 4:
               output_high(PIN_D4);
            break;
            case 5:
               output_high(PIN_D5);
            break;
            case 6:
               output_high(PIN_D6);
            break;
            case 7:
               output_high(PIN_D7);
            break;
         }
      else
         switch(bits)
         {
            case 0:
               output_low(PIN_D0);
            break;
            case 1:
               output_low(PIN_D1);
            break;
            case 2:
               output_low(PIN_D2);
            break;
            case 3:
               output_low(PIN_D3);
            break;
            case 4:
               output_low(PIN_D4);
            break;
            case 5:
               output_low(PIN_D5);
            break;
            case 6:
               output_low(PIN_D6);
            break;
            case 7:
               output_low(PIN_D7);
            break;
         }
   }
}

void measure()
{
   unsigned int16 average=0;
   unsigned int av;
   set_adc_channel(0);        //Spule aus (low), DC-Average aktiv(low)
   output_low(COIL);          //Gate inaktiv(high)
   output_high(GATE);
   output_high(DC_AV);
   output_high(COIL);         //Impuls setzen Spule an (high), 100µs warten
   delay_us(50);             //Spule aus (low)
   output_low(COIL);
   output_low(GATE);
   delay_us(50);              //ladezeit des Messkondensators
   output_high(GATE);          //DC-Average an(low), Gate aus(high)
   for(av=0;av<5;av++)
   {
      setup_adc(ADC_CLOCK_DIV_32);
      delay_us(10);
      messwert=read_adc();
      setup_adc( ADC_OFF );
      average=average+messwert;
      delay_us(10);
   }
  average=average/5;
  messwert=average;
  output_low(DC_AV);
}


//Abgleich ist der größte Wert der gemessen werden kann
//Daher ist eine Subtraktion des Messwertes vom Zerowert
//ein nutzbarer Wert, der immer größer als 0 ist.
//Kleinster AD-Wert 0 Größter AD-Wert 1024

void analyse()
{
   unsigned int16 differenz=0;
   unsigned int ausgabe=0;
   differenz=abgleich-messwert;
   if(messwert<abgleich)
   {
      output_low(LED_GRUEN);
      output_high(BUZZER);
   }
   else
   {
      output_high(LED_GRUEN);
      output_low(BUZZER);
      segment(16);
   }
   if (differenz<=124)
   {
      output_ high(LED_ROT);
      if((differenz>0)&&(differenz<=4))         //Fein Abgleich - 0 : -4
         differenz=16-differenz;                // F(0) - C(4)
      if((differenz>4)&&(differenz<=124))      //Mittel Abgleich - 5 : -124
         differenz=12-((differenz-4)/10);       //B(5-10) - 0(120-124)
   }
   else
   {
      output_low(LED_ROT);
      if((differenz>124)&&(differenz<364))    //Grob Abgleich - 124 : -324
         differenz=9-((differenz-124)/40);      //9(125-164) - 320
      if((differenz>=364)&&(differenz<abgleich))               //sehr grob Abgleich - 324 : -1024
         differenz=4-((differenz-364)/100);
   }
   if((differenz>0)&&(differenz<abgleich))    //nur Ausgabe, wenn wirklich etwas detektiert
   {
      ausgabe=differenz;
      segment(ausgabe);
   }
}

void perisleep()
{
   output_high(LED_BLAU);
   output_high(LED_ROT);
   output_high(LED_GRUEN);
   output_low(BUZZER);
   output_low(COIL);
   output_low(GATE);
   output_high(DC_AV);
   segment(17);            //Segment-Anzeige aus
}

void blink()
{
   output_low(LED_ROT);
   output_high(LED_GRUEN);
   delay_ms(300);
   output_high(LED_ROT);
   output_low(LED_GRUEN);
   delay_ms(300);
   output_low(LED_ROT);
   output_high(LED_GRUEN);
   delay_ms(300);
   output_low(LED_ROT);
   output_low(LED_GRUEN);
   delay_ms(500);
   output_high(LED_ROT);
   output_high(LED_GRUEN);
}

void power()
{
   if(input(ON_OFF))
      toggle=TRUE;
   else
      if(toggle)
      {
         function=!function;
         toggle=FALSE;
      }
   if(function)
      output_low(LED_BLAU);
   else
      output_high(LED_BLAU);
}

void test_voltage()
{
   set_adc_channel(1);
   delay_us(50);
   spannung = read_adc();
   if(spannung>=910)             //14 Volt
      output_high(LED_GRUEN);
   if(spannung>=850)             //13 Volt
      output_high(LED_GRUEN);
   if(spannung>=780)             //12 Volt
      output_high(LED_GRUEN);
      output_high(LED_ROT);
   if(spannung>=720)             //11 Volt
      output_high(LED_ROT);
   if(spannung<720)              //unter 11 Volt
   {
      output_high(LED_ROT);
      output_low(LED_BLAU);
      delay_ms(100);
      output_high(LED_BLAU);
   }
}

void nullabgleich()
{
   unsigned int16 zaus=0;
   unsigned int16 tt=0;
   output_low(BUZZER);
   measure();
   abgleich=messwert;
   tt=abgleich;
   blink();
   zaus=tt/1000;
   tt=tt-zaus*1000;
   if(zaus<10)
      segment(zaus);
   else
      segment(16);
   delay_ms(300);
   zaus=tt/100;
   tt=tt-zaus*100;
   if(zaus<10)
      segment(zaus);
   else
      segment(16);
   delay_ms(300);
   zaus=tt/10;
   tt=tt-zaus*10;
   if(zaus<10)
      segment(zaus);
   else
      segment(16);
   delay_ms(300);
   zaus=tt;
   if(zaus<10)
      segment(zaus);
   else
      segment(16);
   delay_ms(300);
}
/*
void x_analyse()
{
   unsigned int aus=0;
   if(messwert<200)
      aus=16;
   if(messwert>=200)     // größtes Teil ~ ca. 2,5 V
      aus=0;
   if(messwert>=300)
      aus=1;
   if(messwert>=400)
      aus=2;
   if(messwert>=500)
      aus=3;
   if(messwert>=600)
      aus=4;
   if(messwert>=700)
      aus=5;
   if(messwert>=740)
      aus=6;
   if(messwert>=780)
      aus=7;
   if(messwert>=820)
      aus=8;
   if(messwert>=860)
      aus=9;
   if(messwert>=900)
      aus=0;
   if(messwert>=910)
      aus=1;
   if(messwert>=920)
      aus=2;
   if(messwert>=930)
      aus=3;
   if(messwert>=940)
      aus=4;
   if(messwert>=950)
      aus=5;
   if(messwert>=960)
      aus=6;
   if(messwert>=970)
      aus=7;
   if(messwert>=980)
      aus=8;
   if(messwert>=985)
      aus=9;
   if(messwert>=990)
      aus=10;
   if(messwert>=995)
      aus=11;
   if(messwert>=1000)
      aus=12;
   if(messwert>=1005)
      aus=13;
   if(messwert>=1010)
      aus=14;
   if(messwert>=1015)
      aus=15;
   if(messwert>1020)        //kleinstes Teil, höchste empfindlichkeit ~ ca. 4,98 V
      aus=16;
   if(messwert<900)
   {
      output_low(LED_ROT);
      tbuzzer=239-(7*aus);
   }
   else
   {
      output_high(LED_ROT);
      tbuzzer=169-(7*aus);
   }
   segment(aus);
   if(messwert>=1020)      //Ton aus ,wenn nichts detektiert
      tbuzzer=255;
   if(messwert<1020)
      output_low(LED_GRUEN);
   else
      output_high(LED_GRUEN);
}

*/
void main()
{
   init();
   while(1)
   {
      power();
      if(function)            //Gerät ist eingeschaltet
      {
         if(!input(ZERO))      //Nullabgleich
            nullabgleich();
         else
         {
         measure();
         analyse();
         }
//         test_voltage();
      }
      else
         perisleep();
   }
}
