library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity id_ex_tb is
generic(
	number_of_registers : INTEGER := 32; -- number of blocks in cache
	ram_size : integer := 32768
);

end id_ex_tb;

architecture behavior of id_ex_tb is

--------------------------------------------------------------------
-------------------------- I. CONSTANTS ----------------------------
--------------------------------------------------------------------

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

-- FORWARDING CODES
	constant FORWARDING_NONE : std_logic_vector (1 downto 0):= "00";
	constant FORWARDING_EX : std_logic_vector (1 downto 0):= "01";
	constant FORWARDING_MEM : std_logic_vector (1 downto 0):= "10";

--------------------------------------------------------------------
-------------------------- II. COMPONENTS --------------------------
--------------------------------------------------------------------

-- REGISTER FILE COMPONENT 
component regs is
port ( 
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
end component;

-- DECODE COMPONENT 
component decode is
port ( 
    	-- Inputs
	I_clk : in  STD_LOGIC;
    	I_reset: in STD_LOGIC;
        I_dataInst : in  STD_LOGIC_VECTOR (31 downto 0);
        I_en : in  STD_LOGIC;
    	I_pc: in STD_LOGIC_VECTOR (31 downto 0);
	I_fwd_en: in std_logic;
    	-- hazard detection
    	I_id_rd: in std_logic_vector (4 downto 0);
    	I_id_reg_write: in std_logic;
	I_id_mem_read: in std_logic;
    	I_ex_rd: in std_logic_vector (4 downto 0);
    	I_ex_reg_write: in std_logic;
            
   	-- Outputs
    	O_next_pc: out STD_LOGIC_VECTOR (31 downto 0);
        O_rs : out  STD_LOGIC_VECTOR (4 downto 0);
        O_rt : out  STD_LOGIC_VECTOR (4 downto 0);
        O_rd : out  STD_LOGIC_VECTOR (4 downto 0);
        O_dataIMM_SE : out  STD_LOGIC_VECTOR (31 downto 0);
    	O_dataIMM_ZE : out STD_LOGIC_VECTOR (31 downto 0);
        O_regDwe : out  STD_LOGIC;
        O_aluop : out  STD_LOGIC_VECTOR (5 downto 0);
    	O_shamt: out STD_LOGIC_VECTOR (4 downto 0);
    	O_funct: out STD_LOGIC_VECTOR (5 downto 0);
    	O_branch: out STD_LOGIC;
    	O_jump: out STD_LOGIC;
    	O_mem_read: out STD_LOGIC;
    	O_mem_write: out STD_LOGIC;
    	O_addr: out STD_LOGIC_VECTOR (25 downto 0);
	O_stall: out STD_LOGIC
);
end component;


-- EXECUTE STAGE COMPONENT 
component execute is
port(
	-- INPUTS
	I_clk : in std_logic;
	I_reset : in std_logic;
	I_en : in std_logic;

	-- from decode
	I_rs: in std_logic_vector (4 downto 0);
	I_rt: in std_logic_vector (4 downto 0);
 	I_imm_SE : in  std_logic_vector (31 downto 0);
	I_imm_ZE : in std_logic_vector (31 downto 0);
        I_opcode : in  std_logic_vector (5 downto 0);
	I_shamt: in std_logic_vector (4 downto 0);
	I_funct: in std_logic_vector (5 downto 0);
	I_addr: in std_logic_vector (25 downto 0);
	-- control signals 
	I_rd: in std_logic_vector (4 downto 0); 	
	I_branch: in std_logic; 					
	I_jump: in std_logic; 						
	I_mem_read: in std_logic; 					
	I_mem_write: in std_logic; 					
	I_reg_write: in std_logic; 					

	-- from register file
	I_rs_data: in std_logic_vector (31 downto 0);
	I_rt_data: in std_logic_vector (31 downto 0);
	I_next_pc: in std_logic_vector (31 downto 0); 

	-- forwarding
	I_fwd_ex_alu_result: in std_logic_vector (31 downto 0);
	I_fwd_mem_read_data: in std_logic_vector (31 downto 0);
	I_fwd_mem_alu_result: in std_logic_vector (31 downto 0);
	I_fwd_mem_read: in std_logic;
	
	-- from forwarding unit
	I_forward_rs: in std_logic_vector (1 downto 0);
	I_forward_rt: in std_logic_vector (1 downto 0);

	-- OUTPUTS

	-- to memory component
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
	O_address: out INTEGER range 0 to ram_size-1
);
end component;

-- FORWARDING UNIT COMPONENT 
component forwarding_unit is
port(
	-- INPUTS
	I_clk : in std_logic;
	I_reset : in std_logic;
	I_en: in std_logic;

	I_id_rd: in std_logic_vector (4 downto 0); 		
	I_ex_rd: in std_logic_vector (4 downto 0); 	
	I_id_reg_write: in std_logic; 			
	I_ex_reg_write: in std_logic;
	I_id_mem_read: in std_logic;		
	I_f_rs: in std_logic_vector(4 downto 0); 		
	I_f_rt: in std_logic_vector(4 downto 0); 		

	-- OUTPUTS

	-- '00' -> read from ID inputs
	-- '01' -> read from EX stage output
	-- '10' -> read from MEM stage output

	O_forward_rs: out std_logic_vector (1 downto 0); -- selection of left operand for ALU
	O_forward_rt: out std_logic_vector (1 downto 0) -- selection of right operand for ALU
);
end component;

--------------------------------------------------------------------
-------------------------- III. SIGNALS --------------------------
--------------------------------------------------------------------

-- Synchronoucity Inputs
signal I_reset : std_logic := '0';
signal I_clk : std_logic := '0';
signal I_en : std_logic := '0';
signal I_fwd_en : std_logic := '0';

-- REGISTER FILE SIGNALS
-- INPUTS
signal RF_I_rs :  std_logic_vector (4 downto 0);
signal RF_I_rt :  std_logic_vector (4 downto 0);
signal RF_I_rd :  std_logic_vector (4 downto 0); -- from wb to rf
signal RF_I_datad: std_logic_vector (31 downto 0); -- from wb to rf
signal RF_I_we :  std_logic := '0'; -- from wb to rf

-- OUTPUTS
signal RF_O_datas :  std_logic_vector (31 downto 0); -- rf to ex
signal RF_O_datat :  std_logic_vector (31 downto 0); -- rf to ex

-- DECODE SIGNALS
-- OUTPUTS
-- from id to ex

signal ID_O_next_pc: std_logic_vector (31 downto 0);
signal ID_O_rs : std_logic_vector (4 downto 0);
signal ID_O_rt : std_logic_vector (4 downto 0);
signal ID_O_rd : std_logic_vector (4 downto 0);
signal ID_O_dataIMM_SE : std_logic_vector (31 downto 0);
signal ID_O_dataIMM_ZE : std_logic_vector (31 downto 0);
signal ID_O_regDwe : std_logic;
signal ID_O_aluop : std_logic_vector (5 downto 0);
signal ID_O_shamt: std_logic_vector (4 downto 0);
signal ID_O_funct: std_logic_vector (5 downto 0);
signal ID_O_branch: std_logic;
signal ID_O_jump: std_logic;
signal ID_O_mem_read: std_logic;
signal ID_O_mem_write: std_logic;
signal ID_O_addr: std_logic_vector (25 downto 0);
signal ID_O_stall: std_logic := '0';


-- EXECUTE SIGNALS				
-- OUTPUTS 
signal EX_O_alu_result: std_logic_vector (31 downto 0);
signal EX_O_updated_next_pc: std_logic_vector (31 downto 0);
signal EX_O_rt_data: std_logic_vector (31 downto 0);
signal EX_O_stall: std_logic;
signal EX_O_rd: std_logic_vector (4 downto 0);
signal EX_O_branch: std_logic;
signal EX_O_jump: std_logic;
signal EX_O_mem_read: std_logic;
signal EX_O_mem_write: std_logic;
signal EX_O_reg_write: std_logic;
signal EX_O_address: integer;

-- FETCH
signal F_O_dataInst : std_logic_vector (31 downto 0); -- from fetch to id
signal F_O_pc: std_logic_vector (31 downto 0); -- from fetch to id

-- MEMORY
-- mock memory signals
signal MEM_O_rd: std_logic_vector (4 downto 0);
signal MEM_O_reg_write: std_logic; 
signal MEM_O_alu_result: std_logic_vector (31 downto 0);
signal MEM_O_read_data: std_logic_vector (31 downto 0);
signal MEM_O_mem_read: std_logic;

-- WRITE BACK


-- FORWARD UNIT SIGNALS
-- OUTPUTS
signal FWD_O_forward_rs: std_logic_vector (1 downto 0);
signal FWD_O_forward_rt: std_logic_vector (1 downto 0);


--------------------------------------------------------------------
-------------------------- IV. TEST DATA ---------------------------
--------------------------------------------------------------------

constant R3: std_logic_vector(4 downto 0) := "00011"; -- R3
constant R1: std_logic_vector(4 downto 0) := "00001"; -- R1
constant R2: std_logic_vector(4 downto 0) := "00010"; -- R2
constant R4: std_logic_vector(4 downto 0) := "00100"; -- R4
constant R5: std_logic_vector(4 downto 0) := "00101"; -- R5
constant R6: std_logic_vector(4 downto 0) := "00110"; -- R6
constant LR: std_logic_vector(4 downto 0) := "11111"; -- R31
constant R0: std_logic_vector(4 downto 0) := "00000"; -- $R0
constant SHAMT: std_logic_vector(4 downto 0) := "00010";
constant IMM_8: std_logic_vector(15 downto 0) := x"0008"; 
constant IMM_4: std_logic_vector(15 downto 0) := x"0004"; 
constant IMM_0: std_logic_vector(15 downto 0) := x"0000"; 
constant ADDRESS: std_logic_vector(25 downto 0) := "00000000000000000000000100"; 

constant DATA_8: std_logic_vector(31 downto 0) := x"00000008";
constant DATA_4: std_logic_vector(31 downto 0) := x"00000004";
constant DATA_MINUS_4: std_logic_vector(31 downto 0) := x"FFFFFFFC"; 
constant NEXT_PC: std_logic_vector(31 downto 0) := x"00000004";

-- Results Data

-- R
constant ADD_RESULT: std_logic_vector(31 downto 0) := x"0000000C"; -- 4 + 8
constant ADD_RESULT_FWD: std_logic_vector(31 downto 0) := x"00000010"; -- 4 + 8 + 4
constant SUB_RESULT: std_logic_vector(31 downto 0) := x"00000004"; -- 8 - 4
constant MULT_LOW_RESULT: std_logic_vector(31 downto 0) := x"00000020"; -- 4 x 8 (lower)
constant MULT_HIGH_RESULT: std_logic_vector(31 downto 0) := x"00000000"; -- 4 x 8 (upper)
constant DIV_LOW_RESULT: std_logic_vector(31 downto 0) := x"00000002"; -- 8 / 4 (lower)
constant DIV_HIGH_RESULT: std_logic_vector(31 downto 0) := x"00000000"; -- 8 mod 4 (upper)
constant SLT_TRUE_RESULT: std_logic_vector(31 downto 0) := x"00000001"; -- 4 less than 8
constant SLT_FALSE_RESULT: std_logic_vector(31 downto 0) := x"00000000"; -- 8 less than 4
constant AND_RESULT: std_logic_vector(31 downto 0) := "00000000000000000000000000000000"; -- 4 and 8
constant OR_RESULT: std_logic_vector(31 downto 0) := "00000000000000000000000000001100"; -- 4 or 8
constant NOR_RESULT: std_logic_vector(31 downto 0) := "11111111111111111111111111110011"; -- 4 nor 8
constant XOR_RESULT: std_logic_vector(31 downto 0) := "00000000000000000000000000001100"; -- 4 xor 8
constant SLL_RESULT: std_logic_vector(31 downto 0) := x"00000020"; -- 8 left shifted by 2
constant SRL_RESULT: std_logic_vector(31 downto 0) := x"00000002";  -- 8 right shifted by 2
constant SRA_RESULT: std_logic_vector(31 downto 0) := x"00000002"; -- 8 right shifted by 2
constant SRA_NEGATIVE_RESULT: std_logic_vector(31 downto 0) := x"FFFFFFFF"; -- -4 right shifted by 2
constant JR_PC_RESULT: std_logic_vector(31 downto 0) := x"00000008";

-- I
constant ADDI_RESULT: std_logic_vector(31 downto 0) := x"00000008"; -- 4 + IMM_4
constant SLTI_TRUE_RESULT: std_logic_vector(31 downto 0) := x"00000001"; -- 4 less than IMM_8
constant SLTI_FALSE_RESULT: std_logic_vector(31 downto 0) := x"00000000"; -- 8 less than IMM_4
constant ORI_RESULT: std_logic_vector(31 downto 0) := x"0000000C"; -- 4 or IMM_8
constant XORI_RESULT: std_logic_vector(31 downto 0) := x"0000000C"; -- 4 xor IMM_8
constant LUI_RESULT: std_logic_vector(31 downto 0) := x"00040000"; -- upper IMM_4
constant LW_RESULT: std_logic_vector(31 downto 0) := x"0000000C"; -- load in address 4 + IMM_8
constant SW_RESULT: std_logic_vector(31 downto 0) := x"0000000C"; -- store at address 4 + IMM_8
constant BEQ_TAKEN_PC_RESULT: std_logic_vector(31 downto 0) := x"00000014"; -- next_pc + 4 * IMM_4 (4-bytes words)
constant BEQ_NOT_TAKEN_PC_RESULT: std_logic_vector(31 downto 0) := x"00000004"; -- next_pc
constant BNE_TAKEN_PC_RESULT: std_logic_vector(31 downto 0) := x"00000014"; -- next_pc + 4 * IMM_4 (4-bytes words)
constant BNE_NOT_TAKEN_PC_RESULT: std_logic_vector(31 downto 0) := x"00000004"; -- next_pc

-- J
constant J_PC_RESULT: std_logic_vector(31 downto 0) := x"00000010"; -- address * 4
constant JAL_PC_RESULT: std_logic_vector(31 downto 0) := x"00000010"; -- address * 4
constant JAL_RESULT: std_logic_vector(31 downto 0) := x"00000008"; -- next_pc + 4
begin


--------------------------------------------------------------------
-------------------------- V. CONNECTIONS --------------------------
--------------------------------------------------------------------

ex: execute 
port map(
	-- INPUTS
	I_clk => I_clk,
	I_reset => I_reset,
	I_en => I_en,

	I_rs => ID_O_rs,
	I_rt => ID_O_rt,
	I_rd => ID_O_rd,
	I_imm_SE => ID_O_dataIMM_SE,
	I_imm_ZE => ID_O_dataIMM_ZE,
	I_opcode => ID_O_aluop,
	I_shamt => ID_O_shamt,
	I_funct => ID_O_funct,
	I_addr => ID_O_addr,

	I_rs_data => RF_O_datas,
	I_rt_data => RF_O_datat,
	I_next_pc => ID_O_next_pc,

	-- control signals
	I_branch => ID_O_branch,
	I_jump => ID_O_jump,
	I_mem_read => ID_O_mem_read,		
	I_mem_write => ID_O_mem_write, 					
	I_reg_write => ID_O_regDwe,				

	-- forwarding
	I_fwd_ex_alu_result => EX_O_alu_result,
	I_fwd_mem_read_data => MEM_O_read_data, 
	I_fwd_mem_alu_result => MEM_O_alu_result, 
	I_fwd_mem_read => MEM_O_mem_read,
	I_forward_rs => FWD_O_forward_rs,
	I_forward_rt => FWD_O_forward_rt,	

	-- OUTPUTS 
	-- TODO: connect to memory component
	O_alu_result => EX_O_alu_result,
	O_updated_next_pc => EX_O_updated_next_pc,
	O_address => EX_O_address,
	O_rt_data => EX_O_rt_data,
	O_stall => EX_O_stall,

	-- control signals
	O_rd => EX_O_rd,
	O_branch => EX_O_branch,
	O_jump => EX_O_jump,
	O_mem_read => EX_O_mem_read,
	O_mem_write => EX_O_mem_write,
	O_reg_write => EX_O_reg_write
);

id: decode 
port map(
	-- Inputs
	-- TODO: connect to fetch component
	I_clk => I_clk,
	I_reset => I_reset,
    	I_dataInst => F_O_dataInst,
       	I_en => I_en,
	I_pc => F_O_pc,

	-- forwarding
	I_fwd_en => I_fwd_en,
	I_id_rd => ID_O_rd,
	I_id_reg_write => ID_O_regDwe,
	I_id_mem_read => ID_O_mem_read,
	I_ex_rd => EX_O_rd,
	I_ex_reg_write => EX_O_reg_write,

	-- Outputs
	O_next_pc => ID_O_next_pc,
        O_rs => ID_O_rs,
        O_rt => ID_O_rt,
        O_rd => ID_O_rd,
        O_dataIMM_SE => ID_O_dataIMM_SE,
	O_dataIMM_ZE => ID_O_dataIMM_ZE,
        O_aluop => ID_O_aluop,
	O_shamt => ID_O_shamt,
	O_funct => ID_O_funct,
	O_branch => ID_O_branch,
	O_jump => ID_O_jump,
	O_mem_read => ID_O_mem_read,
	O_mem_write => ID_O_mem_write,
	O_regdWe => ID_O_regDwe,
	O_addr => ID_O_addr,
	O_stall => ID_O_stall
);

rf: regs 
port map(
	-- Inputs
	-- requested registers come from decode output
	I_clk => I_clk,
	I_reset => I_reset,
	I_dataD => RF_I_datad,
       	I_en => I_en,
       	I_rs => RF_I_rs,
       	I_rt => RF_I_rt,
       	I_rd => RF_I_rd,
       	I_we => RF_I_we,

	-- Outputs
	-- connect data obtained from register file to execute component
       	O_datas => RF_O_datas,
       	O_datat => RF_O_datat
);

fwd: forwarding_unit
port map(
	-- INPUTS
	I_clk => I_clk,
	I_reset => I_reset,
	I_en => I_fwd_en,

	I_id_rd => ID_O_rd,
	I_ex_rd => EX_O_rd, -- connect: plug mem component
	I_id_reg_write => ID_O_regDwe,
	I_ex_reg_write => EX_O_reg_write, -- connect plug mem component
	I_id_mem_read => ID_O_mem_read,
	I_f_rs => RF_I_rs,
	I_f_rt => RF_I_rt,

	-- OUTPUTS

	-- FORWARDING_NONE -> read from ID inputs
	-- FORWARDING_EX -> read from EX stage output
	-- FORWARDING_MEM -> read from MEM stage output

	O_forward_rs => FWD_O_forward_rs,
	O_forward_rt => FWD_O_forward_rt
);

				
clk_process : process
begin
  I_clk <= '0';
  wait for CLK_PERIOD/2;
  I_clk <= '1';
  wait for CLK_PERIOD/2;
end process;

test_process : process
begin

--------------------------------------------------------------------
-------------------------- VI. TESTS -------------------------------
--------------------------------------------------------------------


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
  -- TEST 0: Store data in register file
  ----------------------------------------------------------------------------------
  	report "----- Test 0: Store data in register file -----";

	-- store 4 in R1
	RF_I_we <= '1';
	RF_I_datad <= DATA_4; --4
	RF_I_rs <= (others=>'0');
	RF_I_rt <= (others=>'0');
	RF_I_rd <= R1;
	wait for CLK_PERIOD;

	-- store 8 in R2
	RF_I_we <= '1';
	RF_I_datad <= DATA_8; --4
	RF_I_rs <= (others=>'0');
	RF_I_rt <= (others=>'0');
	RF_I_rd <= R2;
	wait for CLK_PERIOD;
	
	-- store -4 in R4
	I_en <= '1';
	RF_I_we <= '1';
	RF_I_datad <= DATA_MINUS_4; --4
	RF_I_rs <= (others=>'0');
	RF_I_rt <= (others=>'0');
	RF_I_rd <= R4;
	wait for CLK_PERIOD;

	-- read value in R1 and R2
	RF_I_we <= '0';
	I_en<= '1';
	RF_I_rs <= R1;
	RF_I_rt <= R2;
	wait for CLK_PERIOD;

	assert RF_O_datas = DATA_4 report "Test 0.a: Unsuccessful" severity error;
	assert RF_O_datat = DATA_8 report "Test 0.b: Unsuccessful" severity error;


  ----------------------------------------------------------------------------------
  -- TEST 1: ADD
  ----------------------------------------------------------------------------------
	report "----- Test 1: ADD Instruction -----";

	I_fwd_en <= '0';
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R1 & R2 & R3 & SHAMT & ADD_FUNCT; -- add r1 and r2, store in r3
	
	wait for CLK_PERIOD;
	wait for CLK_PERIOD;
  	assert EX_O_alu_result = ADD_RESULT report "Test 1: Unsuccessful" severity error;


  ----------------------------------------------------------------------------------
  -- TEST 2: SUB
  ----------------------------------------------------------------------------------
  	report "----- Test 2: SUB Instruction -----";

	I_fwd_en <= '0';
	RF_I_rs <= R2;
	RF_I_rt <= R1;

	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R2 & R1 & R3 & SHAMT & SUB_FUNCT; -- sub r2 and r1, store in r3
	
  	wait for CLK_PERIOD;
	wait for CLK_PERIOD;
  	assert EX_O_alu_result =  SUB_RESULT report "Test 2: Unsuccessful" severity error;
  

  ----------------------------------------------------------------------------------
  -- TEST 3: MUL, MFHI, MFLO
  ----------------------------------------------------------------------------------
  	report "----- Test 3: MULT Instruction -----";

	------------ MULT ------------ 
	wait for CLK_PERIOD;

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= R2;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R1 & R2 & R3 & SHAMT & MULT_FUNCT; -- MFHI r2 and r1, store in r3

 	wait for CLK_PERIOD;
	wait for CLK_PERIOD;
	
	
	------------ MFLO ------------ 
 

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= R2;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R1 & R2 & R3 & SHAMT & MFLO_FUNCT; -- MFHI r2 and r1, store in r3

  	wait for CLK_PERIOD;
	wait for CLK_PERIOD;
  	assert EX_O_alu_result = MULT_LOW_RESULT report "Test 3: Unsuccessful - Invalid Low Value" severity error;

	------------ MFHI ------------

  	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R1 & R2 & R3 & SHAMT & MFHI_FUNCT;
	wait for CLK_PERIOD;
	wait for CLK_PERIOD;
  	assert EX_O_alu_result = MULT_HIGH_RESULT report "Test 3: Unsuccessful - Invalid High Value" severity error;
  

  ----------------------------------------------------------------------------------
  -- TEST 4: DIV
  ----------------------------------------------------------------------------------
  	report "----- Test 4: DIV Instruction -----";
	------------ DIV ------------ 
 
	I_fwd_en <= '0';
	RF_I_rs <= R2;
	RF_I_rt <= R1;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R1 & R2 & R3 & SHAMT & DIV_FUNCT; -- MFHI r2 and r1, store in r3

  	wait for CLK_PERIOD;
	wait for CLK_PERIOD;

	------------ DIVLO ------------ 
  
	I_fwd_en <= '0';
	RF_I_rs <= R2;
	RF_I_rt <= R1;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R1 & R2 & R3 & SHAMT & MFLO_FUNCT; -- MFHI r2 and r1, store in r3

  	wait for CLK_PERIOD;
	wait for CLK_PERIOD;
  	assert EX_O_alu_result = DIV_LOW_RESULT report "Test 4: Unsuccessful - Invalid Low Value" severity error;

	------------ MFHI ------------
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R1 & R2 & R3 & SHAMT & MFHI_FUNCT;
	wait for CLK_PERIOD;
	wait for CLK_PERIOD;
  	assert EX_O_alu_result = DIV_HIGH_RESULT report "Test 4: Unsuccessful - Invalid High Value" severity error;
  
  ----------------------------------------------------------------------------------
  -- TEST 5: SLT
  ----------------------------------------------------------------------------------
  report "----- Test 5: SLT Instruction -----";
	
	I_fwd_en <= '0';
	RF_I_rs <= R2;
	RF_I_rt <= R1;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R2 & R1 & R3 & SHAMT & SLT_FUNCT; 
  	wait for CLK_PERIOD;
	wait for CLK_PERIOD;
	
	------------ SLT FALSE ------------ 
  	assert EX_O_alu_result = SLT_FALSE_RESULT report "Test 5: Unsuccessful" severity error;



	------------ SLT TRUE ------------ 

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= R2;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R2 & R1 & R3 & SHAMT & SLT_FUNCT; 
  	wait for CLK_PERIOD;
	wait for CLK_PERIOD;

  	assert EX_O_alu_result = SLT_TRUE_RESULT report "Test 5: Unsuccessful" severity error;
  

  ----------------------------------------------------------------------------------
  -- TEST 6: AND
  ----------------------------------------------------------------------------------
  	report "----- Test 6: AND Instruction -----";
	
	I_fwd_en <= '0';
	RF_I_rs <= R2;
	RF_I_rt <= R1;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R2 & R1 & R3 & SHAMT & AND_FUNCT; 
  	wait for CLK_PERIOD;
	wait for CLK_PERIOD;

  	assert EX_O_alu_result = AND_RESULT report "Test 6: Unsuccessful" severity error;
  

  ----------------------------------------------------------------------------------
  -- TEST 7: OR
  ----------------------------------------------------------------------------------
  	report "----- Test 7: OR Instruction -----";

	I_fwd_en <= '0';
	RF_I_rs <= R2;
	RF_I_rt <= R1;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R2 & R1 & R3 & SHAMT & OR_FUNCT; 
  	wait for CLK_PERIOD;
	wait for CLK_PERIOD;
  	assert EX_O_alu_result = OR_RESULT report "Test 7: Unsuccessful" severity error;
  

  ----------------------------------------------------------------------------------
  -- TEST 8: NOR
  ----------------------------------------------------------------------------------
  	report "----- Test 8: NOR Instruction -----";

	I_fwd_en <= '0';
	RF_I_rs <= R2;
	RF_I_rt <= R1;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R2 & R1 & R3 & SHAMT & NOR_FUNCT; 
  	wait for CLK_PERIOD;
	wait for CLK_PERIOD;
  	assert EX_O_alu_result = NOR_RESULT report "Test 8: Unsuccessful" severity error;
  

  ----------------------------------------------------------------------------------
  -- TEST 9: XOR
  ----------------------------------------------------------------------------------
  	report "----- Test 9: XOR Instruction -----";
	
	I_fwd_en <= '0';
	RF_I_rs <= R2;
	RF_I_rt <= R1;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R2 & R1 & R3 & SHAMT & XOR_FUNCT; 
  	wait for CLK_PERIOD;
	wait for CLK_PERIOD;
  	assert EX_O_alu_result = XOR_RESULT report "Test 9: Unsuccessful" severity error;
  

  ----------------------------------------------------------------------------------
  -- TEST 10: SLL
  ----------------------------------------------------------------------------------
  	report "----- Test 12: SLL Instruction -----";

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= R2;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R1 & R2 & R3 & SHAMT & SLL_FUNCT; 
  	wait for CLK_PERIOD;
	wait for CLK_PERIOD;
  	assert EX_O_alu_result = SLL_RESULT report "Test 12: Unsuccessful" severity error;
  

  ----------------------------------------------------------------------------------
  -- TEST 13: SRL
  ----------------------------------------------------------------------------------
  	report "----- Test 13: SRL Instruction -----";

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= R2;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R1 & R2 & R3 & SHAMT & SRL_FUNCT; 
  	wait for CLK_PERIOD;
	wait for CLK_PERIOD;
  	assert EX_O_alu_result = SRL_RESULT report "Test 13: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- TEST 14: SRA
  ----------------------------------------------------------------------------------
  	report "----- Test 14: SRA Instruction -----";
	
	--- POSITIVE NUMBER -----

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= R2;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R1 & R2 & R3 & SHAMT & SRA_FUNCT; 
  	wait for CLK_PERIOD;
  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = SRA_RESULT report "Test 14a: Unsuccessful" severity error;


	--- NEGATIVE NUMBER -----

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= R4;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R1 & R4 & R3 & SHAMT & SRA_FUNCT; 
  	wait for CLK_PERIOD;
	wait for CLK_PERIOD;
  	assert EX_O_alu_result = SRA_NEGATIVE_RESULT report "Test 14b: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- TEST 15: JR
  ----------------------------------------------------------------------------------
  	report "----- Test 15: JR Instruction -----";

	I_fwd_en <= '0';
	RF_I_rs <= R2;
	RF_I_rt <= R1;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R2 & R1 & R3 & SHAMT & JR_FUNCT; 
  	wait for CLK_PERIOD;
  	wait for CLK_PERIOD;
  	assert EX_O_updated_next_pc = JR_PC_RESULT report "Test 15: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- TEST 16: 
  ----------------------------------------------------------------------------------
  report "----- Test 16: ADDI Instruction -----";

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= (others=>'0');
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= ADDI_OPCODE & R1 & R3 & IMM_4; 
  	wait for CLK_PERIOD;	
  	wait for CLK_PERIOD;

  	assert EX_O_alu_result = ADDI_RESULT report "Test 16: Unsuccessful" severity error;
  

  ----------------------------------------------------------------------------------
  -- TEST 17: SLTI
  ----------------------------------------------------------------------------------
  	report "----- Test 17: SLTI Instruction -----";

	--- SLTI FALSE -----

	I_fwd_en <= '0';
	RF_I_rs <= R2;
	RF_I_rt <= (others=>'0');
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= SLTI_OPCODE & R2 & R3 & IMM_4; 
  	wait for CLK_PERIOD;
	wait for CLK_PERIOD;
  	assert EX_O_alu_result = SLTI_FALSE_RESULT report "Test 17a: Unsuccessful" severity error;


	--- SLTI TRUE -----

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= (others=>'0');
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= SLTI_OPCODE & R1 & R3 & IMM_8; 
  	wait for CLK_PERIOD;
  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = SLTI_TRUE_RESULT report "Test 17b: Unsuccessful" severity error;
  
  ----------------------------------------------------------------------------------
  -- TEST 18: ORI
  ----------------------------------------------------------------------------------
  	report "----- Test 18: ORI Instruction -----";

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= (others=>'0');
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= ORI_OPCODE & R1 & R3 & IMM_8; 
  	wait for CLK_PERIOD;
  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = ORI_RESULT report "Test 18: Unsuccessful" severity error;
  

  ----------------------------------------------------------------------------------
  -- TEST 19: XORI
  ----------------------------------------------------------------------------------
  	report "----- Test 19: XORI Instruction -----";

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= (others=>'0');
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= XORI_OPCODE & R1 & R3 & IMM_8; 
  	wait for CLK_PERIOD;
  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = XORI_RESULT report "Test 19: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- TEST 20: LUI
  ----------------------------------------------------------------------------------
  	report "----- Test 20: LUI Instruction -----";

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= (others=>'0');
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= LUI_OPCODE & R1 & R3 & IMM_4; 
  	wait for CLK_PERIOD;
  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = LUI_RESULT report "Test 20: Unsuccessful" severity error;
  

  ----------------------------------------------------------------------------------
  -- TEST 21: LW
  ----------------------------------------------------------------------------------
  report "----- Test 21: LW Instruction -----";

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= (others=>'0');
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= LW_OPCODE & R1 & R3 & IMM_8; 
  	wait for CLK_PERIOD;
  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = LW_RESULT report "Test 21: Unsuccessful" severity error;
  

  ----------------------------------------------------------------------------------
  -- TEST 22: SW
  ----------------------------------------------------------------------------------
  	report "----- Test 22: SW Instruction -----";

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= (others=>'0');
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= SW_OPCODE & R1 & R3 & IMM_8; 
  	wait for CLK_PERIOD;
  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = SW_RESULT report "Test 22: Unsuccessful" severity error;
 
  ----------------------------------------------------------------------------------
  -- TEST 23: BEQ
  ----------------------------------------------------------------------------------
  	report "----- Test 23: BEQ Instruction -----";

	--- BEQ TAKEN -----

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= R1;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= BEQ_OPCODE & R1 & R1 & IMM_4; 
  	wait for CLK_PERIOD;
  	wait for CLK_PERIOD;
  	assert EX_O_updated_next_pc = BEQ_TAKEN_PC_RESULT report "Test 23.a: Unsuccessful" severity error;

	--- BEQ NOT TAKEN -----

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= R2;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= BEQ_OPCODE & R1 & R2 & IMM_4; 
  	wait for CLK_PERIOD;
  	wait for CLK_PERIOD;
  	assert EX_O_updated_next_pc = BEQ_NOT_TAKEN_PC_RESULT report "Test 23.b: Unsuccessful" severity error;
	

  ----------------------------------------------------------------------------------
  -- TEST 24: BNE
  ----------------------------------------------------------------------------------

  	report "----- Test 24: BNE Instruction -----";

	--- BNE TAKEN -----

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= R2;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= BNE_OPCODE & R1 & R2 & IMM_4; 
  	wait for CLK_PERIOD;
  	wait for CLK_PERIOD;
  	assert EX_O_updated_next_pc = BNE_TAKEN_PC_RESULT report "Test 24.a: Unsuccessful" severity error;
	

	
	--- BNE NOT TAKEN -----

	I_fwd_en <= '0';
	RF_I_rs <= R1;
	RF_I_rt <= R1;
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= BNE_OPCODE & R1 & R1 & IMM_4; 
  	wait for CLK_PERIOD;
  	wait for CLK_PERIOD;
  	assert EX_O_updated_next_pc = BNE_NOT_TAKEN_PC_RESULT report "Test 24.b: Unsuccessful" severity error;
	

  ----------------------------------------------------------------------------------
  -- TEST 25: J
  ----------------------------------------------------------------------------------
  	report "----- Test 25: J Instruction -----";

	I_fwd_en <= '0';
	RF_I_rs <= (others=>'0');
	RF_I_rt <= (others=>'0');

	F_O_PC <= NEXT_PC;
	F_O_dataInst <= J_OPCODE & ADDRESS; 
  	wait for CLK_PERIOD;

  	wait for CLK_PERIOD;
  	assert EX_O_updated_next_pc = J_PC_RESULT report "Test 25: Unsuccessful" severity error;
	

  ----------------------------------------------------------------------------------
  -- TEST 26: JAL
  ----------------------------------------------------------------------------------
  	report "----- Test 26: JAL Instruction -----";

	I_fwd_en <= '0';
	RF_I_rs <= (others=>'0');
	RF_I_rt <= (others=>'0');
	
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= JAL_OPCODE & ADDRESS; 
  	wait for CLK_PERIOD;

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = JAL_RESULT report "Test 26.a: Unsuccessful" severity error;
	assert EX_O_updated_next_pc = JAL_PC_RESULT report "Test 26.b: Unsuccessful" severity error;


  ----------------------------------------------------------------------------------
  -- FORWARDING TESTS
  ----------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------
  -- TEST 27: Forwarding from EX of RS
  ----------------------------------------------------------------------------------
  	report "----- Test 27: Forwarding from EX -----";

	--- FWD RS -----

	I_fwd_en <= '1';
	RF_I_rs <= R1;
	RF_I_rt <= R2;

	-- r1 + r2 --> r3
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R1 & R2 & R3 & SHAMT & ADD_FUNCT; -- add r1 and r2, store in r3
  	wait for CLK_PERIOD;

	-- r3 + r1 --> r4
	-- should use the output of the execute stage as input data for rs
	RF_I_rs <= R3;
	RF_I_rt <= R1;
	F_O_dataInst <= R_OPCODE & R3 & R1 & R4 & SHAMT & ADD_FUNCT; -- add r1 and r2, store in r3
	wait for CLK_PERIOD;
	assert FWD_O_forward_rt = FORWARDING_NONE report "Test 27 fwd rt: Unsuccessful" severity error;
	assert FWD_O_forward_rs = FORWARDING_EX report "Test 27 fwd rs: Unsuccessful" severity error;
	
	wait for CLK_PERIOD;
	assert EX_O_stall = '0' report "Test 27 no stall: Unsuccessful" severity error;
  	assert EX_O_alu_result = ADD_RESULT_FWD report "Test 27 fwd result: Unsuccessful" severity error;
	

  ----------------------------------------------------------------------------------
  -- TEST 28: Forwarding from EX on RT
  ----------------------------------------------------------------------------------
  	report "----- Test 28: Forwarding from MEM -----";

	--- FWD RT -----
  	wait for CLK_PERIOD;

	I_fwd_en <= '1';
	RF_I_rs <= R1;
	RF_I_rt <= R2;

	-- r1 + r2 --> r3
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= R_OPCODE & R1 & R2 & R3 & SHAMT & ADD_FUNCT; -- add r1 and r2, store in r3
  	wait for CLK_PERIOD;

	-- r3 + r1 --> r4
	-- should use the output of the execute stage as input data for rs
	RF_I_rs <= R1;
	RF_I_rt <= R3;
	F_O_dataInst <= R_OPCODE & R1 & R3 & R4 & SHAMT & ADD_FUNCT; -- add r1 and r2, store in r3
	wait for CLK_PERIOD;
	assert FWD_O_forward_rs = FORWARDING_NONE report "Test 28 fwd rt: Unsuccessful" severity error;
	assert FWD_O_forward_rt = FORWARDING_EX report "Test 28 fwd rs: Unsuccessful" severity error;
	
	wait for CLK_PERIOD;
	assert EX_O_stall = '0' report "Test 28 no stall: Unsuccessful" severity error;
  	assert EX_O_alu_result = ADD_RESULT_FWD report "Test 28 fwd result: Unsuccessful" severity error;



  ----------------------------------------------------------------------------------
  -- TEST 29: Data Hazard on RS
  ----------------------------------------------------------------------------------
  	report "----- Test 29: Data Hazard -----";

	--- Hazard RS With Forwarding-----
  	wait for CLK_PERIOD;

	I_fwd_en <= '1';
	RF_I_rs <= R1;

	-- r1 + r2 --> r3
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= LW_OPCODE & R1 & R3 & IMM_0;  -- load r1 in r3
  	wait for CLK_PERIOD;

	-- r3 + r1 --> r4
	RF_I_rs <= R1;
	RF_I_rt <= R3;
	F_O_dataInst <= R_OPCODE & R1 & R3 & R4 & SHAMT & ADD_FUNCT; -- add r1 and r2, store in r3
	wait for CLK_PERIOD;
	
	-- should not be able to forward
	assert FWD_O_forward_rs = FORWARDING_NONE report "Test 29 fwd rt: Unsuccessful" severity error;
	assert FWD_O_forward_rt = FORWARDING_NONE report "Test 29 fwd rs: Unsuccessful" severity error;
	
	-- should stall since the previous instruction is a load instruction writing to r1
	wait for CLK_PERIOD;
	assert EX_O_stall = '1' report "Test 29 no stall: Unsuccessful" severity error;

	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 30: Data Hazard on RT
  ----------------------------------------------------------------------------------
  	report "----- Test 30: Data Hazard -----";

	--- Hazard RT With Forwarding-----
  	wait for CLK_PERIOD;

	I_fwd_en <= '1';
	RF_I_rs <= R1;

	-- r1 + r2 --> r3
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= LW_OPCODE & R1 & R3 & IMM_0;  -- load r1 in r3
  	wait for CLK_PERIOD;

	-- r1 + r3 --> r4
	RF_I_rs <= R3;
	RF_I_rt <= R1;
	F_O_dataInst <= R_OPCODE & R3 & R1 & R4 & SHAMT & ADD_FUNCT; -- add r1 and r2, store in r3
	wait for CLK_PERIOD;
	
	-- should not be able to forward
	assert FWD_O_forward_rs = FORWARDING_NONE report "Test 30 fwd rt: Unsuccessful" severity error;
	assert FWD_O_forward_rt = FORWARDING_NONE report "Test 30 fwd rs: Unsuccessful" severity error;
	
	-- should stall since the previous instruction is a load instruction writing to r1
	wait for CLK_PERIOD;
	assert EX_O_stall = '1' report "Test 30 no stall: Unsuccessful" severity error;

	wait for CLK_PERIOD;

  ----------------------------------------------------------------------------------
  -- TEST 31: Instruction Flush
  ----------------------------------------------------------------------------------
	report "----- Test 31: Instruction Flush -----";
	wait for CLK_PERIOD;

	I_fwd_en <= '0';
	RF_I_rs <= (others=>'0');
	RF_I_rt <= (others=>'0');

	F_O_PC <= NEXT_PC;
	-- jump instruction
	F_O_dataInst <= J_OPCODE & ADDRESS; 
  	wait for CLK_PERIOD;
	-- add instruction (expected to be flushed)
	RF_I_rs <= R3;
	RF_I_rt <= R1;
	F_O_dataInst <= R_OPCODE & R3 & R1 & R4 & SHAMT & ADD_FUNCT;
  	wait for CLK_PERIOD;
  	assert EX_O_updated_next_pc = J_PC_RESULT report "Test 31: Unsuccessful" severity error;
	
	-- next instruction flushed --> stall
  	wait for CLK_PERIOD;
	assert EX_O_stall = '1' report "Test 31 stall: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- TEST 32: Stall and Resume
  ----------------------------------------------------------------------------------
  	report "----- Test 32: Stall & Resume -----";

  	wait for CLK_PERIOD;
	I_fwd_en <= '1';

	-- Load R1 in R3
	RF_I_rs <= R1;
	F_O_PC <= NEXT_PC;
	F_O_dataInst <= LW_OPCODE & R1 & R3 & IMM_0;
  	wait for CLK_PERIOD;

	-- Add R1 + R3 in R4 --> Creates stall due to data hazard in R3
	RF_I_rs <= R1;
	RF_I_rt <= R3;
	F_O_dataInst <= R_OPCODE & R1 & R3 & R4 & SHAMT & ADD_FUNCT; -- add r1 and r3, store in r4
	wait for CLK_PERIOD;
	
	-- should not be able to forward at this point
	assert FWD_O_forward_rs = FORWARDING_NONE report "Test 32 fwd rs none: Unsuccessful" severity error;
	assert FWD_O_forward_rt = FORWARDING_NONE report "Test 32 fwd rt none: Unsuccessful" severity error;
	
	wait for CLK_PERIOD;

	-- mock memory outputs
	MEM_O_read_data <= DATA_8; 
	MEM_O_mem_read <= '1';
	MEM_O_rd <= R3;
	MEM_O_reg_write <= '1';
	
	-- should be able to forward rs from memory
	assert FWD_O_forward_rs = FORWARDING_NONE report "Test 32 fwd rs none: Unsuccessful" severity error;
	assert FWD_O_forward_rt = FORWARDING_MEM report "Test 32 fwd rt from mem: Unsuccessful" severity error; -- should be able to fwd from mem

	-- Ex should stall
	assert EX_O_stall = '1' report "Test 32 stall: Unsuccessful" severity error;
	wait for CLK_PERIOD;

	-- Ex should resume with addition since no more stall
	assert EX_O_stall = '0' report "Test 32 no stall: Unsuccessful" severity error;
	assert EX_O_alu_result = std_logic_vector(to_signed(12,32)) report "Test 32 no stall: Unsuccessful" severity error;

	wait for CLK_PERIOD;

  report "----- Confirming all tests have ran -----";
  wait;

end process;
end;
