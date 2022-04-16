-- Copyright (C) 2020  Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions 
-- and other software and tools, and any partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License 
-- Subscription Agreement, the Intel Quartus Prime License Agreement,
-- the Intel FPGA IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Intel and sold by Intel or its authorized distributors.  Please
-- refer to the applicable agreement for further details, at
-- https://fpgasoftware.intel.com/eula.

-- ***************************************************************************
-- This file contains a Vhdl test bench template that is freely editable to   
-- suit user's needs .Comments are provided in each section to help the user  
-- fill out necessary details.                                                
-- ***************************************************************************
-- Generated on "04/15/2022 16:41:17"
                                                            
-- Vhdl Test Bench template for design  :  write_back
-- 
-- Simulation tool : ModelSim-Altera (VHDL)
-- 

LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;                                

ENTITY write_back_vhd_tst IS
END write_back_vhd_tst;
ARCHITECTURE write_back_arch OF write_back_vhd_tst IS
-- constants                                                 
-- signals                                                   
SIGNAL I_alu : STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
SIGNAL I_branch : STD_LOGIC := '0';
SIGNAL I_clk : STD_LOGIC:= '0';
SIGNAL I_en : STD_LOGIC:= '0';
SIGNAL I_jump : STD_LOGIC:= '0';
SIGNAL I_mem : STD_LOGIC_VECTOR(31 DOWNTO 0):= (others => '0');
SIGNAL I_mem_read : STD_LOGIC:= '0';
SIGNAL I_rd : STD_LOGIC_VECTOR(4 DOWNTO 0):= (others => '0');
SIGNAL I_regDwe : STD_LOGIC:= '0';
SIGNAL I_reset : STD_LOGIC:= '0';
SIGNAL I_stall : std_logic:= '0';
SIGNAL I_datad : STD_LOGIC_VECTOR (31 downto 0):= (others => '0');
SIGNAL I_rt :  STD_LOGIC_VECTOR (4 downto 0):= (others => '0');
SIGNAL I_rs :  STD_LOGIC_VECTOR (4 downto 0):= (others => '0');
SIGNAL I_we : STD_LOGIC:= '0';
SIGNAL O_mux : STD_LOGIC_VECTOR(31 DOWNTO 0):= (others => '0');
SIGNAL O_rd : STD_LOGIC_VECTOR(4 DOWNTO 0):= (others => '0');
SIGNAL O_we : STD_LOGIC:= '0';
SIGNAL O_datas :  STD_LOGIC_VECTOR (31 downto 0):= (others => '0');
SIGNAL O_datat :  STD_LOGIC_VECTOR (31 downto 0):= (others => '0');
COMPONENT write_back
	PORT (
	I_alu : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	I_branch : IN STD_LOGIC;
	I_clk : IN STD_LOGIC;
	I_en : IN STD_LOGIC;
	I_jump : IN STD_LOGIC;
	I_mem : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	I_mem_read : IN STD_LOGIC;
	I_rd : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
	I_regDwe : IN STD_LOGIC;
	I_reset : IN STD_LOGIC;
	I_stall : in std_logic;
	O_mux : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	O_rd : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
	O_we : OUT STD_LOGIC
	);
END COMPONENT;
COMPONENT regs
	PORT (
	I_clk : in  STD_LOGIC;
   I_reset : in STD_LOGIC;
   I_en : in  STD_LOGIC;
   I_datad : in  STD_LOGIC_VECTOR (31 downto 0);
   I_rt : in  STD_LOGIC_VECTOR (4 downto 0);
   I_rs : in  STD_LOGIC_VECTOR (4 downto 0);
   I_rd : in  STD_LOGIC_VECTOR (4 downto 0);
   I_we : in  STD_LOGIC;
   O_datas : out  STD_LOGIC_VECTOR (31 downto 0);
   O_datat : out  STD_LOGIC_VECTOR (31 downto 0)
	);
END COMPONENT;
CONSTANT clk_period : time := 1 ns;
BEGIN
	i1 : write_back
	PORT MAP (
-- list connections between master ports and signals
	I_alu => I_alu,
	I_branch => I_branch,
	I_clk => I_clk,
	I_en => I_en,
	I_jump => I_jump,
	I_mem => I_mem,
	I_mem_read => I_mem_read,
	I_rd => I_rd,
	I_regDwe => I_regDwe,
	I_reset => I_reset,
	I_stall => I_stall,
	O_mux => O_mux,
	O_rd => O_rd,
	O_we => O_we
	);
	
	i2 : regs
	PORT MAP (
-- list connections between master ports and signals
	I_clk => I_clk,
	I_en => I_en,
	I_reset => I_reset,
	I_datad => I_datad,
	I_rt => I_rt,
	I_rs => I_rs,
	I_rd => I_rd,
	I_we => I_we,
	O_datas => O_datas,
	O_datat => O_datat
	);
clk_process : PROCESS
BEGIN
	I_clk <= '0';
	WAIT FOR clk_period/2;
	I_clk <= '1';
	WAIT FOR clk_period/2;
END PROCESS;
init : PROCESS                                               
-- variable declarations                                     
BEGIN                                                        
        -- code that executes only once                      
	I_reset <= '1';
	I_jump <= '0';
	I_branch <= '0';
	I_stall <= '0';
	WAIT FOR 5*clk_period;
	I_reset <= '0';
	I_en <= '0';
	WAIT FOR 5*clk_period;
	
	I_en <= '1';
	I_regDwe <= '1';
	I_mem_read <= '0';
	I_alu <= "11111111111111111111111111111111";
	I_mem <= "00000000000000000000000000000001";
	I_rd <= "00001";
	
	WAIT FOR 5*clk_period;
	assert (O_mux = I_alu) report "Test 1: O_mux != I_alu" severity error;
	WAIT FOR 5*clk_period;
	I_datad <= I_alu;
	I_rs <= I_rd;
	I_we <= '1';
	WAIT FOR 25*clk_period;
	assert (O_mux = O_datas) report "Test 1: O_mux != O_datas" severity error;
	WAIT FOR 5*clk_period;
	
	I_jump <= '1';
	WAIT FOR 5*clk_period;
	assert (O_mux = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX") report "Jump Test: O_mux != Reset Value" severity error;
	I_jump <= '0';
	I_en <= '0';
	WAIT FOR 5*clk_period;
	
	I_en <= '1';
	I_regDwe <= '1';
	I_mem_read <= '1';
	I_rd <= "00010";
	WAIT FOR 5*clk_period;
	assert (O_mux = I_mem) report "Test 2: O_mux != I_mem" severity error;
	WAIT FOR 5*clk_period;
	I_datad <= I_mem;
	I_rs <= I_rd;
	I_we <= '1';
	WAIT FOR 25*clk_period;
	assert (O_mux = O_datas) report "Test 2: O_mux != O_datas" severity error;
	WAIT FOR 5*clk_period;
	
	I_branch <= '1';
	WAIT FOR 5*clk_period;
	assert (O_mux = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX") report "Branch: O_mux != Reset Value" severity error;
	I_branch <= '0';
	I_en <= '0';
	WAIT FOR 5*clk_period;
	
	I_en <= '1';
	I_regDwe <= '0';
	I_mem_read <= '1';
	I_rd <= "00011";
	WAIT FOR 5*clk_period;
	assert (O_mux = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX") report "Test 3: O_mux != Invalid input" severity error;
	WAIT FOR 5*clk_period;
	
	I_stall <= '1';
	WAIT FOR 5*clk_period;
	assert (O_mux = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX") report "Stall: O_mux != Reset Value" severity error;
	
WAIT;                                                       
END PROCESS init;                                           
                                         
END write_back_arch;
