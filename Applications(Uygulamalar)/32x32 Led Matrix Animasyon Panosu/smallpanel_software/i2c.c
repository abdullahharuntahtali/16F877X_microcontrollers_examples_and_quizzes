/*
 * Read Time from Dallas DS1307 chip
 */
void get_time(unsigned char Device, unsigned char *p_time)
{         
  i2c_start(Device+I2C_WRITE);       
  i2c_write(0x00);        
          
  i2c_rep_start(Device+I2C_READ);   
     
  p_time[2] = i2c_readAck();  //hours
  p_time[1] = i2c_readAck();  //minutes
  p_time[0] = i2c_readAck();  //seconds
  
  i2c_stop();
}

