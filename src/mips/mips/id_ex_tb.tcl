
;# add waves to the Wave window

proc AddWaves {} {
	add wave -position end  sim:/id_ex_tb/I_reset
	add wave -position end  sim:/id_ex_tb/I_clk
	add wave -position end  sim:/id_ex_tb/I_en
	add wave -position end  sim:/id_ex_tb/I_fwd_en
	add wave -position end  sim:/id_ex_tb/RF_I_rs
	add wave -position end  sim:/id_ex_tb/RF_I_rt
	add wave -position end  sim:/id_ex_tb/RF_I_rd
	add wave -position end  sim:/id_ex_tb/RF_I_datad
	add wave -position end  sim:/id_ex_tb/RF_I_we
	add wave -position end  sim:/id_ex_tb/RF_O_datas
	add wave -position end  sim:/id_ex_tb/RF_O_datat
	add wave -position end  sim:/id_ex_tb/ID_O_next_pc
	add wave -position end  sim:/id_ex_tb/ID_O_rs
	add wave -position end  sim:/id_ex_tb/ID_O_rt
	add wave -position end  sim:/id_ex_tb/ID_O_rd
	add wave -position end  sim:/id_ex_tb/ID_O_dataIMM_SE
	add wave -position end  sim:/id_ex_tb/ID_O_dataIMM_ZE
	add wave -position end  sim:/id_ex_tb/ID_O_regDwe
	add wave -position end  sim:/id_ex_tb/ID_O_aluop
	add wave -position end  sim:/id_ex_tb/ID_O_shamt
	add wave -position end  sim:/id_ex_tb/ID_O_funct
	add wave -position end  sim:/id_ex_tb/ID_O_branch
	add wave -position end  sim:/id_ex_tb/ID_O_jump
	add wave -position end  sim:/id_ex_tb/ID_O_mem_read
	add wave -position end  sim:/id_ex_tb/ID_O_mem_write
	add wave -position end  sim:/id_ex_tb/ID_O_addr
	add wave -position end  sim:/id_ex_tb/ID_O_stall
	add wave -position end  sim:/id_ex_tb/EX_O_alu_result
	add wave -position end  sim:/id_ex_tb/EX_O_updated_next_pc
	add wave -position end  sim:/id_ex_tb/EX_O_rt_data
	add wave -position end  sim:/id_ex_tb/EX_O_stall
	add wave -position end  sim:/id_ex_tb/EX_O_rd
	add wave -position end  sim:/id_ex_tb/EX_O_branch
	add wave -position end  sim:/id_ex_tb/EX_O_jump
	add wave -position end  sim:/id_ex_tb/EX_O_mem_read
	add wave -position end  sim:/id_ex_tb/EX_O_mem_write
	add wave -position end  sim:/id_ex_tb/EX_O_reg_write
	add wave -position end  sim:/id_ex_tb/F_O_dataInst
	add wave -position end  sim:/id_ex_tb/F_O_pc
	add wave -position end  sim:/id_ex_tb/MEM_O_rd
	add wave -position end  sim:/id_ex_tb/MEM_O_reg_write
	add wave -position end  sim:/id_ex_tb/MEM_O_result
	add wave -position end  sim:/id_ex_tb/FWD_O_forward_rs
	add wave -position end  sim:/id_ex_tb/FWD_O_forward_rt
}

vlib work

;# compile components
vcom execute.vhd
vcom decode.vhd
vcom regs.vhd
vcom forwarding_unit.vhd
vcom id_ex_tb.vhd

;# start simulation
vsim -t ps work.id_ex_tb

;# add the waves
AddWaves

;# run for 2 us
run 2 us