if {[file  isdirectory work]} {vdel -all -lib work}
vlib work
vmap work work

#memory source
vcom -work work ../../rtl/storage/single-port-ram-orca/ram.vhd

#router sources
vcom -work work ./ram_tb.vhd 

#sim source
vsim -novopt ram_tb

do wave.do

run 200 ms

#quit
