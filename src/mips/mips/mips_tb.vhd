library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mips_tb is
end mips_tb;

architecture behavior of mips_tb is

constant clk_period : time := 1 ns;
constant number_of_clock_cycles : integer := 10000; -- run for 10 000 cc

component mips is
	port(
	I_clk: in std_logic;		
	I_reset: in std_logic;		
	I_en: in std_logic;		
	I_fwd_en: in std_logic
	);
end component;
	
signal I_clk : std_logic := '0';
signal I_reset : std_logic := '0';
signal I_en: std_logic := '0';
signal I_fwd_en: std_logic := '0';

begin

dut_mips: mips
port map(
        I_clk => I_clk,
        I_reset => I_reset,
	I_en => I_en,
	I_fwd_en => I_fwd_en
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
	-- Reset
	I_reset <= '1';
	wait for clk_period;

	I_reset <= '0';
	I_en <= '1';

	wait for clk_period * number_of_clock_cycles;

    report "----- End of Test -----";
    wait;
end process;

end behavior;