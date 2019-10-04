/*
 * Timer2 ISR for SLM1606M modules
 * Multiplex Module, must be called periodically to avoid module destruction 
 * shifts one line of pixels to panel
 */
SIGNAL(SIG_OUTPUT_COMPARE2)
{
  static short x=0,y=0,p=0,m=0xff,inuse=0;
  static short mask=1,bits;

  Mux7Segm();

  if (!y)
  {
  	/* toggle Reset pin to reset counter */
    sbi(LEDPORT,LEDRESET);
//    nop();nop();nop();
    cbi(LEDPORT,LEDRESET);
//    nop();nop();nop();
    
    if (altered && (m==0xff)) 
    {
    	m=0;
      p=0;
    	mask=1;
    }    
  }
  	
  if (m!=0xff)
  {
//  	m=0;
#if defined(LED138)
    outp(m<<4,LEDMUX);
#else
    if (m)
      outp(0xa0,LEDMUX);
    else
      outp(0x50,LEDMUX);  
      
      //outp((1<<m)<<4,LEDMUX);
#endif    
      /*sbi(LEDPORT,LEDBRIGHT);*/
    for (x=0;x<16;x++)
    {
  	  bits=BV(LEDBRIGHT);
      if (screen[p]&mask) bits|=BV(LEDRED0);
      if (screen[p+(BUFSIZE>>1)]&mask) bits|=BV(LEDGREEN0);
      if (screen[p+(MAXX<<1)]&mask) bits|=BV(LEDRED1);
      if (screen[p+(BUFSIZE>>1)+(MAXX<<1)]&mask) bits|=BV(LEDGREEN1);
      outp(bits,LEDPORT);  
//      nop();
      sbi(LEDPORT,LEDCLOCK);
//      nop();
      cbi(LEDPORT,LEDCLOCK);
      p++;
    }
    cbi(LEDPORT,LEDBRIGHT);
   	p-=16;
    mask<<=1;
    y++;
    if (y==8)
    {
 	    mask=1;
   	  p+=MAXX;
    }
    if (y==16)
    {
      y=0;
      p-=MAXX;
      p+=16;
      mask=1;
      m++;
      if (m==2) 
      {
        altered=0;
  	    m=0xff;
#if defined(LED138)
        outp(4<<4,LEDMUX);
#else
        outp(0x00,LEDMUX);
        //outp((1<<4)<<4,LEDMUX);
#endif    
      }
    }
  }
  else
  {
  	for (x=0;x<16;x++)
  	{ 
  		sbi(LEDPORT,LEDCLOCK);
  		cbi(LEDPORT,LEDCLOCK);
  	}
	  y++;
	  if (y==16)
	  {
	  	y=0;
 	    if (!inuse)                // Animation routine already running, so skip
 	    {
        inuse=1;
 	      sei();
     		if (altered) 
     		{  
   	  		memcpy(screen,buffer,BUFSIZE);
   		  	altered=0;
      	  m=0;
          p=0;
      	  mask=1;
   		  }
 	      LEDAnimate();
 	      inuse=0;
 	    }
	  }	
  }
}
