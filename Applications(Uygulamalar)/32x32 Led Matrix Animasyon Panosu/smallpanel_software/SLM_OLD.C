/*
 * Timer2 ISR for SLM1606M modules
 * Multiplex Module, must be called periodically to avoid module destruction 
 * shifts one line of pixels to panel
 */
SIGNAL(SIG_OUTPUT_COMPARE2)
{
  static short x=0,y=0,p=0,m=0xff,inuse=0;
  static u_char bits,red0,green0,red1,green1;

  Mux7Segm(1);
  
  if (!y)
  {
  	/* toggle Reset pin to reset counter */
    sbi(LEDEPORT,LEDRESET);
    cbi(LEDEPORT,LEDRESET);
    if ((altered==2) && (m==0xff)) 
    {
    	m=0;
      p=0;
    }    
  }
  	
  if (m!=0xff)
  {
    x=0;
//   	p+=MAXX;
p+=15;
  	red0  =screen[p];
   	green0=screen[p+(BUFSIZE>>1)];
  	red1  =screen[p+16];
   	green1=screen[p+(BUFSIZE>>1)+16];
//   	sbi(LEDEPORT,LEDBRIGHT);
  	sbi(LEDEPORT,m?LEDSEL1:LEDSEL0);
    do
    {
    	bits=0;
//  	  bits=BV(m?LEDSEL1:LEDSEL0);
  	  if (red0&0x01)   bits|=BV(LEDRED0);
  	  if (green0&0x01) bits|=BV(LEDGREEN0);
  	  if (red1&0x01)   bits|=BV(LEDRED1);
  	  if (green1&0x01) bits|=BV(LEDGREEN1);
      outp(bits,LEDPORT);  
      sbi(LEDEPORT,LEDCLOCK);
      red0  >>=1;
      green0>>=1;
      red1  >>=1;
      green1>>=1;
      cbi(LEDEPORT,LEDCLOCK);
      x++;
    } while (x<8);
//    cbi(LEDEPORT,m?LEDSEL1:LEDSEL0);
//    p-=MAXX;

p+=MAXX;
    x=0;
  	red0  =screen[p];
   	green0=screen[p+(BUFSIZE>>1)];
  	red1  =screen[p+16];
   	green1=screen[p+(BUFSIZE>>1)+16];
//  	sbi(LEDEPORT,m?LEDSEL1:LEDSEL0);
    do
    {
    	bits=0;
//  	  bits=BV(m?LEDSEL1:LEDSEL0);
  	  if (red0&0x01)   bits|=BV(LEDRED0);
  	  if (green0&0x01) bits|=BV(LEDGREEN0);
  	  if (red1&0x01)   bits|=BV(LEDRED1);
  	  if (green1&0x01) bits|=BV(LEDGREEN1);
      outp(bits,LEDPORT);  
      sbi(LEDEPORT,LEDCLOCK);
      red0  >>=1;
      green0>>=1;
      red1  >>=1;
      green1>>=1;
      cbi(LEDEPORT,LEDCLOCK);
      x++;
    } while (x<8);
    p-=MAXX;
p-=15;
    p--;
    cbi(LEDEPORT,m?LEDSEL1:LEDSEL0);

//    outp(0x00,LEDMUX);
//    outp(0x00,LEDPORT);
    y++;
    if (y==16)
    {
    	p+=MAXX+MAXX+MAXX-16;
      y=0;
      m++;
      if (m==2) 
      {
        altered=0;
  	    m=0xff;
      }
    }
  }
  else
  {
  	for (x=0;x<16;x++)
  	{ 
  		sbi(LEDEPORT,LEDCLOCK);
  		cbi(LEDEPORT,LEDCLOCK);
  	}
	  y++;
	  if (y==16)
	  {
	  	y=0;
 	    if (!inuse)                // Animation routine already running, so skip
 	    {
        inuse=1;
 	      sei();
/* 	      
    		if (altered) 
     		{  
   	  		memcpy(screen,buffer,BUFSIZE);
   		  	altered=0;
   		  	m=0;
          p=0;
   		  }
 	      LEDAnimate();
 	      inuse=0;
*/ 	      

     		if (altered) 
     		{  
   	  		memcpy(screen,buffer,BUFSIZE);
      	  m=0;
          p=0;

   		  }
 	      LEDAnimate();
 		  	if (altered) altered=2;
 	      inuse=0;
 	      
 	    }
	  }	
  }
}
