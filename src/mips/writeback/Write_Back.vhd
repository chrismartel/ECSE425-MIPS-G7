library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity write_back is
port (I_regDwe : in std_logic;
	I_mem_read : in std_logic;
	I_alu : in std_logic_vector (31 downto 0);
	I_mem: in std_logic_vector (31 downto 0);
	I_rd: in std_logic_vector (4 downto 0);
	I_jump : in std_logic;
	I_branch: in std_logic;
	
	O_we : out std_logic;
	O_rd: out std_logic_vector (4 downto 0);
	O_mux : out std_logic_vector (31 downto 0);
  );
end write_back;

architecture write_back_arch of write_back is
	
begin
	process(I_clk)
		begin
			if rising_edge(I_clk) then
				if ((I_jump or I_branch) != '1') then
					--mux for choosing input from ALU or MEM
					if ((I_regDwe and I_mem_read) = '0') then
						O_mux <= I_alu;
					elsif ((I_regDwe and I_mem_read) = '1') then
						O_mux <= I_mem;
					else
						O_mux <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
					end if;
					O_rd <= I_rd;
					O_we <= '1';
				else
					O_rd <= "XXXXX";
					O_mux <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
					O_we <= '0';
				end if;
			end if;
	end process;
end write_back_arch;