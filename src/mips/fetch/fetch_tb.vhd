library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Fetch_tb is
end Fetch_tb;

architecture behavior of Fetch_tb is
constant clk_period : time := 10 ns;

component fetch is
	port (
        clk: in std_logic;
        reset: in std_logic;
        stall: in std_logic;
    
        -- jump flag
        jump: in std_logic;
        -- branch flag 
        branch: in std_logic; 
        -- incase of a branch or a jump use this
        pc_branch: in std_logic_vector (31 downto 0); 
        
        -- Memory Inputs:
        mem_instruction : in std_logic_vector (31 downto 0);
        waitrequest: in std_logic;
    
        -- Outputs for fetch unit
        pc_updated: out std_logic_vector (31 downto 0);
        instruction_address: out std_logic_vector (31 downto 0);
        memread: out std_logic
	);
end component;
	
signal clk : std_logic := '0';
signal reset : std_logic := '0';
signal stall : std_logic := '0';
signal jump : std_logic := '0';
signal branch : std_logic := '0';
signal pc_branch : std_logic_vector (31 downto 0);
signal mem_instruction : std_logic_vector (31 downto 0);
signal waitrequest : std_logic := '1';
signal pc_updated : std_logic_vector (31 downto 0);
signal instruction_address : std_logic_vector (31 downto 0);
signal memread : std_logic := '0';

begin

dut_fetch: fetch
port map(
        clk => clk,
        reset => reset,
        stall => stall,
        jump => jump,
        branch => branch,
        pc_branch => pc_branch,
        mem_instruction => mem_instruction,
        waitrequest => waitrequest,
        pc_updated => pc_updated,
        instruction_address => instruction_address,
        memread =>  memread
);


clk_process : process
begin
  clk <= '0';
  wait for clk_period/2;
  clk <= '1';
  wait for clk_period/2;
end process;

test_process : process
begin
	stall <= '0'; -- assume there is no stall
	jump <= '0';	--  assume there is no jump
	branch <= '0'; -- assume there is no branch
    waitrequest <= '0'; -- assume there is no wait

	-- Test case 1: Fetch instruction pc = 0
    report "----- Test 1: fetch pc = 0 -----";
	pc_branch <= std_logic_vector( to_unsigned( 5, pc_branch'length));
	branch <= '0';
    wait for clk_period;
	assert unsigned(pc_updated) = 4 report "updated pc test 1 is wrong" severity error;

    report "----- Test 2: fetch pc = 4 -----";
	pc_branch <= std_logic_vector( to_unsigned( 5, pc_branch'length));
	branch <= '0';
    wait for clk_period;
	assert unsigned(pc_updated) = 8 report "updated pc test 2 is wrong" severity error;
	
    report "----- Test 3: fetch pc = 4 but pc branch = 5 -----";
	pc_branch <= std_logic_vector(to_unsigned( 5, pc_branch'length));
	branch <= '1';
    wait for clk_period;
	assert unsigned(pc_updated) = 5 report "pc branch test 3 is wrong" severity error;
	
    report "----- Confirming all tests have ran -----";
    wait;
end process;
end;