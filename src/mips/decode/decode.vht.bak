-- Copyright (C) 2017  Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License 
-- Subscription Agreement, the Intel Quartus Prime License Agreement,
-- the Intel FPGA IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Intel and sold by Intel or its authorized distributors.  Please
-- refer to the applicable agreement for further details.

-- ***************************************************************************
-- This file contains a Vhdl test bench template that is freely editable to   
-- suit user's needs .Comments are provided in each section to help the user  
-- fill out necessary details.                                                
-- ***************************************************************************
-- Generated on "04/07/2022 14:49:49"
                                                            
-- Vhdl Test Bench template for design  :  regs
-- 
-- Simulation tool : ModelSim-Altera (VHDL)
-- 

LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;                                

ENTITY decode_vhd_tst IS
END decode_vhd_tst;
ARCHITECTURE decode_arch OF decode_vhd_tst IS
-- constants                                                 
-- signals                                                   
SIGNAL I_clk :  STD_LOGIC;
      SIGNAL     I_dataInst :  STD_LOGIC_VECTOR (31 downto 0);
          SIGNAL I_en :   STD_LOGIC;
			SIGNAL  I_pc:  STD_LOGIC_VECTOR (31 downto 0);
		SIGNAL	I_ex_rd:  std_logic_vector (4 downto 0);
			 SIGNAL I_ex_reg_write:  std_logic;
		SIGNAL	  I_mem_rd:  std_logic_vector (4 downto 0);
		SIGNAL	  I_mem_reg_write: std_logic;
			SIGNAL  O_next_pc:  STD_LOGIC_VECTOR (31 downto 0);
        SIGNAL   O_rs :   STD_LOGIC_VECTOR (4 downto 0);
        SIGNAL   O_rt :   STD_LOGIC_VECTOR (4 downto 0);
        SIGNAL   O_rd :   STD_LOGIC_VECTOR (4 downto 0);
        SIGNAL   O_dataIMM_SE :   STD_LOGIC_VECTOR (31 downto 0);
			SIGNAL  O_dataIMM_ZE :  STD_LOGIC_VECTOR (31 downto 0);
         SIGNAL  O_regDwe :  STD_LOGIC;
        SIGNAL   O_aluop :  STD_LOGIC_VECTOR (5 downto 0);
			SIGNAL  O_shamt: STD_LOGIC_VECTOR (4 downto 0);
			SIGNAL  O_funct: STD_LOGIC_VECTOR (5 downto 0);
			SIGNAL  O_branch: STD_LOGIC;
			SIGNAL  O_jump: STD_LOGIC;
			SIGNAL  O_mem_read: STD_LOGIC;
			SIGNAL  O_mem_write: STD_LOGIC;
			SIGNAL  O_mem_to_reg: STD_LOGIC;
			SIGNAL  O_addr: STD_LOGIC_VECTOR (25 downto 0);
			Signal I_reset: STD_LOGIC;
COMPONENT decode
	PORT (
	I_clk : in  STD_LOGIC;
           I_dataInst : in  STD_LOGIC_VECTOR (31 downto 0);
           I_en : in  STD_LOGIC;
			  I_ex_rd: in std_logic_vector (4 downto 0);
			  I_ex_reg_write: in std_logic;
			  I_mem_rd: in std_logic_vector (4 downto 0);
			  I_mem_reg_write: in std_logic;
			  I_pc: in STD_LOGIC_VECTOR (31 downto 0);
			  O_next_pc: out STD_LOGIC_VECTOR (31 downto 0);
           O_rs : out  STD_LOGIC_VECTOR (4 downto 0);
           O_rt : out  STD_LOGIC_VECTOR (4 downto 0);
           O_rd : out  STD_LOGIC_VECTOR (4 downto 0);
           O_dataIMM_SE : out  STD_LOGIC_VECTOR (31 downto 0);
			  O_dataIMM_ZE : out STD_LOGIC_VECTOR (31 downto 0);
           O_regDwe : out  STD_LOGIC;
           O_aluop : out  STD_LOGIC_VECTOR (5 downto 0);
			  O_shamt: out STD_LOGIC_VECTOR (4 downto 0);
			  O_funct: out STD_LOGIC_VECTOR (5 downto 0);
			  O_branch: out STD_LOGIC;
			  O_jump: out STD_LOGIC;
			  O_mem_read: out STD_LOGIC;
			  O_mem_write: out STD_LOGIC;
			  O_mem_to_reg: out STD_LOGIC;
			  O_addr: out STD_LOGIC_VECTOR (25 downto 0);
			  I_reset: in STD_LOGIC
	);
END COMPONENT;
CONSTANT clk_period : time := 10 ns;
BEGIN
	i1 : decode
	PORT MAP (
-- list connections between master ports and signals
	I_clk => I_clk,
	I_dataInst => I_dataInst,
	I_en => I_en,
	I_pc=> I_pc,
	I_ex_rd => I_ex_rd,
	I_ex_reg_write => I_ex_reg_write,
	I_mem_rd => I_mem_rd,
	I_mem_reg_write => I_mem_reg_write,
	O_next_pc => O_next_pc,
	O_rs => O_rs,
	 O_rt =>  O_rt,
	O_rd => O_rd,
	O_dataIMM_SE => O_dataIMM_SE,
	 O_dataIMM_ZE =>  O_dataIMM_ZE,
	O_regDwe => O_regDwe,
	O_aluop => O_aluop,
	O_shamt => O_shamt,
	O_funct => O_funct,
	 O_branch =>    O_branch,
	O_jump => O_jump,
	O_mem_read => O_mem_read,
	 O_mem_write =>  O_mem_write,
	 O_mem_to_reg=>     O_mem_to_reg,
	O_addr => O_addr,
	I_reset => I_reset
	
	);
clk_process : PROCESS
BEGIN
	I_clk <= '0';
	WAIT FOR clk_period/2;
	I_clk <= '1';
	WAIT FOR clk_period/2;
END PROCESS;                                          
always : PROCESS                                              
-- optional sensitivity list                                  
-- (        )                                                 
-- variable declarations                                      
BEGIN                                                         
        -- code executes for every event on sensitivity list  
	I_dataInst <= "00000000001000100001100000100000";
	I_pc <= "00000000000000000000000000000000";
	I_reset <= '0';
	I_ex_rd <= "00000";
	I_ex_reg_write <= '1';
	I_mem_rd <= "00001";
	I_mem_reg_write <= '0';
	I_en <= '1';
	
	
	
	WAIT FOR 3*clk_period;
	I_en <= '0';
	Wait for 3*clk_period;
		
	I_dataInst <= "00000000001000100001100000100000";
	I_pc <= "00000000000000000000000000000000";
	I_reset <= '0';
	I_ex_rd <= "00000";
	I_ex_reg_write <= '1';
	I_mem_rd <= "00011";
	I_mem_reg_write <= '1';
	I_en <= '1';
	
	
	
	WAIT FOR 3*clk_period;
	I_en <= '0';
	Wait for 3*clk_period;
	
	I_dataInst <= "00000000001000100001100000100000";
	I_pc <= "00000000000000000000000000000000";
	I_reset <= '0';
	I_ex_rd <= "00000";
	I_ex_reg_write <= '1';
	I_mem_rd <= "00010";
	I_mem_reg_write <= '1';
	I_en <= '1';	
	
	
	WAIT FOR 3*clk_period;
	I_en <= '0';
	Wait for 3*clk_period;
	
	I_dataInst <= "00000000001000100001100000100000";
	I_pc <= "00000000000000000000000000000000";
	I_reset <= '0';
	I_ex_rd <= "00001";
	I_ex_reg_write <= '1';
	I_mem_rd <= "00000";
	I_mem_reg_write <= '0';
	I_en <= '1';
	
	WAIT FOR 3*clk_period;
	I_en <= '0';
	Wait for 3*clk_period;
	
	I_dataInst <= "00000000001000100001100000100000";
	I_pc <= "00000000000000000000000000000000";
	I_reset <= '0';
	I_ex_rd <= "00010";
	I_ex_reg_write <= '1';
	I_mem_rd <= "00000";
	I_mem_reg_write <= '0';
	I_en <= '1';
	
	WAIT FOR 3*clk_period;
	I_en <= '0';
	Wait for 3*clk_period;
	
	
	I_dataInst <= "00000000001000100001100000100000";
	I_pc <= "00000000000000000000000000000000";
	I_reset <= '0';
	I_ex_rd <= "00000";
	I_ex_reg_write <= '0';
	I_mem_rd <= "00011";
	I_mem_reg_write <= '1';
	I_en <= '1';
	
	
	
	WAIT FOR 3*clk_period;
	I_en <= '0';
	Wait for 3*clk_period;
	
	I_dataInst <= "00000000001000100001100000100000";
	I_pc <= "00000000000000000000000000000000";
	I_reset <= '0';
	I_ex_rd <= "00011";
	I_ex_reg_write <= '1';
	I_mem_rd <= "00011";
	I_mem_reg_write <= '0';
	I_en <= '1';
	
	
	
	WAIT FOR 3*clk_period;
	I_en <= '0';
	Wait for 3*clk_period;
	
	I_dataInst <= "00000000001000100001100000100000";
	I_pc <= "00000000000000000000000000000000";
	I_reset <= '0';
	I_ex_rd <= "00011";
	I_ex_reg_write <= '1';
	I_mem_rd <= "00011";
	I_mem_reg_write <= '1';
	I_en <= '1';
	
	
	
	WAIT FOR 3*clk_period;
	I_en <= '0';
	Wait for 3*clk_period;
	
	
	I_dataInst <= "00010000100001011000000000000000";
	I_pc <= "00000000000000000000000000000010";
	I_ex_rd <= "00000";
	I_ex_reg_write <= '1';
	I_mem_rd <= "00011";
	I_mem_reg_write <= '0';
	I_en <= '1';
	
	WAIT FOR 3* clk_period;
	
	I_en <= '0';
	Wait for 3*clk_period;
	I_dataInst <= "00010000100001001000000000000000";
	I_pc <= "00000000000000000000000000000010";
	I_ex_rd <= "00100";
	I_ex_reg_write <= '1';
	I_mem_rd <= "00011";
	I_mem_reg_write <= '0';
	
	I_en <= '1';
	WAIT FOR 3* clk_period;
	
	I_en <= '0';
	Wait for 3*clk_period;
	I_dataInst <= "00010100100001001000000000000000";
	I_pc <= "00000000000000000000000000000010";
	I_en <= '1';

	
WAIT;                                                        
END PROCESS always;                                          
END decode_arch;
