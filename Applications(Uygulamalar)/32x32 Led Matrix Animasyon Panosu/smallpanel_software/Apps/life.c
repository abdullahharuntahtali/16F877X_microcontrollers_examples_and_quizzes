/*
 * Panel application "LIFE"
 */
#include <application.h> 

/*
 * function prototypes
 */
int life_init(void);

const char life_name_P[] PROGMEM="Life";
const char life_icon_P[] PROGMEM={0,0,0,0,0,0,0};
struct application LIFE={life_name_P, life_icon_P, life_init, 0, 0};

 
/*
 * draw a new Life Generation
 */
#define MAXSTAGNATION 3  /* number of equal generations when to skip */ 

int LEDLife(int x, int y, int w, int h, u_char c)
{
	static int generation=0;
  static int old_population=0; /* number of living cells last generation */
  static int old_death=0;      /* number of deaths last generation */
  static int old_birth=0;      /* number of births last generation */
  static int stagnation=0;     /* stagnation count */

  int xx,yy;
  int xl,xr,yu,yl;
  int population=0;     /* number of living cells */
  int death=0;          /* number of deaths */
  int birth=0;          /* number of births */
  u_char neighbors;
  u_char cyclic;
  
  if (c&0x80)
  {
  	generation=0;
  	return 1;
  }
  else
    generation++;
    
  cyclic=(c&0x40);
  c&=0x03;
      
  if (!w) w=MAXX;
  if (!h) h=MAXY;
  
  /* clear area */
  LEDFRectangle(x,y,w,h,0);

  for (yy=y;yy<y+h;yy++)
  {
		if (yy>y)
	    yu=yy-1;
		else
		  yu=(cyclic)?y+h-1:-1;
		  
		if (yy<y+h-1)
		  yl=yy+1;
		else
  	  yl=(cyclic)?y:-1;
  		  
  	for (xx=x;xx<x+w;xx++)
  	{
  		/* count the neighbors */
  		neighbors=0;

  		if (xx>x) 
		    xl=xx-1;
 		  else
 		    xl=(cyclic)?x+w-1:-1;  
 		    
  		if (xx<x+w-1)
  		  xr=xx+1;
  		else  
  		  xr=(cyclic)?x:-1;
  		  
  		if (yu>=0)
  		{      
  		  if ((xl>=0) && (LEDGetPixel(xl,yu)==c)) neighbors++;   
  	  	if (           (LEDGetPixel(xx,yu)==c)) neighbors++;   
  		  if ((xr>=0) && (LEDGetPixel(xr,yu)==c)) neighbors++;
  	  }
  	  
  		if ((xl>=0)   && (LEDGetPixel(xl,yy)==c)) neighbors++;    
  		if ((xr>=0)   && (LEDGetPixel(xr,yy)==c)) neighbors++;    

      if (yl>=0)
      {
  		  if ((xl>=0) && (LEDGetPixel(xl,yl)==c)) neighbors++;   
  		  if (           (LEDGetPixel(xx,yl)==c)) neighbors++;   
  		  if ((xr>=0) && (LEDGetPixel(xr,yl)==c)) neighbors++;
      }
/*
  		// x-1, y-1 
  		if ((xx>x)&&(yy>y)&&    (LEDGetPixel(xx-1,yy-1)==c)) neighbors++;
  		// x  , y-1 
  		if ((yy>y)&&            (LEDGetPixel(xx  ,yy-1)==c)) neighbors++;
  		// x+1, y-1 
  		if ((xx<x+w)&&(yy>y)&&  (LEDGetPixel(xx+1,yy-1)==c)) neighbors++;
  		// x-1, y   
  		if ((xx>x)&&            (LEDGetPixel(xx-1,yy  )==c)) neighbors++;
  		// x+1, y   
  		if ((xx<x+w)&&          (LEDGetPixel(xx+1,yy  )==c)) neighbors++;
  		// x-1, y+1 
  		if ((xx>x)&&(yy<y+h)&&  (LEDGetPixel(xx-1,yy+1)==c)) neighbors++;
  		// x  , y+1 
  		if ((yy<y+h)&&          (LEDGetPixel(xx  ,yy+1)==c)) neighbors++;
  		// x+1, y+1 
  		if ((xx<x+w)&&(yy<y+h)&&(LEDGetPixel(xx+1,yy+1)==c)) neighbors++;
*/

  		/* is current cell alife */
  		if (LEDGetPixel(xx,yy)==c)
  		{
  			if ((neighbors==2) || (neighbors==3))
  			{
  			  LEDPixel(xx,yy,c);
  			  population++;
  			}
  			else
  			  death++;
  		}
  		else
  			if (neighbors==3)
  			{
  			  LEDPixel(xx,yy,c);  
  			  birth++;
  			  population++;
  			}
  	}
  }
  if ((population==old_population)&&(death==old_death)&&(birth==old_birth))
  {
  	stagnation++;
  	if (stagnation>MAXSTAGNATION)
  	{
  		old_population=0;
  		old_death=0;
  		old_birth=0;
  		return(0);
  	}
  }
  else
  {
  	old_population=population;
  	old_death=death;
  	old_birth=birth;
  	stagnation=0;
  }	
  printf_P(PSTR("Gen: %3i  Pop: %3i  Birth: %3i  Death: %3i"), generation, population, birth, death);
  if (stagnation) printf_P(PSTR("  Stag: %3i"), stagnation);
  putchar('\n');
  LEDNumout(generation,0);
  LEDNumout(population,4);
  LEDNumout(birth,8);
  LEDNumout(death,12);
  return(generation && (death || birth));
}

int life_init(void)
{
	int lifex, lifey, lifew, lifeh;
	
	puts_P(PSTR("Press Ctrl-C to quit"));
  lifex=0; lifey=0; lifew=MAXX; lifeh=MAXY;
  LEDRandomfill(lifex,lifey,lifew,lifeh,RED,(lifew*lifeh)/10);
  LEDLife(lifex,lifey,lifew,lifeh,0xA0+RED);
  LEDDraw();
  delay(10);
  do
  {
    if ((!LEDLife(lifex,lifey,lifew,lifeh,0x40+RED))||UartKbhit())
    {
    	if (UartKbhit()) 
    	  if (UartGetChar()==3) return 0;
    	LEDLine(lifex,lifey,lifex+lifew-1,lifey+lifeh-1,YELLOW);
    	LEDLine(lifex,lifey+lifeh-1,lifex+lifew-1,lifey,YELLOW);
    	LEDDraw();
    	delay(100);
      LEDFRectangle(lifex,lifey,lifew,lifeh,BLACK);
      LEDRandomfill(lifex,lifey,lifew,lifeh,RED,(lifew*lifeh)/10);
      LEDLife(lifex,lifey,lifew,lifeh,0xA0+RED);
    }
    LEDDraw();
    delay(50);
  } while(1);
  return 0;
}
