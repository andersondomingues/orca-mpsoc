#!/bin/bash

# This script can be executed in two modes:
# - without arguments, to run with the defaults values
# - with arguments, to change the MPSoC configuration
# When running with arguments, their orders are:
# - NoC flit width
# - NoC input port buffer depth
# - Number of processors, including the Zynq's ARM processor
# - Number of processors in the X axis (Mesh NoC topology)
# - Number of processors in the Y axis (Mesh NoC topology)

# change app endianness to send accordingly the riscv. 
#./change_endianness.sh mpsoc/app/app.txt > mpsoc/app/app_endianness.txt
#./change_endianness.sh mpsoc/app/packet.txt > mpsoc/app/packet_endianness.txt

# the MPSoC configurable parameters
tam_flit=0
tam_buffer=0
num_proc=0
num_proc_x=0
num_proc_y=0
if [ "$#" -eq 0 ]; then
    tam_flit=32
    tam_buffer=4
    num_proc=2
    num_proc_x=2
    num_proc_y=1
    echo "Using the default MPSoC configuration:"
elif [ "$#" -eq 5 ]; then
    tam_flit=$1
    tam_buffer=$2
    num_proc=$3
    num_proc_x=$4
    num_proc_y=$5
    echo "Using a custom MPSoC configuration:"
else 
    echo "ERROR: Invalid arguments."
    echo ""
    echo "This script can be executed in two modes:"
    echo " - without arguments, to run with the defaults values"
    echo " - with arguments, to change the MPSoC configuration"
    echo " When running with arguments, their orders are:"
    echo " - NoC flit width. Typical values: 32 and 16"
    echo " - NoC input port buffer depth. Typical values: 2, 4, 8"
    echo " - Number of processors, including the Zynq's ARM processor. Typical must be NUMBER_PROCESSORS_X * NUMBER_PROCESSORS_Y"
    echo " - Number of processors in the X axis (Mesh NoC topology). Typical values: [1,8]"
    echo " - Number of processors in the Y axis (Mesh NoC topology). Typical values: [1,8]"
    echo ""
    echo "Example of default configuration:"
    echo "$ ./run.sh"
    echo ""
    echo "Example of custom configuration:"
    echo "$ ./run.sh 16 4 4 2 2" 
    exit 2
fi

echo " - TAM_FLIT            = $tam_flit"
echo " - TAM_BUFFER          = $tam_buffer"
echo " - NUMBER_PROCESSORS   = $num_proc"
echo " - NUMBER_PROCESSORS_X = $num_proc_x"
echo " - NUMBER_PROCESSORS_Y = $num_proc_y"

# convenience script to easily replace the main design parameters of the MPSoC
sed -i -e "/constant TAM_FLIT/s/32/${tam_flit}/g" ../rtl/orca_defaults.vhd
sed -i -e "/constant TAM_BUFFER/s/4/${tam_buffer}/g" ../rtl/orca_defaults.vhd
sed -i -e "/constant NUMBER_PROCESSORS /s/2/${num_proc}/g" ../rtl/orca_defaults.vhd
sed -i -e "/constant NUMBER_PROCESSORS_X /s/2/${num_proc_x}/g" ../rtl/orca_defaults.vhd
sed -i -e "/constant NUMBER_PROCESSORS_Y/s/2/${num_proc_y}/g" ../rtl/orca_defaults.vhd

# Make sure you have loaded "questa" module before running this script
# when at the GAPH. If running at home, make sure you have installed 
# model sim or questa tools.

# To load quest, type the command below.
# $module load questa/modelsim

#vsim -do sim.do

#cleanup
#rm -rf vsim.wlf transcript modelsim.ini work
#rm -rf mpsoc/app/app_endianness.txt
#rm -rf mpsoc/app/packet_endianness.txt

