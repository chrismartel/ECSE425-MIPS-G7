;# ECSE425 W2022
;# Final Project, Group 07
;# Memory Access Stage intermediate testbench script

proc AddWaves {} {
	add wave -position end  sim:/memory_tb/I_clk
	add wave -position end  sim:/memory_tb/I_mem_read
	add wave -position end  sim:/memory_tb/I_mem_write
	add wave -position end  sim:/memory_tb/I_reg_write
	add wave -position end  sim:/memory_tb/I_rt_data
	add wave -position end  sim:/memory_tb/I_alu_result
	add wave -position end  sim:/memory_tb/O_data_address
	add wave -position end  sim:/memory_tb/O_data_memread
	add wave -position end  sim:/memory_tb/I_data_waitrequest
	add wave -position end  sim:/memory_tb/O_data_memwrite
	add wave -position end  sim:/memory_tb/O_data_readdata
	add wave -position end  sim:/memory_tb/data_mem/ram_block(0)
	add wave -position end  sim:/memory_tb/data_mem/ram_block(4)
	add wave -position end  sim:/memory_tb/data_mem/ram_block(8)
	add wave -position end  sim:/memory_tb/data_mem/ram_block(16)
	add wave -position end  sim:/memory_tb/data_mem/address
	add wave -position end  sim:/memory_tb/data_mem/memwrite
	add wave -position end  sim:/memory_tb/data_mem/read_address_reg
	add wave -position end  sim:/memory_tb/data_mem/writedata
}

vlib work

vcom data_memory.vhd
vcom memory.vhd
vcom memory_tb.vhd

vsim memory_tb

force -deposit I_clk 0 0 ns, 1 0.5 ns -repeat 1 ns

AddWaves

run 20 ns