all: clock

test: testout
	picprog -d pic16f628 -p /dev/ttyS0 -i testout.hex --erase --burn

testout: test.hex eepromdata.hex
	tail -n +2 test.hex | head -n -1 > testout.hex
	cat eepromdata.hex >> testout.hex
	tail -n -1 test.hex >> testout.hex

test.hex: test.jal
	../jal/bin/jal -s../jal/lib test.jal

clock: clockout
	picprog -d pic16f628 -p /dev/ttyS0 -i clockout.hex --erase --burn

clockout: clock.hex eepromdata.hex
	tail -n +2 clock.hex | head -n -1 > clockout.hex
	cat eepromdata.hex >> clockout.hex
	tail -n -1 clock.hex >> clockout.hex

clock.hex: clock.jal intrh.jal
	../jal/bin/jal -s../jal/lib clock.jal

eepromdata.hex: eepromdata.in eepromdata.pl
	cat eepromdata.in | perl eepromdata.pl > eepromdata.hex

eepromdata.in: eepromdata-pt2.raw
	cat eepromdata-pt2.raw | perl eepromdata-raw.pl >> eepromdata-pt2.in
	cat eepromdata-pt1.in eepromdata-pt2.in >> eepromdata.in

clean:
	rm -f testout.hex test.hex clockout.hex clock.hex eepromdata.hex eepromdata.in eepromdata-pt2.in
