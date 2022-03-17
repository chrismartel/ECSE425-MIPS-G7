library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity forwarding_unit is

port(
	-- INPUTS
	clk : in std_logic;
	reset : in std_logic;

	ex_rd: in std_logic_vector (4 downto 0); -- destination register for instruction completed by the ex stage
	mem_rd: in std_logic_vector (4 downto 0); -- destination register for instruction completed by the mem stage
	ex_reg_write: in std_logic; -- reg_write setting for instruction completed by ex stage
	mem_reg_write: in std_logic; -- reg_write setting for instruction completed by mem stage
	id_rs: in std_logic_vector(4 downto 0); -- left operand for instruction completed by id stage
	id_rt: in std_logic_vector(4 downto 0); -- right operand for instruction completed by id stage

	-- OUTPUTS

	-- '00' -> read from ID inputs
	-- '01' -> read from EX stage output
	-- '10' -> read from MEM stage output

	forward_rs: out std_logic_vector (1 downto 0); -- selection of left operand for ALU
	forward_rt: out std_logic_vector (1 downto 0) -- selection of right operand for ALU
);
end forwarding_unit;

architecture arch of forwarding_unit is

begin
	-- forwarding pprocess
	forwarding_process: process(clk, reset)
	begin
		-- asynchronous reset active high
		if reset'event and reset = '1' then
			-- by defaut, read from id stage outputs (no forwarding)
			forward_rs <= "00";
			forward_rt <= "00";
			
		-- synchronous clock active high
		elsif clk'event and clk = '1' then
			-- rs input
			if ex_reg_write = '1' and id_rs = ex_rd then
				forward_rs <= "01"; -- read from ex stage output
			elsif mem_reg_write = '1' and id_rs = mem_rd then
				forward_rs <= "10"; -- read from mem stage output
			else
				forward_rs <= "00"; -- read from id stage output
			end if;

			-- rt input
			if ex_reg_write = '1' and id_rt = ex_rd then
				forward_rt <= "01"; -- read from ex stage output
			elsif mem_reg_write = '1' and id_rt = mem_rd then
				forward_rt <= "10"; -- read from mem stage output
			else
				forward_rt <= "00"; -- read from id stage output
			end if;
		end if;
	end process;
end arch;