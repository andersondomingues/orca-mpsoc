#!/bin/bash

# Make sure you have loaded "questa" module before running this script
# when at the GAPH. If running at home, make sure you have installed 
# model sim or questa tools.

# To load quest, type the command below.
# $module load questa

vsim -do sim.do

#cleanup
rm -rf transcript modelsim.ini work
