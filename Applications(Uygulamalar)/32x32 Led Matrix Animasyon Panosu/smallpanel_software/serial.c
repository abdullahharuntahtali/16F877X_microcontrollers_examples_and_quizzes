/*
 * Interrupt driven serial driver
 */
#include <avr/signal.h>
#include <stdlib.h>
#include <avr/io.h>
#include <stdio.h>

#include "serial.h"

// size of receive buffer
#define UART_BUFSIZE 16
// ASCII code for software flow control, starts transmitter
#define ASCII_XON    0x11
// ASCII code for software flow control, stops transmitter
#define ASCII_XOFF   0x13
// XON transmit pending flag
#define XON_PENDING  0x10
// XOFF transmit pending flag
#define XOFF_PENDING 0x20
// XOFF sent flag
#define XOFF_SENT    0x40
// XOFF received flag
#define XOFF_RCVD    0x80

extern volatile char buf7seg[32];
char *uart_rx_buffer=0;
volatile int  uart_rx_head, uart_rx_tail;
volatile char uart_rx_error;
char uart_handshake;

/*
 * initialize uart
 */
void UartInit(unsigned long rate, char handshake, char echo)
{
  unsigned int sv;
  uart_handshake=handshake;
  if (!uart_rx_buffer) uart_rx_buffer=malloc(UART_BUFSIZE);
  uart_rx_head=uart_rx_tail=0;

#ifdef __AVR_ATmega128__
  if (bit_is_clear(UCSR0C, UMSEL)) 
  {
    if (bit_is_set(UCSR0A, U2X)) 
    {
      rate <<= 2;
    } 
    else 
    {
      rate <<= 3;
    }
  }
#else
  rate <<= 3;
#endif
  sv = (unsigned int) ((CPUCLOCK / rate + 1UL) / 2UL) - 1;
  UBRR0L=(unsigned char) sv;
#ifdef __AVR_ATmega128__
  UBRR0H=(unsigned char) (sv >> 8);
#endif

  // set parity mode to NONE and Databits to 8
  UCSR0C= _BV(UCSZ01) | _BV(UCSZ00);

  //UCSR0B= _BV(RXCIE) | _BV(UDRIE) | _BV(RXEN) | _BV(TXEN);
  UCSR0B= _BV(RXCIE) | _BV(RXEN) | _BV(TXEN);
  // dummy read to reset error bits
  sv=UDR0;
  uart_rx_error=0;
#ifdef UART_RTS_PORT
  sbi(UART_RTS_DDR, UART_RTS_BIT);
  cbi(UART_RTS_PORT, UART_RTS_BIT);
#endif  
#ifdef UART_CTS_PORT
  cbi(UART_CTS_DDR, UART_CTS_BIT);
#endif  
	fdevopen(UartPutChar, UartGetChar, 0);
}

/*
 * transmit a character
 */
int UartPutChar(char ch)
{
	// check handshake status
	if ((uart_handshake&3) == HANDSHAKE_SOFTWARE)
	  loop_until_bit_is_clear(uart_handshake, XOFF_RCVD);
#ifdef UART_CTS_PORT	  
	else
	  if ((uart_handshake&3) == HANDSHAKE_HARDWARE)
	    loop_until_bit_is_clear(UART_CTS_PORT, UART_CTS_BIT);
#endif	    
	// insert a LF if there is a CR
	if (ch=='\n') UartPutChar('\r');
	// wait for transmitter empty
  loop_until_bit_is_set(UCSR0A, UDRE0);
	// transmit character
	UDR0=ch;
	uart_rx_error=0;
	return 0;
}

/*
 * get character from receive buffer
 */
int UartGetChar(void)
{
	char ch;
	int cnt;
	// wait for character
	while (uart_rx_head==uart_rx_tail);
	ch=uart_rx_buffer[uart_rx_tail++];
	if (uart_rx_tail==UART_BUFSIZE) uart_rx_tail=0;
  cnt = uart_rx_head-uart_rx_tail;
  if (cnt<0) cnt+=UART_BUFSIZE;
  if (cnt<UART_BUFSIZE-4)
  {
  	if (uart_handshake & XOFF_SENT) 
    {
  	  UartPutChar(ASCII_XON);
  	  uart_handshake &= ~XOFF_SENT;
    }  
#ifdef UART_RTS_PORT      
    else
      if ((uart_handshake&3)==HANDSHAKE_HARDWARE)
        cbi(UART_RTS_PORT, UART_RTS_BIT);     
#endif        
  }      
	return ch;
}

/*
 * check if character present
 */
int UartKbhit(void)
{
	return (uart_rx_head!=uart_rx_tail);
}

SIGNAL(SIG_UART0_RECV)
{
	char ch;
	int cnt;
	
  // are there any errors
  uart_rx_error |= UCSR0A&0x0e;

  // read the character
  ch = UDR0;

  if ((uart_handshake&3)==HANDSHAKE_SOFTWARE)
  {
    // XOFF character disables transmit interrupts.
    if (ch == ASCII_XOFF)
    {
      // cbi(UCSR0B, UDRIE);
      uart_handshake |= XOFF_RCVD;
      return;
    }
    else
      // XON enables transmit interrupts. 
      if (ch == ASCII_XON) 
      {
        // sbi(UCSR0B, UDRIE);
        uart_handshake &= ~XOFF_RCVD;
        return;
      }
  }

  // Check buffer overflow.
  cnt = uart_rx_head-uart_rx_tail;
  if (cnt<0) cnt+=UART_BUFSIZE;
  
  if (cnt >= UART_BUFSIZE-1) 
  {
    uart_rx_error |= _BV(DOR);
    return;
  }

  // software handshake ?
  if ((uart_handshake&3) == HANDSHAKE_SOFTWARE)
  {
  	// are we above the high water mark
    if(cnt >= UART_BUFSIZE-4) 
    {
    	// and did not already sent XOFF
      if((uart_handshake & XOFF_SENT) == 0) 
      {
      	// then sent it if transmitter is free
        if (inb(UCSR0A) & _BV(UDRE)) 
        {
          //outb(UDR0, ASCII_XOFF);
          UartPutChar(ASCII_XOFF);
          uart_handshake |= XOFF_SENT;
          uart_handshake &= ~XOFF_PENDING;
        } 
        // if not mark it for sending
        else 
        {
          buf7seg[15]|=4;
          UartPutChar(ASCII_XOFF);
          uart_handshake |= XOFF_PENDING;
        }
      }
    }
  }
#ifdef UART_RTS_PORT
  else
    // hardware handshake ? 
    if ((uart_handshake&3) == HANDSHAKE_HARDWARE)
    {
    	// are we above the high water mark
    	if (cnt >= UART_BUFSIZE-4) 
    	  sbi(UART_RTS_PORT, UART_RTS_BIT);
    }
#endif  
  // store the character and increment and the ring buffer pointer. 
  uart_rx_buffer[uart_rx_head++] = ch;
  if (uart_rx_head == UART_BUFSIZE) 
    uart_rx_head = 0;
}
