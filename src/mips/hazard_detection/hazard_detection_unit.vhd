
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_detection_unit is
generic(
	number_of_registers : INTEGER := 32 -- number of blocks in cache
);
port(
	-- INPUTS
	clk : in std_logic;
	reset : in std_logic;

	id_rd: in std_logic_vector (4 downto 0); -- destination register for instruction completed by the id stage
	id_reg_write: in std_logic; -- reg_write setting for instruction completed by id stage
	
	ex_rd: in std_logic_vector (4 downto 0); -- destination register for instruction completed by the ex stage
	ex_reg_write: in std_logic; -- reg_write setting for instruction completed by ex stage

	mem_rd: in std_logic_vector (4 downto 0); -- destination register for instruction completed by the mem stage
	mem_reg_write: in std_logic; -- reg_write setting for instruction completed by mem stage


	-- OUTPUTS
	
	-- Indicate presence of hazard for each register in the RF.
	-- '1': hazard
	-- '0': no hazard
	hazards: out std_logic_vector(number_of_registers-1 downto 0)
);

end hazard_detection_unit;

architecture arch of hazard_detection_unit is

begin
	-- forwarding pprocess
	hazard_detection_process: process(clk, reset)
	begin
		-- asynchronous reset active high
		if reset'event and reset = '1' then
			-- by defaut, no hazard
			hazards <= (others=>'0');
		-- synchronous clock active high
		elsif clk'event and clk = '1' then

			-- check if hazard exists on each register
			for i in 0 to number_of_registers-1 loop

				-- if id stage writes to register file there exist data hazard
				-- on destination register.
				if i = to_integer(unsigned(id_rd)) and id_reg_write ='1'  then
					hazards(i) <= '1';
				
				-- if ex stage writes to register file there exist data hazard
				-- on destination register.
				elsif i = to_integer(unsigned(ex_rd)) and ex_reg_write ='1'  then
					hazards(i) <= '1';

				-- if mem stage writes to register file there exist data hazard
				-- on destination register.
				elsif i = to_integer(unsigned(mem_rd)) and mem_reg_write ='1' then
					hazards(i) <= '1';

				-- no hazard
				else
					hazards(i) <= '0';
				end if;			
			end loop;
		end if;
	end process;
end arch;