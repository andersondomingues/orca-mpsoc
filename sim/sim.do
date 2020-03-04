if {[file  isdirectory work]} {vdel -all -lib work}
vlib work
vmap work work

#hfriscv sources
vcom -work work ../rtl/processors/hfriscv-2018/reg_bank.vhd
vcom -work work ../rtl/processors/hfriscv-2018/control.vhd
vcom -work work ../rtl/processors/hfriscv-2018/bshift.vhd
vcom -work work ../rtl/processors/hfriscv-2018/alu.vhd
vcom -work work ../rtl/processors/hfriscv-2018/datapath.vhd
vcom -work work ../rtl/processors/hfriscv-2018/int_control.vhd
vcom -work work ../rtl/processors/hfriscv-2018/cpu.vhd

#router sources
vcom -work work ../rtl/routers/hermes/HeMPS_defaults.vhd 
vcom -work work ../rtl/routers/hermes/Hermes_buffer.vhd 
vcom -work work ../rtl/routers/hermes/Hermes_crossbar.vhd 
vcom -work work ../rtl/routers/hermes/Hermes_switchcontrol.vhd 
vcom -work work ../rtl/routers/hermes/RouterCC.vhd

#memory core sources
vcom -work work ../rtl/storage/single-port-ram-orca/single_port_ram.vhd

#network interface sources
vcom -work work ../rtl/others/orca-ni/orca-ni-recv.vhd
vcom -work work ../rtl/others/orca-ni/orca-ni-send.vhd
vcom -work work ../rtl/others/orca-ni/orca-ni-top.vhd

#top-level source
vcom -work work ../rtl/others/tile-comm.vhd
vcom -work work ../rtl/others/tile-proc.vhd
vcom -work work ../rtl/orca-top.vhd

#sim source
vsim -novopt ./orca-tb.vhd

do wave.do

run 1 us

quit