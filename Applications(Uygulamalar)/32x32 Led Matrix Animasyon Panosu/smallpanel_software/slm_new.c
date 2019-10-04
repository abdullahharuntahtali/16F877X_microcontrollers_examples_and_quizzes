/*
 * Timer2 ISR for SLM1606M modules
 * Multiplex Module, must be called periodically to avoid module destruction 
 * shifts one line of pixels to panel
 */
SIGNAL(SIG_OUTPUT_COMPARE2)
{
  static short x=0,y=0,p=0,m=0xff,inuse=0;
  static short mask=1,bits;

  Mux7Segm(1);

  if (!y)
  {
  	/* toggle Reset pin to reset counter */
    sbi(LEDEPORT,LEDRESET);
    cbi(LEDEPORT,LEDRESET);
    
    if (altered && (m==0xff)) 
    {
    	m=0;
      p=47; // p=1;
    	mask=1;
    }    
  }
  	
  if (m!=0xff)
  {
    sbi(LEDEPORT,m?LEDSEL1:LEDSEL0);  
    for (x=0;x<16;x++)
    {
  	  bits=0;    //BV(m?LEDSEL1:LEDSEL0);
      if (screen[p]&mask) bits|=BV(LEDRED0);
      if (screen[p+(BUFSIZE>>1)]&mask) bits|=BV(LEDGREEN0);
      if (screen[p+16]&mask) bits|=BV(LEDRED1);
      if (screen[p+(BUFSIZE>>1)+16]&mask) bits|=BV(LEDGREEN1);
      outp(bits,LEDPORT);
      sbi(LEDEPORT,LEDCLOCK);
      cbi(LEDEPORT,LEDCLOCK);
      p--; //p++;
    }
    cbi(LEDEPORT,m?LEDSEL1:LEDSEL0);
//    cbi(LEDPORT,LEDBRIGHT);
   	p+=16; //p-=16;
    mask>>=1;
    y++;
    if (y==8)
    {
 	    mask=0x80;
   	  p-=MAXX;
    }
    if (y==16)
    {
      y=0;
      p+=MAXX+MAXX+MAXX;
      mask=0x80;
      m++;
      if (m==2) 
      {
        altered=0;
  	    m=0xff;
        outp(0x00,LEDEPORT);
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
     		if (altered) 
     		{  
   	  		memcpy(screen,buffer,BUFSIZE);
   		  	altered=0;
      	  m=0;
          p=47; //p=0;
      	  mask=0x80;
   		  }
 	      LEDAnimate();
 	      inuse=0;
 	    }
	  }	
  }
}
