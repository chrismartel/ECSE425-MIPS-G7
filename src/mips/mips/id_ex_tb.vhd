
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity id_ex_tb is
generic(
	number_of_registers : INTEGER := 32 -- number of blocks in cache
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
	constant CLK_PERIOD : time := 10 ns;


--------------------------------------------------------------------
-------------------------- II. COMPONENTS --------------------------
--------------------------------------------------------------------

-- REGISTER FILE COMPONENT 
component register_file is
port ( 
	I_clk: in std_logic;
	I_reset : in std_logic;
       	I_en : in  std_logic;
       	I_rs : in  std_logic_vector (4 downto 0);
       	I_rt : in  std_logic_vector (4 downto 0);
       	I_rd : in  std_logic_vector (4 downto 0);
       	I_we : in  std_logic;

	-- Outputs
       	O_rs_data : out  std_logic_vector (31 downto 0);
       	O_rt_data : out  std_logic_vector (31 downto 0)
);	 
end component;

-- DECODE COMPONENT 
component decode is
port ( 
	-- Inputs
	I_clk : in  std_logic;
	I_reset : in std_logic;
    	I_dataInst : in  std_logic_vector (31 downto 0);
       	I_en : in  std_logic;
	I_pc: in std_logic_vector (31 downto 0);

	-- hazard detection
	I_hazards: in std_logic_vector (31 downto 0);
	
	-- Outputs
	O_next_pc: out std_logic_vector (31 downto 0);
	O_rs : out  std_logic_vector (4 downto 0);
        O_rt : out  std_logic_vector (4 downto 0);
        O_rd : out  std_logic_vector (4 downto 0);
        O_imm_SE : out  std_logic_vector (31 downto 0);
	O_imm_ZE : out std_logic_vector (31 downto 0);
        O_reg_write : out  std_logic;
        O_opcode : out  std_logic_vector (5 downto 0);
	O_shamt: out std_logic_vector (4 downto 0);
	O_funct: out std_logic_vector (5 downto 0);
	O_branch: out std_logic;
	O_jump: out std_logic;
	O_mem_read: out std_logic;
	O_mem_write: out std_logic;
	O_mem_to_reg: out std_logic;
	O_addr: out std_logic_vector (25 downto 0)
);
end component;


-- EXECUTE STAGE COMPONENT 
component execute is
port(
	-- INPUTS
	I_clk : in std_logic;
	I_reset : in std_logic;

	-- instruction signals
	I_rs: in std_logic_vector (4 downto 0);
	I_rt: in std_logic_vector (4 downto 0);
 	I_imm_SE : in  std_logic_vector (31 downto 0);
	I_imm_ZE : in std_logic_vector (31 downto 0);
        I_opcode : in  std_logic_vector (5 downto 0);
	I_shamt: in std_logic_vector (4 downto 0);
	I_funct: in std_logic_vector (5 downto 0);
	I_addr: in std_logic_vector (25 downto 0);
	
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
	I_mem_to_reg: in std_logic; 					-- indicates if value loaded from memory must be writte to destination register

	-- forwarding
	I_ex_data: in std_logic_vector (31 downto 0);
	I_mem_data: in std_logic_vector (31 downto 0);

	I_forward_rs: in std_logic_vector (1 downto 0);
	I_forward_rt: in std_logic_vector (1 downto 0);

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
	O_mem_to_reg: out std_logic
);
end component;

-- FORWARDING UNIT COMPONENT 
component forwarding_unit is
port(
	-- INPUTS
	I_clk : in std_logic;
	I_reset : in std_logic;

	I_ex_rd: in std_logic_vector (4 downto 0); 		-- destination register for instruction completed by the ex stage
	I_mem_rd: in std_logic_vector (4 downto 0); 	-- destination register for instruction completed by the mem stage
	I_ex_reg_write: in std_logic; 			-- reg_write setting for instruction completed by ex stage
	I_mem_reg_write: in std_logic; 			-- reg_write setting for instruction completed by mem stage
	I_id_rs: in std_logic_vector(4 downto 0); 		-- left operand for instruction completed by id stage
	I_id_rt: in std_logic_vector(4 downto 0); 		-- right operand for instruction completed by id stage

	-- OUTPUTS

	-- '00' -> read from ID inputs
	-- '01' -> read from EX stage output
	-- '10' -> read from MEM stage output

	O_forward_rs: out std_logic_vector (1 downto 0); -- selection of left operand for ALU
	O_forward_rt: out std_logic_vector (1 downto 0) -- selection of right operand for ALU
);
end component;


-- HAZARD DETECTION COMPONENT 
component hazard_detection_unit is
port(
	-- INPUTS
	I_clk : in std_logic;
	I_reset : in std_logic;

	I_id_rd: in std_logic_vector (4 downto 0); 		-- destination register for instruction completed by the id stage
	I_id_reg_write: in std_logic; 			-- reg_write setting for instruction completed by id stage
	
	I_ex_rd: in std_logic_vector (4 downto 0); 		-- destination register for instruction completed by the ex stage
	I_ex_reg_write: in std_logic; 			-- reg_write setting for instruction completed by ex stage

	I_mem_rd: in std_logic_vector (4 downto 0); 		-- destination register for instruction completed by the mem stage
	I_mem_reg_write: in std_logic; 			-- reg_write setting for instruction completed by mem stage

	-- OUTPUTS
	
	-- Indicate presence of hazard for each register in the RF.
	-- '1': hazard
	-- '0': no hazard
	O_hazards: out std_logic_vector(number_of_registers-1 downto 0)
);

end component;


--------------------------------------------------------------------
-------------------------- III. SIGNALS --------------------------
--------------------------------------------------------------------

-- Synchronoucity Inputs
signal I_reset : std_logic := '0';
signal I_clk : std_logic := '0';


-- REGISTER FILE SIGNALS
-- INPUTS
signal RF_I_en :  std_logic := '1';
signal RF_I_we :  std_logic := '1';
signal RF_I_rs :  std_logic_vector (4 downto 0);
signal RF_I_rt :  std_logic_vector (4 downto 0);
signal RF_I_rd :  std_logic_vector (4 downto 0);
-- OUTPUTS
signal RF_O_rs_data :  std_logic_vector (31 downto 0);
signal RF_O_rt_data :  std_logic_vector (31 downto 0);

-- DECODE SIGNALS
-- INPUTS
signal ID_I_dataInst : std_logic_vector (31 downto 0);
signal ID_I_en : std_logic := '1';
signal ID_I_pc: std_logic_vector (31 downto 0);
signal ID_I_hazards: std_logic_vector (31 downto 0);
-- OUTPUTS
signal ID_O_next_pc: std_logic_vector (31 downto 0);
signal ID_O_rs : std_logic_vector (4 downto 0);
signal ID_O_rt : std_logic_vector (4 downto 0);
signal ID_O_rd : std_logic_vector (4 downto 0);
signal ID_O_imm_SE : std_logic_vector (31 downto 0);
signal ID_O_imm_ZE : std_logic_vector (31 downto 0);
signal ID_O_reg_write : std_logic;
signal ID_O_opcode : std_logic_vector (5 downto 0);
signal ID_O_shamt: std_logic_vector (4 downto 0);
signal ID_O_funct: std_logic_vector (5 downto 0);
signal ID_O_branch: std_logic;
signal ID_O_jump: std_logic;
signal ID_O_mem_read: std_logic;
signal ID_O_mem_write: std_logic;
signal ID_O_mem_to_reg: std_logic;
signal ID_O_addr: std_logic_vector (25 downto 0);


-- EXECUTE SIGNALS
-- INPUTS
signal EX_I_rs: std_logic_vector (4 downto 0);
signal EX_I_rt: std_logic_vector (4 downto 0);
signal EX_I_imm_SE :  std_logic_vector (31 downto 0);
signal EX_I_imm_ZE : std_logic_vector (31 downto 0);
signal EX_I_opcode :  std_logic_vector (5 downto 0);
signal EX_I_shamt: std_logic_vector (4 downto 0);
signal EX_I_funct: std_logic_vector (5 downto 0);
signal EX_I_addr: std_logic_vector (25 downto 0);
signal EX_I_rs_data: std_logic_vector (31 downto 0);
signal EX_I_rt_data: std_logic_vector (31 downto 0);
signal EX_I_next_pc: std_logic_vector (31 downto 0);
signal EX_I_rd: std_logic_vector (4 downto 0); 	
signal EX_I_branch: std_logic; 					
signal EX_I_jump: std_logic; 						
signal EX_I_mem_read: std_logic; 					
signal EX_I_mem_write: std_logic; 					
signal EX_I_reg_write: std_logic; 					
signal EX_I_mem_to_reg: std_logic; 					
signal EX_I_ex_data: std_logic_vector (31 downto 0);
signal EX_I_mem_data: std_logic_vector (31 downto 0);
signal EX_I_forward_rs: std_logic_vector (1 downto 0);
signal EX_I_forward_rt: std_logic_vector (1 downto 0);
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
signal EX_O_mem_to_reg: std_logic;


-- FORWARD UNIT SIGNALS
-- INPUTS
signal FWD_I_ex_rd: std_logic_vector (4 downto 0); 		
signal FWD_I_mem_rd: std_logic_vector (4 downto 0); 	
signal FWD_I_ex_reg_write: std_logic; 			
signal FWD_I_mem_reg_write: std_logic; 			
signal FWD_I_id_rs: std_logic_vector(4 downto 0); 		
signal FWD_I_id_rt: std_logic_vector(4 downto 0); 		
-- OUTPUTS
signal FWD_O_forward_rs: std_logic_vector (1 downto 0);
signal FWD_O_forward_rt: std_logic_vector (1 downto 0);


-- HAZARD DETECTION UNIT SIGNALS
-- INPUTS
signal HD_I_id_rd: std_logic_vector (4 downto 0); 		
signal HD_I_id_reg_write: std_logic; 			
signal HD_I_ex_rd: std_logic_vector (4 downto 0); 		
signal HD_I_ex_reg_write: std_logic; 			
signal HD_I_mem_rd: std_logic_vector (4 downto 0); 		
signal HD_I_mem_reg_write: std_logic; 			
-- OUTPUTS
signal HD_O_hazards: std_logic_vector(number_of_registers-1 downto 0);


--------------------------------------------------------------------
-------------------------- IV. TEST DATA ---------------------------
--------------------------------------------------------------------

constant R3: std_logic_vector(4 downto 0) := "00011"; -- R3
constant R1: std_logic_vector(4 downto 0) := "00001"; -- R1
constant R2: std_logic_vector(4 downto 0) := "00010"; -- R2
constant LR: std_logic_vector(4 downto 0) := "11111"; -- R31
constant R0: std_logic_vector(4 downto 0) := "00000"; -- $R0
constant SHAMT_2: std_logic_vector(4 downto 0) := "00010";
constant IMM_8: std_logic_vector(31 downto 0) := x"00000008"; 
constant IMM_4: std_logic_vector(31 downto 0) := x"00000004"; 
constant ADDRESS: std_logic_vector(25 downto 0) := "00000000000000000000000100"; 

constant DATA_8: std_logic_vector(31 downto 0) := x"00000008";
constant DATA_4: std_logic_vector(31 downto 0) := x"00000004";
constant DATA_MINUS_4: std_logic_vector(31 downto 0) := x"FFFFFFFC"; 
constant NEXT_PC_VALUE: std_logic_vector(31 downto 0) := x"00000004";

-- Results Data

-- R
constant ADD_RESULT: std_logic_vector(31 downto 0) := x"0000000C"; -- 4 + 8
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
constant ADDI_RESULT: std_logic_vector(31 downto 0) := x"0000000C"; -- 4 + IMM_4
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

	I_rs => ID_O_rs,
	I_rt => ID_O_rt,
	I_rd => ID_O_rd,
	I_imm_SE => ID_O_imm_SE,
	I_imm_ZE => ID_O_imm_ZE,
	I_opcode => ID_O_opcode,
	I_shamt => ID_O_shamt,
	I_funct => ID_O_funct,
	I_addr => ID_O_addr,

	I_rs_data => RF_O_rs_data,
	I_rt_data => RF_O_rt_data,
	I_next_pc => ID_O_next_pc,

	-- control signals
	I_branch => ID_O_branch,
	I_jump => ID_O_jump,
	I_mem_read => ID_O_mem_read,		
	I_mem_write => ID_O_mem_write, 					
	I_reg_write => ID_O_reg_write,				
	I_mem_to_reg => ID_O_mem_to_reg,	

	-- forwarding
	I_ex_data => EX_O_alu_result,
	I_mem_data => (others=>'0'), -- TODO: connect mem component
	I_forward_rs => FWD_O_forward_rs,
	I_forward_rt => FWD_O_forward_rt,	

	-- OUTPUTS 
	-- TODO: connect to memory component
	O_alu_result => EX_O_alu_result,
	O_updated_next_pc => EX_O_updated_next_pc,
	O_rt_data => EX_O_rt_data,
	O_stall => EX_O_stall,

	-- control signals
	O_rd => EX_O_rd,
	O_branch => EX_O_branch,
	O_jump => EX_O_jump,
	O_mem_read => EX_O_mem_read,
	O_mem_write => EX_O_mem_write,
	O_reg_write => EX_O_reg_write,
	O_mem_to_reg => EX_O_mem_to_reg
);

id: decode 
port map(
	-- Inputs
	-- TODO: connect to fetch component
	I_clk => I_clk,
	I_reset => I_reset,
    	I_dataInst => ID_I_dataInst,
       	I_en => ID_I_en,
	I_pc => ID_I_pc,
	I_hazards => HD_O_hazards,

	-- Outputs
	O_next_pc => EX_I_next_pc,
        O_rs => EX_I_rs,
        O_rt => EX_I_rt,
        O_rd => EX_I_rd,
        O_imm_SE => EX_I_imm_SE,
	O_imm_ZE => EX_I_imm_ZE,
        O_reg_write => EX_I_reg_write,
        O_opcode => EX_I_opcode,
	O_shamt => EX_I_shamt,
	O_funct => EX_I_funct,
	O_branch => EX_I_branch,
	O_jump => EX_I_jump,
	O_mem_read => EX_I_mem_read,
	O_mem_write => EX_I_mem_write,
	O_mem_to_reg => EX_I_mem_to_reg,
	O_addr => EX_I_addr
);

rf: register_file 
port map(
	-- Inputs
	-- requested registers come from decode output
	I_clk => I_clk,
	I_reset => I_reset,
       	I_en => RF_I_en,
       	I_rs => ID_O_rs,
       	I_rt => ID_O_rt,
       	I_rd => ID_O_rd,
       	I_we => RF_I_we,

	-- Outputs
	-- connect data obtained from register file to execute component
       	O_rs_data => EX_I_rs_data,
       	O_rt_data => EX_I_rt_data
);

fwd: forwarding_unit
port map(
	-- INPUTS
	I_clk => I_clk,
	I_reset => I_reset,

	I_ex_rd => EX_O_rd,
	I_mem_rd => "00000", -- connect: plug mem component
	I_ex_reg_write => EX_O_reg_write,
	I_mem_reg_write => '0', -- connect plug mem component
	I_id_rs => ID_O_rs,
	I_id_rt => ID_O_rt,

	-- OUTPUTS

	-- '00' -> read from ID inputs
	-- '01' -> read from EX stage output
	-- '10' -> read from MEM stage output

	O_forward_rs => EX_I_forward_rs,
	O_forward_rt => EX_I_forward_rt
);

hd: hazard_detection_unit
port map(
	-- INPUTS
	I_clk => I_clk,
	I_reset => I_reset,

	I_id_rd => ID_O_rd,
	I_id_reg_write => ID_O_reg_write,
	
	I_ex_rd => EX_O_rd,
	I_ex_reg_write => EX_O_reg_write,

	I_mem_rd => "00000", -- TODO: connect mem component
	I_mem_reg_write => '0', -- TODO: connect mem component

	-- OUTPUTS
	
	-- Indicate presence of hazard for each register in the RF.
	-- '1': hazard
	-- '0': no hazard
	O_hazards => ID_I_hazards
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

  ----------------------------------------------------------------------------------
  -- TEST 1: ADD
  ----------------------------------------------------------------------------------
  	report "----- Test 1: ADD Instruction -----";
	
	
  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = ADD_RESULT report "Test 1: Unsuccessful" severity error;

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

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result =  SUB_RESULT report "Test 2: Unsuccessful" severity error;
  
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

	------------ MULT ------------ 

	------------ MFLO ------------ 
  	wait for CLK_PERIOD;


  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = MULT_LOW_RESULT report "Test 3: Unsuccessful - Invalid Low Value" severity error;

	------------ MFHI ------------

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = MULT_HIGH_RESULT report "Test 3: Unsuccessful - Invalid High Value" severity error;
  
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
	------------ DIV ------------ 
  	wait for CLK_PERIOD;

	------------ MFLO ------------ 
  	wait for CLK_PERIOD;



  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = DIV_LOW_RESULT report "Test 3: Unsuccessful - Invalid Low Value" severity error;

	------------ MFHI ------------

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = DIV_HIGH_RESULT report "Test 3: Unsuccessful - Invalid High Value" severity error;
  
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
	
	
	------------ SLT FALSE ------------ 
  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = SLT_FALSE_RESULT report "Test 5: Unsuccessful" severity error;

	------------ SLT TRUE ------------ 
  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = SLT_TRUE_RESULT report "Test 5: Unsuccessful" severity error;
  
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


  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = AND_RESULT report "Test 6: Unsuccessful" severity error;
  
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


  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = OR_RESULT report "Test 7: Unsuccessful" severity error;
  
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

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = NOR_RESULT report "Test 8: Unsuccessful" severity error;
  
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

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = XOR_RESULT report "Test 9: Unsuccessful" severity error;
  
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

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = SLL_RESULT report "Test 12: Unsuccessful" severity error;
  
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

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = SRL_RESULT report "Test 13: Unsuccessful" severity error;
  
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
	
	--- POSITIVE NUMBER -----

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = SRA_RESULT report "Test 14: Unsuccessful" severity error;


	--- NEGATIVE NUMBER -----

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = SRA_NEGATIVE_RESULT report "Test 14: Unsuccessful" severity error;
  
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

  	wait for CLK_PERIOD;
  	assert EX_O_updated_next_pc = JR_PC_RESULT report "Test 15: Unsuccessful" severity error;
  
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

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = ADDI_RESULT report "Test 16: Unsuccessful" severity error;
  
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

	--- SLTI FALSE -----

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = SLTI_FALSE_RESULT report "Test 17: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

	--- SLTI TRUE -----

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = SLTI_TRUE_RESULT report "Test 17: Unsuccessful" severity error;
  
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

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = ORI_RESULT report "Test 18: Unsuccessful" severity error;
  
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

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = XORI_RESULT report "Test 19: Unsuccessful" severity error;
   
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

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = LUI_RESULT report "Test 20: Unsuccessful" severity error;
  
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

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = LW_RESULT report "Test 21: Unsuccessful" severity error;
  
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

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = SW_RESULT report "Test 22: Unsuccessful" severity error;
  

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

	--- BEQ TAKEN -----

  	wait for CLK_PERIOD;
  	assert EX_O_updated_next_pc = BEQ_TAKEN_PC_RESULT report "Test 23.a: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

----------------------------------------------------------------------------------
	
	--- BEQ NOT TAKEN -----

  	wait for CLK_PERIOD;
  	assert EX_O_updated_next_pc = BEQ_NOT_TAKEN_PC_RESULT report "Test 23.b: Unsuccessful" severity error;
  
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

	--- BNE TAKEN -----

  	wait for CLK_PERIOD;
  	assert EX_O_updated_next_pc = BNE_TAKEN_PC_RESULT report "Test 24.a: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

----------------------------------------------------------------------------------
	
	--- BNE NOT TAKEN -----

  	wait for CLK_PERIOD;
  	assert EX_O_updated_next_pc = BNE_NOT_TAKEN_PC_RESULT report "Test 24.b: Unsuccessful" severity error;

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


  	wait for CLK_PERIOD;
  	assert EX_O_updated_next_pc = J_PC_RESULT report "Test 25: Unsuccessful" severity error;

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

  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = JAL_RESULT report "Test 26.a: Unsuccessful" severity error;
	assert EX_O_updated_next_pc = JAL_PC_RESULT report "Test 26.b: Unsuccessful" severity error;

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

	--- FWD RS -----
	
  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = ADD_RESULT report "Test 27: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

	--- FWD RT -----
	
  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = ADD_RESULT report "Test 27: Unsuccessful" severity error;

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

	--- FWD RS -----
	
  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = ADD_RESULT report "Test 28: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  	wait for CLK_PERIOD;
  	I_reset <= '1';
  	wait for CLK_PERIOD;
  	I_reset <= '0';
  	wait for CLK_PERIOD;

	--- FWD RT -----
	
  	wait for CLK_PERIOD;
  	assert EX_O_alu_result = ADD_RESULT report "Test 28: Unsuccessful" severity error;


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
	
	
  	wait for CLK_PERIOD;
  	assert EX_O_stall = '1' 
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