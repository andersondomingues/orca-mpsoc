
# NC-Sim Command File
# TOOL:	ncsim	10.20-s071
#
#
# You can restore this configuration with:
#
#      irun -f file_list -input restore.tcl
#

set tcl_prompt1 {puts -nonewline "ncsim> "}
set tcl_prompt2 {puts -nonewline "> "}
set vlog_format %h
set vhdl_format %v
set real_precision 6
set display_unit auto
set time_unit module
set heap_garbage_size -200
set heap_garbage_time 0
set assert_report_level note
set assert_stop_level error
set autoscope yes
set assert_1164_warnings yes
set pack_assert_off {}
set severity_pack_assert_off {note warning}
set assert_output_stop_level failed
set tcl_debug_level 0
set relax_path_name 1
set vhdl_vcdmap XX01ZX01X
set intovf_severity_level ERROR
set probe_screen_format 0
set rangecnst_severity_level ERROR
set textio_severity_level ERROR
set vital_timing_checks_on 1
set vlog_code_show_force 0
set assert_count_attempts 1
set tcl_all64 false
set tcl_runerror_exit false
set assert_report_incompletes 1
set show_force 1
set force_reset_by_reinvoke 0
set tcl_relaxed_literal 0
set probe_exclude_patterns {}
database -open -shm -into waves.shm waves -default
probe -create -database waves :clk :interrupt :mem_address :mem_byte_sel :mem_data_r :mem_data_w :mem_pause :mem_write :reset :uart_av :u1_cpu:u4_reg_bank:tri_port_ram

simvision -input restore.tcl.svcf
