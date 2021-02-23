onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group Control /ni_tb/clock
add wave -noupdate -expand -group Control /ni_tb/reset
add wave -noupdate -expand -group Control /ni_tb/stall
add wave -noupdate -expand -group Memory /ni_tb/m_data_i
add wave -noupdate -expand -group Memory /ni_tb/m_addr_o
add wave -noupdate -expand -group Memory /ni_tb/m_wb_o
add wave -noupdate -expand -group Router /ni_tb/r_clock_tx
add wave -noupdate -expand -group Router /ni_tb/r_tx
add wave -noupdate -expand -group Router /ni_tb/r_data_o
add wave -noupdate -expand -group Router /ni_tb/r_credit_i
add wave -noupdate -expand -group Programming /ni_tb/send_start
add wave -noupdate -expand -group Programming /ni_tb/send_status
add wave -noupdate -expand -group Programming /ni_tb/prog_address
add wave -noupdate -expand -group Programming /ni_tb/prog_size
add wave -noupdate -expand -group Internals /ni_tb/ni_sender_mod/send_state
add wave -noupdate -expand -group Internals /ni_tb/ni_sender_mod/send_copy_addr
add wave -noupdate -expand -group Internals /ni_tb/ni_sender_mod/send_copy_size
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
WaveRestoreZoom {0 ns} {756 ns}
