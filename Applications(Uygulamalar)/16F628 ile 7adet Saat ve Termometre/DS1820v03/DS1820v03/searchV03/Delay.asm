                ;**********************************
                ;*    The Delay routines          *
                ;*                                *
                ;* used by Wait <time>            *
                ;**********************************

    include tempdemo.inc

    global longdelay, shortdelay

PROG CODE

longdelay   movwf   tempone
ldloop1     clrf    temptwo
ldloop2     decfsz  temptwo, F  ;becomes 11111111
            goto    ldloop2
            decfsz  tempone, F
            goto    ldloop1
            return

shortdelay  movwf   tempone
sdloop      decfsz  tempone, F
            goto    sdloop
            return

        end
