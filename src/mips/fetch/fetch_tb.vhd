-- ECSE425 W2022
-- Final Project, Group 07
-- Fetch Stage Testbench

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Fetch_tb is
end Fetch_tb;

architecture behavior of Fetch_tb is
constant clk_period : time := 1 ns;

component fetch is
	port (
        I_clk: in std_logic;
        I_reset: in std_logic;
	I_en: in std_logic;
        I_stall: in std_logic;
    
        -- I_jump flag
        I_jump: in std_logic;
        -- I_branch flag 
        I_branch: in std_logic; 
        -- incase of a I_branch or a I_jump use this
        I_pc_branch: in std_logic_vector (31 downto 0); 
        
        -- Memory Inputs:
        I_mem_instruction : in std_logic_vector (31 downto 0);
        I_waitrequest: in std_logic;
    
        -- Outputs for fetch unit
	O_updated_pc: out std_logic_vector (31 downto 0);
	O_instruction_address: out INTEGER RANGE 0 TO 32768-1;
	O_memread: out std_logic;
	O_instruction : out std_logic_vector (31 downto 0)
	);
end component;
	
signal I_clk : std_logic := '0';
signal I_reset : std_logic := '0';
signal I_en: std_logic := '0';
signal I_stall : std_logic := '0';
signal I_jump : std_logic := '0';
signal I_branch : std_logic := '0';
signal I_pc_branch : std_logic_vector (31 downto 0);
signal I_mem_instruction : std_logic_vector (31 downto 0);
signal I_waitrequest : std_logic := '1';
signal O_updated_pc : std_logic_vector (31 downto 0);
signal O_instruction_address : INTEGER RANGE 0 TO 32768-1;
signal O_instruction : std_logic_vector (31 downto 0);
signal O_memread : std_logic := '0';

begin

dut_fetch: fetch
port map(
        I_clk => I_clk,
        I_reset => I_reset,
	I_en => I_en,
        I_stall => I_stall,
        I_jump => I_jump,
        I_branch => I_branch,
        I_pc_branch => I_pc_branch,
        I_mem_instruction => I_mem_instruction,
        I_waitrequest => I_waitrequest,
        O_updated_pc => O_updated_pc,
        O_instruction_address => O_instruction_address,
        O_memread =>  O_memread
);


clk_process : process
begin
  I_clk <= '0';
  wait for clk_period/2;
  I_clk <= '1';
  wait for clk_period/2;
end process;

test_process : process
begin
	I_en <= '1';
	I_stall <= '0'; -- assume there is no I_stall
	I_jump <= '0';	--  assume there is no I_jump
	I_branch <= '0'; -- assume there is no I_branch
    	I_waitrequest <= '0'; -- assume there is no wait

	-- Test case 1: Fetch instruction pc = 0
    	report "----- Test 1: fetch pc = 0 -----";
	I_pc_branch <= std_logic_vector( to_unsigned( 5, I_pc_branch'length));
	I_branch <= '0';
    	wait for clk_period;
	assert unsigned(O_updated_pc) = 4 report "updated pc test 1 is wrong" severity error;

    	report "----- Test 2: fetch pc = 4 -----";
	I_pc_branch <= std_logic_vector( to_unsigned( 5, I_pc_branch'length));
	I_branch <= '0';
    	wait for clk_period;
	assert unsigned(O_updated_pc) = 8 report "updated pc test 2 is wrong" severity error;
	
    	report "----- Test 3: fetch pc = 4 but pc I_branch = 5 -----";
	I_pc_branch <= std_logic_vector(to_unsigned( 5, I_pc_branch'length));
	I_branch <= '1';
    	wait for clk_period;
	assert unsigned(O_updated_pc) = 5 report "pc I_branch test 3 is wrong" severity error;
	
    report "----- Confirming all tests have ran -----";
    wait;
end process;
end;
