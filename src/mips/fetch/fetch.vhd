library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fetch is

port(
	-- INPUTS

	-- Synchronoucity Inputs
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
	waitrequest : in std_logic;

	-- Outputs for fetch unit
	pc_updated: out std_logic_vector (31 downto 0);
	instruction_address: out std_logic_vector (31 downto 0);
	memread: out std_logic
);

end fetch;

architecture arch of fetch is
	signal pc: std_logic_vector(31 downto 0) := "00000000000000000000000000000000"; -- initial pc
	begin
	fetch_process: process(clk, reset)	
	begin
		-- if reset
		if reset'event and reset = '1' then
			pc_updated <= (others => '0');
			instruction_address <= (others => '0');
			memread <= '0';
		
		-- if clock is high
		elsif clk'event and clk = '1' then
			-- if there is no stall start fetch component
			if stall = '0' then
				if waitrequest = '1' then
					instruction_address <= pc;
					memread <= '1';
				elsif waitrequest = '0' then
					-- no jump or branch so pc is incremented
					if jump = '0' and branch = '0' then 
						pc_updated <= std_logic_vector(unsigned(pc) + 4); -- pc + 4
						pc <= std_logic_vector(unsigned(pc) + 4);
						-- instruction_address <= mem_instruction;
					-- jump or branch so pc is set to the branch or jump address
					else 
						pc_updated <= pc_branch;
						pc <= pc_branch;
					end if;
					memread <= '0';
				end if;
			end if;
		end if;
	end process;
	end arch;