## Project F: Pong - iCEBreaker Makefile
## (C)2021 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io

# configuration
SHELL = /bin/sh
FPGA_PKG = sg48
FPGA_TYPE = up5k
PCF = icebreaker.pcf

# included modules
PATH_LIB = ../../../lib
ADD_SRC  = ${PATH_LIB}/clock/ice40/clock_gen_480p.sv 
ADD_SRC += ${PATH_LIB}/essential/debounce.sv
ADD_SRC += ../simple_display_timings_480p.sv

top_pong: top_pong.rpt top_pong.bin
top_pong_v1: top_pong_v1.rpt top_pong_v1.bin
top_pong_v2: top_pong_v2.rpt top_pong_v2.bin
top_pong_v3: top_pong_v3.rpt top_pong_v3.bin
top_pong_v4: top_pong_v4.rpt top_pong_v4.bin

%.json: %.sv $(ADD_SRC)
	yosys -ql $(subst .json,,$@)-yosys.log -p 'synth_ice40 -abc2 -top $(subst .json,,$@) -json $@' $< $(ADD_SRC)

%.asc: %.json
	nextpnr-ice40 --${FPGA_TYPE} --package ${FPGA_PKG} --json $< --pcf ${PCF} --asc $@

%.rpt: %.asc
	icetime -d ${FPGA_TYPE} -mtr $@ $<

%.bin: %.asc
	icepack $< $@

clean:
	rm -f top*.json top*.asc top*.rpt top*.bin top*yosys.log

all: top_pong top_pong_v1 top_pong_v2 top_pong_v3 top_pong_v4

.PHONY: all clean
