#include <16F877.h>
#device adc=10
#use delay(clock=20000000)
#fuses HS,NOWDT,PUT,BROWNOUT,NOLVP

#use fixed_io(a_outputs=PIN_A5)
#use fixed_io(c_outputs=PIN_C3, PIN_C4, PIN_C5, PIN_C6)
#use fixed_io(d_outputs=PIN_D0, PIN_D1, PIN_D2, PIN_D3, PIN_D4, PIN_D5, PIN_D6, PIN_D7)
#use fixed_io(e_outputs=PIN_E0, PIN_E1)

void init();
void segment(unsigned int zeichen);
void measure();
void analyse();
void nullabgleich();
void perisleep();
void power();
void blink();
void test_voltage();
//unsigned int tbuzzer;
unsigned int16 messwert=0,abgleich=0,spannung=0;//,div1,div2,div3;
//unsigned int16 temp1,temp2;
unsigned int1 toggle=FALSE,function=FALSE,welle=FALSE,ton=FALSE;
//7-Segment- Zeichen-Code : 0    1    2    3    4    5    6    7    8    9    A    b    C    d    E    F    -   nichts
unsigned int char_out[18]={0xf5,0x21,0xf8,0xb9,0x2d,0x9d,0xdd,0x31,0xfd,0xbd,0x7d,0xcd,0xd4,0xe9,0xdc,0x5c,0x08,0};
//                                                                            10   11   12   13   14   15   16  17
//Ausgänge

//Nachladewerte für die Buzzer-Frequenzen
//unsigned int frequenz[17]={255,240,236,235,233,231,229,226,224,220,215,209,200,188,169,136,61};
//                          0  400 650 900 1150
#define COIL      PIN_C3
#define GATE      PIN_E0
#define DC_AV     PIN_E1
#define LED_BLAU  PIN_C4
#define LED_GRUEN PIN_C5
#define LED_ROT   PIN_C6
#define BUZZER    PIN_A5

//Eingänge

#define ON_OFF    PIN_B4
#define ZERO      PIN_B5


