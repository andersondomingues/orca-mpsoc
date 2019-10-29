clear -all

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
elaborate -vhdl -top {RouterCC} -multiple_clock -loop_limit 65536

# set up clock and reset signals
clock clock -factor 1 -phase 1 -both_edges
reset -expression {reset = '1'};

# get designs statistics
get_design_info

# this command might be useful for more complex designs
#set_max_trace_length 150

prove -all

# report proof results
report


