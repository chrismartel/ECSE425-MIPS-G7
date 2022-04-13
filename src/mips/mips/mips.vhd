library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mips is 

port (

);
end mips

architecture behaviour of mips is

--------------------------------------------------------------------
-------------------------- COMPONENTS ------------------------------
--------------------------------------------------------------------

-- INSTRUCTION MEMORY COMPONENT
entity instruction_memory is
	port (
		I_clock: in std_logic;
		I_writedata: in std_logic_vector (31 downto 0);
		I_address: in integer range 0 to ram_size-1;
		I_memwrite: in std_logic;
		I_memread: in std_logic;
		O_readdata: out std_logic_vector (31 downto 0);
		O_waitrequest: out std_logic
	);
end instruction_memory;

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
	O_instruction_address: out INTEGER RANGE 0 TO 32768-1;
	O_memread: out std_logic;
	O_instruction : out std_logic_vector (31 downto 0)
);
end component

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
    	O_mem_to_reg: out STD_LOGIC;
    	O_addr: out std_logic_vector (25 downto 0)
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
	I_mem_to_reg: in std_logic; 

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

-- GLOBAL
signal I_reset : std_logic := '0'; -- asynchronous reset
signal I_clk : std_logic := '0'; -- synchronous clock

signal MIPS_I_en : std_logic := '0'; -- use this signal to enable the MIPS processor

-- FETCH
-- from fetch to instruction memory
signal F_O_instruction_address : INTEGER RANGE 0 TO 32768-1; 
signal F_O_memread : std_logic;
-- from fetch to decode/register file
signal F_O_instruction : std_logic_vector (31 downto 0);
signal F_O_updated_pc : std_logic_vector (31 downto 0);

-- REGISTER FILE 
signal RF_O_datas :  std_logic_vector (31 downto 0); -- rf to ex
signal RF_O_datat :  std_logic_vector (31 downto 0); -- rf to ex

-- DECODE SIGNALS
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
signal ID_O_mem_to_reg: std_logic;
signal ID_O_addr: std_logic_vector (25 downto 0);


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
signal EX_O_mem_to_reg: std_logic;

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

ex: execute 
port map(
	-- INPUTS
	I_clk => I_clk,
	I_reset => I_reset,
	I_en => EX_I_en,

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
	I_mem_to_reg => ID_O_mem_to_reg,	

	-- forwarding
	I_ex_data => EX_O_alu_result,
	I_mem_data => MEM_O_result, 
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
    	I_dataInst => F_O_dataInst,
       	I_en => ID_I_en,
	I_pc => F_O_PC,

	-- forwarding
	I_fwd_en => FWD_I_en,
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
	O_mem_to_reg => ID_O_mem_to_reg,
	O_regdWe => ID_O_regDwe,
	O_addr => ID_O_addr
);

rf: regs 
port map(
	-- Inputs
	-- requested registers come from decode output
	I_clk => I_clk,
	I_reset => I_reset,
	I_dataD => RF_I_datad,
       	I_en => RF_I_en,
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
	I_en => FWD_I_en,

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
end arch;
