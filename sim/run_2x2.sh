#!/bin/bash

# Make sure you have loaded "questa" module before running this script
# when at the GAPH. If running at home, make sure you have installed 
# model sim or questa tools.

# To load quest, type the command below.
# $module load questa/modelsim

vsim -do sim_2x2.do

#cleanup
rm -rf vsim.wlf transcript modelsim.ini work
