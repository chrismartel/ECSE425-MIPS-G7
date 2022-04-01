
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
	constant CLK_PERIOD : time := 10 ns;

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
	updated_next_pc: out std_logic_vector (31 downto 0);
	rt_data_out: out std_logic_vector (31 downto 0);
	stall_out: out std_logic;

	-- control signals
	destination_register_out: out std_logic_vector (4 downto 0);
	branch_out: out std_logic;
	jump_out: out std_logic;
	mem_read_out: out std_logic;
	mem_write_out: out std_logic;
	reg_write_out: out std_logic;
	mem_to_reg_out: out std_logic;

	-- forwarding
	ex_data: in std_logic_vector (31 downto 0);
	mem_data: in std_logic_vector (31 downto 0);

	forward_rs: in std_logic_vector (1 downto 0);
	forward_rt: in std_logic_vector (1 downto 0)
);
end component;

-- Synchronoucity Inputs
signal reset : std_logic := '0';
signal clk : std_logic := '0';

-- Execute Inputs
signal instruction: std_logic_vector (31 downto 0);
signal rs_data_in: std_logic_vector (31 downto 0);
signal rt_data_in: std_logic_vector (31 downto 0);
signal next_pc: std_logic_vector (31 downto 0); 

-- Control Signals Inputs
signal destination_register_in: std_logic_vector (4 downto 0); 	
signal branch_in: std_logic; 					
signal jump_in: std_logic; 						
signal mem_read_in: std_logic; 					
signal mem_write_in: std_logic; 					
signal reg_write_in: std_logic; 					
signal mem_to_reg_in: std_logic; 					

-- Execute Outputs
signal alu_result: std_logic_vector (31 downto 0);
signal updated_next_pc: std_logic_vector (31 downto 0);
signal rt_data_out: std_logic_vector (31 downto 0);

-- Control Signals Outputs
signal destination_register_out: std_logic_vector (4 downto 0);
signal branch_out: std_logic;
signal jump_out: std_logic;
signal mem_read_out: std_logic;
signal mem_write_out: std_logic;
signal reg_write_out: std_logic;
signal mem_to_reg_out: std_logic;
signal stall_out: std_logic;

-- Forwarding Signals
signal ex_data: std_logic_vector (31 downto 0);
signal mem_data: std_logic_vector (31 downto 0);

signal forward_rs: std_logic_vector (1 downto 0);
signal forward_rt: std_logic_vector (1 downto 0);

-- Input data
constant RD: std_logic_vector(4 downto 0) := "00011"; -- R3
constant RS: std_logic_vector(4 downto 0) := "00001"; -- R1
constant RT: std_logic_vector(4 downto 0) := "00010"; -- R2
constant LR: std_logic_vector(4 downto 0) := "11111"; -- R31
constant R0: std_logic_vector(4 downto 0) := "00000"; -- $R0
constant SHAMT: std_logic_vector(4 downto 0) := "00010"; -- 2
constant IMM_8: std_logic_vector(15 downto 0) := x"0008"; 
constant IMM_4: std_logic_vector(15 downto 0) := x"0004"; 
constant ADDRESS: std_logic_vector(25 downto 0) := "00000000000000000000000100"; 

constant DATA_8: std_logic_vector(31 downto 0) := x"00000008";
constant DATA_4: std_logic_vector(31 downto 0) := x"00000004";
constant DATA_MINUS_4: std_logic_vector(31 downto 0) := x"FFFFFFFC"; 
constant NEXT_PC_VALUE: std_logic_vector(31 downto 0) := x"00000004";

-- Results Data

-- R
constant ADD_RESULT: std_logic_vector(31 downto 0) := x"0000000C";
constant SUB_RESULT: std_logic_vector(31 downto 0) := x"00000004";
constant MULT_LOW_RESULT: std_logic_vector(31 downto 0) := x"00000020";
constant MULT_HIGH_RESULT: std_logic_vector(31 downto 0) := x"00000000";
constant DIV_LOW_RESULT: std_logic_vector(31 downto 0) := x"00000002";
constant DIV_HIGH_RESULT: std_logic_vector(31 downto 0) := x"00000000";
constant SLT_TRUE_RESULT: std_logic_vector(31 downto 0) := x"00000001";
constant SLT_FALSE_RESULT: std_logic_vector(31 downto 0) := x"00000000";
constant AND_RESULT: std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
constant OR_RESULT: std_logic_vector(31 downto 0) := "00000000000000000000000000001100";
constant NOR_RESULT: std_logic_vector(31 downto 0) := "11111111111111111111111111110011";
constant XOR_RESULT: std_logic_vector(31 downto 0) := "00000000000000000000000000001100";
constant SLL_RESULT: std_logic_vector(31 downto 0) := x"00000020";
constant SRL_RESULT: std_logic_vector(31 downto 0) := x"00000002"; 
constant SRA_RESULT: std_logic_vector(31 downto 0) := x"00000002";
constant SRA_NEGATIVE_RESULT: std_logic_vector(31 downto 0) := x"FFFFFFFF";
constant JR_PC_RESULT: std_logic_vector(31 downto 0) := x"00000008";

-- I
constant ADDI_RESULT: std_logic_vector(31 downto 0) := x"0000000C";
constant SLTI_TRUE_RESULT: std_logic_vector(31 downto 0) := x"00000001";
constant SLTI_FALSE_RESULT: std_logic_vector(31 downto 0) := x"00000000";
constant ORI_RESULT: std_logic_vector(31 downto 0) := x"0000000C";
constant XORI_RESULT: std_logic_vector(31 downto 0) := x"0000000C";
constant LUI_RESULT: std_logic_vector(31 downto 0) := x"00040000";
constant LW_RESULT: std_logic_vector(31 downto 0) := x"0000000C";
constant SW_RESULT: std_logic_vector(31 downto 0) := x"0000000C";
constant BEQ_TAKEN_PC_RESULT: std_logic_vector(31 downto 0) := x"00000014";
constant BEQ_NOT_TAKEN_PC_RESULT: std_logic_vector(31 downto 0) := x"00000004";
constant BNE_TAKEN_PC_RESULT: std_logic_vector(31 downto 0) := x"00000014";
constant BNE_NOT_TAKEN_PC_RESULT: std_logic_vector(31 downto 0) := x"00000004";

-- J
constant J_PC_RESULT: std_logic_vector(31 downto 0) := x"00000010";
constant JAL_PC_RESULT: std_logic_vector(31 downto 0) := x"00000010";
constant JAL_RESULT: std_logic_vector(31 downto 0) := x"00000008";
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

	-- control signals
	destination_register_in => destination_register_in,
	branch_in => branch_in,
	jump_in => jump_in,
	mem_read_in => mem_read_in,		
	mem_write_in => mem_write_in, 					
	reg_write_in => reg_write_in,				
	mem_to_reg_in => mem_to_reg_in,	

	-- forwarding
	ex_data => ex_data,
	mem_data => mem_data,
	forward_rs => forward_rs,
	forward_rt => forward_rt,	

	-- OUTPUTS
	alu_result => alu_result,
	updated_next_pc => updated_next_pc,
	rt_data_out => rt_data_out,
	stall_out => stall_out,

	-- control signals
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

	instruction <= R_OPCODE & RS & RT & RD & SHAMT & ADD_FUNCT;
	rs_data_in <= DATA_8;
	rt_data_in <= DATA_4;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";
	
  	wait for CLK_PERIOD;
  	assert alu_result = ADD_RESULT report "Test 1: Unsuccessful" severity error;

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

	instruction <= R_OPCODE & RS & RT & RD & SHAMT & SUB_FUNCT;
	rs_data_in <= DATA_8;
	rt_data_in <= DATA_4;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";	

  	wait for CLK_PERIOD;
  	assert alu_result =  SUB_RESULT report "Test 2: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	reset <= '1';
  	wait for CLK_PERIOD;
  	reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 3: MUL, MFHI, MFLO
  ----------------------------------------------------------------------------------
  	report "----- Test 3: MULT Instruction -----";

	instruction <= R_OPCODE & RS & RT & RD & SHAMT & MULT_FUNCT;
	rs_data_in <= DATA_8;
	rt_data_in <= DATA_4;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '0';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

	------------ MFLO ------------ 
  	wait for CLK_PERIOD;

	instruction <= R_OPCODE & RS & RT & RD & SHAMT & MFLO_FUNCT;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = MULT_LOW_RESULT report "Test 3: Unsuccessful - Invalid Low Value" severity error;

	------------ MFHI ------------
	instruction <= R_OPCODE & RS & RT & RD & SHAMT & MFHI_FUNCT;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = MULT_HIGH_RESULT report "Test 3: Unsuccessful - Invalid High Value" severity error;
  
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
  	instruction <= R_OPCODE & RS & RT & RD & SHAMT & DIV_FUNCT;

	rs_data_in <= DATA_8;
	rt_data_in <= DATA_4;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '0';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;

	------------ MFLO ------------ 
  	wait for CLK_PERIOD;

	instruction <= R_OPCODE & RS & RT & RD & SHAMT & MFLO_FUNCT;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = DIV_LOW_RESULT report "Test 3: Unsuccessful - Invalid Low Value" severity error;

	------------ MFHI ------------
	instruction <= R_OPCODE & RS & RT & RD & SHAMT & MFHI_FUNCT;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = DIV_HIGH_RESULT report "Test 3: Unsuccessful - Invalid High Value" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	reset <= '1';
  	wait for CLK_PERIOD;
  	reset <= '0';
  	wait for CLK_PERIOD;
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
  	instruction <= R_OPCODE & RS & RT & RD & SHAMT & SLT_FUNCT;

	rs_data_in <= DATA_8;
	rt_data_in <= DATA_4;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = SLT_FALSE_RESULT report "Test 5: Unsuccessful" severity error;


  	instruction <= R_OPCODE & RS & RT & RD & SHAMT & SLT_FUNCT;

	rs_data_in <= DATA_4;
	rt_data_in <= DATA_8;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = SLT_TRUE_RESULT report "Test 5: Unsuccessful" severity error;
  
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
  	instruction <= R_OPCODE & RS & RT & RD & SHAMT & AND_FUNCT;


	rs_data_in <= DATA_4;
	rt_data_in <= DATA_8;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = AND_RESULT report "Test 6: Unsuccessful" severity error;
  
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
  	instruction <= R_OPCODE & RS & RT & RD & SHAMT & OR_FUNCT;

	rs_data_in <= DATA_4;
	rt_data_in <= DATA_8;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = OR_RESULT report "Test 7: Unsuccessful" severity error;
  
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
  	instruction <= R_OPCODE & RS & RT & RD & SHAMT & NOR_FUNCT;
	
	rs_data_in <= DATA_4;
	rt_data_in <= DATA_8;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = NOR_RESULT report "Test 8: Unsuccessful" severity error;
  
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
  	instruction <= R_OPCODE & RS & RT & RD & SHAMT & XOR_FUNCT;
	
	rs_data_in <= DATA_4;
	rt_data_in <= DATA_8;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = XOR_RESULT report "Test 9: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	reset <= '1';
  	wait for CLK_PERIOD;
  	reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 10: SLL
  ----------------------------------------------------------------------------------
  	report "----- Test 12: SLL Instruction -----";
  	instruction <= R_OPCODE & RS & RT & RD & SHAMT & SLL_FUNCT;

	rt_data_in <= DATA_8;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = SLL_RESULT report "Test 12: Unsuccessful" severity error;
  
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
  	instruction <= R_OPCODE & RS & RT & RD & SHAMT & SRL_FUNCT;

	rt_data_in <= DATA_8;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = SRL_RESULT report "Test 13: Unsuccessful" severity error;
  
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
  	instruction <= R_OPCODE & RS & RT & RD & SHAMT & SRA_FUNCT;

	rt_data_in <= DATA_8;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = SRA_RESULT report "Test 14: Unsuccessful" severity error;

  	instruction <= R_OPCODE & RS & RT & RD & SHAMT & SRA_FUNCT;

	rt_data_in <= DATA_MINUS_4;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = SRA_NEGATIVE_RESULT report "Test 14: Unsuccessful" severity error;
  
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
  	instruction <= R_OPCODE & RS & RT & RD & SHAMT & JR_FUNCT;

	rs_data_in <= DATA_8;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '1';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '0';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert updated_next_pc = JR_PC_RESULT report "Test 15: Unsuccessful" severity error;
  
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
  	instruction <= ADDI_OPCODE & RS & RT & IMM_4;

	rs_data_in <= DATA_8;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RT;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = ADDI_RESULT report "Test 16: Unsuccessful" severity error;
  
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
  	instruction <= SLTI_OPCODE & RS & RT & IMM_4;

	rs_data_in <= DATA_8;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RT;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = SLTI_FALSE_RESULT report "Test 17: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	reset <= '1';
  	wait for CLK_PERIOD;
  	reset <= '0';
  	wait for CLK_PERIOD;

  	instruction <= SLTI_OPCODE & RS & RT & IMM_8;
	rs_data_in <= DATA_4;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RT;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = SLTI_TRUE_RESULT report "Test 17: Unsuccessful" severity error;
  
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

  	instruction <= ORI_OPCODE & RS & RT & IMM_8;
	rs_data_in <= DATA_4;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RT;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = ORI_RESULT report "Test 18: Unsuccessful" severity error;
  
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
  	instruction <= XORI_OPCODE & RS & RT & IMM_8;

	rs_data_in <= DATA_4;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RT;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = XORI_RESULT report "Test 19: Unsuccessful" severity error;
   
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
  	instruction <= LUI_OPCODE & RS & RT & IMM_4;

	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RT;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = LUI_RESULT report "Test 20: Unsuccessful" severity error;
  
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
  	instruction <= LW_OPCODE & RS & RT & IMM_4;

	rs_data_in <= DATA_8;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RT;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '1';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '1';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = LW_RESULT report "Test 21: Unsuccessful" severity error;
  
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
  	instruction <= SW_OPCODE & RS & RT & IMM_4;

	rs_data_in <= DATA_8;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RT;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '1'; 					
	reg_write_in <= '0';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = SW_RESULT report "Test 22: Unsuccessful" severity error;
  

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
  	instruction <= BEQ_OPCODE & RS & RT & IMM_4;

	rs_data_in <= DATA_4;
	rt_data_in <= DATA_4;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= "00000";
	branch_in <= '1';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '0';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert updated_next_pc = BEQ_TAKEN_PC_RESULT report "Test 23.a: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	reset <= '1';
  	wait for CLK_PERIOD;
  	reset <= '0';
  	wait for CLK_PERIOD;

----------------------------------------------------------------------------------

  	instruction <= BEQ_OPCODE & RS & RT & IMM_4;

	rs_data_in <= DATA_4;
	rt_data_in <= DATA_8;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= "00000";
	branch_in <= '1';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '0';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert updated_next_pc = BEQ_NOT_TAKEN_PC_RESULT report "Test 23.b: Unsuccessful" severity error;
  
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
  	instruction <= BNE_OPCODE & RS & RT & IMM_4;

	rs_data_in <= DATA_4;
	rt_data_in <= DATA_8;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= "00000";
	branch_in <= '1';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '0';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert updated_next_pc = BNE_TAKEN_PC_RESULT report "Test 24.a: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	reset <= '1';
  	wait for CLK_PERIOD;
  	reset <= '0';
  	wait for CLK_PERIOD;

----------------------------------------------------------------------------------

  	instruction <= BNE_OPCODE & RS & RT & IMM_4;

	rs_data_in <= DATA_8;
	rt_data_in <= DATA_8;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= "00000";
	branch_in <= '1';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '0';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert updated_next_pc = BNE_NOT_TAKEN_PC_RESULT report "Test 24.b: Unsuccessful" severity error;

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
  	instruction <= J_OPCODE & ADDRESS;

	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= "00000";
	branch_in <= '0';
	jump_in <= '1';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '0';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert updated_next_pc = J_PC_RESULT report "Test 25: Unsuccessful" severity error;

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
  	instruction <= JAL_OPCODE & ADDRESS;

	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= LR;
	branch_in <= '0';
	jump_in <= '1';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '0';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";

  	wait for CLK_PERIOD;
  	assert alu_result = JAL_RESULT report "Test 26.a: Unsuccessful" severity error;
	assert updated_next_pc = JAL_PC_RESULT report "Test 26.b: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	reset <= '1';
  	wait for CLK_PERIOD;
  	reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 27: Forwarding from EX
  ----------------------------------------------------------------------------------
  	report "----- Test 27: Forwarding from EX -----";

  	instruction <= R_OPCODE & RS & RT & RD & SHAMT & ADD_FUNCT;

	rs_data_in <= (others=>'0');
	rt_data_in <= DATA_4;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= DATA_8;
	mem_data <= (others=>'0');
	forward_rs <= "01";
	forward_rt <= "00";
	
  	wait for CLK_PERIOD;
  	assert alu_result = ADD_RESULT report "Test 27: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	reset <= '1';
  	wait for CLK_PERIOD;
  	reset <= '0';
  	wait for CLK_PERIOD;

  	instruction <= R_OPCODE & RS & RT & RD & SHAMT & ADD_FUNCT;

	rs_data_in <= DATA_8;
	rt_data_in <= (others=>'0');
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= DATA_4;
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "01";
	
  	wait for CLK_PERIOD;
  	assert alu_result = ADD_RESULT report "Test 27: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	reset <= '1';
  	wait for CLK_PERIOD;
  	reset <= '0';
  	wait for CLK_PERIOD;


  ----------------------------------------------------------------------------------
  -- TEST 28: Forwarding from MEM
  ----------------------------------------------------------------------------------
  	report "----- Test 28: Forwarding from MEM -----";
  	instruction <= R_OPCODE & RS & RT & RD & SHAMT & ADD_FUNCT;

	rs_data_in <= (others=>'0');
	rt_data_in <= DATA_4;
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= DATA_8;
	forward_rs <= "10";
	forward_rt <= "00";
	
  	wait for CLK_PERIOD;
  	assert alu_result = ADD_RESULT report "Test 28: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	reset <= '1';
  	wait for CLK_PERIOD;
  	reset <= '0';
  	wait for CLK_PERIOD;

  	instruction <= R_OPCODE & RS & RT & RD & SHAMT & ADD_FUNCT;

	rs_data_in <= DATA_8;
	rt_data_in <= (others=>'0');
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= RD;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '1';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= DATA_4;
	forward_rs <= "00";
	forward_rt <= "10";
	
  	wait for CLK_PERIOD;
  	assert alu_result = ADD_RESULT report "Test 28: Unsuccessful" severity error;


  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	reset <= '1';
  	wait for CLK_PERIOD;
  	reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 29: Data Hazard
  ----------------------------------------------------------------------------------
  	report "----- Test 29: Data Hazard -----";

	instruction <= R_OPCODE & R0 & R0 & R0 & SHAMT & ADD_FUNCT;
	rs_data_in <= (others=>'0');
	rt_data_in <= (others=>'0');
	next_pc <= NEXT_PC_VALUE;

	-- control signals
	destination_register_in <= R0;
	branch_in <= '0';
	jump_in <= '0';
	mem_read_in <= '0';		
	mem_write_in <= '0'; 					
	reg_write_in <= '0';				
	mem_to_reg_in <= '0';	

	-- forwarding
	ex_data <= (others=>'0');
	mem_data <= (others=>'0');
	forward_rs <= "00";
	forward_rt <= "00";
	
  	wait for CLK_PERIOD;
  	assert stall_out = '1' 
report "Test 29: Unsuccessful" severity error;

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