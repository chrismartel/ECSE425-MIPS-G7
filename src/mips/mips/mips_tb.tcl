

;# add waves to the Wave window

proc AddWaves {} {
	add wave -position end  sim:/mips_tb/I_clk
	add wave -position end  sim:/mips_tb/I_reset
	add wave -position end  sim:/mips_tb/I_en
	add wave -position end  sim:/mips_tb/I_fwd_en
}

vlib work

;# compile components
vcom fetch.vhd
vcom decode.vhd
vcom execute.vhd
vcom memory.vhd
vcom write_back.vhd
vcom forwarding_unit.vhd
vcom mips.vhd
vcom mips_tb.vhd

;# start simulation
vsim -t ps work.mips_tb

;# add the waves
AddWaves

;# run for 2 us
run 20 us