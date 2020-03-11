if {[file  isdirectory work]} {vdel -all -lib work}
vlib work
vmap work work

#memory source
vcom -work work ../../../rtl/others/orca-ni/orca-ni-send.vhd
vcom -work work ../../../rtl/others/orca-ni/orca-ni-recv.vhd
vcom -work work ../../../rtl/others/orca-ni/orca-ni-top.vhd

#tb source
vcom -work work ./ni_tb.vhd 

#sim source
#vsim -novopt ni_tb
vsim ni_tb

do wave.do

run 20 ms

#quit
