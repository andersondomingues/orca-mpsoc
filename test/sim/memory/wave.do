onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ram_tb/memory0lb/ram1
add wave -noupdate /ram_tb/address_width
add wave -noupdate /ram_tb/memory_file
add wave -noupdate /ram_tb/clock
add wave -noupdate /ram_tb/reset
add wave -noupdate /ram_tb/counter
add wave -noupdate /ram_tb/read_ram
add wave -noupdate -expand /ram_tb/we
add wave -noupdate -expand /ram_tb/memory0lb/ram1
add wave -noupdate /ram_tb/memory0ub/ram1
add wave -noupdate /ram_tb/memory1lb/ram1
add wave -noupdate -expand /ram_tb/memory1ub/ram1
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
WaveRestoreZoom {2282 ns} {3038 ns}
