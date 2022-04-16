
;# add waves to the Wave window

proc AddWaves {} {
	add wave -position end  sim:/fetch_tb/I_alu
	add wave -position end  sim:/fetch_tb/I_branch
	add wave -position end  sim:/fetch_tb/I_clk
	add wave -position end  sim:/fetch_tb/I_en
	add wave -position end  sim:/fetch_tb/I_jump
	add wave -position end  sim:/fetch_tb/I_mem
	add wave -position end  sim:/fetch_tb/I_mem_read 
	add wave -position end  sim:/fetch_tb/I_rd
	add wave -position end  sim:/fetch_tb/I_regDwe
	add wave -position end  sim:/fetch_tb/I_reset
	add wave -position end  sim:/fetch_tb/I_stall
	add wave -position end  sim:/fetch_tb/I_datad
	add wave -position end  sim:/fetch_tb/I_rt
	add wave -position end  sim:/fetch_tb/I_rs
	add wave -position end  sim:/fetch_tb/I_we
	add wave -position end  sim:/fetch_tb/O_mux
	add wave -position end  sim:/fetch_tb/O_rd
	add wave -position end  sim:/fetch_tb/O_we
	add wave -position end  sim:/fetch_tb/O_datas
	add wave -position end  sim:/fetch_tb/O_datat
	
}

vlib work

;# compile components
vcom Write_back.vhd
vcom write_back_tb.vhd

;# start simulation
vsim -t ps work.write_back_tb

;# add the waves
AddWaves

;# run for 2 us
run 2 us