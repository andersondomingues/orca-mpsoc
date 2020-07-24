if {[file  isdirectory work]} {vdel -all -lib work}
vlib work
vmap work work

#SystemC sources
sccom -g ./mpsoc/tb/SC_InputModule.cpp
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
vcom -work work ../rtl/storage/single-port-ram-orca/single_port_ram.vhd

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

#force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_ni_binding/ni_recv_mod/recv_reload 0 17us
#force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_ni_binding/ni_recv_mod/prog_size 32'h00000008 22us
#force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_ni_binding/ni_recv_mod/recv_start 1 23us
#force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_ni_binding/ni_recv_mod/recv_start 0 24us
#force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_ni_binding/ni_recv_mod/prog_size 32'h00000009 25us
#force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_mem_binding/ram(0) 32'h00000000 26us
#force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_mem_binding/ram(1) 32'h00000007 26us
#force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_ni_binding/ni_sender_mod/send_start 1 26us
#force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_ni_binding/ni_recv_mod/recv_reload 1 28us

force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_ni_binding/ni_recv_mod/recv_reload 0 34us
force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_ni_binding/ni_recv_mod/prog_size 32'h00000008 38us
force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_ni_binding/ni_recv_mod/recv_start 1 39us
force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_ni_binding/ni_recv_mod/recv_start 0 40us
force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_ni_binding/ni_recv_mod/prog_size 32'h00000009 41us
force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_mem_binding/ram(0) 32'h00000000 42us
force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_mem_binding/ram(1) 32'h00000007 42us
force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_ni_binding/ni_sender_mod/send_start 1 43us
force -freeze sim:/tbench/u1_orca/proc(1)/orca_tile/proc_tile_ni_binding/ni_recv_mod/recv_reload 1 45us

do wave.do

run 46us
