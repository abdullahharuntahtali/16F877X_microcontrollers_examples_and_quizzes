/*
 * Timer2 ISR for discrete LED matrix
 * Multiplex Module, must be called periodically to avoid module destruction 
 * shifts one line of pixels to panel
 */
SIGNAL(SIG_OUTPUT_COMPARE2)
{
  static short x,y=0,z, mask=1, ptr=0,inuse=0;


  if ((y==0)||(y==8))
  {
  mask=1;
  }
  if (y>7)
    ptr=MAXX;
  else 
    ptr=0;  
  if (y<16)
  {  
    for (z=0;z<MAXY;z+=16)
    { 
      for (x=0;x<MAXX;x++)        // shift all pixel of one line
      {
        LEDPORT=1<<LEDCLOCK;        // inact strobe
        if (screen[ptr] & mask)   // red pixel set?
          sbi(LEDPORT,LEDRED);
        if (screen[ptr+(BUFSIZE>>1)] & mask) // green pixel set?
          sbi(LEDPORT,LEDGREEN);
        ptr++;  
        cbi(LEDPORT,LEDCLOCK);             // set clock
        sbi(LEDPORT,LEDCLOCK);             // again to make the pulse longer 
        sbi(LEDPORT,LEDCLOCK);
      }
      ptr+=MAXX;
    } 
    LEDPORT = (1<<LEDBRIGHT)+(1<<LEDCLOCK);
    LEDPORT = (1<<LEDBRIGHT)+(1<<LEDSTROBE)+(1<<LEDCLOCK);
    LEDMUX = y<<4;
    LEDPORT = (1<<LEDBRIGHT)+(1<<LEDCLOCK);
    // we have to wait a little time to stabilize the LED panel
    // so we do something usefull, not to waste CPU time
    // like muxing the 7-segment displays
    Mux7Segm();
    LEDPORT = 1<<LEDCLOCK;            // enable panel
    mask<<=1;               // shift mask to next line
  }
  else
    LEDPORT=(1<<LEDBRIGHT)+(1<<LEDCLOCK); // disable panel
  y++;
  if (y>=17) 
    y=0;
    
  if (y==16)
  { 
    if (altered)
    {
      memcpy(screen,buffer,BUFSIZE);
      altered=0;
    }
  
    if (!inuse)                // Animation routine already running, so skip
    {
      sei();
      inuse=1;
      LEDAnimate();
      inuse=0;
    }
  }
  
}
