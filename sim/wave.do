onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tbench/u1_orca/clk
add wave -noupdate /tbench/u1_orca/rst
add wave -noupdate /tbench/u1_orca/clock_rx_local
add wave -noupdate /tbench/u1_orca/rx_local
add wave -noupdate /tbench/u1_orca/data_in_local
add wave -noupdate /tbench/u1_orca/credit_o_local
add wave -noupdate /tbench/u1_orca/clock_tx_local
add wave -noupdate /tbench/u1_orca/tx_local
add wave -noupdate /tbench/u1_orca/data_out_local
add wave -noupdate /tbench/u1_orca/credit_i_local
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {26166910 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
configure wave -timelineunits ps
update
WaveRestoreZoom {26032 ns} {26288 ns}
