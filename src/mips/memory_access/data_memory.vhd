-- ECSE425 W2022
-- Final Project, Group 07
-- Data Memory

--Adapted from memory.vhd from Project 2
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY data_memory IS
	GENERIC(
		ram_size : INTEGER := 32768;
		mem_delay : time := 1 ns;
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
END data_memory;

ARCHITECTURE rtl OF data_memory IS
	TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL ram_block: MEM;
	SIGNAL read_address_reg: INTEGER RANGE 0 to ram_size-1;
	SIGNAL write_waitreq_reg: STD_LOGIC := '1';
	SIGNAL read_waitreq_reg: STD_LOGIC := '1';
BEGIN
	--This is the main section of the SRAM model
	mem_process: PROCESS (clock)
	BEGIN
		--This is a cheap trick to initialize the SRAM in simulation
		IF(now < 1 ps)THEN
			For i in 0 to ram_size-1 LOOP
				ram_block(i) <= std_logic_vector(to_unsigned(0,8));
			END LOOP;
		end if;

		--This is the actual synthesizable SRAM block
		IF (clock'event AND clock = '1') THEN
			IF (memwrite = '1') THEN
				ram_block(address) <= writedata(7 downto 0);
        ram_block(address+1) <= writedata(15 downto 8);
        ram_block(address+2) <= writedata(23 downto 16);
        ram_block(address+3) <= writedata(31 downto 24);
				write_waitreq_reg <= '0', '1' after clock_period;
			elsif memread='1' then
				read_waitreq_reg <= '0', '1' after clock_period;
			END IF;
		read_address_reg <= address;
		END IF;
	END PROCESS;
  readdata(7 downto 0) <= ram_block(read_address_reg);
  readdata(15 downto 8) <= ram_block(read_address_reg+1);
  readdata(23 downto 16) <= ram_block(read_address_reg+2);
  readdata(31 downto 24) <= ram_block(read_address_reg+3);
	waitrequest <= write_waitreq_reg and read_waitreq_reg;


END rtl;