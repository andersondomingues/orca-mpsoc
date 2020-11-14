#!/bin/bash

# change app endianness to send accordingly the riscv. 
./change_endianness.sh mpsoc/app/app.txt > mpsoc/app/app_endianness.txt
./change_endianness.sh mpsoc/app/packet.txt > mpsoc/app/packet_endianness.txt

# Make sure you have loaded "questa" module before running this script
# when at the GAPH. If running at home, make sure you have installed 
# model sim or questa tools.

# To load quest, type the command below.
# $module load questa/modelsim

vsim -do sim.do

#cleanup
#rm -rf vsim.wlf transcript modelsim.ini work
rm -rf mpsoc/app/app_endianness.txt
rm -rf mpsoc/app/packet_endianness.txt
