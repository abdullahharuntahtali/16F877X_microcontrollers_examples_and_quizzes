#if !defined(LEDdotH)
#define LEDdotH


/***********************************************************
 * constants for defining your display type                *
 ***********************************************************/
#define SLM_OLD   0      /* old style SLM1606M panel       */
#define SLM_NEW   1      /* new style SLM1606M panel       */
#define SLM_HUGE  2      /* huge 256x64 SLM1606M panel     */
#define DISCRETE  3      /* discrete 4094 based panel      */
#define SPI       4      /* discrete panel connected to SPI*/

/***********************************************************
 * define your display type here using the above constants *
 ***********************************************************/
#define DISPTYPE  4      /* display type                   */

/***********************************************************
 * display parameters for SLM1606M panels                  *
 ***********************************************************/
#if ((DISPTYPE==SLM_OLD) || (DISPTYPE==SLM_NEW) || (DISPTYPE==SLM_HUGE))
#if (DISPTYPE==SLM_HUGE)
#define MAXX      256    /* display width                  */
#define MAXY      64     /* display height                 */
#else
#define MAXX      32     /* display width                  */
#define MAXY      32     /* display height                 */
#endif
#define LEDPORT   PORTE  /* LED control port               */
//#define LEDMUX    PORTE  /* MUX control port               */
#define LEDEPORT  PORTD  /* LED enable port                */
#define LEDRED0   4      /* LED data red pin, left side    */
#define LEDGREEN0 5      /* LED data green pin, left side  */
#define LEDRED1   6      /* LED data red pin, right side   */
#define LEDGREEN1 7      /* LED data green pin, right side */
#define LEDCLOCK  4      /* LED clock pin                  */
#define LEDRESET  5      /* LED reset pin                  */
#define LEDSEL0   6      /* LED select upper panel row     */
#define LEDSEL1   7      /* LED select upper panel row     */
//#define LEDBRIGHT 4      /* LED enable pin                 */
#endif

/***********************************************************
 * display parameters for discrete 4094 based panels       *
 ***********************************************************/
#if (DISPTYPE==DISCRETE)
#define MAXX      40     /* display width                  */ 
#define MAXY      16     /* display height                 */
#define LEDPORT   PORTD  /* LED control port               */
#define LEDMUX    PORTE  /* MUX control port               */
#define LEDMUX0   4      /* lowest Bit of MUX              */
#define LEDRED    0      /* LED data red pin               */
#define LEDGREEN  1      /* LED data green pin             */
#define LEDCLOCK  6      /* LED clock pin                  */
#define LEDBRIGHT 5      /* LED enable pin                 */
#define LEDSTROBE 4      /* LED strobe pin                 */
#endif

/***********************************************************
 * display parameters for discrete panels connected to SPI *
 ***********************************************************/
#if (DISPTYPE==SPI)
#define MAXX      40     /* display width                  */ 
#define MAXY      32     /* display height                 */
#define LEDPORT   PORTD  /* LED control port               */
//#define LEDMUX    PORTE  /* MUX control port               */
//#define LEDMUX0   4      /* lowest Bit of MUX              */
//#define LEDRED    0      /* LED data red pin               */
//#define LEDGREEN  1      /* LED data green pin             */
//#define LEDCLOCK  6      /* LED clock pin                  */
#define LEDBRIGHT  6      /* LED enable pin                */
#define LEDSTROBE  4      /* LED strobe pin                */
#endif

/***********************************************************
 * 7-segment display parameters                            *
 ***********************************************************/
#define SEGPORT    PORTB  /* 7-Segment Port                */ 
#define SEGCLOCK   1      /* 7-Segment Clock (SPI Clock)   */
#define SEGDATA    2      /* 7-Segment Data  (SPI Data)    */
#define SEGSTROBE  0      /* 7-Segment Strobe              */

/***********************************************************
 * Color constants                                         *
 ***********************************************************/
#define BLACK      0
#define RED        1
#define GREEN      2
#define YELLOW     3

/***********************************************************
 * Text Allignment constants                               *
 ***********************************************************/
#define TE_LEFT    0
#define TE_CENTER  1
#define TE_RIGHT   2

/***********************************************************
 * Keypad Bitcodes                                         *
 ***********************************************************/
#define KP_LEFT   64
#define KP_RIGHT   2
#define KP_UP      4
#define KP_DOWN    8
#define KP_BTN_L 128
#define KP_BTN_C  16
#define KP_BTN_R  32

/***********************************************************
 * Function prototypes                                     *
 ***********************************************************/
#define u_char    unsigned char
#define u_int     unsigned int
#define BUFSIZE MAXX*MAXY/4

extern volatile char buf7seg[32];
extern volatile char animation;
extern volatile char keypad;


/*
 * Startup Timer2 ISR for muxing the panel
 */
void startTimer(void);

/*
 * Get adress of current display buffer
 */
char *LEDGetbuffer(void);

/*
 * Initialize LED Matrix
 */
void LEDInit(void);

/* 
 * Clear Screen
 */
void LEDClear(void);

/*
 * Draw Pixel to VFD
 */
void LEDPixel(int x, int y, u_char c);

/*
 * Draw Line 
 */
void LEDLine(int x1,int y1,int x2,int y2, int c);

/*
 * Draw horizontal line to VFD
 */
void LEDHLine(int x, int y, u_int l, u_char c);

/* 
 * Draw vertical line to VFD
 */
void LEDVLine(int x, int y, u_int l, u_char c);

/*
 * Draw Rectangle to vfd
 */
void LEDRectangle(int x, int y, int w, int h, u_char c);

/*
 * Draw filled Rectangle to vfd
 */
void LEDFRectangle(int x, int y, int w, int h, u_char c);

/*
 * Draw string to VFD
 */
int LEDStr(int x, int y, u_char c, const char *s);

/*
 * Draw formatted string to VFD
 */
void LEDFStr(int x, int y, int w, u_char f, u_char c, const char *s);

/*
 * Draw a stored scrolled text to display
 */
int LEDScrolledText(int n);

/*
 * Draw scrolled formatted string
 */
void LEDSStr(int x, int y, int w, u_char f, u_char c, const char *s);

/*
 * Scroll all scrolled text fields
 */
int LEDAnimate(void);

/* 
 * Draw a Circle
 */
void LEDCircle(int x,int y,int r,int c);

/* 
 * Draw a filled Circle 
 */
void LEDFCircle(int x,int y,int r,int c);

/* 
 * Actualize Display
 */
void LEDDraw(void);

/*
 * calculate string length
 */
int LEDGetStrLength(const char *s);

/*
 * calculate string Height
 */
int LEDGetStrHeight(void);

/*
 * Draw Bitmap on VFD
 */
void LEDBitmap(int x, int y, unsigned char c, PGM_P bm);

/*
 * Display a Bitmap centered
 */
void LEDCenteredBitmap(unsigned char c, PGM_P bm);

/*
 * Display an animated Bitmap
 */
void LEDABitmap(int x, int y, unsigned char c, PGM_P bm);

/*
 * fills Display with a random pattern
 */
void LEDRandomfill(int x, int y, int w, int h, unsigned char c, int count);

/*
 * get pixel color of active screen
 */
u_char LEDGetPixel(int x, int y);

/*
 * draw a new Life Generation
 */
int LEDLife(int x, int y, int w, int h, unsigned char c);

/*
 * display a number on 7 segment display 
 */
void LEDNumout(int c, char x);

#endif
