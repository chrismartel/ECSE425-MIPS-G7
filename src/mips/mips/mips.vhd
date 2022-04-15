library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mips is 
generic(
	RAM_SIZE : INTEGER := 32768;
	CLK_PERIOD : time := 10 ns
);
port (
	I_clk: in std_logic;		-- synchronous active-high clock
	I_reset: in std_logic;		-- asynchronous active-high reset
	I_en: in std_logic;		-- enabled mips processor
	I_fwd_en: in std_logic		-- enables forwarding
);
end mips;

architecture behaviour of mips is

--------------------------------------------------------------------
-------------------------- COMPONENTS ------------------------------
--------------------------------------------------------------------

-- INSTRUCTION MEMORY COMPONENT
component instruction_memory is
port (
	I_clock: in std_logic;
	I_writedata: in std_logic_vector (31 downto 0);
	I_address: in integer range 0 to RAM_SIZE-1;
	I_memwrite: in std_logic;
	I_memread: in std_logic;
	O_readdata: out std_logic_vector (31 downto 0);
	O_waitrequest: out std_logic
);
end component;

-- FETCH STAGE COMPONENT
component fetch is
port(
	-- INPUTS

	-- Synchronoucity Inputs
	I_clk: in std_logic;
	I_reset: in std_logic;
	I_en: in std_logic;
	I_stall: in std_logic;

	-- I_jump flag
	I_jump: in std_logic;
	-- branch flag
	I_branch: in std_logic;
	-- incase of a branch or a jump use this
	I_pc_branch: in std_logic_vector (31 downto 0);

	-- Memory Inputs:
	I_mem_instruction : in std_logic_vector (31 downto 0);
	I_waitrequest : in std_logic;

	-- Outputs for fetch unit
	O_updated_pc: out std_logic_vector (31 downto 0);
	O_instruction_address: out INTEGER range 0 to RAM_SIZE-1;
	O_memread: out std_logic;
	O_instruction : out std_logic_vector (31 downto 0)
);
end component;

-- REGISTER FILE COMPONENT 
component regs is
port ( 
	-- Inputs
	I_clk : in  STD_LOGIC;
       	I_reset : in STD_LOGIC;
       	I_en : in  STD_LOGIC;
       	I_datad : in  std_logic_vector (31 downto 0);
       	I_rt : in  std_logic_vector (4 downto 0);
       	I_rs : in  std_logic_vector (4 downto 0);
       	I_rd : in  std_logic_vector (4 downto 0);
       	I_we : in  STD_LOGIC;
	
	-- Outputs
       	O_datas : out  std_logic_vector (31 downto 0);
       	O_datat : out  std_logic_vector (31 downto 0)
);	 
end component;

-- DECODE STAGE COMPONENT 
component decode is
port ( 
    	-- Inputs
	I_clk : in  STD_LOGIC;
    	I_reset: in STD_LOGIC;
        I_dataInst : in  std_logic_vector (31 downto 0);
        I_en : in  STD_LOGIC;
    	I_pc: in std_logic_vector (31 downto 0);
	I_fwd_en: in std_logic;
    	-- hazard detection
    	I_id_rd: in std_logic_vector (4 downto 0);
    	I_id_reg_write: in std_logic;
	I_id_mem_read: in std_logic;
    	I_ex_rd: in std_logic_vector (4 downto 0);
    	I_ex_reg_write: in std_logic;
            
   	-- Outputs
    	O_next_pc: out std_logic_vector (31 downto 0);
        O_rs : out  std_logic_vector (4 downto 0);
        O_rt : out  std_logic_vector (4 downto 0);
        O_rd : out  std_logic_vector (4 downto 0);
        O_dataIMM_SE : out  std_logic_vector (31 downto 0);
    	O_dataIMM_ZE : out std_logic_vector (31 downto 0);
        O_regDwe : out  STD_LOGIC;
        O_aluop : out  std_logic_vector (5 downto 0);
    	O_shamt: out std_logic_vector (4 downto 0);
    	O_funct: out std_logic_vector (5 downto 0);
    	O_branch: out STD_LOGIC;
    	O_jump: out STD_LOGIC;
    	O_mem_read: out STD_LOGIC;
    	O_mem_write: out STD_LOGIC;
    	O_addr: out std_logic_vector (25 downto 0);
	O_stall: out std_logic;
	O_stalled_instruction: out std_logic_vector (31 downto 0);
	O_stalled_pc: out std_logic_vector (31 downto 0)
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
	I_ex_data: in std_logic_vector (31 downto 0);
	I_mem_data: in std_logic_vector (31 downto 0);
	
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
	O_reg_write: out std_logic
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
	O_forward_rs: out std_logic_vector (1 downto 0); -- selection of left operand for ALU
	O_forward_rt: out std_logic_vector (1 downto 0) -- selection of right operand for ALU
);
end component;


--------------------------------------------------------------------
-------------------------- SIGNALS ---------------------------------
--------------------------------------------------------------------

-- NOTE: only list the outputs of each component as intermediate signals to avoid duplicates

-- GLOBAL
--signal GLOBAL_I_reset : std_logic := '0'; -- asynchronous reset
--signal GLOBAL_I_clk : std_logic := '0'; -- synchronous clock
--signal MIPS_I_en : std_logic := '0'; -- use this signal to enable the MIPS processor

-- INSTRUCTION MEMORY
signal INSTR_MEM_O_readdata: std_logic_vector (31 downto 0);
signal INSTR_MEM_O_waitrequest: std_logic;

-- FETCH
signal F_O_instruction_address : integer range 0 to RAM_SIZE-1; 
signal F_O_memread : std_logic;
signal F_O_instruction : std_logic_vector (31 downto 0);
signal F_O_updated_pc : std_logic_vector (31 downto 0);

-- REGISTER FILE 
signal RF_O_datas :  std_logic_vector (31 downto 0); -- rf to ex
signal RF_O_datat :  std_logic_vector (31 downto 0); -- rf to ex

-- DECODE SIGNALS

-- Inputs
signal ID_I_dataInst: std_logic_vector (31 downto 0); 	-- the input instruction to the decode stage. 
							-- Can come either from fetch or from stalled instruction.

signal ID_I_pc: std_logic_vector (31 downto 0); 	-- the input pc to the decode stage. 
							-- Can come either from fetch or from stalled instruction.
-- Outputs
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
signal ID_O_stall: std_logic;
signal ID_O_stalled_instruction: std_logic_vector (31 downto 0);
signal ID_O_stalled_pc: std_logic_vector (31 downto 0);

-- EXECUTE SIGNALS		
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

-- MEMORY
signal MEM_O_rd: std_logic_vector (4 downto 0); -- TODO: replace when memory added
signal MEM_O_reg_write: std_logic; -- TODO: replace when memory added
signal MEM_O_result: std_logic_vector (31 downto 0); -- TODO: replace when memory added

-- WRITE BACK
signal WB_O_rd :  std_logic_vector (4 downto 0); -- from wb to rf
signal WB_O_datad: std_logic_vector (31 downto 0); -- from wb to rf
signal WB_O_we :  std_logic := '0'; -- from wb to rf

-- FORWARD UNIT SIGNALS
signal FWD_I_en :  std_logic := '1'; -- use this signal to activate or deactivate forwarding
signal FWD_O_forward_rs: std_logic_vector (1 downto 0);
signal FWD_O_forward_rt: std_logic_vector (1 downto 0);

--------------------------------------------------------------------
-------------------------- PORT MAPPING ----------------------------
--------------------------------------------------------------------
begin
instr_mem: instruction_memory
port map(
	-- Inputs
	I_clock => I_clk,

	-- from fetch component
	I_address => F_O_instruction_address,
	I_memread => F_O_memread,

	I_memwrite => '0', --TODO Bruno: what goes here?
	I_writedata => (others=>'0'), -- TODO Bruno: what goes here?
	
	-- Outputs
	-- to fetch component
	O_readdata => INSTR_MEM_O_readdata,
	O_waitrequest => INSTR_MEM_O_waitrequest
);

f: fetch
port map(
	-- Inputs
	I_clk => I_clk,
	I_reset => I_reset,
	I_en => I_en,
	
	-- from decode component
	I_stall => ID_O_stall,

	-- from execute component (where branch resolution occurs)
	I_jump => EX_O_jump,
	I_branch => EX_O_branch,
	I_pc_branch => EX_O_updated_next_pc,

	-- from intrusction memory
	I_mem_instruction => INSTR_MEM_O_readdata,
	I_waitrequest => INSTR_MEM_O_waitrequest,

	-- Outputs
	-- to decode component
	O_updated_pc => F_O_updated_pc,
	O_instruction_address => F_O_instruction_address,
	O_memread => F_O_memread,
	O_instruction => F_O_instruction
);

rf: regs 
port map(
	-- Inputs
	I_clk => I_clk,
	I_reset => I_reset,
       	I_en => I_en,

	-- from fetch component
       	I_rs => F_O_instruction(25 downto 21), -- extract rs operand from instruction
       	I_rt => F_O_instruction(20 downto 16), -- extract rt operand from instruction

	-- from write-back component
	I_dataD => (others=>'0'), -- TODO Luke connect WB_O_datad signal here
       	I_rd => (others=>'0'), -- TODO Luke connect WB_O_rd signal here
       	I_we => '0', -- TODO Luke connect WB_O_we signal here

	-- Outputs
	-- to execute component
       	O_datas => RF_O_datas,
       	O_datat => RF_O_datat
);

id: decode 
port map(
	-- Inputs
	I_clk => I_clk,
	I_reset => I_reset,
       	I_en => I_en,

	-- from fetch component
    	I_dataInst => ID_I_dataInst,
	I_pc => ID_I_pc,

	-- forwarding
	I_fwd_en => FWD_I_en,
	I_id_rd => ID_O_rd,
	I_id_reg_write => ID_O_regDwe,
	I_id_mem_read => ID_O_mem_read,
	I_ex_rd => EX_O_rd,
	I_ex_reg_write => EX_O_reg_write,

	-- Outputs
	-- to execute component
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
	O_stall => ID_O_stall,
	O_stalled_instruction => ID_O_stalled_instruction,
	O_stalled_pc => ID_O_stalled_pc
);

ex: execute 
port map(
	-- INPUTS
	I_clk => I_clk,
	I_reset => I_reset,
	I_en => I_en,
	
	-- instruction
	I_rs => ID_O_rs,
	I_rt => ID_O_rt,
	I_rd => ID_O_rd,
	I_imm_SE => ID_O_dataIMM_SE,
	I_imm_ZE => ID_O_dataIMM_ZE,
	I_opcode => ID_O_aluop,
	I_shamt => ID_O_shamt,
	I_funct => ID_O_funct,
	I_addr => ID_O_addr,
	
	-- operands
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
	-- from execution stage
	I_ex_data => EX_O_alu_result,
	-- from memory stage
	I_mem_data => MEM_O_result, 
	-- from forwarding unit
	I_forward_rs => FWD_O_forward_rs,
	I_forward_rt => FWD_O_forward_rt,	

	-- OUTPUTS 
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
	O_reg_write => EX_O_reg_write
);

fwd: forwarding_unit
port map(
	-- INPUTS
	I_clk => I_clk,
	I_reset => I_reset,
	I_en => I_fwd_en,

	I_id_rd => ID_O_rd,
	I_ex_rd => EX_O_rd, 
	I_id_reg_write => ID_O_regDwe,
	I_ex_reg_write => EX_O_reg_write, 
	I_id_mem_read => ID_O_mem_read,
	I_f_rs => F_O_instruction(25 downto 21),
	I_f_rt => F_O_instruction(20 downto 16),

	-- OUTPUTS
	O_forward_rs => FWD_O_forward_rs,
	O_forward_rt => FWD_O_forward_rt
);

-- Process indicating to decode which instruction to take.
-- When a stall occurs, the decode stage takes the stalled instruction
-- and stalled pc  as input. 
-- Otherwise, the decode stage takes the instruction and pc from the fetch stage.
decode_instruction_choice: process(I_clk, I_reset)
begin
	if I_reset'event and I_reset = '1' then
	elsif I_clk'event and I_clk = '1' then
		if I_en = '1' then
			if ID_O_stall = '1' then
				ID_I_dataInst <= ID_O_stalled_instruction;
				ID_I_pc <= ID_O_stalled_pc;
			else
				ID_I_dataInst <= F_O_instruction;
				ID_I_pc <= F_O_updated_pc;
			end if;
		end if;
	end if;
end process;
end behaviour;
