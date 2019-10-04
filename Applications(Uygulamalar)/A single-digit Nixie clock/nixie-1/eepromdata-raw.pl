#!/usr/bin/perl

$i = 64;

while (<>)
{
	chomp;
	printf("( 0x%2.2x, 0x%2.2x )\n", $i++, $_);
}
