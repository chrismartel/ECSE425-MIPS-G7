;# add waves to the Wave window

proc AddWaves {} {
    add wave -position end  sim:/execute_tb/I_reset
    add wave -position end  sim:/execute_tb/I_clk
    add wave -position end  sim:/execute_tb/I_rs
    add wave -position end  sim:/execute_tb/I_rt
    add wave -position end  sim:/execute_tb/I_imm_SE
    add wave -position end  sim:/execute_tb/I_imm_ZE
    add wave -position end  sim:/execute_tb/I_opcode
    add wave -position end  sim:/execute_tb/I_shamt
    add wave -position end  sim:/execute_tb/I_funct
    add wave -position end  sim:/execute_tb/I_addr
    add wave -position end  sim:/execute_tb/I_rs_data
    add wave -position end  sim:/execute_tb/I_rt_data
    add wave -position end  sim:/execute_tb/I_next_pc
    add wave -position end  sim:/execute_tb/I_rd
    add wave -position end  sim:/execute_tb/I_branch
    add wave -position end  sim:/execute_tb/I_jump
    add wave -position end  sim:/execute_tb/I_mem_read
    add wave -position end  sim:/execute_tb/I_mem_write
    add wave -position end  sim:/execute_tb/I_reg_write
    add wave -position end  sim:/execute_tb/I_mem_to_reg
    add wave -position end  sim:/execute_tb/O_alu_result
    add wave -position end  sim:/execute_tb/O_updated_next_pc
    add wave -position end  sim:/execute_tb/O_rt_data
    add wave -position end  sim:/execute_tb/O_rd
    add wave -position end  sim:/execute_tb/O_branch
    add wave -position end  sim:/execute_tb/O_jump
    add wave -position end  sim:/execute_tb/O_mem_read
    add wave -position end  sim:/execute_tb/O_mem_write
    add wave -position end  sim:/execute_tb/O_reg_write
    add wave -position end  sim:/execute_tb/O_mem_to_reg
    add wave -position end  sim:/execute_tb/O_stall
    add wave -position end  sim:/execute_tb/I_ex_data
    add wave -position end  sim:/execute_tb/I_mem_data
    add wave -position end  sim:/execute_tb/I_forward_rs
    add wave -position end  sim:/execute_tb/I_forward_rt
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
