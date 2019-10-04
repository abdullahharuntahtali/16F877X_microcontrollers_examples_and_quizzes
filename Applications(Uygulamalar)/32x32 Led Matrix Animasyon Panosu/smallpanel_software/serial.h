#if !defined(UARTdotH)
#define UARTdotH

/*
 * CPU clock in Hz
 */
#define CPUCLOCK 14745600L

#define HANDSHAKE_NONE     0
#define HANDSHAKE_HARDWARE 1
#define HANDSHAKE_SOFTWARE 2

/*
 * RTS Port and Bit
 */
#define UART_RTS_PORT PORTE
#define UART_RTS_DDR  DDRE
#define UART_RTS_BIT  3
#define UART_CTS_PORT PORTE
#define UART_CTS_DDR  DDRE
#define UART_CTS_BIT  2

/*
 * initialize uart
 */
void UartInit(unsigned long rate, char handshake, char echo);

/*
 * send a character to uart0
 */
int UartGetChar(void);

/*
 * receive a character from uart0
 */
int UartPutChar(char ch);

/*
 * check if character present
 */
int UartKbhit(void);

#endif
