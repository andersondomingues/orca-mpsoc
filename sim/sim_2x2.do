if {[file  isdirectory work]} {vdel -all -lib work}
vlib work
vmap work work

#SystemC sources
sccom -g ./mpsoc/tb/SC_InputModule_2x2.cpp
sccom -link -B/usr/lib

#defaults 
vcom -work work ../rtl/orca_defaults.vhd

#hfriscv sources
vcom -work work ../rtl/processors/hfriscv-2020/reg_bank.vhd
vcom -work work ../rtl/processors/hfriscv-2020/control.vhd
vcom -work work ../rtl/processors/hfriscv-2020/bshifter.vhd
vcom -work work ../rtl/processors/hfriscv-2020/alu.vhd
vcom -work work ../rtl/processors/hfriscv-2020/datapath.vhd
vcom -work work ../rtl/processors/hfriscv-2020/int_control.vhd
vcom -work work ../rtl/processors/hfriscv-2020/cpu.vhd

#router sources
vcom -work work ../rtl/routers/hermes/Hermes_buffer.vhd 
vcom -work work ../rtl/routers/hermes/Hermes_crossbar.vhd 
vcom -work work ../rtl/routers/hermes/Hermes_switchcontrol.vhd 
vcom -work work ../rtl/routers/hermes/RouterCC.vhd

#memory core sources
vcom -work work ../rtl/storage/single-port-ram-orca/single_port_ram_8bits_sim_only.vhd
vcom -work work ../rtl/storage/single-port-ram-orca/single_port_ram_32bits.vhd

#network interface sources
vcom -work work ../rtl/network-interfaces/orca-ni/orca-ni-recv-Nflit.vhd
vcom -work work ../rtl/network-interfaces/orca-ni/orca-ni-send-Nflit.vhd
vcom -work work ../rtl/network-interfaces/orca-ni/orca-ni-top.vhd

#top-level source
vcom -work work ../rtl/orca-minimal-soc.vhd
vcom -work work ../rtl/orca-tile-proc.vhd
vcom -work work ../rtl/orca-top-v2.vhd

#testbench source
#vcom -work work ./mpsoc/tb/SC_InputModule.vhd
vcom -work work ./mpsoc/tb/tbench.vhd

sccom 
#sim source
vsim -novopt -t ps work.tbench


