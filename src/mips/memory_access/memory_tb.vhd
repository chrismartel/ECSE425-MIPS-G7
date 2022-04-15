-- plan: present a load instruction to the memory stage, load the specfied value
--       present a store     ""        ""       ""  "" , store ""         ""
--       present any other instruction to the memory stage, load the specified value
--       Note: for loads, much check that value is forwarded. Or is this tested elsewhere?

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory_tb is
end memory_tb;


architecture behavior of memory_tb is

	component memory is
		generic(
			ram_size : INTEGER := 32768
		);
		port (
			I_clk : in std_logic;
			I_reset : in std_logic;
			I_en : in std_logic;
			
			
			-- Control Signals Inputs
			I_rd: in std_logic_vector (4 downto 0); 			-- the destination register where to write the instr. result
			I_branch: in std_logic; 					-- indicates if its is a branch operation (beq, bne)
			I_jump: in std_logic; 						-- indicates if it is a jump instruction (j, jr, jal)
			I_mem_read: in std_logic; 					-- indicates if a value must be read from memory at calculated address
			I_mem_write: in std_logic; 					-- indicates if value in I_rt_data must be written in memory at calculated address
			I_reg_write: in std_logic; 					-- indicates if value calculated in ALU must be written to destination register

			I_rt_data: in std_logic_vector (31 downto 0); -- the data that needs to be written
			I_alu_result: in std_logic_vector (31 downto 0); -- connected to alu_result in execute, holds address to send data to. If not a load/store, simply passes data forward
			I_stall: in std_logic;
			
			
			-- data_memory relevant signals
			data_address: out integer range 0 to ram_size-1;
			data_memread: out std_logic;
			data_waitrequest: in std_logic;
			data_writedata: out std_logic_vector(31 downto 0);
			data_memwrite: out std_logic;
			data_readdata: in std_logic_vector(31 downto 0);
			
			-- Control Signals Outputs
			O_rd: out std_logic_vector (4 downto 0); 			-- the destination register where to write the instr. result
			O_branch: out std_logic; 					-- indicates if its is a branch operation (beq, bne)
			O_jump: out std_logic; 						-- indicates if it is a jump instruction (j, jr, jal)
			O_mem_read: out std_logic; 					-- indicates if a value must be read from memory at calculated address
			O_mem_write: out std_logic; 					-- indicates if value in I_rt_data must be written in memory at calculated address
			O_reg_write: out std_logic; 					-- indicates if value calculated in ALU must be written to destination register
			
			O_alu_result: out std_logic_vector(31 downto 0);
			O_stall: out std_logic;
			
			O_forward_rd: out std_logic_vector (4 downto 0);
			O_forward_mem_reg_write: out std_logic
		);
		
	end component;
	
	-- taken from data_memory.vhd
	
	component data_memory IS
	GENERIC(
		ram_size : INTEGER := 32768;
		-- mem_delay : time := 1 ns;
		clock_period : time := 1 ns
	);
	PORT (
		clock: IN STD_LOGIC;
		writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address: IN INTEGER RANGE 0 TO ram_size-1;
		memwrite: IN STD_LOGIC;
		memread: IN STD_LOGIC;
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest: OUT STD_LOGIC
	);
	END component;
	
	signal I_clk : std_logic:='1';
	constant clk_period : time := 1 ns;
	signal I_en: std_logic:='1';
	
	signal I_reset : std_logic;
	
	
	-- Control Signals Inputs
	signal I_rd: std_logic_vector (4 downto 0);
	signal I_branch: std_logic;
	signal I_jump: std_logic; 
	signal I_mem_read: std_logic;
	signal I_mem_write: std_logic;
	signal I_reg_write: std_logic;
	
	signal I_rt_data: std_logic_vector (31 downto 0); 
	signal I_alu_result: std_logic_vector (31 downto 0);
	signal I_stall: std_logic;
	
	
	-- data_memory relevant signals
	signal data_address: integer range 0 to 32767;
	signal data_memread: std_logic;
	signal data_waitrequest: std_logic;
	signal data_writedata: std_logic_vector(31 downto 0);
	signal data_memwrite: std_logic;
	signal data_readdata: std_logic_vector(31 downto 0);
	
	-- Control Signals Outputs
	signal O_rd: std_logic_vector (4 downto 0);
	signal O_branch: std_logic;
	signal O_jump: std_logic;
	signal O_mem_read: std_logic;
	signal O_mem_write: std_logic;
	signal O_reg_write: std_logic;
	
	signal O_alu_result: std_logic_vector(31 downto 0);
	signal O_stall: std_logic;
	
	signal O_forward_rd: std_logic_vector (4 downto 0);
	signal O_forward_mem_reg_write: std_logic;
	
begin


	dut: memory port map (
		-- TODO: map all signals to component signal
		I_clk => I_clk,
		I_reset => I_reset,
		I_en => I_en,
		I_rd => I_rd,
		I_jump => I_jump,
		I_mem_read => I_mem_read,
		I_mem_write => I_mem_write,
		I_reg_write => I_reg_write,
		I_rt_data => I_rt_data,
		I_branch => I_branch,
		I_alu_result => I_alu_result,
		I_stall => I_stall,
		data_address => data_address,
		data_memread => data_memread,
		data_waitrequest => data_waitrequest,
		data_writedata => data_writedata,
		data_memwrite => data_memwrite,
		data_readdata => data_readdata,
		O_rd => O_rd,
		O_branch => O_branch,
		O_jump => O_jump,
		O_mem_read => O_mem_read,
		O_mem_write => O_mem_write,
		O_reg_write => O_reg_write,
		O_alu_result => O_alu_result,
		O_stall => O_stall,
		O_forward_rd => O_forward_rd,
		O_forward_mem_reg_write => O_forward_mem_reg_write
	);
	
	data_mem: data_memory port map (
		clock => I_clk,
		writedata => data_writedata,
		address => data_address,
		memwrite => data_memwrite,
		memread => data_memread,
		readdata => data_readdata,
		waitrequest => data_waitrequest
	);



clk_process : process
begin
  I_clk <= '1';
  wait for clk_period/2;
  I_clk <= '0';
  wait for clk_period/2;
end process;

test_process : process
begin 

-- tests here

-- TEST 1: store instruction, store immediately into memory
I_alu_result <= X"00000000";
I_branch <= '0';
I_mem_write <= '1';
I_mem_read <= '0';
I_jump <= '0';
I_rd <= "00111";
I_reg_write <= '0';

I_rt_data <= X"10101010";
I_stall <= '0';

wait for clk_period;

-- assert expected values

-- assert data in memory at 0xABCDEF00 is 0x10101010
-- assert output control signals match

assert O_rd = "00111" report "Test case 1 failed : O_rd" severity error;
assert O_branch = '0' report "Test case 1 failed : O_branch" severity error;
assert O_jump = '0' report "Test case 1 failed : O_jump" severity error;
assert O_mem_read = '0' report "Test case 1 failed : O_mem_read" severity error;
assert O_mem_write = '1' report "Test case 1 failed : O_mem_write" severity error;
assert O_reg_write = '0' report "Test case 1 failed : O_reg_write" severity error;
assert O_stall = '0' report "Test case 1 failed : O_stall" severity error;



-- wait for clk_period;

-- TEST 2: load instruction, load immediately from memory
I_alu_result <= X"00000010";
I_branch <= '0';
I_mem_write <= '0';
I_mem_read <= '1';
I_jump <= '0';
I_rd <= "00111";
I_reg_write <= '1';

I_rt_data <= X"11111111";
I_stall <= '0';

-- wait until memory done
wait for clk_period;

-- assert expected value

-- assert 0x10101010 in O_mem_data
-- assert output control signals match

assert O_rd = "00111" report "Test case 2 failed : O_rd" severity error;
assert O_branch = '0' report "Test case 2 failed : O_branch" severity error;
assert O_jump = '0' report "Test case 2 failed : O_jump" severity error;
assert O_mem_read = '1' report "Test case 2 failed : O_mem_read" severity error;
assert O_mem_write = '0' report "Test case 2 failed : O_mem_write" severity error;
assert O_reg_write = '1' report "Test case 2 failed : O_reg_write" severity error;
assert O_stall = '0' report "Test case 2 failed : O_stall" severity error;

-- wait for clk_period/2;

-- TEST 3: other instruction, pass all signals forward.

I_alu_result <= X"00000000";
I_branch <= '0';
I_mem_write <= '0';
I_mem_read <= '0';
I_jump <= '0';
I_rd <= "01000";
I_reg_write <= '1';

I_stall <= '0';

wait for clk_period;

assert data_readdata = X"00000000" report "Test case 2 failed : data_readdata" severity error;


-- assert nothing special happened, everything passed forward

-- assert control signal matches

assert O_rd = "01000" report "Test case 3 failed : O_rd" severity error;
assert O_branch = '0' report "Test case 3 failed : O_branch" severity error;
assert O_jump = '0' report "Test case 3 failed : O_jump" severity error;
assert O_mem_read = '0' report "Test case 3 failed : O_mem_read" severity error;
assert O_mem_write = '0' report "Test case 3 failed : O_mem_write" severity error;
assert O_reg_write = '1' report "Test case 3 failed : O_reg_write" severity error;
assert O_stall = '0' report "Test case 3 failed : O_stall" severity error;
assert O_alu_result = x"00000000" report "Test case 3 failed : O_alu_result" severity error;


-- TEST 4: two consecutive writes

-- first write to 0x4, value ABCDABCD

I_alu_result <= X"00000004";
I_branch <= '0';
I_mem_write <= '1';
I_mem_read <= '0';
I_jump <= '0';
I_rd <= "00111";
I_reg_write <= '0';

I_rt_data <= X"ABCDABCD";
I_stall <= '0';

wait for clk_period;

-- write to 0x8, value 0x EFEFEFEF

I_alu_result <= X"00000008";
I_branch <= '0';
I_mem_write <= '1';
I_mem_read <= '0';
I_jump <= '0';
I_rd <= "00111";
I_reg_write <= '0';

I_rt_data <= X"EFEFEFEF";
I_stall <= '0';

wait for clk_period;

-- assert through reads that writes worked correctly

-- read 0x4, assert ABCDABCD

I_alu_result <= X"00000004";
I_branch <= '0';
I_mem_write <= '0';
I_mem_read <= '1';
I_jump <= '0';
I_rd <= "00111";
I_reg_write <= '1';

I_rt_data <= X"11111111";
I_stall <= '0';

wait for clk_period;


-- read 0x4, assert ABCDABCD

I_alu_result <= X"00000008";
I_branch <= '0';
I_mem_write <= '0';
I_mem_read <= '1';
I_jump <= '0';
I_rd <= "00111";
I_reg_write <= '1';

I_rt_data <= X"11111111";
I_stall <= '0';

wait for clk_period;

assert data_readdata = X"ABCDABCD" report "Test case 4 failed : 0x4 ABCDABCD" severity error;

wait for clk_period;

assert data_readdata = X"EFEFEFEF" report "Test case 4 failed : 0x8 EFEFEFEF" severity error;

-- TEST 5: 2 consecutive reads

-- read 1: 0x0, value 0x10101010

I_alu_result <= X"00000000";
I_branch <= '0';
I_mem_write <= '0';
I_mem_read <= '1';
I_jump <= '0';
I_rd <= "00111";
I_reg_write <= '1';

I_rt_data <= X"11111111";
I_stall <= '0';

wait for clk_period;

-- read 2: 0x4, value 0xABCDABCD

I_alu_result <= X"00000004";
I_branch <= '0';
I_mem_write <= '0';
I_mem_read <= '1';
I_jump <= '0';
I_rd <= "00111";
I_reg_write <= '1';

I_rt_data <= X"11111111";
I_stall <= '0';

wait for clk_period;

assert data_readdata = X"10101010" report "Test case 5 failed : 0x0 10101010" severity error;

wait for clk_period;

assert data_readdata = X"ABCDABCD" report "Test case 5 failed : 0x4 ABCDABCD" severity error;


wait;

end process;

end;