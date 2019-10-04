/*
 * Timer2 ISR for discrete LED matrix
 * Multiplex Module, must be called periodically to avoid module destruction 
 * shifts one line of pixels to panel
 */
SIGNAL(SIG_OUTPUT_COMPARE2)
{
  static short x,y=0,z, mask=1, ptr=0,inuse=0,bit;
  unsigned char v;

  if ((y==0)||(y==8))
  {
  	mask=1;
  }
  if (y>7)
    ptr = MAXX;
  else
    ptr=0;    
    
  if (y<16)
  {  
    sbi(LEDPORT,LEDBRIGHT);     // enable panel
  	for (z=0;z<MAXY;z+=16)
  	{
  	  // shift in a red pixel row 
      for (x=0;x<MAXX;x+=8)        // shift all pixel of one line
      {
//        LEDPORT=(1<<LEDBRIGHT);//0;        // inact strobe
        for (bit=0;bit<8;bit++)
        {
          v<<=1;
          if (screen[ptr++] & mask)   // red pixel set?
            v|=1;
        }
  	    outp(v,SPDR); // output one byte of pixels
        while(!(inp(SPSR) & (1<<SPIF)));
      }
      ptr-=MAXX;

  	  // shift in a green pixel row 
      for (x=0;x<MAXX;x+=8)        // shift all pixel of one line
      {
//        LEDPORT=(1<<LEDBRIGHT);//0;        // inact strobe
        for (bit=0;bit<8;bit++)
        {
          v<<=1;
          if (screen[(ptr++)+(BUFSIZE>>1)] & mask) // green pixel set?
            v|=1;
        }
  	    outp(v,SPDR); // output one byte of pixels
        while(!(inp(SPSR) & (1<<SPIF)));
      }
      //ptr-=MAXX;
      ptr+=MAXX;
    }  
    outp(y,SPDR); // output row adress
    while(!(inp(SPSR) & (1<<SPIF)));
    cbi(LEDPORT,LEDBRIGHT);     // disable panel
    sbi(LEDPORT,LEDSTROBE);    // set strobe
    //LEDPORT = (1<<LEDSTROBE); 
    nop();
    //LEDPORT=0;
    cbi(LEDPORT,LEDSTROBE);    // reset strobe
    // we have to wait a little time to stabilize the LED panel
    // so we do something usefull, not to waste CPU time
    // like muxing the 7-segment displays
    Mux7Segm(1);
    sbi(LEDPORT,LEDBRIGHT);     // enable panel
    mask<<=1;                   // shift mask to next line
  }

  y++;
  sei();
  if (y==16)
  {	
    cbi(LEDPORT,LEDBRIGHT);     // disable panel
//    Mux7Segm(0);
  	/* during the 17th cycle blank panel and redraw the screen */
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
  if (y>17) y=0;
}
