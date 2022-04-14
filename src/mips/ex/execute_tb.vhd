
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

-- FORWARDING CODES
	constant FORWARDING_NONE : std_logic_vector (1 downto 0):= "00";
	constant FORWARDING_EX : std_logic_vector (1 downto 0):= "01";
	constant FORWARDING_MEM : std_logic_vector (1 downto 0):= "10";

component execute is

port(
	-- INPUTS
	I_clk : in std_logic;
	I_reset : in std_logic;
	I_en : in std_logic;

	-- instruction signals
	I_rs: in std_logic_vector (4 downto 0);
	I_rt: in std_logic_vector (4 downto 0);
 	I_imm_SE : in  STD_LOGIC_VECTOR (31 downto 0);
	I_imm_ZE : in STD_LOGIC_VECTOR (31 downto 0);
        I_opcode : in  STD_LOGIC_VECTOR (5 downto 0);
	I_shamt: in STD_LOGIC_VECTOR (4 downto 0);
	I_funct: in STD_LOGIC_VECTOR (5 downto 0);
	I_addr: in STD_LOGIC_VECTOR (25 downto 0);
	
	I_rs_data: in std_logic_vector (31 downto 0);
	I_rt_data: in std_logic_vector (31 downto 0);
	I_next_pc: in std_logic_vector (31 downto 0); -- pc + 4

	-- control signals (passed from decode stage to wb stage)
	I_rd: in std_logic_vector (4 downto 0); 	-- the destination register where to write the instr. result
	I_branch: in std_logic; 					-- indicates if its is a branch operation (beq, bne)
	I_jump: in std_logic; 						-- indicates if it is a jump instruction (j, jr, jal)
	I_mem_read: in std_logic; 					-- indicates if a value must be read from memory at calculated address
	I_mem_write: in std_logic; 					-- indicates if value in I_rt_data must be written in memory at calculated address
	I_reg_write: in std_logic; 					-- indicates if value calculated in ALU must be written to destination register

	-- OUTPUTS
	O_alu_result: out std_logic_vector (31 downto 0);
	O_updated_next_pc: out std_logic_vector (31 downto 0);
	O_rt_data: out std_logic_vector (31 downto 0);
	O_stall: out std_logic;

	-- control signals
	O_rd: out std_logic_vector (4 downto 0);
	O_branch: out std_logic;
	O_jump: out std_logic;
	O_mem_read: out std_logic;
	O_mem_write: out std_logic;
	O_reg_write: out std_logic;

	-- forwarding
	I_ex_data: in std_logic_vector (31 downto 0);
	I_mem_data: in std_logic_vector (31 downto 0);

	I_forward_rs: in std_logic_vector (1 downto 0);
	I_forward_rt: in std_logic_vector (1 downto 0)
);
end component;

-- Synchronoucity Inputs
signal I_reset : std_logic := '0';
signal I_clk : std_logic := '0';
signal I_en : std_logic := '0';

-- Execute Inputs

-- instruction signals
signal I_rs: std_logic_vector (4 downto 0);
signal I_rt: std_logic_vector (4 downto 0);
signal I_imm_SE :  std_logic_vector (31 downto 0);
signal I_imm_ZE : std_logic_vector (31 downto 0);
signal I_opcode :  std_logic_vector (5 downto 0);
signal I_shamt: std_logic_vector (4 downto 0);
signal I_funct: std_logic_vector (5 downto 0);
signal I_addr: std_logic_vector (25 downto 0);
signal I_rs_data: std_logic_vector (31 downto 0);
signal I_rt_data: std_logic_vector (31 downto 0);
signal I_next_pc: std_logic_vector (31 downto 0); 

-- Control Signals Inputs
signal I_rd: std_logic_vector (4 downto 0); 	
signal I_branch: std_logic; 					
signal I_jump: std_logic; 						
signal I_mem_read: std_logic; 					
signal I_mem_write: std_logic; 					
signal I_reg_write: std_logic; 						

-- Execute Outputs
signal O_alu_result: std_logic_vector (31 downto 0);
signal O_updated_next_pc: std_logic_vector (31 downto 0);
signal O_rt_data: std_logic_vector (31 downto 0);

-- Control Signals Outputs
signal O_rd: std_logic_vector (4 downto 0);
signal O_branch: std_logic;
signal O_jump: std_logic;
signal O_mem_read: std_logic;
signal O_mem_write: std_logic;
signal O_reg_write: std_logic;
signal O_stall: std_logic;

-- Forwarding Signals
signal I_ex_data: std_logic_vector (31 downto 0);
signal I_mem_data: std_logic_vector (31 downto 0);

signal I_forward_rs: std_logic_vector (1 downto 0);
signal I_forward_rt: std_logic_vector (1 downto 0);

-- Input data
constant RD: std_logic_vector(4 downto 0) := "00011"; -- R3
constant RS: std_logic_vector(4 downto 0) := "00001"; -- R1
constant RT: std_logic_vector(4 downto 0) := "00010"; -- R2
constant LR: std_logic_vector(4 downto 0) := "11111"; -- R31
constant R0: std_logic_vector(4 downto 0) := "00000"; -- $R0
constant SHAMT: std_logic_vector(4 downto 0) := "00010"; -- 2
constant IMM_8: std_logic_vector(31 downto 0) := x"00000008"; 
constant IMM_4: std_logic_vector(31 downto 0) := x"00000004"; 
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
	I_clk => I_clk,
	I_reset => I_reset,
	I_en => I_en,

	I_rs => I_rs,
	I_rt => I_rt,
	I_imm_SE => I_imm_SE,
	I_imm_ZE => I_imm_ZE,
	I_opcode => I_opcode,
	I_shamt => I_shamt,
	I_funct => I_funct,
	I_addr => I_addr,

	I_rs_data => I_rs_data,
	I_rt_data => I_rt_data,
	I_next_pc => I_next_pc,

	-- control signals
	I_rd => I_rd,
	I_branch => I_branch,
	I_jump => I_jump,
	I_mem_read => I_mem_read,		
	I_mem_write => I_mem_write, 					
	I_reg_write => I_reg_write,				

	-- forwarding
	I_ex_data => I_ex_data,
	I_mem_data => I_mem_data,
	I_forward_rs => I_forward_rs,
	I_forward_rt => I_forward_rt,	

	-- OUTPUTS
	O_alu_result => O_alu_result,
	O_updated_next_pc => O_updated_next_pc,
	O_rt_data => O_rt_data,
	O_stall => O_stall,

	-- control signals
	O_rd => O_rd,
	O_branch => O_branch,
	O_jump => O_jump,
	O_mem_read => O_mem_read,
	O_mem_write => O_mem_write,
	O_reg_write => O_reg_write
);

				
I_clk_process : process
begin
  I_clk <= '0';
  wait for CLK_PERIOD/2;
  I_clk <= '1';
  wait for CLK_PERIOD/2;
end process;

test_process : process
begin

-- put your tests here

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;
  ----------------------------------------------------------------------------------
  
  	report "----- Starting tests -----";
	I_en <= '1';

  ----------------------------------------------------------------------------------
  -- TEST 1: ADD
  ----------------------------------------------------------------------------------
  	report "----- Test 1: ADD Instruction -----";
	
	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= ADD_FUNCT;
	
	I_rs_data <= DATA_8;
	I_rt_data <= DATA_4;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';



	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;
	
  	wait for CLK_PERIOD;
  	assert O_alu_result = ADD_RESULT report "Test 1: Unsuccessful" severity error;

----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 2: SUB
  ----------------------------------------------------------------------------------
  	report "----- Test 2: SUB Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= SUB_FUNCT;
	
	I_rs_data <= DATA_8;
	I_rt_data <= DATA_4;
	I_next_pc <= NEXT_PC_VALUE;
	I_rs_data <= DATA_8;
	I_rt_data <= DATA_4;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';



	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;	

  	wait for CLK_PERIOD;
  	assert O_alu_result =  SUB_RESULT report "Test 2: Unsuccessful" severity error;
  
----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 3: MUL, MFHI, MFLO
  ----------------------------------------------------------------------------------
  	report "----- Test 3: MULT Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= MULT_FUNCT;

	I_rs_data <= DATA_8;
	I_rt_data <= DATA_4;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '0';



	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

	------------ MFLO ------------ 
  	wait for CLK_PERIOD;

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= MFLO_FUNCT;

	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';




	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = MULT_LOW_RESULT report "Test 3: Unsuccessful - Invalid Low Value" severity error;

	------------ MFHI ------------

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= MFHI_FUNCT;

	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';




	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = MULT_HIGH_RESULT report "Test 3: Unsuccessful - Invalid High Value" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 4: DIV
  ----------------------------------------------------------------------------------
  	report "----- Test 4: DIV Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= DIV_FUNCT;

	I_rs_data <= DATA_8;
	I_rt_data <= DATA_4;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '0';



	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;

	------------ MFLO ------------ 
  	wait for CLK_PERIOD;

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= MFLO_FUNCT;

	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';



	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = DIV_LOW_RESULT report "Test 3: Unsuccessful - Invalid Low Value" severity error;

	------------ MFHI ------------
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= MFHI_FUNCT;

	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';



	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = DIV_HIGH_RESULT report "Test 3: Unsuccessful - Invalid High Value" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 5: SLT
  ----------------------------------------------------------------------------------
  report "----- Test 5: SLT Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= SLT_FUNCT;

	I_rs_data <= DATA_8;
	I_rt_data <= DATA_4;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';



	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = SLT_FALSE_RESULT report "Test 5: Unsuccessful" severity error;


	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= SLT_FUNCT;

	I_rs_data <= DATA_4;
	I_rt_data <= DATA_8;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';



	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = SLT_TRUE_RESULT report "Test 5: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 6: AND
  ----------------------------------------------------------------------------------
  	report "----- Test 6: AND Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= AND_FUNCT;

	I_rs_data <= DATA_4;
	I_rt_data <= DATA_8;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';
	

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = AND_RESULT report "Test 6: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 7: OR
  ----------------------------------------------------------------------------------
  	report "----- Test 7: OR Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= OR_FUNCT;

	I_rs_data <= DATA_4;
	I_rt_data <= DATA_8;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';

	

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = OR_RESULT report "Test 7: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;
  ----------------------------------------------------------------------------------
  -- TEST 8: NOR
  ----------------------------------------------------------------------------------
  	report "----- Test 8: NOR Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= NOR_FUNCT;

	I_rs_data <= DATA_4;
	I_rt_data <= DATA_8;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';

	

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = NOR_RESULT report "Test 8: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 9: XOR
  ----------------------------------------------------------------------------------
  	report "----- Test 9: XOR Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= XOR_FUNCT;

	I_rs_data <= DATA_4;
	I_rt_data <= DATA_8;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';

	

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = XOR_RESULT report "Test 9: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 10: SLL
  ----------------------------------------------------------------------------------
  	report "----- Test 12: SLL Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= SLL_FUNCT;

	I_rt_data <= DATA_8;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';

	

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = SLL_RESULT report "Test 12: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 13: SRL
  ----------------------------------------------------------------------------------
  	report "----- Test 13: SRL Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= SRL_FUNCT;

	I_rt_data <= DATA_8;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';

	

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = SRL_RESULT report "Test 13: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 14: SRA
  ----------------------------------------------------------------------------------
  	report "----- Test 14: SRA Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= SRA_FUNCT;

	I_rt_data <= DATA_8;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';

	

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = SRA_RESULT report "Test 14: Unsuccessful" severity error;

	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= SRA_FUNCT;

	I_rt_data <= DATA_MINUS_4;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';

	

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = SRA_NEGATIVE_RESULT report "Test 14: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 15: JR
  ----------------------------------------------------------------------------------
  	report "----- Test 15: JR Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= JR_FUNCT;

	I_rs_data <= DATA_8;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '1';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '0';

	
	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_updated_next_pc = JR_PC_RESULT report "Test 15: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 16: ADDI
  ----------------------------------------------------------------------------------
  report "----- Test 16: ADDI Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RT;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_4;
	I_imm_SE <= IMM_4;
	I_addr <= ADDRESS;
	I_opcode <= ADDI_OPCODE;
	I_funct <= "000000";

	I_rs_data <= DATA_8;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_rd <= RT;
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';

	

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = ADDI_RESULT report "Test 16: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 17: SLTI
  ----------------------------------------------------------------------------------
  	report "----- Test 17: SLTI Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RT;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_4;
	I_imm_SE <= IMM_4;
	I_addr <= ADDRESS;
	I_opcode <= SLTI_OPCODE;
	I_funct <= "000000";

	I_rs_data <= DATA_8;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_rd <= RT;
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';

	

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = SLTI_FALSE_RESULT report "Test 17: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RT;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= SLTI_OPCODE;
	I_funct <= "000000";

	I_rs_data <= DATA_4;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_rd <= RT;
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';

	

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = SLTI_TRUE_RESULT report "Test 17: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 18: ORI
  ----------------------------------------------------------------------------------
  	report "----- Test 18: ORI Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RT;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= ORI_OPCODE;
	I_funct <= "000000";

	I_rs_data <= DATA_4;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_rd <= RT;
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';

	

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = ORI_RESULT report "Test 18: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 19: XORI
  ----------------------------------------------------------------------------------
  	report "----- Test 19: XORI Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RT;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= XORI_OPCODE;
	I_funct <= "000000";

	I_rs_data <= DATA_4;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_rd <= RT;
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';

	

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = XORI_RESULT report "Test 19: Unsuccessful" severity error;
   
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 20: LUI
  ----------------------------------------------------------------------------------
  	report "----- Test 20: LUI Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RT;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_4;
	I_imm_SE <= IMM_4;
	I_addr <= ADDRESS;
	I_opcode <= LUI_OPCODE;
	I_funct <= "000000";


	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_rd <= RT;
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';

	

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = LUI_RESULT report "Test 20: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 21: LW
  ----------------------------------------------------------------------------------
  report "----- Test 21: LW Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RT;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_4;
	I_imm_SE <= IMM_4;
	I_addr <= ADDRESS;
	I_opcode <= LW_OPCODE;
	I_funct <= "000000";

	I_rs_data <= DATA_8;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_rd <= RT;
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '1';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';				

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = LW_RESULT report "Test 21: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;
  ----------------------------------------------------------------------------------
  -- TEST 22: SW
  ----------------------------------------------------------------------------------
  	report "----- Test 22: SW Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RT;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_4;
	I_imm_SE <= IMM_4;
	I_addr <= ADDRESS;
	I_opcode <= SW_OPCODE;
	I_funct <= "000000";

	I_rs_data <= DATA_8;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_rd <= RT;
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '1'; 					
	I_reg_write <= '0';

	

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = SW_RESULT report "Test 22: Unsuccessful" severity error;
  

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 23: BEQ
  ----------------------------------------------------------------------------------
  	report "----- Test 23: BEQ Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= "00000";
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_4;
	I_imm_SE <= IMM_4;
	I_addr <= ADDRESS;
	I_opcode <= BEQ_OPCODE;
	I_funct <= "000000";

	I_rs_data <= DATA_4;
	I_rt_data <= DATA_4;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_rd <= "00000";
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '0';

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
	assert O_branch = '1' report "Test 23.1 branch: Unsuccessful" severity error;
  	assert O_updated_next_pc = BEQ_TAKEN_PC_RESULT report "Test 23.1 pc: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

----------------------------------------------------------------------------------

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= "00000";
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_4;
	I_imm_SE <= IMM_4;
	I_addr <= ADDRESS;
	I_opcode <= BEQ_OPCODE;
	I_funct <= "000000";

	I_rs_data <= DATA_4;
	I_rt_data <= DATA_8;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_rd <= "00000";
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '0';

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
	assert O_branch = '0' report "Test 23.2 branch: Unsuccessful" severity error;
  	assert O_updated_next_pc = BEQ_NOT_TAKEN_PC_RESULT report "Test 23.2 pc: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 24: BNE
  ----------------------------------------------------------------------------------

  	report "----- Test 24: BNE Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= "00000";
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_4;
	I_imm_SE <= IMM_4;
	I_addr <= ADDRESS;
	I_opcode <= BNE_OPCODE;
	I_funct <= "000000";

	I_rs_data <= DATA_4;
	I_rt_data <= DATA_8;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_rd <= "00000";
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '0';

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
	assert O_branch = '1' report "Test 24.1 branch: Unsuccessful" severity error;
  	assert O_updated_next_pc = BNE_TAKEN_PC_RESULT report "Test 24 pc: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

----------------------------------------------------------------------------------

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= "00000";
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_4;
	I_imm_SE <= IMM_4;
	I_addr <= ADDRESS;
	I_opcode <= BNE_OPCODE;
	I_funct <= "000000";

	I_rs_data <= DATA_8;
	I_rt_data <= DATA_8;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_rd <= "00000";
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '0';

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
	assert O_branch = '0' report "Test 24.2 branch: Unsuccessful" severity error;
  	assert O_updated_next_pc = BNE_NOT_TAKEN_PC_RESULT report "Test 24.2 pc Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 25: J
  ----------------------------------------------------------------------------------
  	report "----- Test 25: J Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= "00000";
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_4;
	I_imm_SE <= IMM_4;
	I_addr <= ADDRESS;
	I_opcode <= J_OPCODE;
	I_funct <= "000000";
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '1';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '0';

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_updated_next_pc = J_PC_RESULT report "Test 25: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 26: JAL
  ----------------------------------------------------------------------------------
  	report "----- Test 26: JAL Instruction -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= LR;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_4;
	I_imm_SE <= IMM_4;
	I_addr <= ADDRESS;
	I_opcode <= JAL_OPCODE;
	I_funct <= "000000";
	I_next_pc <= NEXT_PC_VALUE;


	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '1';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '0';

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;

  	wait for CLK_PERIOD;
  	assert O_alu_result = JAL_RESULT report "Test 26.a: Unsuccessful" severity error;
	assert O_updated_next_pc = JAL_PC_RESULT report "Test 26.b: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 27: Forwarding from EX
  ----------------------------------------------------------------------------------
  	report "----- Test 27: Forwarding from EX -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= ADD_FUNCT;

	I_rs_data <= (others=>'0');
	I_rt_data <= DATA_4;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';

	-- forwarding
	I_ex_data <= DATA_8;
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_EX;
	I_forward_rt <= FORWARDING_NONE;
	
  	wait for CLK_PERIOD;
  	assert O_alu_result = ADD_RESULT report "Test 27: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= ADD_FUNCT;

	I_rs_data <= DATA_8;
	I_rt_data <= (others=>'0');
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';

	-- forwarding
	I_ex_data <= DATA_4;
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_EX;
	
  	wait for CLK_PERIOD;
  	assert O_alu_result = ADD_RESULT report "Test 27: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 28: Forwarding from MEM
  ----------------------------------------------------------------------------------
  	report "----- Test 28: Forwarding from MEM -----";

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= ADD_FUNCT;

	I_rs_data <= (others=>'0');
	I_rt_data <= DATA_4;
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';

	
	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= DATA_8;
	I_forward_rs <= FORWARDING_MEM;
	I_forward_rt <= FORWARDING_NONE;
	
  	wait for CLK_PERIOD;
  	assert O_alu_result = ADD_RESULT report "Test 28: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

	-- instruction signals
	I_rs <= RS;
	I_rt <= RT;
	I_rd <= RD;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= ADD_FUNCT;

	I_rs_data <= DATA_8;
	I_rt_data <= (others=>'0');
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '1';

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= DATA_4;
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_MEM;
	
  	wait for CLK_PERIOD;
  	assert O_alu_result = ADD_RESULT report "Test 28: Unsuccessful" severity error;


  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 29: Data Hazard
  ----------------------------------------------------------------------------------
  	report "----- Test 29: Data Hazard -----";

	-- instruction signals
	I_rs <= R0;
	I_rt <= R0;
	I_rd <= R0;
	I_shamt <= SHAMT;
	I_imm_ZE <= IMM_8;
	I_imm_SE <= IMM_8;
	I_addr <= ADDRESS;
	I_opcode <= R_OPCODE;
	I_funct <= ADD_FUNCT;

	I_rs_data <= (others=>'0');
	I_rt_data <= (others=>'0');
	I_next_pc <= NEXT_PC_VALUE;

	-- control signals
	I_branch <= '0';
	I_jump <= '0';
	I_mem_read <= '0';		
	I_mem_write <= '0'; 					
	I_reg_write <= '0';

	-- forwarding
	I_ex_data <= (others=>'0');
	I_mem_data <= (others=>'0');
	I_forward_rs <= FORWARDING_NONE;
	I_forward_rt <= FORWARDING_NONE;
	
  	wait for CLK_PERIOD;
  	assert O_stall = '1' 
report "Test 29: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

	
  report "----- Confirming all tests have ran -----";
  wait;

end process;
	
end;