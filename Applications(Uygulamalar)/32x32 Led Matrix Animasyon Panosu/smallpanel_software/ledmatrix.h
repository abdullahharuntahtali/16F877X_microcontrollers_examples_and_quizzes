/*
 * LED Matrix display driver (main functions and tcpip routines)
 *
 * Controlling several LED Matrix Modules Samsung SLM1606M/SLM1608M
 * connected to port B/D of Ethernut:
 *
 * Printer   Module
 * -----------------
 * D0 (2)    SELECT (CN2-2)
 * D1 (3)    RED    (CN3-2)
 * D2 (4)    GREEN  (CN3-4)
 * D3 (6)    CLOCK  (CN3-6)
 * D4 (8)    BRIGHT (CN3-8)
 * D5 (9)    RESET  (CN3-10)
 * GND (20)  GND    (CN3-3)
 *
 * Written by Thorsten Erdmann 06/2003 (thorsten.erdmann@gmx.de)
 */

/**************************************************************
 **** CAUTION: The module can be destroyed if applied      ****
 ****          static signals, so NEVER interrupt the      ****
 ****          program without switching off module's      ****
 ****          power source first !!!                      ****
 **************************************************************/

/*
 * show configuration
 */
void showConfigInfo(FILE *stream);
