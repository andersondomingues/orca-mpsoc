onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ni_tb/clock
add wave -noupdate /ni_tb/reset
add wave -noupdate /ni_tb/stall
add wave -noupdate -expand -group {Main Memory I/F} /ni_tb/m_wb_o
add wave -noupdate -expand -group {Main Memory I/F} /ni_tb/m_data_o
add wave -noupdate -expand -group {Main Memory I/F} /ni_tb/m_addr_o
add wave -noupdate -expand -group {Buffer I/F} /ni_tb/b_wb_o
add wave -noupdate -expand -group {Buffer I/F} /ni_tb/b_data_o
add wave -noupdate -expand -group {Buffer I/F} /ni_tb/b_data_i
add wave -noupdate -expand -group {Buffer I/F} /ni_tb/b_addr_o
add wave -noupdate -expand -group {Router I/F} /ni_tb/r_clock_rx
add wave -noupdate -expand -group {Router I/F} /ni_tb/r_rx
add wave -noupdate -expand -group {Router I/F} /ni_tb/r_data_i
add wave -noupdate -expand -group {Router I/F} /ni_tb/r_credit_o
add wave -noupdate -expand -group Programming /ni_tb/recv_start
add wave -noupdate -expand -group Programming /ni_tb/recv_status
add wave -noupdate -expand -group Programming /ni_tb/prog_address
add wave -noupdate -expand -group Programming /ni_tb/prog_size
add wave -noupdate -expand -group Internals /ni_tb/ni_recv_mod/recv_state
add wave -noupdate -expand -group Internals /ni_tb/ni_recv_mod/recv_copy_addr
add wave -noupdate -expand -group Internals /ni_tb/ni_recv_mod/recv_copy_size
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {858 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 450
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {190 ns}
