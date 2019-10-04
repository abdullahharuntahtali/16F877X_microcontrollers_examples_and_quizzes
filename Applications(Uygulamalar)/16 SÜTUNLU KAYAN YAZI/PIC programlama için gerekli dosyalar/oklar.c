#include <pic.h>
#include <delay.c>

main(void)
{
//Deðiþken tanýmlamalarý
unsigned int i;
unsigned const char oklar[]={
0x08,0x0c,0xfe,0xff,0xfe,0x0c,0x08,0x00,
0x00,0x10,0x30,0x7f,0xFF,0x7f,0x30,0x10};

//port ayarlama iþlemleri
TRISB=0; // PortB'nin hepsi çýkýþ
TRISA=0; // PortA'nin hepsi çýkýþ
CMCON=0x07; // PORTA sayýsal giriþ/çýkýþ
PORTB=0x00; // Baþlangýçta LED'ler sönük

//16 adet satýr verisini sýrayla PORT'a gönder
for(;;){
	for(i=0;i<=15;i++){
	PORTB=oklar[i]; // Verileri PortB'ye gönder
	PORTA=i; // ilgili sütunu seç
	DelayMs(1); // 1ms bekle
}} 
}// Program sonu

