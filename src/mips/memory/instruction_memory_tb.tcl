
;# add waves to the Wave window

proc AddWaves {} {
	add wave -position end  sim:/instruction_memory_tb/clk
	add wave -position end  sim:/instruction_memory_tb/writedata
	add wave -position end  sim:/instruction_memory_tb/address
	add wave -position end  sim:/instruction_memory_tb/memwrite
	add wave -position end  sim:/instruction_memory_tb/memread
	add wave -position end  sim:/instruction_memory_tb/readdata
	add wave -position end  sim:/instruction_memory_tb/wairequest
}

vlib work

;# compile components
vcom instruction_memory.vhd
vcom instruction_memory_tb.vhd

;# start simulation
vsim -t ps work.instruction_memory_tb

;# add the waves
AddWaves

;# run for 2 us
run 2 us
