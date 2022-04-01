;# add waves to the Wave window

proc AddWaves {} {
    add wave -position end  sim:/execute_tb/reset
    add wave -position end  sim:/execute_tb/clk
    add wave -position end  sim:/execute_tb/instruction
    add wave -position end  sim:/execute_tb/rs_data_in
    add wave -position end  sim:/execute_tb/rt_data_in
    add wave -position end  sim:/execute_tb/next_pc
    add wave -position end  sim:/execute_tb/destination_register_in
    add wave -position end  sim:/execute_tb/branch_in
    add wave -position end  sim:/execute_tb/jump_in
    add wave -position end  sim:/execute_tb/mem_read_in
    add wave -position end  sim:/execute_tb/mem_write_in
    add wave -position end  sim:/execute_tb/reg_write_in
    add wave -position end  sim:/execute_tb/mem_to_reg_in
    add wave -position end  sim:/execute_tb/alu_result
    add wave -position end  sim:/execute_tb/updated_next_pc
    add wave -position end  sim:/execute_tb/rt_data_out
    add wave -position end  sim:/execute_tb/destination_register_out
    add wave -position end  sim:/execute_tb/branch_out
    add wave -position end  sim:/execute_tb/jump_out
    add wave -position end  sim:/execute_tb/mem_read_out
    add wave -position end  sim:/execute_tb/mem_write_out
    add wave -position end  sim:/execute_tb/reg_write_out
    add wave -position end  sim:/execute_tb/mem_to_reg_out
    add wave -position end  sim:/execute_tb/stall_out
    add wave -position end  sim:/execute_tb/ex_data
    add wave -position end  sim:/execute_tb/mem_data
    add wave -position end  sim:/execute_tb/forward_rs
    add wave -position end  sim:/execute_tb/forward_rt
}

vlib work

;# compile components
vcom execute.vhd
vcom execute_tb.vhd

;# start simulation
vsim -t ps work.execute_tb

;# add the waves
AddWaves

;# run for 2 us
run 2 us
