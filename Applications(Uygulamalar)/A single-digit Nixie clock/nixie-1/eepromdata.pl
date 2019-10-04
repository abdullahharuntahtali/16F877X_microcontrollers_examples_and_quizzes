#!/usr/bin/perl -w

while (<>)
{
    chomp;
    if (/\( (....), 0x(..) \)/)
    {
        $addr = $1;
        $data = $2;

        $addr = sprintf("%4.4x", 2*hex($addr) + hex("0x4200"));
        $data = $data . "00";
        $strn = "02" . $addr . "00" . $data;
        $tot = 0;
        @nums = (split(//,$strn));
        for ($i=0; $i<=$#nums; $i+=2)
        {
            $tot += hex($nums[$i] . $nums[$i+1]);
        }
        $cksm = sprintf("%2.2x", 256 - ($tot % 256));
        print ":" . $strn . $cksm, "\n";
    }
    else
    {
        die "Regexp didn't match\n";
    }
}
