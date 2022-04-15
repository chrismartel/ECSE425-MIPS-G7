library ieee; -- allows use of the std_logic_vector type
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- needed if you are using unsigned numbers

entity regs is
Port ( 
	-- Inputs
	I_clk : in  STD_LOGIC;
       	I_reset : in STD_LOGIC;
       	I_en : in  STD_LOGIC;
       	I_datad : in  STD_LOGIC_VECTOR (31 downto 0);
       	I_rt : in  STD_LOGIC_VECTOR (4 downto 0);
       	I_rs : in  STD_LOGIC_VECTOR (4 downto 0);
       	I_rd : in  STD_LOGIC_VECTOR (4 downto 0);
       	I_we : in  STD_LOGIC;
	
	-- Outputs
       	O_datas : out  STD_LOGIC_VECTOR (31 downto 0);
       	O_datat : out  STD_LOGIC_VECTOR (31 downto 0)
	); 
end regs;

architecture Behavioral of regs is

	type store_t is array (0 to 31) of std_logic_vector(31 downto 0);
  
	signal regs: store_t := (others => X"00000000");
  
	begin

	process(I_clk, I_reset)
	begin
	if I_reset='1' then
		for i in 0 to 31 loop
			regs(i) <= (others => '0');
		end loop;
		O_datas <= (others=>'0');
		O_datat <= (others=>'0');
  	elsif I_clk'event and I_clk='1' then
		if I_en ='1' then
    			O_datas <= regs(to_integer(unsigned(I_rs)));
    			O_datat <= regs(to_integer(unsigned(I_rt)));
    			if (I_we = '1') then
      				regs(to_integer(unsigned(I_rd))) <= I_datad;
			end if;
		end if;
	end if;
end process;
end Behavioral;