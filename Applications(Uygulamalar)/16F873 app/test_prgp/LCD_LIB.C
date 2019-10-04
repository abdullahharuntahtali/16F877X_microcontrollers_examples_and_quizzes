///////////////////////////////////////////////
//  LCD control Library
//  functions are below
//    lcd_init()-------- initialize
//    lcd_ready()------- busy check
//    lcd_cmd(cmd)------ send command
//    lcd_data(string)-- display string
//    lcd_clear() ------ clear display
//////////////////////////////////////////////

int	temp;

/////////// lcd ready check function	
int lcd_ready(){
	int high,low;
	set_tris_a(Amode | 0x0f);	//lower is input
	output_low(rs);
	output_high(rw);		//read mode
	output_high(stb);
	high = db & 0x0f;		//input upper
	output_low(stb);
	output_high(stb); 
	low = db & 0x0f;		//input lower
	output_low(stb);
	set_tris_a(Amode);
	return(swap(high) | low);	//end check
}

////////// lcd display data function
void lcd_data(int asci){
	temp = asci;			//set upper data
	db = swap(temp);
	output_low(rw);			//set write
	output_high(rs);		//set rs high
	output_high(stb);		//strobe
	output_low(stb);
	db = asci;			//set lower data
	output_high(stb);		//strobe
	output_low(stb);
	while(bit_test(lcd_ready(),7));
}

////////// lcd command out function
void cmdout(int cmd){
	temp = cmd;			//set upper data
	db = swap(temp);
	output_low(rw);			//set write
	output_low(rs);			//set rs low
	output_high(stb);		//strobe
	output_low(stb);
	db = cmd;			//set lower data
	output_high(stb);		//strobe
	output_low(stb);
}
void lcd_cmd(int cmd){
	cmdout(cmd);
	while(bit_test(lcd_ready(),7));	//end check
}

//////////  lcd display clear function
void lcd_clear(){
	lcd_cmd(1);			//initialize command
}

///////// lcd initialize function
void lcd_incmd(int cmd){
	db = cmd;				//mode command
	output_low(rw);				//set write
	output_low(rs);				//set rs low
	output_high(stb);			//strobe
	output_low(stb);
	delay_us(100);
}

void lcd_init(){
	delay_ms(15);
	lcd_incmd(0x03);			//8bit mode set
	delay_ms(5);
	lcd_incmd(0x03);			//8bit mode set
	lcd_incmd(0x03);			//8bit mode set
	lcd_incmd(0x02);			//4bit mode set
	lcd_cmd(0x2E);				//DL=0 4bit mode
	lcd_cmd(0x08);				//disolay off C=D=B=0
	lcd_cmd(0x0D);				//display on C=D=1 B=0
	lcd_cmd(0x06);				//entry I/D=1 S=0
}

