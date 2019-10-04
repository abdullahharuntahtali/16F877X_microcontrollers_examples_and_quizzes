#include <pic.h>
#include <delay.c>

main(void)
{
//Deðiþken tanýmlamalarý
unsigned int i;
unsigned const char araba[]={
0x60,0x70,0x70,0xf0,0xf8,0x74,0x72,0x7e,
0x72,0x72,0x72,0x7e,0xF2,0xf4,0x78,0x30};

//port ayarlama iþlemleri
TRISB=0; // PortB'nin hepsi çýkýþ
TRISA=0; // PortA'nin hepsi çýkýþ
CMCON=0x07; // PORTA sayýsal giriþ/çýkýþ
PORTB=0x00; // Baþlangýçta LED'ler sönük

//16 adet satýr verisini sýrayla PORT'a gönder
for(;;){
	for(i=0;i<=15;i++){
	PORTB=araba[i]; // Verileri PortB'ye gönder
	PORTA=i; // ilgili sütunu seç
	DelayMs(1); // 1ms bekle
}} 
}// Program sonu

