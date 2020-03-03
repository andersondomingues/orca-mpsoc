if {[file  isdirectory work]} {vdel -all -lib work}
vlib work
vmap work work

#router files
vcom -work work ../rtl/router/HeMPS_defaults.vhd 
vcom -work work ../rtl/router/Hermes_buffer.vhd 
vcom -work work ../rtl/router/Hermes_crossbar.vhd 
vcom -work work ../rtl/router/Hermes_switchcontrol.vhd 
vcom -work work ../rtl/router/RouterCC.vhd

#core files 
vcom -work work ../rtl/hfriscv/alu.vhd
vcom -work work ../rtl/hfriscv/bshifter.vhd
vcom -work work ../rtl/hfriscv/control.vhd
vcom -work work ../rtl/hfriscv/cpu.vhd
vcom -work work ../rtl/hfriscv/datapath.vhd
vcom -work work ../rtl/hfriscv/int_control.vhd
vcom -work work ../rtl/hfriscv/reg_bank.vhd

#memory core files 
vcom -work work ../rtl/memory/fifo.vhd
vcom -work work ../rtl/memory/single_port_ram.sv

#network interface files 
vcom -work work ../rtl/orca-ni/ni.vhd

#top-level files 
vcom -work work ../rtl/tile-comm.vhd
vcom -work work ../rtl/tile-proc.vhd
vcom -work work ../rtl/orca-top.vhd

#testbench files
vcom -work work ./tb.vhd

vsim -novopt work.tb

do wave.do

run 1 us
