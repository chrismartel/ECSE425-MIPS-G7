library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fetch is

port(
	-- INPUTS

	-- Synchronoucity Inputs
	I_clk: in std_logic;
	I_reset: in std_logic;
	I_en: in std_logic;
	I_stall: in std_logic;

	-- I_jump flag
	I_jump: in std_logic;
	-- branch flag
	I_branch: in std_logic;
	-- incase of a branch or a jump use this
	I_pc_branch: in std_logic_vector (31 downto 0);

	-- Memory Inputs:
	I_mem_instruction : in std_logic_vector (31 downto 0);
	I_waitrequest : in std_logic;

	-- Outputs for fetch unit
	O_updated_pc: out std_logic_vector (31 downto 0);
	O_instruction_address: out INTEGER RANGE 0 TO 32768-1;
	O_memread: out std_logic;
	O_instruction : out std_logic_vector (31 downto 0)
);

end fetch;

architecture arch of fetch is
	signal pc: std_logic_vector(31 downto 0) := "00000000000000000000000000000000"; -- initial pc
	begin
	fetch_process: process(I_clk, I_reset)
	begin
		-- if I_reset
		if I_reset'event and I_reset = '1' then
				O_updated_pc <= (others => '0');
				O_instruction_address <= 0;
				O_memread <= '0';
		-- if clock is high
		elsif I_clk'event and I_clk = '1' then
			if I_en = '1' then
			-- if there is no I_stall start fetch component
			if I_stall = '0' then
				--Check if Instruction Memory is available (line goes low when data is ready)
				if I_waitrequest = '1' then
					--Ask Instruction Memory for next instruction
					O_instruction_address <=to_integer(unsigned(pc));
					O_memread <= '1';
				end if;
			end if;
			-- no jump or branch so pc is incremented
			if I_jump = '0' and I_branch = '0' then
				O_updated_pc <= std_logic_vector(unsigned(pc) + 4); -- pc + 4
				pc <= std_logic_vector(unsigned(pc) + 4);
			-- jump or branch so pc is set to the branch or jump address
			else
				O_updated_pc <= I_pc_branch;
				pc <= I_pc_branch;
			end if;
			

		-- Halfway through stage time (1cc) check if data can be read from cache, if so pass onto next stage
		elsif I_clk'event and I_clk = '0' then
			if I_waitrequest = '0' then
				--Pass through the retrieved instruction
				O_instruction <= I_mem_instruction;
				O_memread <= '0';
			end if;
			end if;
		end if;
	end process;
	end arch;