#BYTE TRISA=0x85
#BYTE PORTA=0x5
#BYTE STATUS=0x3
#define RP0  5
#define C 0


// The following are standard 1-Wire routines.
void make_ds1820_high_pin(int sensor)
{
   TRISA = 0xff;
}

void make_ds1820_low_pin(int sensor)
{
   PORTA = 0x00;
   TRISA = 0xff & (~(0x01 << sensor));
}


// delay routines
void delay_10us(int t)
{
#asm
            BCF STATUS, RP0
 DELAY_10US_X:
            CLRWDT
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            DECFSZ t, F
            GOTO DELAY_10US_X
#endasm
}

void delay_ms(long t)	// delays t millisecs
{
   do
   {
     delay_10us(100);
   } while(--t);
}

void init_ds1820(int sensor)
{
   make_ds1820_high_pin(sensor);
   make_ds1820_low_pin(sensor);
   delay_10us(50);

   make_ds1820_high_pin(sensor);
   delay_10us(50);
}

int read_ds1820_one_byte(int sensor)
{
   int n, i_byte, temp, mask;
   mask = 0xff & (~(0x01<<sensor));
   for (n=0; n<8; n++)
   {
      PORTA=0x00;
      TRISA=mask;
      TRISA=0xff;
#asm
      CLRWDT
      NOP
      NOP
#endasm
      temp=PORTA;
      if (temp & ~mask)
      {
        i_byte=(i_byte>>1) | 0x80;	// least sig bit first
      }
      else
      {
        i_byte=i_byte >> 1;
      }
      delay_10us(6);
   }
   return(i_byte);
}

void write_ds1820_one_byte(int d, int sensor)
{
   int n, mask;
   mask = 0xff & (~(0x01<<sensor));
   for(n=0; n<8; n++)
   {
      if (d&0x01)
      {
         PORTA=0;
         TRISA=mask;		// momentary low
         TRISA=0xff;
         delay_10us(6);
      }

      else
      {
          PORTA=0;
          TRISA=mask;
	  delay_10us(6);
          TRISA=0xff;
      }
      d=d>>1;
   }
}

int16 read_sensor(byte sensor)
{	  
	int16 t1;
	int buff[9], n,temp,temp_dec;
	
      init_ds1820(sensor);
      write_ds1820_one_byte(0xcc, sensor); 
      write_ds1820_one_byte(0x44, sensor); 
      while (read_ds1820_one_byte(sensor)==0xff); 
      init_ds1820(sensor);
      write_ds1820_one_byte(0xcc, sensor);
      write_ds1820_one_byte(0xbe, sensor);
      for (n=0; n<9; n++) {
         buff[n]=read_ds1820_one_byte(sensor);  // read DS1820
      }
      temp=buff[0]>>1;
      if ((buff[0] & 0x1)==1)
         temp_dec=5;
      else
         temp_dec=0;
     
     t1=temp;
     t1=(t1<<8) | temp_dec;   // 0xTT0D
     return(t1);
}
