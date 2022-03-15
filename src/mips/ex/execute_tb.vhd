
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity execute_tb is
end execute_tb;

architecture behavior of execute_tb is

-- constants
	-- opcodes
	constant R_OPCODE : std_logic_vector (5 downto 0) := "000000"; -- R type instructions

-- R-TYPE INSTRUCTION FUNCTIONAL BITS

    -- arithmetic
	constant ADD_FUNCT : std_logic_vector (5 downto 0) := "100000"; -- add
	constant SUB_FUNCT : std_logic_vector (5 downto 0) := "100010"; -- subtract
	constant MULT_FUNCT : std_logic_vector (5 downto 0) := "011000"; -- multiply
	constant DIV_FUNCT : std_logic_vector (5 downto 0) := "011010"; -- divide
	constant SLT_FUNCT : std_logic_vector (5 downto 0) := "101010"; -- set less than
	
    -- logical
	constant AND_FUNCT : std_logic_vector (5 downto 0) := "100100"; -- and
	constant OR_FUNCT : std_logic_vector (5 downto 0) := "100101"; -- or
	constant NOR_FUNCT : std_logic_vector (5 downto 0) := "100111"; -- nor
	constant XOR_FUNCT : std_logic_vector (5 downto 0) := "101000"; -- xor
	
    -- transfer
	constant MFHI_FUNCT : std_logic_vector (5 downto 0) := "010000"; -- move from HI
	constant MFLO_FUNCT : std_logic_vector (5 downto 0) := "010010"; -- move from LO

    -- shift
	constant SLL_FUNCT : std_logic_vector (5 downto 0) := "000000"; -- shift left logical
	constant SRL_FUNCT  : std_logic_vector (5 downto 0) := "000010"; -- shift right logical
	constant SRA_FUNCT : std_logic_vector (5 downto 0) := "000011"; -- shift right arithmetic

    -- control-flow
	constant JR_FUNCT : std_logic_vector (5 downto 0) := "001000"; -- jump register

-- I-TYPE INSTRUCTION OPCODES

    -- arithmetic
	constant ADDI_OPCODE : std_logic_vector (5 downto 0) := "001000"; -- add immediate
	constant SLTI_OPCODE : std_logic_vector (5 downto 0) := "001010"; -- set less than immediate
	
    -- logical
    constant ANDI_OPCODE : std_logic_vector (5 downto 0) := "001100"; -- and immediate
	constant ORI_OPCODE : std_logic_vector (5 downto 0) := "001101"; -- or immediate
	constant XORI_OPCODE : std_logic_vector (5 downto 0) := "001110"; -- xor immediate
	
    -- transfer
    constant LUI_OPCODE : std_logic_vector (5 downto 0) := "001111"; -- load upper immediate
	
    -- memory
    constant LW_OPCODE : std_logic_vector (5 downto 0) := "100011"; -- load word
	constant SW_OPCODE : std_logic_vector (5 downto 0) := "101011"; -- store word
	
    -- control-flow
    constant BEQ_OPCODE : std_logic_vector (5 downto 0) := "000100"; -- branch on equal
	constant BNE_OPCODE : std_logic_vector (5 downto 0) := "000101"; -- branch on not equal
	
-- J-TYPE INSTRUCTION OPCODES

    -- control-flow
	constant J_OPCODE : std_logic_vector (5 downto 0) := "000010"; -- jump
	constant JAL_OPCODE : std_logic_vector (5 downto 0) := "000011"; -- jump and link
    
-- CLOCK
	constant CLK_PERIOD : time := 1 ns;

component execute is

port(
	-- INPUTS
	clk : in std_logic;
	reset : in std_logic;

	instruction: in std_logic_vector (31 downto 0);
	rs_data_in: in std_logic_vector (31 downto 0);
	rt_data_in: in std_logic_vector (31 downto 0);
	next_pc: in std_logic_vector (31 downto 0); -- pc + 4

	-- control signals (passed from decode stage to wb stage)
	destination_register_in: in std_logic_vector (4 downto 0); 	-- the destination register where to write the instr. result
	branch_in: in std_logic; 					-- indicates if its is a branch operation (beq, bne)
	jump_in: in std_logic; 						-- indicates if it is a jump instruction (j, jr, jal)
	mem_read_in: in std_logic; 					-- indicates if a value must be read from memory at calculated address
	mem_write_in: in std_logic; 					-- indicates if value in rt_data_in must be written in memory at calculated address
	reg_write_in: in std_logic; 					-- indicates if value calculated in ALU must be written to destination register
	mem_to_reg_in: in std_logic; 					-- indicates if value loaded from memory must be writte to destination register

	-- OUTPUTS
	alu_result: out std_logic_vector (31 downto 0);
	updated_pc: out std_logic_vector (31 downto 0);
	rt_data_out: out std_logic_vector (31 downto 0);

	-- control signals
	destination_register_out: out std_logic_vector (4 downto 0);
	branch_out: out std_logic;
	jump_out: out std_logic;
	mem_read_out: out std_logic;
	mem_write_out: out std_logic;
	reg_write_out: out std_logic;
	mem_to_reg_out: out std_logic
);
end component;

-- test signals 

-- inputs
signal reset : std_logic := '0';
signal clk : std_logic := '0';

signal instruction: std_logic_vector (31 downto 0);
signal rs_data_in: std_logic_vector (31 downto 0);
signal rt_data_in: std_logic_vector (31 downto 0);
signal next_pc: std_logic_vector (31 downto 0); 

signal destination_register_in: std_logic_vector (4 downto 0); 	
signal branch_in: std_logic; 					
signal jump_in: std_logic; 						
signal mem_read_in: std_logic; 					
signal mem_write_in: std_logic; 					
signal reg_write_in: std_logic; 					
signal mem_to_reg_in: std_logic; 					

-- outputs
signal alu_result: std_logic_vector (31 downto 0);
signal updated_pc: std_logic_vector (31 downto 0);
signal rt_data_out: std_logic_vector (31 downto 0);

signal destination_register_out: std_logic_vector (4 downto 0);
signal branch_out: std_logic;
signal jump_out: std_logic;
signal mem_read_out: std_logic;
signal mem_write_out: std_logic;
signal reg_write_out: std_logic;
signal mem_to_reg_out: std_logic;


begin

-- Connect the components which we instantiated above to their
-- respective signals.
dut: execute 
port map(
	-- INPUTS
	clk => clk,
	reset => reset,

	instruction => instruction,
	rs_data_in => rs_data_in,
	rt_data_in => rt_data_in,
	next_pc => next_pc,

	destination_register_in => destination_register_in,
	branch_in => branch_in,
	jump_in => jump_in,
	mem_read_in => mem_read_in,		
	mem_write_in => mem_write_in, 					
	reg_write_in => reg_write_in,				
	mem_to_reg_in => mem_to_reg_in,				

	-- OUTPUTS
	alu_result => alu_result,
	updated_pc => updated_pc,
	rt_data_out => rt_data_out,

	destination_register_out => destination_register_out,
	branch_out => branch_out,
	jump_out => jump_out,
	mem_read_out => mem_read_out,
	mem_write_out => mem_write_out,
	reg_write_out => reg_write_out,
	mem_to_reg_out => mem_to_reg_out
);

				

clk_process : process
begin
  clk <= '0';
  wait for CLK_PERIOD/2;
  clk <= '1';
  wait for CLK_PERIOD/2;
end process;

test_process : process
begin

-- put your tests here

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for clk_period;
  reset <= '1';
  wait for clk_period;
  reset <= '0';
  wait for clk_period;
  ----------------------------------------------------------------------------------
  
  report "----- Starting tests -----";

  ----------------------------------------------------------------------------------
  -- TEST 1: ADD
  ----------------------------------------------------------------------------------
  report "----- Test 1: ADD Instruction -----";

  assert alu_result =  report "Test 1: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 2: SUB
  ----------------------------------------------------------------------------------
  report "----- Test 2: SUB Instruction -----";

  assert alu_result =  report "Test 2: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 3: MULT
  ----------------------------------------------------------------------------------
  report "----- Test 3: MULT Instruction -----";

  assert alu_result =  report "Test 3: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 4: DIV
  ----------------------------------------------------------------------------------
  report "----- Test 4: DIV Instruction -----";

  assert alu_result =  report "Test 4: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 5: SLT
  ----------------------------------------------------------------------------------
  report "----- Test 5: SLT Instruction -----";

  assert alu_result =  report "Test 5: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 6: AND
  ----------------------------------------------------------------------------------
  report "----- Test 6: AND Instruction -----";

  assert alu_result =  report "Test 6: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 7: OR
  ----------------------------------------------------------------------------------
  report "----- Test 7: OR Instruction -----";

  assert alu_result =  report "Test 7: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 8: NOR
  ----------------------------------------------------------------------------------
  report "----- Test 8: NOR Instruction -----";

  assert alu_result =  report "Test 8: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 9: XOR
  ----------------------------------------------------------------------------------
  report "----- Test 9: XOR Instruction -----";

  assert alu_result =  report "Test 9: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 10: MFHI
  ----------------------------------------------------------------------------------
  report "----- Test 10: MFHI Instruction -----";

  assert alu_result =  report "Test 10: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 11: MFLO
  ----------------------------------------------------------------------------------
  report "----- Test 11: MFLO Instruction -----";

  assert alu_result =  report "Test 11: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 12: SLL
  ----------------------------------------------------------------------------------
  report "----- Test 12: SLL Instruction -----";

  assert alu_result =  report "Test 12: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 13: SRL
  ----------------------------------------------------------------------------------
  report "----- Test 13: SRL Instruction -----";

  assert alu_result =  report "Test 13: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 14: SRA
  ----------------------------------------------------------------------------------
  report "----- Test 14: SRA Instruction -----";

  assert alu_result =  report "Test 14: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 15: JR
  ----------------------------------------------------------------------------------
  report "----- Test 15: JR Instruction -----";

  assert alu_result =  report "Test 15: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 16: ADDI
  ----------------------------------------------------------------------------------
  report "----- Test 16: ADDI Instruction -----";

  assert alu_result =  report "Test 16: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 17: SLTI
  ----------------------------------------------------------------------------------
  report "----- Test 17: SLTI Instruction -----";

  assert alu_result =  report "Test 17: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 18: ORI
  ----------------------------------------------------------------------------------
  report "----- Test 18: ORI Instruction -----";

  assert alu_result =  report "Test 18: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 19: XORI
  ----------------------------------------------------------------------------------
  report "----- Test 19: XORI Instruction -----";

  assert alu_result =  report "Test 19: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 20: LUI
  ----------------------------------------------------------------------------------
  report "----- Test 20: LUI Instruction -----";

  assert alu_result =  report "Test 20: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 21: LW
  ----------------------------------------------------------------------------------
  report "----- Test 21: LW Instruction -----";

  assert alu_result =  report "Test 21: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 22: SW
  ----------------------------------------------------------------------------------
  report "----- Test 22: SW Instruction -----";

  assert alu_result =  report "Test 22: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 23: BEQ
  ----------------------------------------------------------------------------------
  report "----- Test 23: BEQ Instruction -----";

  assert alu_result =  report "Test 23: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 24: BNE
  ----------------------------------------------------------------------------------
  report "----- Test 24: BNE Instruction -----";

  assert alu_result =  report "Test 24: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 25: J
  ----------------------------------------------------------------------------------
  report "----- Test 25: J Instruction -----";

  assert alu_result =  report "Test 25: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 26: JAL
  ----------------------------------------------------------------------------------
  report "----- Test 26: JAL Instruction -----";

  assert alu_result =  report "Test 26: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for CLK_PERIOD;
  reset <= '1';
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD;

  report "----- Confirming all tests have ran -----";
  wait;

end process;
	
end;