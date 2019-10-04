/* LED Matrix display driver (LED panel drawing routines)
 *
 * Controlling several LED Matrix Modules Samsung SLM1606M/SLM1608M
 * connected to port B/D of Ethernut:
 *
 * Printer   Module
 * -----------------
 * D0 (2)    SELECT (CN2-2)
 * D1 (3)    RED    (CN3-2)
 * D2 (4)    GREEN  (CN3-4)
 * D3 (6)    CLOCK  (CN3-6)
 * D4 (8)    BRIGHT (CN3-8)
 * D5 (9)    RESET  (CN3-10)
 * GND (20)  GND    (CN3-3)
 *
 * Written by Thorsten Erdmann 06/2003 (thorsten.erdmann@gmx.de)
 */

/**************************************************************
 **** CAUTION: The module can be destroyed if applied      ****
 ****          static signals, so NEVER interrupt the      ****
 ****          program without switching off module's      ****
 ****          power source first !!!                      ****
 **************************************************************/
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <avr/io.h>
#include <avr/signal.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>

#include "led.h"
#include "chrsmall.c"

#define BUFSIZE MAXX*MAXY/4
#define OBJC_EOF       0  // end of file
#define OBJC_POINT     1  // single pixel
#define OBJC_LINE      2  // line
#define OBJC_HLINE     3  // horizontal line
#define OBJC_VLINE     4  // vertical line
#define OBJC_RECT      5  // rectangle
#define OBJC_FRECT     6  // filled rectangle
#define OBJC_CIRCLE    7  // circle
#define OBJC_FCIRCLE   8  // filled circle
#define OBJC_CHAR      9  // character
#define OBJC_STRING   10  // string
#define OBJC_FSTRING  11  // formated string
#define OBJC_SSTRING  12  // scrolling string
#define OBJC_BITMAP   13  // bitmap
#define OBJC_CBITMAP  14  // centered bitmap
#define OBJC_ABITMAP  15  // animated bitmap
#define OBJC_ACBITMAP 16  // animated centered bitmap

volatile char altered;
volatile char screen[BUFSIZE];
volatile char buffer[BUFSIZE];
volatile char buf7seg[32];
volatile char *bufgreen;
volatile char *bufred;
volatile char animation;
volatile char keypad;


#define  nop()   __asm__ __volatile__ ("nop" ::) 

#define MAXSCROLL 4
volatile struct
{
	u_char type;            // object type
  int x,y,w,h;            // object coordinates and width
  u_char c;               // object color
  u_char delay;           // delay between frames in timer ticks 
  u_char delaycnt;        // delay counter
  u_char p1;              // object parameter (e.g. string format)
  int count;              // counter used by objcAnimate Routine
  void *p2;               // pointer to object working data
  void *s;                // pointer to object data
} scr[MAXSCROLL];

static int    clipx0,clipy0,clipx1,clipy1;
static PGM_P  font;


/*
 * Startup Timer2 ISR for muxing the panel
 */
void startTimer(void)
{
  /* set timer 2 to CTC mode, clock / 256 = 16uS */
//  TCCR2 = BV(CTC2) | BV(CS22);
  TCCR2 = BV(WGM21) | BV(CS22);
  /* Set output compare register to 10 = 160uS for now */
  OCR2 = 35;
  /* enable the output compare match interrupt */
  TIMSK |= BV(OCIE2);
  /* initialize SPI interface */
  outp((1<<SPE)+(1<<MSTR)+(1<<SPR0)+(1<<CPHA)+(1<<CPOL),SPCR);  /* Enable SPI Master mode 3*/
  //outp(0xff,PORTE);
  animation=1;
  //outp(inp(DDRE)|((1<<LEDSEL0)+(1<<LEDSEL1)),DDRE);
  //outp(inp(LEDMUX)|((1<<LEDSEL0)+(1<<LEDSEL1)),LEDMUX);
}




/* SPI Test */
void Mux7Segm(char active)
{
	static u_char column=0;
	static u_int mask=0x0001;
	static u_int keys=0;
	if (active)
	{
		/* scan keypad */
    if bit_is_set(PINB,7) keys|=mask;
		/* show 7-segment display */
	  outp(mask>>8,SPDR); /* output colomn */
    while(!(inp(SPSR) & (1<<SPIF)));
	  outp(mask&0xff,SPDR); /* output colomn */
    while(!(inp(SPSR) & (1<<SPIF)));
	  outp(buf7seg[column],SPDR); /* output image line 0*/
    while(!(inp(SPSR) & (1<<SPIF)));
    sbi(PORTB,0);
    cbi(PORTB,0);
    mask<<=1;
    column++;
    if (!mask) 
    {
      keypad=keys&0xff;
    	keys=0;
    	mask=0x0001;
    	column=0;
    }
  }
  else
  {  
  	/* blank 7-segment display */
	  outp(0,SPDR); /* output colomn */
    while(!(inp(SPSR) & (1<<SPIF)));
	  outp(0,SPDR); /* output image line 0*/
    while(!(inp(SPSR) & (1<<SPIF)));
	  outp(0,SPDR); /* output colomn */
    while(!(inp(SPSR) & (1<<SPIF)));
    sbi(PORTB,0);
    cbi(PORTB,0);
  }  
}  

#if (DISPTYPE==SLM_OLD)
#include "slm_old.c"
#endif

#if (DISPTYPE==SLM_NEW)
#include "slm_new.c"
#endif

#if (DISPTYPE==SLM_HUGE)
#include "slm_huge.c"
#endif

#if (DISPTYPE==DISCRETE)
#include "discrete.c"
#endif

#if (DISPTYPE==SPI)
#include "spi.c"
#endif


char *LEDGetbuffer(void)
{
	return bufred;
}

/*
 * HERE COMES THE DRAWING PRIMITIVES
 */

/*
 * Actualize Panel
 */
void LEDDraw(void)
{
	while (altered); // wait for screen actualizing complete 
	altered=1;
	while (altered); // wait for screen actualizing complete 
}

/* 
 * Clear Screen
 */
void LEDClear(void)
{
  clipx0=0; clipx1=MAXX;
  clipy0=0; clipy1=MAXY; 
  memset(scr,0,sizeof(scr));  
  memset(bufred,0,BUFSIZE);
}

/*
 * Initialize LED Matrix
 */
void LEDInit(void)
{
  outp(0xff, DDRD);
  outp(0x00, PORTD);

  outp(0x77,DDRB);
  outp(0xdf,PORTB);
  
  outp(0xfb,DDRE);
 
  memset(buf7seg,0,sizeof(buf7seg));
  bufred=buffer;
  bufgreen=buffer+BUFSIZE/2;
  font=chrsmall; /* assign font */
  LEDClear();
  startTimer();
  sei();
  puts("Timer started.");
	LEDDraw();
}

/*
 * Draw Pixel
 */
void LEDPixel(int x, int y, u_char c)
{
  u_int s;
  if ((x<0)||(x>=MAXX)||(y<0)||(y>=MAXY)) return;
  s=x+(y>>3)*MAXX;
  if (c&1)
    bufred[s]|=  0x01<<(y&0x07);
  else
    bufred[s]&=~(0x01<<(y&0x07));
  if (c&2)
    bufgreen[s]|=  0x01<<(y&0x07);
  else
    bufgreen[s]&=~(0x01<<(y&0x07));
}

/*
 * Draw horizontal line
 */
void LEDHLine(int x, int y, u_int l, u_char c)
{
  u_int s,i;
  u_char w,b;

  if ((x>=MAXX)||(y<0)||(y>=MAXY)) return;
  b=MAXY>>3;
  if (x<0)
  {
    l+=x;
    x=0;
  }
  if (x+l>MAXX)
    l=MAXX-x;
  s=x+(y>>3)*MAXX;
  if (c&1)
  {
    w=0x01<<(y&0x07);
    for (i=0;i<l;i++)
    {
      bufred[s]|=w;
      s++;
    }
  }
  else
  {
    w=~(0x01<<(y&0x07));
    for (i=0;i<l;i++)
    {
      bufred[s]&=w;
      s++;
    }
  }
  s-=l;
  if (c&2)
  {
    w=0x01<<(y&0x07);
    for (i=0;i<l;i++)
    {
      bufgreen[s]|=w;
      s++;
    }
  }
  else
  {
    w=~(0x01<<(y&0x07));
    for (i=0;i<l;i++)
    {
      bufgreen[s]&=w;
      s++;
    }
  }
}

/* 
 * Draw vertical line
 */
void LEDVLine(int x, int y, u_int l, u_char c)
{
  u_int i;
  if ((x>=MAXX)||(x<0)||(y>=MAXY)) return;
  for (i=0;i<l;i++) LEDPixel(x,y+i,c);
}

/*
 * Draw Rectangle
 */
void LEDRectangle(int x, int y, int w, int h, u_char c)
{
  LEDHLine(x,y,w,c);
  LEDHLine(x,y+h-1,w,c);
  LEDVLine(x,y,h,c);
  LEDVLine(x+w-1,y,h,c);
}

/*
 * Draw filled Rectangle
 */
void LEDFRectangle(int x, int y, int w, int h, u_char c)
{
  int i;
  for (i=0;i<h;i++)
    LEDHLine(x,y+i,w,c);
}

/* 
 * Draw character
 */
int LEDChar(int x, int y, u_char c, u_char ch)
{
  int adr,d,n,x0,x1,y0,y1,k,w,bpr,bpc,s,b;

  if (ch<4) return x;
  if ((ch<PRG_RDB(font)) || (ch>PRG_RDB(font+1))) return x;
  b=MAXY>>3;
  n=ch-PRG_RDB(font);
  /* get character width */
  w=PRG_RDB(font+3+3*n);
  /* get offset to character bitmap */
  k=PRG_RDB(font+3+3*n+1)+(PRG_RDB(font+3+3*n+2)<<8);
  /* calculate byte per character column */
  bpc=(PRG_RDB(font+2)+7)/8;
  bpr=bpc;
  /* calculate y byte adress */
  y0=y>>3;
  /* clip x coordinates */
  if (x>=clipx0)
    x0=x;
  else
  {
    if (x+w<=clipx0) return x+w;
    x0=clipx0;
  }
  /* calculate bit shift of character row */
  s=y&7;
  
  if (y0>b)
  {
    bpr-=y0;
    y0=b;
  }
    
  /* calculate start adress */
  adr=x0+y0*MAXX;
  n=k+bpc-1+(x0-x)*bpc;
  y1=0;
  while ((y0<b) && (y1<=bpr))
  {
    k=n;
    d=adr;
    for (x1=x0;(x1<x+w)&&(x1<clipx1);x1++)
    {
    	if (c&1)
    	{
        if (y1<bpc) bufred[d]|=PRG_RDB(font+3+k)<<s;
        if (y1>0)   bufred[d]|=(PRG_RDB(font+3+k+1)>>(8-s));
      }
    	if (c&2)
    	{
        if (y1<bpc) bufgreen[d]|=PRG_RDB(font+3+k)<<s;
        if (y1>0)   bufgreen[d]|=(PRG_RDB(font+3+k+1)>>(8-s));
      }
      d++;
      k+=bpc;
    }
    adr+=MAXX;
    n--;
    y0++;
    y1++;
  }
  return x+w;
}

/*
 * calculate character width
 */
int LEDGetChrLength(u_char ch)
{
	if (ch<4) return 0;
  if ((ch<PRG_RDB(font)) || (ch>PRG_RDB(font+1))) return 1;
  /* get character width */
  return PRG_RDB(font+3+3*(ch-PRG_RDB(font)));
}

/*
 * calculate character width
 */
int LEDGetStrHeight(void)
{
  /* get character height */
  return PRG_RDB(font+2);
}

/*
 * calculate string length
 */
int LEDGetStrLength(const char *s)
{
  int i=0, l=0;
  while (s[i]!=0)
    l+=LEDGetChrLength(s[i++]);
  return l;
}

/*
 * Draw string
 */
int LEDStr(int x, int y, u_char c, const char *s)
{
  int i;
  u_char color=c;

  LEDFRectangle(x,y,LEDGetStrLength(s),PRG_RDB(font+2),0);
  i=0;
  while ((s[i]!=0) && (x<MAXX))
  {
  	if (s[i]<4)
  	  color=s[i];
  	else  
      x=LEDChar(x,y,color,s[i++]);
  }  
  return x;
}

/*
 * Draw formatted string
 */
void LEDFStr(int x, int y, int w, u_char f, u_char c, const char *s)
{
  int i,x0,l;
  u_char color=c;

  l=LEDGetStrLength(s);
  if (x+w>MAXX) w=MAXX-x;
  switch (f)
  {
    case TE_CENTER: x0=x+((w-l)>>1); break;
    case TE_RIGHT : x0=x+w-l; break;
    default       : x0=x; break;
  }
  if (x>0) clipx0=x;
  if (x+w<MAXX) clipx1=x+w;
  LEDFRectangle(clipx0,y,clipx1-clipx0,PRG_RDB(font+2),0);  // Clear text area
  i=0;
  while ((s[i]!=0) && (x<MAXX))
  {
  	if (s[i]<4)
  	  color=s[i];
  	else  
      x0=LEDChar(x0,y,c,s[i++]);
  }
  clipx0=0;
  clipx1=MAXX;
}

/*
 * Draw a stored scrolled text to display
 */
int LEDScrolledText(int n)
{
  int i,j,x0,l;
  u_char color,*s;
  PGM_P sfont;

  if ((scr[n].y<0) || (scr[n].y>MAXY)) return 0;
  if (scr[n].delaycnt!=(scr[n].delay))
  {
  	scr[n].delaycnt++;
  	return 0;
  }
  s=(char *)scr[n].s;
  scr[n].delaycnt=0;
  sfont=font;
  font=scr[n].p2;
  l=LEDGetStrLength(s);
  if (scr[n].x>0) clipx0=scr[n].x;
  if (scr[n].w+scr[n].x<MAXX) 
    clipx1=clipx0+scr[n].w;
  else
    clipx1=MAXX;  
  if (l<=scr[n].w)
  {
    LEDFStr(scr[n].x,scr[n].y,scr[n].w,scr[n].p1,scr[n].c,s);
    return 0;
  }
  else
  {
    j=LEDGetStrLength("    ");
    LEDFRectangle(clipx0,scr[n].y,clipx1-clipx0,PRG_RDB(font+2),0);
    i=0;
    x0=scr[n].x-scr[n].count;
    color=scr[n].c;
    while (x0<clipx1)
    {
    	if (s[i]<4)
    	  color=s[i++];
    	else  
        x0=LEDChar(x0,scr[n].y,color,s[i++]);
      if (s[i]==0)
      {
        i=0;
        x0+=j;
        color=scr[n].c;
      }
    }
    scr[n].count=(scr[n].count+1)%(l+j);
  }
  clipx0=0;
  clipx1=MAXX;
  font=sfont;
  return 1;
}

/*
 * Draw scrolled formatted string to VFD
 */
void LEDSStr(int x, int y, int w, u_char f, u_char c, const char *s)
{
  u_char i;
  i=0;
  while ((scr[i].type) && (i<MAXSCROLL)) i++;  // find a free storage slot
  if (i>=MAXSCROLL)
    LEDFStr(x,y,w,f,c,s);                      // no free slot, so draw the string non scrolling
  else
  {
  	scr[i].type=OBJC_SSTRING;
    scr[i].p1=f&0x0f;
    scr[i].c=c;
    scr[i].count=0;
    scr[i].delay=f>>4;
    scr[i].delaycnt=0;
    scr[i].p2=font;
    scr[i].s=s;
    scr[i].w=w;
    scr[i].x=x;
    scr[i].y=y;
    if (x+w>MAXX) w=MAXX-x;
  }
}

/*
 * Draw a stored scrolled text to display
 */
int LEDAnimateBitmap(int n)
{
  PGM_P bm;

  if (scr[n].delaycnt!=(scr[n].delay))
  {
  	scr[n].delaycnt++;
  	return 0;
  }
  bm=scr[n].p2;
  LEDBitmap(scr[n].x,scr[n].y,scr[n].c,bm); 
  bm+=((PRG_RDB(bm)+7)>>3)*PRG_RDB(bm+1)+2;
  if (PRG_RDB(bm)!=0xff)
  {
    scr[n].delay=5*PRG_RDB(bm);
    bm++;
  }
  else
    bm=scr[n].s;
  scr[n].delaycnt=0;  
  scr[n].p2=bm;  
  return 1;
}

/*
 * Display an animated Bitmap
 */
void LEDABitmap(int x, int y, unsigned char c, PGM_P bm)
{
  u_char i;
  i=0;
  while ((scr[i].type) && (i<MAXSCROLL)) i++;  // find a free storage slot
  if (i>=MAXSCROLL)
    LEDBitmap(x,y,c,bm+5);                     // no free slot, so draw the string non scrolling
  else
  {
  	scr[i].type=OBJC_ABITMAP;
    scr[i].delay=0;
    scr[i].delaycnt=0;
    scr[i].c=c;
    scr[i].count=0;
    scr[i].p2=bm+5;
    scr[i].s=bm+5;
    scr[i].x=x;
    scr[i].y=y;
  }
}

/*
 * Animate all animated objects
 */
int LEDAnimate(void)
{
  u_char i,j=0;
  if (animation)
  {
    for (i=0;i<MAXSCROLL;i++) 
    {
  	  switch (scr[i].type)
  	  {
  		  case OBJC_SSTRING:
  		    j+=LEDScrolledText(i);
  		    break;
  		  case OBJC_ABITMAP:
  		    j+=LEDAnimateBitmap(i);
  		    break;  
  	  }
    }
  }
  if (j) altered=1;
  return j;
}

/* 
 * Draw a Circle
 */
void LEDCircle(int x,int y,int r,int c)
{
  int d,xx,yy;
  if (r<2) return;
  d=3-2*r;
  xx=0;
  yy=r;
  while(xx<=yy)
  {
    LEDPixel(x+xx,y+yy,c);
    LEDPixel(x+xx,y-yy,c);
    LEDPixel(x-xx,y+yy,c);
    LEDPixel(x-xx,y-yy,c);
    LEDPixel(x+yy,y+xx,c);
    LEDPixel(x+yy,y-xx,c);
    LEDPixel(x-yy,y+xx,c);
    LEDPixel(x-yy,y-xx,c);
    xx++;
    if (d<0)
    {
      d=d+4*xx+2;
    }
    else
    {
      d=d+4*xx+2-4*(yy-1);
      yy=yy-1;
    }
  }
}

/* 
 * Draw a filled Circle 
 */
void LEDFCircle(int x,int y,int r,int c)
{
  int d,xx,yy;
  if (r<2) return;
  d=3-2*r;
  xx=0;
  yy=r;
  while(xx<=yy)
  {
    LEDHLine(x-xx,y+yy,2*xx,c);
    LEDHLine(x-xx,y-yy,2*xx,c);
    LEDHLine(x-yy,y-xx,2*yy,c);
    LEDHLine(x-yy,y+xx,2*yy,c);
    xx++;
    if (d<0)
    {
      d=d+4*xx+2;
    }
    else
    {
      d=d+4*xx+2-4*(yy-1);
      yy=yy-1;
    }
  }
}

/*
 * Draw Line 
 */
void LEDLine(int x1,int y1,int x2,int y2, int c)
{
  int a,m,x,y;
  int d,dx,dy,xInc,yInc;

  x=x1;
  y=y1;
  d=0;
  dx=x2-x1;
  dy=y2-y1;
  xInc=1;
  yInc=1;

  if (dx<0)
  {
    xInc=-1;
    dx=-dx;
  }
  if (dy<0)
  {
    yInc=-1;
    dy=-dy;
  }
  if (dy<=dx)
  {
    a=2*dx;
    m=2*dy;
    while (1)
    {
      LEDPixel(x,y,c);
      if (x==x2) break;
      x+=xInc;
      d+=m;
      if (d>dx)
      {
        y+=yInc;
        d-=a;
      }
    }
  }
  else
  {
    a=2*dy;
    m=2*dx;
    while (1)
    {
      LEDPixel(x,y,c);
      if (y==y2) break;
      y+=yInc;
      d+=m;
      if (d>dy)
      {
        x+=xInc;
        d-=a;
      }
    }
  }
}
/* 
void LEDLine(int x1,int y1,int x2,int y2, int c)
{
  int a,x,y,xInc,yInc;
  int m,d,dx,dy;
  x=x1;
  y=y1;
  d=0;
  dx=x2-x1;
  dy=y2-y1;
  xInc=1;
  yInc=1;
  if (dx<0)
  {
    xInc=-1;
    dx=-dx;
  }
  if (dy<0)
  {
    yInc=-1;
    dy=-dy;
  }
  if (dy<=dx)
  {
    a=2*dx;
    m=2*dy;

    for (x=x1;x<=x2;x+=xInc)
    {
      LEDPixel(x,y,c);
      d+=m;
      if (d>dx)
      {
        y+=yInc;
        d-=a;
      }
    }
  }
  else
  {
    a=2*dy;
    m=2*dx;

    for (y=y1;y<=y2;y+=yInc)
    {
      LEDPixel(x,y,c);
      d+=m;
      if (d>dy)
      {
        x+=xInc;
        d-=a;
      }
    }
  }
}
*/
// Draw Bitmap on VFD
void LEDBitmap(int x, int y, unsigned char c, PGM_P bm)
{
  int dx,dy,w,h,i,j,bpl,dest,d;

  prog_char *s,*src;
  unsigned char sbit,dbit;

  w=PRG_RDB(bm);
  h=PRG_RDB(bm+1);
  bpl=(w+7)/8;
  if (x+w>MAXX) w=MAXX-x;
  if (y+h>MAXY) h=MAXY-y;
 
/*
  if (display.rotate)
  {
  	
    mr=0;
    for (i=0;i<(w&7);i++) mr=(mr>>1) + 0x80;
    by=(MAXX>>3)-bpl;
    bpc=x&7;
    src =bm+2;
    dest=(x>>3)+(MAXX>>3)*y;
    for (dy=0;dy<h;dy++)
    {
      dbit=0;
      s=src;
      for (dx=0;dx<bpl;dx++)
      {
        sbit=*s;
        if (dx==bpl-1) sbit&=mr;
        t=sbit;
        sbit>>=bpc;
        if (c&1)
          bufred[dest]|=sbit;
        if (c&2)
          bufgreen[dest]|=sbit;
        dbit=t<<=8-bpc;
        dest++;
        if (c&1)
          bufred[dest]|=dbit;
        if (c&2)
          bufgreen[dest]|=dbit;
        s++;
      }
      src+=bpl;
      dest+=by;
    }
  }

  else
  {
  	*/
    src=bm+2;
    dest=x+MAXX*(y>>3);
  
    d=dest; s=src;
  
    for (dx=0;dx<w;dx+=8)
    {
      sbit=0x80;
      for (i=0;(i<8)&&(dx+i<w);i++)
      {
        s=src;
        d=dest;
        dy=0;
        while (dy<h)
        {
          dbit=0x01<<(y&7);
          for ((j=0);(j<8)&&(dy<h);j++)
          {
            if (c&1)
            {
              if (PRG_RDB(s)&sbit)
                bufred[d]|=dbit;
              else
                bufred[d]&=~dbit;  
            }
            if (c&2)
            {
              if (PRG_RDB(s)&sbit)
                bufgreen[d]|=dbit;
              else
                bufgreen[d]&=~dbit;  
            }
            if (dbit<0x80)
              dbit<<=1;
            else
            {
              d+=MAXX;
              dbit=0x01;
            }
            s+=bpl;
            dy++;
          }
        }
        dest++;
        sbit>>=1;
      }
      src++;
    }
  
  
}

// Display a Bitmap centered
void LEDCenteredBitmap(unsigned char c, PGM_P bm)
{
  LEDBitmap((MAXX-PRG_RDB(bm))>>1,(MAXY-PRG_RDB(bm+1))>>1,c,bm);
}

/*
 * fills Display with a random pattern
 */
void LEDRandomfill(int x, int y, int w, int h, unsigned char c, int count)
{
	int i;
	if (!w) w=MAXX;
	if (!h) h=MAXY;
	for (i=0;i<count;i++)
	{
		LEDPixel(x+rand()%w,y+rand()%h,c);
	}
}

/*
 * get pixel color of active screen
 */
u_char LEDGetPixel(int x, int y)
{
	u_char erg=0;
  u_int s;
  if ((x<0)||(x>=MAXX)||(y<0)||(y>=MAXY)) return 0;
  s=x+(y>>3)*MAXX;
  if (screen[s]&(0x01<<(y&0x07))) erg|=1;
  if (screen[s+(BUFSIZE>>1)]&(0x01<<(y&0x07))) erg|=2;
  return erg;
}

/* display a number on 7 segment display */
void LEDNumout(int c, char x)
{
	static int crs;
	char leadingzero=0;
	const char digit[]={0xfc,0x60,0xda,0xf2,0x66,0xb6,0xbe,0xe0,0xfe,0xf6,0xee,0x3e,0x9c,0x7a,0x9e,0x8e};
	if (x!=0xff) crs=x;
	if (c>9999)
	{
		buf7seg[crs++]=0x02;
		buf7seg[crs++]=0x02;
		buf7seg[crs++]=0x02;
		buf7seg[crs++]=0x02;
	}
	else
	{
		if ((leadingzero) || (c>999))
		{
	    buf7seg[crs++]=digit[c/1000]; c%=1000;
	    leadingzero=1;
	  } else buf7seg[crs++]=0;  
		if ((leadingzero) || (c>99))
		{
	    buf7seg[crs++]=digit[c/100]; c%=100;
	    leadingzero=1;
	  } else buf7seg[crs++]=0;  
		if ((leadingzero) || (c>9))
		{
	    buf7seg[crs++]=digit[c/10]; c%=10;
	    leadingzero=1;
	  } else buf7seg[crs++]=0;  
	  buf7seg[crs++]=digit[c];
  }  
}
