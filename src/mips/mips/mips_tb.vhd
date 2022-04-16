library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mips_tb is
end mips_tb;

architecture behavior of mips_tb is

constant clk_period : time := 1 ns;
constant number_of_clock_cycles : integer := 150; -- run for 10 000 cc

component mips is
	port (
		I_clk: in std_logic;		-- synchronous active-high clock
		I_reset: in std_logic;		-- asynchronous active-high reset
		I_en: in std_logic;		-- enabled mips processor
		I_fwd_en: in std_logic;		-- enables forwarding
		--Signals for Instruction memory
		O_read_instr_cach: out std_logic; -- control bit to read from instruction cache
		I_instr: in std_logic_vector (31 downto 0);  -- input for new instruction
		O_instr_address :  out INTEGER RANGE 0 TO ram_size-1; -- specifying the address in instruction cache where we wish to store this instruction
		--Signals for Data memory
		O_write_data_cach: out std_logic; -- control bit to write to data cache
		O_read_data_cach: out std_logic; -- control bit to read from data cache
		I_data: in std_logic_vector (31 downto 0);  -- input for read data from data cache
		O_data_address :  out INTEGER RANGE 0 TO ram_size-1; -- specifying the address in data cache where we wish to load/store data
		O_writedata: IN std_logic_vector (31 DOWNTO 0) -- data line we wish to write to data cache

	);
end component;

COMPONENT instruction_memory IS
		GENERIC(
				ram_size : INTEGER := 32768;
				clock_period : time := 1 ns
		);
		PORT (
				clock: IN STD_LOGIC;
				writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				address: IN INTEGER RANGE 0 TO ram_size-1;
				memwrite: IN STD_LOGIC := '0';
				memread: IN STD_LOGIC := '0';
				readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
				waitrequest: OUT STD_LOGIC
		);
END COMPONENT;

COMPONENT data_memory IS
		GENERIC(
				ram_size : INTEGER := 32768;
				clock_period : time := 1 ns
		);
		PORT (
				clock: IN STD_LOGIC;
				writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				address: IN INTEGER RANGE 0 TO ram_size-1;
				memwrite: IN STD_LOGIC := '0';
				memread: IN STD_LOGIC := '0';
				readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
				waitrequest: OUT STD_LOGIC
		);
END COMPONENT;

--signals for mips
signal I_clk : std_logic := '0';
signal I_reset : std_logic := '0';
signal I_en: std_logic := '0';
signal I_fwd_en: std_logic := '0';
signal O_read_instr_cach: std_logic :='0';
signal instr : std_logic_vector (31 downto 0);
signal instr_address : INTEGER RANGE 0 TO ram_size-1; -- specifying the address in instruction cache where we wish to store this instruction
signal write_data_cach:  std_logic; -- control bit to write to data cache
signal read_data_cach:  std_logic; -- control bit to read from data cache
signal data: std_logic_vector (31 downto 0);  -- input for read data from data cache
signal data_cache_address : INTEGER RANGE 0 TO ram_size-1; -- specifying the address in data cache where we wish to load/store data
signal data_cache_writedata: std_logic_vector (31 DOWNTO 0); -- data line we wish to write to data cache


--EXTRA Signals for instruction cache
signal I_instr_writedata : std_logic_vector (31 downto 0);
signal I_instr_write : std_logic := '0';
signal O_instr_waitrequest: STD_LOGIC;

--EXTRA Signals for data dut_data_cache
signal data_waitrequest: STD_LOGIC;


begin

dut_mips: mips
port map(
        I_clk => I_clk,
        I_reset => I_reset,
				I_en => I_en,
				I_fwd_en => I_fwd_en,
				O_read_instr_cach=>O_read_instr_cach,
				instr	=>I_instr,
				instr_address	=>O_instr_address,
				write_data_cach	=>O_write_data_cach,
				read_data_cach	=>O_read_data_cach,
				data	=>I_data,
				data_cache_address	=>O_data_address,
				data_cache_writedata	=>O_writedata
);

dut_instr_cache: instruction_memory
port map(
				I_clk => clock,
				I_instr_writedata=>writedata,
				instr_address=>address,
				I_instr_write=>memwrite,
				O_read_instr_cach => memread,
				instr => readdata,
				O_instr_waitrequest=>waitrequest
);

dut_data_cache: data_memory
port map(
				I_clk => clock,
				data_cache_writedata=>writedata,
				data_cache_address=>address,
				write_data_cach=>memwrite,
				read_data_cach => memread,
				data => readdata,
				data_waitrequest=>waitrequest
);

clk_process : process
begin
  I_clk <= '0';
  wait for clk_period/2;
  I_clk <= '1';
  wait for clk_period/2;
end process;

test_process : process
	-- Variables used to load memory from text file
	variable line_v : line;
	file read_file : text;
	file write_file : text;
	variable instruction : std_logic_vector(31 downto 0);
	variable count : INTEGER Range 0 to 31 := 0;
begin
	wait until rising_edge(clk);
	-- Load from text file
	file_open(read_file, "C:\Users\Bruno\IdeaProjects\ECSE425-MIPS-G7\src\mips\memory\source.txt", read_mode);
	while not endfile(read_file) loop
		readline(read_file, line_v);
		bread(line_v, instruction);
		report "instruction: " & to_bstring(instruction);
		-- Now load data into instruction memory
		I_instr <= instruction;
		address <= count;
		I_write_instr_cach <= '1';
		wait until falling_edge(waitrequest);
		count := count + 4;
	end loop;
	file_close(read_file);
	I_write_instr_cach <= '0';
	-- Starting Execution:
	report "Starting Execution" ;
	wait for clk_period;
	wait until rising_edge(clk);
	-- Reset
	I_reset <= '1';
	wait for clk_period;

	I_reset <= '0';
	I_en <= '1';

	wait for clk_period * number_of_clock_cycles;
	report "----- End of Test -----";

	-- Now that the execution is done, write the data memory to a file
	file_open(write_file, "C:\Users\Bruno\IdeaProjects\ECSE425-MIPS-G7\src\mips\memory\target.txt", write_mode);
	count := 0;
	 loop
		 if count >= 32768 THEN
		 	exit;
		end if;
		 read_data_cach <= '1';
		 data_cache_address <= count;
		wait until falling_edge(data_waitrequest);
		bwrite(line_v, data);
		writeline(write_file, line_v);
		count := count + 4;
	end loop;
	file_close(write_file);

  wait;
end process;

end behavior;