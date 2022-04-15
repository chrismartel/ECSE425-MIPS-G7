-- ECSE425 W2022
-- Final Project, Group 07
-- Forwarding Unit

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity forwarding_unit is

port(
	-- INPUTS
	I_clk : in std_logic;
	I_reset : in std_logic;
	I_en: in std_logic;

	I_id_rd: in std_logic_vector (4 downto 0); -- destination register for instruction completed by the ex stage
	I_ex_rd: in std_logic_vector (4 downto 0); -- destination register for instruction completed by the mem stage
	I_id_reg_write: in std_logic; -- reg_write setting for instruction completed by ex stage
	I_ex_reg_write: in std_logic; -- reg_write setting for instruction completed by mem stage
	I_id_mem_read: in std_logic; -- reg_write setting for instruction completed by ex stage
	I_f_rs: in std_logic_vector(4 downto 0); -- left operand for instruction completed by id stage
	I_f_rt: in std_logic_vector(4 downto 0); -- right operand for instruction completed by id stage

	-- OUTPUTS

	-- '00' -> read from ID inputs
	-- '01' -> read from EX stage output
	-- '10' -> read from MEM stage output

	O_forward_rs: out std_logic_vector (1 downto 0); -- selection of left operand for ALU
	O_forward_rt: out std_logic_vector (1 downto 0) -- selection of right operand for ALU
);
end forwarding_unit;

architecture arch of forwarding_unit is

-- constants
	constant FORWARDING_NONE : std_logic_vector (1 downto 0):= "00";
	constant FORWARDING_EX : std_logic_vector (1 downto 0):= "01";
	constant FORWARDING_MEM : std_logic_vector (1 downto 0):= "10";

begin
	-- forwarding pprocess
	forwarding_process: process(I_clk, I_reset)
	begin
		-- asynchronous I_reset active high
		if I_reset'event and I_reset = '1' then
			-- by defaut, read from id stage outputs (no forwarding)
			O_forward_rs <= FORWARDING_NONE;
			O_forward_rt <= FORWARDING_NONE;
			
		-- synchronous clock active high
		elsif I_clk'event and I_clk = '1' then
			if I_en = '1' then
				-- rs input
				if I_id_reg_write = '1' and I_id_mem_read = '0' and I_f_rs = I_id_rd then
					O_forward_rs <= FORWARDING_EX; -- read from ex stage output
				elsif I_ex_reg_write = '1' and I_f_rs = I_ex_rd then
					O_forward_rs <= FORWARDING_MEM; -- read from mem stage output
				else
					O_forward_rs <= FORWARDING_NONE; -- read from id stage output
				end if;

				-- rt input
				if I_id_reg_write = '1' and I_id_mem_read = '0' and I_f_rt = I_id_rd then
					O_forward_rt <= FORWARDING_EX; -- read from ex stage output
				elsif I_ex_reg_write = '1' and I_f_rt = I_ex_rd then
					O_forward_rt <= FORWARDING_MEM; -- read from mem stage output
				else
					O_forward_rt <= FORWARDING_NONE; -- read from id stage output
				end if;
			else
				O_forward_rs <= FORWARDING_NONE;
				O_forward_rt <= FORWARDING_NONE;
			end if;
		end if;
	end process;
end arch;
