-- ECSE425 W2022
-- Final Project, Group 07
-- Fetch Stage

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

	-- Outputs for fetch unit
	O_updated_pc: out std_logic_vector (31 downto 0);
	O_instruction_address: out INTEGER RANGE 0 TO 32768-1;
	O_memread: out std_logic
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
						--Ask Instruction Memory for next instruction
						O_instruction_address <=to_integer(unsigned(pc));
						O_memread <= '1';
					-- end if;
				elsif I_stall = '1' then
					O_memread <= '0';
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
			end if;
		end if;
	end process;
	end arch;
