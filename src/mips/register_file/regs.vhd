--https://domipheus.com/blog/designing-a-cpu-in-vhdl-part-2-xilinx-ise-suite-register-file-testing/
library ieee; -- allows use of the std_logic_vector type
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- needed if you are using unsigned numbers
entity regs is

Port ( I_clk : in  STD_LOGIC;
       I_en : in  STD_LOGIC;
       I_dataD : in  STD_LOGIC_VECTOR (31 downto 0);
       O_dataA : out  STD_LOGIC_VECTOR (31 downto 0);
       O_dataB : out  STD_LOGIC_VECTOR (31 downto 0);
       I_selA : in  STD_LOGIC_VECTOR (4 downto 0);
       I_selB : in  STD_LOGIC_VECTOR (4 downto 0);
       I_selD : in  STD_LOGIC_VECTOR (4 downto 0);
       I_we : in  STD_LOGIC);
		 
end regs;


architecture Behavioral of regs is

  type store_t is array (0 to 31) of std_logic_vector(31 downto 0);
  
  signal regs: store_t := (others => X"00000000");
  
begin

process(I_clk)

begin

  if rising_edge(I_clk) and I_en='1' then
  
    O_dataA <= regs(to_integer(unsigned(I_selA)));
    O_dataB <= regs(to_integer(unsigned(I_selB)));
	 
    if (I_we = '1') then
	 
      regs(to_integer(unsigned(I_selD))) <= I_dataD;
		
    end if;
  end if;
end process;
end Behavioral;