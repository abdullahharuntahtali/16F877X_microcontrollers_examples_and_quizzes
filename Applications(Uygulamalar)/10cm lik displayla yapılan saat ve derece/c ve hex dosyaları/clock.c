//================================================
// DIGITAL thermometer project
// Compiler : CCS V 3.222
//================================================

#include <16F628.h>
#use delay(clock=4000000)
#fuses NOWDT,XT, NOPUT, PROTECT,NOLVP,NOMCLR,NOLVP  // for 628
//#fuses NOWDT,XT, NOPUT, PROTECT    // for 84a
#include <ds1820.c>
#define DS1307_SDA  PIN_A2
#define DS1307_SCL  PIN_A3
#use i2c(master, sda=DS1307_SDA, scl=DS1307_SCL)


byte CONST MAP1[10]={0xFA,0x30,0xD9,0x79,0X33,0x6B,0xEB,0x38,0xFB,0x7B};
byte CONST MAP2[10]={0xDE,0x18,0xCD,0x5D,0X1B,0x57,0xD7,0x1c,0xDF,0x5F};
byte sec,min,hour;
byte fs_flag;

#define EXP_OUT_LATCH   PIN_B7
#define EXP_OUT_CLOCK   PIN_B3
#define EXP_OUT_DO      PIN_B5
#define EXP_OUT_CLEAR   PIN_B6
#define colon           PIN_B4
#define DEC             PIN_B1
#define INC             PIN_B2


   BYTE buff[9], sensor, n,temp,temp_dec,RES;
   BYTE D_SHIFT;


//==========================
// initial DS1307
//==========================
void init_DS1307()
{
   output_float(DS1307_SCL);
   output_float(DS1307_SDA);
}
//==========================
// write data one byte to
// DS1307
//==========================
void write_DS1307(byte address, BYTE data)
{
   short int status;
   i2c_start();
   i2c_write(0xd0);
   i2c_write(address);
   i2c_write(data);
   i2c_stop();
   i2c_start();
   status=i2c_write(0xd0);
   while(status==1)
   {
      i2c_start();
      status=i2c_write(0xd0);
   }
}
//==========================
// read data one byte from DS1307
//==========================
BYTE read_DS1307(byte address)
{
   BYTE data;
   i2c_start();
   i2c_write(0xd0);
   i2c_write(address);
   i2c_start();
   i2c_write(0xd1);
   data=i2c_read(0);
   i2c_stop();
   return(data);
}

//=================================
// WRITE DATA TO 6B595
//=================================
void write_expanded_outputs(BYTE *D)
{
  BYTE i;

  for(i=1;i<=8;++i)
  {  // Clock out bits from the eo array
    if ((D & 0x80)==0)
      output_low(EXP_OUT_DO);
    else
      output_high(EXP_OUT_DO);

   D=D<<1;
   output_high(EXP_OUT_CLOCK);
   output_low(EXP_OUT_CLOCK);
  }

}

//=================================
// show temperature
//=================================
void show_temp()
{
   int8 count;

    output_high(colon);

    for (count=0;count<8;count++)  // blink temperature 8 times
    {
      output_low(EXP_OUT_LATCH);
      sensor=0;   // DS1820 CONNECT TO PIN A0
      init_ds1820(sensor);
      write_ds1820_one_byte(0xcc, sensor);  // skip ROM
      write_ds1820_one_byte(0x44, sensor);  // perform temperature conversion
      while (read_ds1820_one_byte(sensor)==0xff); // wait for conversion complete
      init_ds1820(sensor);
      write_ds1820_one_byte(0xcc, sensor);  // skip ROM
      write_ds1820_one_byte(0xbe, sensor);  // read the result

      for (n=0; n<9; n++)     // read 9 bytes but, use only one byte
      {
         buff[n]=read_ds1820_one_byte(sensor);  // read DS1820
      }
      temp=buff[0]>>1;

      if ((buff[0] & 0x1)==1)
         temp_dec=5;
      else
         temp_dec=0;

      D_SHIFT=0xC6;
      write_expanded_outputs(D_SHIFT);

      D_SHIFT=0x0F;  // show 'C
      write_expanded_outputs(D_SHIFT);

      RES=TEMP%10;
      D_SHIFT=MAP1[RES];
      write_expanded_outputs(D_SHIFT);

      RES=TEMP/10;
      if (RES==0)
        D_SHIFT=0x00;
      else
        D_SHIFT=MAP1[RES];

      write_expanded_outputs(D_SHIFT);
      output_high(EXP_OUT_LATCH);
      delay_ms(500);


    }
}

//=================================
// show time 1
//=================================
void show_time1()
{
   byte m;
         output_low(EXP_OUT_LATCH);
         output_low(colon);
         min=read_ds1307(1);
         hour=read_ds1307(2);

         m=min & 0x0F;
         D_SHIFT=MAP2[m];
         write_expanded_outputs(D_SHIFT);
         swap(min);
         m=min & 0x07;
         D_SHIFT=MAP2[m];
         write_expanded_outputs(D_SHIFT);

         m=hour & 0x0F;
         D_SHIFT=MAP1[m];
         write_expanded_outputs(D_SHIFT);
         swap(hour);
         m=hour & 0x03;
         D_SHIFT=MAP1[m];
         write_expanded_outputs(D_SHIFT);
         output_high(EXP_OUT_LATCH);
         swap(min);
         swap(hour);
}

//=================================
// check switch
//=================================
void check_sw()
{
byte j;
   if (fs_flag!=0)
   {
      if (!input(INC))
      {
         if (fs_flag==1)
         {
            min=read_ds1307(1);
            min++;
            j=min & 0x0F;
            if (j>=0x0A) min=min+0x06;
            if (min>=0x60) min=0;
            write_ds1307(1,min);
         }
         else
         {
            hour=read_ds1307(2);
            hour++;
            j=hour & 0x0F;
            if (j>=0x0A) hour=hour+0x06;
            if (hour>=0x24) hour=0;
            write_ds1307(2,hour);
         }
       show_time1();
      }
      if (!input(DEC))
      {
         if (fs_flag==1)
         {
            min=read_ds1307(1);
            if (min!=0)
            {
               min--;
               j=min & 0x0F;
               if (j>=0x0A) min=min-0x06;
            }
            else min=0x59;
            write_ds1307(1,min);

         }
         else
         {
            hour=read_ds1307(2);
            if (hour!=0)
            {
               hour--;
               j=hour & 0x0F;
               if (j>=0x0A) hour=hour-0x06;
            }
            else hour=0x23;
            write_ds1307(2,hour);
         }
       show_time1();
      }
   }
}



//=================================
// show time
//=================================
void show_time(byte fs)
{
   byte m;

         output_low(EXP_OUT_LATCH);
         output_low(colon);
         min=read_ds1307(1);
         hour=read_ds1307(2);

         m=min & 0x0F;
         D_SHIFT=MAP2[m];
         write_expanded_outputs(D_SHIFT);
         swap(min);
         m=min & 0x07;
         D_SHIFT=MAP2[m];
         write_expanded_outputs(D_SHIFT);

         m=hour & 0x0F;
         D_SHIFT=MAP1[m];
         write_expanded_outputs(D_SHIFT);
         swap(hour);
         m=hour & 0x03;
         D_SHIFT=MAP1[m];
         write_expanded_outputs(D_SHIFT);

         output_high(EXP_OUT_LATCH);

         swap(min);
         swap(hour);

         delay_ms(100);
         check_sw();
         delay_ms(100);
         check_sw();
         delay_ms(100);
         check_sw();
         delay_ms(100);
         check_sw();
         delay_ms(100);
         check_sw();
         //delay_ms(500);

         if (fs==0)
         {
            output_high(colon);
            //delay_ms(500);
         }
         else
         {
            if (fs==1)
            {
               output_high(colon);
               output_low(EXP_OUT_LATCH);

               D_SHIFT=0x00;
               write_expanded_outputs(D_SHIFT);

               D_SHIFT=0x00;
               write_expanded_outputs(D_SHIFT);

               m=hour & 0x0F;
               D_SHIFT=MAP1[m];
               write_expanded_outputs(D_SHIFT);
               swap(hour);
               m=hour & 0x03;
               D_SHIFT=MAP1[m];
               write_expanded_outputs(D_SHIFT);

               output_high(EXP_OUT_LATCH);
               //delay_ms(500);
            }
            else
            {
               output_high(colon);
               output_low(EXP_OUT_LATCH);

               m=min & 0x0F;
               D_SHIFT=MAP2[m];
               write_expanded_outputs(D_SHIFT);
               swap(min);
               m=min & 0x07;
               D_SHIFT=MAP2[m];
               write_expanded_outputs(D_SHIFT);

               D_SHIFT=0x00;
               write_expanded_outputs(D_SHIFT);

               D_SHIFT=0x00;
               write_expanded_outputs(D_SHIFT);

               output_high(EXP_OUT_LATCH);
               //delay_ms(500);
            }
         }

         delay_ms(100);
         check_sw();
         delay_ms(100);
         check_sw();
         delay_ms(100);
         check_sw();
         delay_ms(100);
         check_sw();
         delay_ms(100);
         check_sw();

}

#int_EXT
void EXT_isr()
{
   fs_flag++;
   if (fs_flag>=3) fs_flag=0;
   delay_ms(100);
}


//=====================================
// main program start here
//=====================================
void main(void)
{
byte u;
   delay_ms(5);
   port_b_pullups(true);
   output_low(EXP_OUT_CLEAR);
   delay_us(10);
   output_high(EXP_OUT_CLEAR);

   for(RES=0;RES<80;RES++)
   {
      sensor=0;   // DS1820 CONNECT TO PIN A0
      init_ds1820(sensor);
      write_ds1820_one_byte(0xcc, sensor);  // skip ROM
      write_ds1820_one_byte(0x44, sensor);  // perform temperature conversion
      while (read_ds1820_one_byte(sensor)==0xff); // wait for conversion complete
      init_ds1820(sensor);
      write_ds1820_one_byte(0xcc, sensor);  // skip ROM
      write_ds1820_one_byte(0xbe, sensor);  // read the result

      for (n=0; n<9; n++)     // read 9 bytes but, use only one byte
      {
         buff[n]=read_ds1820_one_byte(sensor);  // read DS1820
      }
   }

   init_ds1307();
   u=read_ds1307(0);
   sec=u & 0x7F;// enable RTC
   write_ds1307(0,sec);   // set second to 00 and enable clock(bit7=0)
   output_low(EXP_OUT_CLOCK);

   fs_flag=0;
   ext_int_edge(H_TO_L);      // init interrupt triggering for button press
   enable_interrupts(INT_EXT);
   enable_interrupts(GLOBAL);

   while(true)
   {
      disable_interrupts(INT_EXT);
      if (fs_flag==0)
      {
         show_temp();
      }
      enable_interrupts(INT_EXT);
      for (u=0;u<20;u++)
      {
         show_time(fs_flag);
      }

   }

} //enf of main program
