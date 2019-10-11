clear -all

# analyze the design
analyze -vhdl ../../models/vhdl/router/RouterCC.vhd ;
analyze -vhdl ../../models/vhdl/router/Hermes_buffer.vhd ;
analyze -vhdl ../../models/vhdl/router/Hermes_crossbar.vhd ;
analyze -vhdl ../../models/vhdl/router/Hermes_switchcontrol.vhd ;
analyze -vhdl ../../models/vhdl/router/HeMPS_defaults.vhd ;

# Analyze property files
analyze -sva bindings.sv properties.sv ;

#set_evaluate_properties_on_formal_reset off

# elaborate the design, point to the design top level
elaborate -vhdl -top {RouterCC}

# Set up Clocks and Resets
clock clock -factor 1 -phase 1
reset -expression {reset = '1'};

# get designs statistics
get_design_info

# this command might be useful for more complex designs
#set_max_trace_length 150

prove -all

# Report proof results
report

