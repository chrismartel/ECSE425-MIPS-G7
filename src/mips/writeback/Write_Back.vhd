library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity write_back is
port (memToReg: in std_logic;
	toAlu : in std_logic_vector (31 downto 0);
	toMem: in std_logic_vector (31 downto 0);
	muxOut : out std_logic_vector (31 downto 0);
	
	regWriteI: in std_logic;
	regWriteO: out std_logic;
	
	writeAddressI: in std_logic_vector (4 downto 0);
	writeAddressO: out std_logic_vector (4 downto 0)
  );
end write_back;

architecture write_back_arch of write_back is

begin
	process(memToReg, toAlu, toMem, regWriteI)
		begin
		
			--mux for sending input to ALU or MEM
			case memToReg is
				when '0' => 
					muxOut <= toAlu;
				when '1' => 
					muxOut <= toMem;
			end case;
	
			--passing input address/register write bit to output
			writeAddressO <= writeAddressI;
			regWriteO <= regWriteI;
	end process;
end write_back_arch;