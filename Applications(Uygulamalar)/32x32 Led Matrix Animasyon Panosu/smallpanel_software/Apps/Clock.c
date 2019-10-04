/*
 * Panel application "CLOCK"
 */
#include <application.h> 

/*
 * function prototypes
 */
int clock_init(void);

const char clock_name_P[] PROGMEM="Clock";
const char clock_icon_P[] PROGMEM={0,0,0,0,0,0,0};
struct application CLOCK={clock_name_P, clock_icon_P, clock_init, 0, 0};

int clock_init(void)
{
  typedef struct
  {
    int x,y;
  } NUMBER;
  
  const NUMBER number[12]=
  {
     {  0,-15},
     {  7,-13},
     { 13, -7},
     { 15,  0},
     { 13,  7},
     {  7, 13},
     {  0, 15},
     { -7, 13},
     {-13,  7},
     {-15,  0},
     {-13, -7},
     { -7,-13} 
  };
  
  typedef struct
  {
    int x1,y1;
    int x2,y2;
  } POINTER;
  
  const POINTER pointer[60]=
  {
     {  0,-14,  0,-10},
     {  1,-14,  1,-10},
     {  3,-14,  2,-10},
     {  4,-13,  3, -9},
     {  5,-13,  4, -9},
     {  7,-12,  5, -9},
     {  8,-11,  6, -8},
     {  9,-10,  7, -7},
     { 10, -9,  7, -7},
     { 11, -8,  8, -6},
     { 12, -7,  9, -5},
     { 13, -5,  9, -4},
     { 13, -4,  9, -3},
     { 14, -3, 10, -2},
     { 14, -1, 10, -1},
     { 14,  0, 10,  0},
     { 14,  1, 10,  1},
     { 14,  3, 10,  2},
     { 13,  4,  9,  3},
     { 13,  5,  9,  4},
     { 12,  7,  9,  5},
     { 11,  8,  8,  6},
     { 10,  9,  7,  7},
     {  9, 10,  7,  7},
     {  8, 11,  6,  8},
     {  7, 12,  5,  9},
     {  5, 13,  4,  9},
     {  4, 13,  3,  9},
     {  3, 14,  2, 10},
     {  1, 14,  1, 10},
     {  0, 14,  0, 10},
     { -1, 14, -1, 10},
     { -3, 14, -2, 10},
     { -4, 13, -3,  9},
     { -5, 13, -4,  9},
     { -7, 12, -5,  9},
     { -8, 11, -6,  8},
     { -9, 10, -7,  7},
     {-10,  9, -7,  7},
     {-11,  8, -8,  6},
     {-12,  7, -9,  5},
     {-13,  5, -9,  4},
     {-13,  4, -9,  3},
     {-14,  3,-10,  2},
     {-14,  1,-10,  1},
     {-14,  0,-10,  0},
     {-14, -1,-10, -1},
     {-14, -3,-10, -2},
     {-13, -4, -9, -3},
     {-13, -5, -9, -4},
     {-12, -7, -9, -5},
     {-11, -8, -8, -6},
     {-10, -9, -7, -7},
     { -9,-10, -7, -7},
     { -8,-11, -6, -8},
     { -7,-12, -5, -9},
     { -5,-13, -4, -9},
     { -4,-13, -3, -9},
     { -3,-14, -2,-10},
     { -1,-14, -1,-10} 
  };

  int  i;
  int  hh,mm,ss;

  hh=2;
  mm=15;
  ss=0;

  do
  {
    LEDClear();
    /* Ziffernblatt */
    for (i=0;i<12;i++)
      LEDPixel(15+number[i].x,15+number[i].y, 3);
  
    /* Minutenzeiger */
    LEDLine(15,15,15+pointer[mm].x1,15+pointer[mm].y1, 2);
  
    /* Stundenzeiger */
    LEDLine(15,15,15+pointer[hh*5+mm/12].x2,15+pointer[hh*5+mm/12].y2, 2);
  
    /* Sekundenzeiger */
    LEDLine(15,15,15+pointer[ss].x1,15+pointer[ss].y1, 1);
  
    LEDDraw();
    ss++;
    if (ss>59)
    {
      ss=0;
      mm++;
      if (mm>59)
      {
        mm=0;
        hh++;
        if (hh>12)
          hh=0;
      }
    }
    delay(100);
  }
  while (!UartKbhit());
  return 0;
}
