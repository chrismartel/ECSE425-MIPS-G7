library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity write_back is
port (I_regDwe : in std_logic;
	I_mem_read : in std_logic;
	I_alu : in std_logic_vector (31 downto 0);
	I_mem: in std_logic_vector (31 downto 0);
	I_reg_address: in std_logic_vector (4 downto 0);
	I_clk : in std_logic;
	I_reset : in std_logic;
	I_rt : in std_logic_vector(4 downto 0);
	I_rs: in std_logic_vector(4 downto 0);
	O_datas: out std_logic_vector(31 downto 0);
	O_datat: out std_logic_vector(31 downto 0)
  );
end write_back;

architecture write_back_arch of write_back is

	component regs
		port (I_clk: in std_logic;
				I_reset: in std_logic;
				I_en: in std_logic;
				I_datad: in std_logic_vector(31 downto 0);
				I_rt: in std_logic_vector(4 downto 0);
				I_rs: in std_logic_vector(4 downto 0);
				I_rd: in std_logic_vector(4 downto 0);
				I_we: in std_logic;
				O_datas: out std_logic_vector(31 downto 0);
				O_datat: out std_logic_vector(31 downto 0)
		); 
	end component;
	
	signal O_mux : std_logic_vector (31 downto 0);
	signal I_en : std_logic;
	
begin

	regWrite : regs
	port map(I_clk => I_clk,
				I_reset => I_reset,
				I_en => I_en,
				I_datad => O_mux,
				I_rt => I_rt,
				I_rs => I_rs,
				I_rd => I_reg_address,
				I_we => I_regDwe,
				O_datas => O_datas,
				O_datat => O_datat
	);
	
	process(I_clk)
		begin
			if rising_edge(I_clk) then
				--mux for choosing input from ALU or MEM
				if ((I_regDwe and I_mem_read) = '0') then
					O_mux <= I_alu;
				elsif ((I_regDwe and I_mem_read) = '1') then
					O_mux <= I_mem;
				else
					O_mux <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
				end if;
			
				I_en <= '1';
			end if;
	end process;
end write_back_arch;