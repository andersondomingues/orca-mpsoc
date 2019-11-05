clear -all

#add more engines to proof checking
set_engine_mode {Hp Bm J Q3 U L R B N}

#enable parallel processing 
set_parallel_proof_mode on

# analyze the design
analyze -vhdl ../../models/vhdl/router/HeMPS_defaults.vhd ;
analyze -vhdl ../../models/vhdl/router/Hermes_buffer.vhd ;
analyze -vhdl ../../models/vhdl/router/Hermes_crossbar.vhd ;
analyze -vhdl ../../models/vhdl/router/Hermes_switchcontrol.vhd ;
analyze -vhdl ../../models/vhdl/router/RouterCC.vhd ;

# analyze property and binding files
analyze -sva hemps_defaults.sv bindings.sv properties.sv 

# set_evaluate_properties_on_formal_reset off

# elaborate the design, point to the design top level
elaborate -vhdl -top {RouterCC} -multiple_clock -loop_limit 65535

# set up clock 
#clock clock -factor 1 -phase 1 -both_edges
clock clock [list {clock_rx(0)} {clock_rx(1)} {clock_rx(2)} {clock_rx(3)} {clock_rx(4)}] 1 1 -both_edges
#{clock_tx(0)} {clock_tx(1)} {clock_tx(2)} {clock_tx(3)} {clock_tx(4)}] 

#set reset sig
reset -expression {reset = '1'};
##??
sanity_check -verbose -analyze all

# get designs statistics
get_design_info

# this command might be useful for more complex designs
#set_max_trace_length 150

prove -all -orchestration on

# report proof results
report


