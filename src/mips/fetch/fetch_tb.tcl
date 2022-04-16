
;# add waves to the Wave window

proc AddWaves {} {
	add wave -position end  sim:/fetch_tb/I_clk
	add wave -position end  sim:/fetch_tb/I_reset
	add wave -position end  sim:/fetch_tb/I_en
	add wave -position end  sim:/fetch_tb/I_stall
	add wave -position end  sim:/fetch_tb/I_jump
	add wave -position end  sim:/fetch_tb/I_branch
	add wave -position end  sim:/fetch_tb/I_pc_branch
	add wave -position end  sim:/fetch_tb/O_updated_pc
	add wave -position end  sim:/fetch_tb/O_instruction_address
	add wave -position end  sim:/fetch_tb/O_instruction
	add wave -position end  sim:/fetch_tb/O_memread
}

vlib work

;# compile components
vcom fetch.vhd
vcom fetch_tb.vhd

;# start simulation
vsim -t ps work.fetch_tb

;# add the waves
AddWaves

;# run for 2 us
run 2 us