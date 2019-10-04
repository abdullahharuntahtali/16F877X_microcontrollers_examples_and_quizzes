/* LED Matrix display driver (Commandline Interpreter)
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
 
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <avr/pgmspace.h>
#include <avr/interrupt.h>
#include <uart_util.h>

#include "application.h"
#include "led.h"
#include "dataflash.h"

#define stricmp strcasecmp

const char help_P[] PROGMEM = "\nList of commands follows\n"
"  PRINT [AT x,y[,w]] [LEFT|CENTERED|RIGHT] [SCROLLED [delay]]\"txt\"\n"
"                              draw text\n"
"  PIXEL x,y[,color]           draw Pixel\n"
"  LINE [x,y] to x,y[,color]   draw line\n"
"  HLINE x,y,l[,color]         draw vertical line\n"
"  VLINE x,y,l[,color]         draw horizontal line\n"
"  RECT x,y,w,h[,color]        draw rectangle\n"
"  FRECT x,y,w,h[,color]       draw filled rectangle\n"
"  CIRCLE x,y,r[,color]        draw circle\n"
"  FCIRCLE x,y,r[,color]       draw filled circle\n"
"  TEXTCOLOR color             set text color\n"
"  LINECOLOR color             set line color\n"
"  COLOR color                 set text and line color\n"
"  FONT BIG|SMALL              select font\n"
"  CLS                         clear display\n" 
"  DRAWDISPLAY [AUTO|MANU]     actualize display or (re)sets autoupdate mode\n"
"  INFO                        show configuration info\n"
"  DIR                         show contents of dataflash\n"
"  RDFLASH                     read dataflash to buffer\n"
"  WRBUFFER                    write buffer to dataflash\n"
"  DELFLASH                    erase dataflash page\n"
"  FREEZE [ON|OFF]             freezes all animations\n"
"  APPS                        list all installed applications\n"
"  START applname              start an application\n"                      
"  QUIT                        end telnet session\n"
"  HELP|?                      display this help\n";

const char crlf[]   PROGMEM ="\n";
const char error0[] PROGMEM ="\nERROR: ";
const char error1[] PROGMEM ="ERROR: Missing parameter\n";
const char error2[] PROGMEM ="ERROR: Wrong parameter\n";
const char error3[] PROGMEM ="ERROR: Cannot load font\n";
const char error4[] PROGMEM ="ERROR: Unknown command\n";  

int txtx=0, txty=0, txtformat=TE_LEFT;
int linex=0, liney=0; 
u_char linecolor=1, txtcolor=1;
char alwaysdraw=1;

char *strpbrk(const char *s1, const char *s2)
{
  const char *scanp;
  int c, sc;

  while ((c = *s1++) != 0)
  {
    for (scanp = s2; (sc = *scanp++) != 0;)
      if (sc == c)
	      return s1-1;
  }
  return 0;
}

size_t strspn(const char *s1, const char *s2)
{
  const char *p = s1, *spanp;
  char c, sc;

 cont:
  c = *p++;
  for (spanp = s2; (sc = *spanp++) != 0;)
    if (sc == c)
      goto cont;
  return (p - 1 - s1);
}

/*
 * check if char is a space or a tab
 * The C standard routine get confused with special characters
 */
int myisspace(char c)
{
  return ((c==' ') || (c==8) || (c=='\n'));
}

/* Remove trailing spaces from string */
void strrtrim(char *s)
{
  int i;
  if (s==NULL) return;
  i=strlen(s)-1;
  while ((i>=0) && (myisspace(s[i])))
    s[i--]=0;
}

/* Remove leading spaces from string */
void strltrim(char *s)
{
  u_int i=0;
  if (s==NULL) return;
  while ((i<strlen(s)) && (myisspace(s[i]))) i++;
  strcpy(s,&s[i]);
}

/* Remove Comments */
void removeComments(char *s)
{
  u_int i=0, str=0;
  if (s==NULL) return;
  while ((i<strlen(s)) && (s[i]))
  {
    if (s[i]=='"')
      str=~str;
    if ((!str) && ((s[i]=='#') || (s[i]=='\'')))
      s[i]=0;
    else
      i++;
  }
}

/* removes comments, leading and trailing spaces from s */
int trimline(char *s)
{
  if (s==NULL) return 0;
  removeComments(s);
  strrtrim(s);
  strltrim(s);
  return(s[0]!=0);
}

/*
 * like strtok but skips string constants embedded in ""
 */
char *strtoken(char *s)
{
  const char b[]=" \n\t,";
  static char *p=NULL,*p2=NULL;
  static char c;
  if (!s)
  {
    if (p) *p=c;
    s=p2;
  }
  if (!(*s)) return NULL;
  if (*s=='"')
  {
    p=s+1;
    for (;;)
    {
      if (!(p=strchr(p,'"'))) return NULL;
      if (*(p+1)!='"')
      {
        p++;
        if (*p)
        {
          if ((p=strpbrk(p,b)))
          {
            p2=&p[strspn(p,b)];
            c=*p;
            if (c=='\n') c=0;
            *p=0;
          }
        }
        return s;
      }
      else
        p+=2;
    }
  }
  else
  {
    if ((p=strpbrk(s,b)))
    {
      p2=&p[strspn(p,b)];
      c=*p;
      if (c=='\n') c=0;
      *p=0;
    }
    else
    {
    	p2=NULL;
      return s;
    }
  }
  return s;
}

/*
 * get a string from a quoted string
 */
char* getString(char *s)
{
  char *p;
  if ((s==NULL) || (*s!='"')) return NULL;
  s++;
  p=s;
  for (;;)
  {
    if (!(p=strchr(p,'"'))) return NULL;
    if (*(p+1)!='"')
    {
      *p=0;
      return s;
    }
    else
    {
      p++;
      strcpy(p,p+1);
    }
  }
  return NULL;
}

/*
 * draw a text string
 */
int cmdPrint(void)
{
  char *par,*t;
  int x,y,w;
  u_char c,sc,f,nl;
  
  nl=1;
  x=txtx;
  y=txty;
  w=0;
  sc=0;
  f=0xff;
  c=txtcolor;
  t=NULL;

  par=strtoken(NULL);
  if (!stricmp(par,"AT"))
  {
    par=strtoken(NULL);
    if (!par) return 3;
    x=atoi(par);
    par=strtoken(NULL);
    if (!par) return 3;
    y=atoi(par);
    par=strtoken(NULL);
  }
  if (par)
  {
    if(isdigit(*par))
    {
      w=atoi(par);
      f=txtformat;
      par=strtoken(NULL);
    }
  }
  if (par)
  {
    if (!stricmp(par,"LEFT"))
    {
      f=TE_LEFT;
      par=strtoken(NULL);
    }
    else
      if (!stricmp(par,"CENTERED"))
      {
        f=TE_CENTER;
        par=strtoken(NULL);
      }
      else
        if (!stricmp(par,"RIGHT"))
        {
          f=TE_RIGHT;
          par=strtoken(NULL);
        }
        
    if (!stricmp(par,"SCROLLED"))
    {
    	sc=1;
    	par=strtoken(NULL);
    }  
    if ((par) &&  (*par!='"'))
    {
    	f+=atoi(par)<<4;
    	par=strtoken(NULL);
    }	
    if (par)
    {
      if (*par=='"')
      {
        if ((*(par+strlen(par)-1))==';') nl=0;
        t=getString(par);
      }
      else return 4;
    }
  }

  if (t)
  {
    if (f==0xff)
      LEDStr(x,y,c,t);
    else
    {
    	if (sc)
        LEDSStr(x,y,w,f,c,t);
      else  
        LEDFStr(x,y,w,f,c,t);
    }
  }
  if (nl)
  {
    txtx=0;
    txty+=LEDGetStrHeight();
  }
  else
  {
    txtx+=LEDGetStrLength(t);
    if (txtx>MAXX)
    {
      txtx=0;
      txty+=LEDGetStrHeight();
    }
  }
  return 0;
}

/*
 * draw a pixel
 */
int cmdPixel(void)
{
  int x,y;
  u_char c;
  char *par;

  c=linecolor;
  x=linex;
  y=liney;

  par=strtoken(NULL);
  if (!par) return 3;
  x=atoi(par);
  par=strtoken(NULL);
  if (!par) return 3;
  y=atoi(par);
  par=strtoken(NULL);
  LEDPixel(x,y,c);
  return 0;
}

/*
 * draw a line
 */
int cmdLine(void)
{
  int x1,y1,x2,y2;
  u_char c;
  char *par;

  c=linecolor;
  x1=linex;
  y1=liney;

  par=strtoken(NULL);
  if (stricmp(par,"TO"))
  {
    if (!par) return 3;
    x1=atoi(par);
    par=strtoken(NULL);
    if (!par) return 3;
    y1=atoi(par);
    par=strtoken(NULL);
  }
  if ((par) && (!stricmp(par,"TO")))
  {
    par=strtoken(NULL);
    if (!par) return 3;
    x2=atoi(par);
    par=strtoken(NULL);
    if (!par) return 3;
    y2=atoi(par);
    par=strtoken(NULL);
  }
  else
  {
    x2=x1;
    y2=y1;
    x1=linex;
    y1=liney;
  }
  if (par) c=atoi(par);
  linex=x2;
  liney=y2;

  if (x1==x2)
    LEDVLine(x1,y1,y2-y1,c);
  else
    if (y1==y2)
      LEDHLine(x1,y1,x2-x1,c);
    else
      LEDLine(x1,y1,x2,y2,c);
  return 0;
}

/*
 * draw a horizontal line
 */
int cmdHLine(void)
{
  int x,y,l;
  u_char c;
  char *par;

  c=linecolor;

  par=strtoken(NULL);
  if (!par) return 3;
  x=atoi(par);
  par=strtoken(NULL);
  if (!par) return 3;
  y=atoi(par);
  par=strtoken(NULL);
  if (!par) return 3;
  l=atoi(par);
  par=strtoken(NULL);
  if (par) c=atoi(par);

  LEDHLine(x,y,l,c);
  return 0;
}

/*
 * draw a vertical line
 */
int cmdVLine(void)
{
  int x,y,l;
  u_char c;
  char *par;

  c=linecolor;

  par=strtoken(NULL);
  if (!par) return 3;
  x=atoi(par);
  par=strtoken(NULL);
  if (!par) return 3;
  y=atoi(par);
  par=strtoken(NULL);
  if (!par) return 3;
  l=atoi(par);
  par=strtoken(NULL);
  if (par) c=atoi(par);

  LEDVLine(x,y,l,c);
  return 0;
}

/*
 * draw a circle
 */
int cmdCircle(void)
{
  int x,y,r;
  u_char c;
  char *par;

  c=linecolor;
  par=strtoken(NULL);
  if (!par) return 3;
  x=atoi(par);
  par=strtoken(NULL);
  if (!par) return 3;
  y=atoi(par);
  par=strtoken(NULL);
  if (!par) return 3;
  r=atoi(par);
  par=strtoken(NULL);
  if (par)
    c=atoi(par);
  LEDCircle(x,y,r,c);
  return 0;
}

/*
 * draw a filled circle
 */
int cmdFCircle(void)
{
  int x,y,r;
  u_char c;
  char *par;

  c=linecolor;
  par=strtoken(NULL);
  if (!par) return 3;
  x=atoi(par);
  par=strtoken(NULL);
  if (!par) return 3;
  y=atoi(par);
  par=strtoken(NULL);
  if (!par) return 3;
  r=atoi(par);
  par=strtoken(NULL);
  if (par)
    c=atoi(par);
  LEDFCircle(x,y,r,c);
  return 0;
}

/*
 * draw a rectangle
 */
int cmdRect(void)
{
  int x,y,w,h;
  u_char c;
  char *par;

  c=linecolor;
  par=strtoken(NULL);
  if (!par) return 3;
  x=atoi(par);
  par=strtoken(NULL);
  if (!par) return 3;
  y=atoi(par);
  par=strtoken(NULL);
  if (!par) return 3;
  w=atoi(par);
  par=strtoken(NULL);
  if (!par) return 3;
  h=atoi(par);
  par=strtoken(NULL);
  if (par)
    c=atoi(par);
  LEDRectangle(x,y,w,h,c);
  return 0;
}

/*
 * Draw a filled rectangle
 */
int cmdFRect(void)
{
  int x,y,w,h;
  u_char c;
  char *par;

  c=linecolor;
  par=strtoken(NULL);
  if (!par) return 3;
  x=atoi(par);
  par=strtoken(NULL);
  if (!par) return 3;
  y=atoi(par);
  par=strtoken(NULL);
  if (!par) return 3;
  w=atoi(par);
  par=strtoken(NULL);
  if (!par) return 3;
  h=atoi(par);
  par=strtoken(NULL);
  if (par)
    c=atoi(par);
  LEDFRectangle(x,y,w,h,c);
  return 0;
}

/*
 * sets text color
 */
int cmdTextcolor(void)
{
  char *par;

  par=strtoken(NULL);
  if (!par) return 3;
  txtcolor=(u_char)atoi(par);
  return 0;
}

/*
 * sets line color
 */
int cmdLinecolor(void)
{
  char *par;

  par=strtoken(NULL);
  if (!par) return 3;
  linecolor=(u_char)atoi(par);
  return 0;
}

/*
 * sets line AND textcolor
 */
int cmdColor(void)
{
  char *par;

  par=strtoken(NULL);
  if (!par) return 3;
  txtcolor=linecolor=(u_char)atoi(par);
  return 0;
}

/*
 * loads and activates a display font
 */
int cmdFont(void)
{
	/*
  char *par;

  par=strtoken(NULL);
  if (!par) return 3;
  if (!stricmp(par,"SMALL"))
    LEDSelectFont(smallfont);
  else
    LEDSelectFont(bigfont);
*/    
  return 0;
}

/*
 * clear display
 */
int cmdCls(void)
{
  LEDClear();
  txtcolor=1;
  linecolor=1;
  txtx=txty=linex=liney=0;
  txtformat=TE_LEFT;
  return 0;
}

/*
 * actualize display
 */
int cmdDraw(void)
{
	char *par;
	
	par=strtoken(NULL);
	if (!stricmp(par,"AUTO"))
		alwaysdraw=1;
	else
	  if (!stricmp(par,"MANU"))
	    alwaysdraw=0;
	  else
      LEDDraw();
  return 0;
}
/*
 * Format dataflash
 */
int cmdWrBuffer(void)
{
	const char str[]="The Quick Brown Fox jumps over the Lazy Dog";
  Buffer_Write_Str(1,0,strlen(str),str);
  return 0;
}

/*
 * Format dataflash
 */
int cmdWrFlash(void)
{
  Buffer_To_Page(1,0);
  return 0;
}

/*
 * Format dataflash
 */
int cmdDelFlash(void)
{
  Erase_Page(0);
  return 0;
}

/*
 * Format dataflash
 */
int cmdRdFlash(void)
{
  Page_To_Buffer(0,1);
  return 0;
}


/*
 * display contents of dataflash
 */
int cmdDir(void)
{
	unsigned int adr;
	unsigned char x,y,c;
	char line[40];
  DF_get_type(line);
  printf("\nDataflash type: %s\n",line);
  adr=0;
  for (y=0;y<16;y++)
  {
  	printf("%04x : ",adr);
    for (x=0;x<16;x++) line[x]=Buffer_Read_Byte(1,adr+x);
    for (x=0;x<16;x++) printf("%02x ",line[x]);
    for (x=0;x<16;x++)
    {
    	c=line[x];
    	putchar(((c>=0x20)&&(c<128))?c:'.');
    }
    printf("\r\n");
    adr+=16;
  }
	//showConfigInfo(stream);
  return 0;
}

/*
 * display configuration
 */
int cmdInfo(void)
{
	char line[40];
  DF_get_type(line);
  printf("\nDataflash type: %s",line);
	//showConfigInfo(stream);
  return 0;
}

/*
 * display help 
 */
int cmdHelp(void)
{
	puts_P(help_P);
  return 0;
}

/*
 * quit
 */
int cmdQuit(void)
{
  return 1;
}
  
/*
 * quit
 */
int cmdFreeze(void)
{
	char *par;
	
	par=strtoken(NULL);
	if (!stricmp(par,"ON"))
		animation=0;
	else
	  if (!stricmp(par,"OFF"))
	    animation=1;
	  else
      animation=0;
  return 0;
}

/*
 * list all applications
 */
int cmdApps(void)
{
	int i=0;
	puts_P(PSTR("\nInstalled applications:"));
	while ((appl[i]) && (i<MAXAPPLICATIONS))
	{
		printf_P(PSTR("%2i. "),i+1);
		puts_P(appl[i]->name);
		i++;
	}
	return 0;
}

/*
 * start an application
 */
int cmdStart(void)
{
	int i=0;
	char *par;
  par=strtoken(NULL);
  if (!par) return 3;
	printf_P(PSTR("\nStarting %s\n"),par);
	while ((appl[i]) && (i<MAXAPPLICATIONS))
	{
		if (!strcasecmp_P(par,appl[i]->name))
		{
			if (appl[i]->appl_init)
			{
				LEDClear();
				appl[i]->appl_init();
				LEDClear();
				i=254;
			}
			else
			  puts_P(PSTR("Error: Application has no startup call"));
		}	
		i++;
	}
	if (i!=255) puts_P(PSTR("Error: Application not found"));
	return 0;
}

typedef struct
{
  const char *cmd;
  int (*func)(void);
} TCOMMAND;

TCOMMAND commands[]=
{
  {"PRINT",cmdPrint},
  {"PIXEL" ,cmdPixel},
  {"LINE" ,cmdLine},
  {"HLINE" ,cmdHLine},
  {"VLINE" ,cmdVLine},
  {"CIRCLE", cmdCircle},
  {"FCIRCLE", cmdFCircle},
  {"RECT", cmdRect},
  {"FRECT", cmdFRect},
  {"TEXTCOLOR",cmdTextcolor},
  {"LINECOLOR",cmdLinecolor},
  {"COLOR",cmdColor},
  {"FONT",cmdFont},
  {"DRAWDISPLAY",cmdDraw},
  {"CLS",cmdCls},
  {"DIR",cmdDir},
  {"WRBUFFER",cmdWrBuffer},
  {"WRFLASH",cmdWrFlash},
  {"RDFLASH",cmdRdFlash},
  {"DELFLASH",cmdDelFlash},
  {"HELP",cmdHelp},
  {"INFO",cmdInfo},
  {"FREEZE",cmdFreeze},
  {"APPS",cmdApps},
  {"START",cmdStart},
  {"?",cmdHelp},
  {"QUIT",cmdQuit},
  {NULL ,NULL}
};

/*
 * process a command line
 */
int Processline(char *line)
{
  short i,err=0;
  char *cmd;
  if (!trimline(line)) return 0;
  cmd=strtoken(line);
  i=0;
  while (commands[i].cmd && strcasecmp(cmd,commands[i].cmd)) i++;
  if (commands[i].cmd) 
  {
    err=commands[i].func();
    if ((!err) && alwaysdraw) LEDDraw();
  }
  else
    err=6;
  if (err>2)
  {
  	puts_P(crlf);
  	puts(line);
  }
  switch(err)
  {
    case 3: puts_P(error1); break;
    case 4: puts_P(error2); break;
    case 5: puts_P(error3); break;
	  case 6: puts_P(error4); break;
  }
  return err;
}

