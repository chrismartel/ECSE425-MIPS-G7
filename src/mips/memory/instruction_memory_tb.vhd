library ieee;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use std.textio.all;

entity instruction_memory_tb is
end entity;

architecture syn of instruction_memory_tb is

  COMPONENT instruction_memory IS
      GENERIC(
          ram_size : INTEGER := 32768;
          mem_delay : time := 1 ns;
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

  --all the input signals with initial values
  signal clk : std_logic := '0';
  constant clk_period : time := 1 ns;
  signal writedata: std_logic_vector(31 downto 0);
  signal address: INTEGER RANGE 0 TO 32768-1;
  signal memwrite: STD_LOGIC := '0';
  signal memread: STD_LOGIC := '0';
  signal readdata: STD_LOGIC_VECTOR (31 DOWNTO 0);
  signal waitrequest: STD_LOGIC;

begin

  --dut => Device Under Test
  dut: instruction_memory GENERIC MAP(
          ram_size => 32
              )
              PORT MAP(
                  clk,
                  writedata,
                  address,
                  memwrite,
                  memread,
                  readdata,
                  waitrequest
              );


  clk_process : process
  begin
      clk <= '0';
      wait for clk_period/2;
      clk <= '1';
      wait for clk_period/2;
  end process;

  load_from_txt: process is
    variable line_v : line;
    file read_file : text;
    file write_file : text;
    variable instruction : std_logic_vector(31 downto 0);
    variable count : INTEGER Range 0 to 31 := 0;
  begin
    file_open(read_file, "C:\Users\Bruno\IdeaProjects\ECSE425-MIPS-G7\src\mips\memory\source.txt", read_mode);
    file_open(write_file, "C:\Users\Bruno\IdeaProjects\ECSE425-MIPS-G7\src\mips\memory\target.txt", write_mode);
    while not endfile(read_file) loop
      readline(read_file, line_v);
      bread(line_v, instruction);
      report "instruction: " & to_bstring(instruction);
      bwrite(line_v, instruction);
      writeline(write_file, line_v);
      -- Now load data into instruction memory
      writedata <= instruction;
      address <= count;
      memwrite <= '1';
      wait until rising_edge(waitrequest);
      memwrite <= '0';
      count := count + 4;
    end loop;
    file_close(read_file);
    file_close(write_file);
    wait;



  end process;


end architecture;