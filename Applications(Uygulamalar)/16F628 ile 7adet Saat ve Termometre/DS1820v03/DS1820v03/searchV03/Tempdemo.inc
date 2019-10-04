;****************************************************************************
;*                                                                          *
;*                   Dallas 1 Wire Bus Temperature demo                     *
;*                                                                          *
;****************************************************************************

Clock_Freq      equ     d'4000000'      ;4MHz - for wait macro calculations

    udata_ovr   0x20                    ;0x0C 16F84
DScommbuff      res     1
DSCRC           res     1

tempone         res     1
temptwo         res     1
count           res     1
count2          res     1               ; 2nd loop counter for nested loops
bits_byte       res     1

CHARBUF         res     1
temp_hi         res     1
temp_lo         res     1
acc_lo          res     1
acc_hi          res     1

vvshift         res     1

#define PRESENCE_bit    bits_byte, 0
#define round00_bit     bits_byte, 1
#define DSNext_bit      bits_byte, 2
#define neg_temp_bit    bits_byte, 3
#define DALLAS_BUS      PORTA, 4

ROM_no          res     8
id_bit_number   res     1
last_zero       res     1
LastDiscrepancy res     1
LastFamilyDiscr res     1
id_bits_byte    res     1
rom_mask        res     1

#define id_bit          id_bits_byte, 0 ; first bit read in a search ID sequence
#define cmp_id_bit      id_bits_byte, 1 ; complement of id_bit
#define test_bit        id_bits_byte, 2 ; test id_bit & cmp_id_bit

#define last_device     id_bits_byte, 6
#define Direction       id_bits_byte, 7
