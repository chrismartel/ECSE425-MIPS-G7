library ieee; -- allows use of the std_logic_vector type
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- needed if you are using unsigned numbers
Entity decode is
    Port ( 
		-- Inputs
		I_clk : in  STD_LOGIC;
		I_reset: in STD_LOGIC;
           	I_dataInst : in  STD_LOGIC_VECTOR (31 downto 0);
           	I_en : in  STD_LOGIC;
		I_pc: in STD_LOGIC_VECTOR (31 downto 0);
		I_fwd_en: in std_logic;				

		-- hazard detection
		-- need an rd and a reg_write signal for id and ex 
		--to see if they're currently writing to a reg, and which reg is being written to)
		--also need a mem_read to know if id is reading memory
		I_id_rd: in std_logic_vector (4 downto 0);	
		I_id_reg_write: in std_logic;			
		I_id_mem_read: in std_logic;
		I_ex_rd: in std_logic_vector (4 downto 0);
		I_ex_reg_write: in std_logic;			
			  
		-- Outputs
		O_next_pc: out STD_LOGIC_VECTOR (31 downto 0);
			--reg selection bits parsed from instruction 
           	O_rs : out  STD_LOGIC_VECTOR (4 downto 0); 
           	O_rt : out  STD_LOGIC_VECTOR (4 downto 0);
           	O_rd : out  STD_LOGIC_VECTOR (4 downto 0);
           		-- immediates (ex needs a sign extension and a zero extension
		O_dataIMM_SE : out  STD_LOGIC_VECTOR (31 downto 0);
		O_dataIMM_ZE : out STD_LOGIC_VECTOR (31 downto 0);
           		--register d write enable (register D is the write register)
		O_regDwe : out  STD_LOGIC;
           		-- more instruction slices
		O_aluop : out  STD_LOGIC_VECTOR (5 downto 0);
		O_shamt: out STD_LOGIC_VECTOR (4 downto 0);
		O_funct: out STD_LOGIC_VECTOR (5 downto 0);
			-- control signals, indicates if branching, jumping, memory reads, memory writes, or stalls happen. 
		O_branch: out STD_LOGIC;
		O_jump: out STD_LOGIC;
		O_mem_read: out STD_LOGIC;
		O_mem_write: out STD_LOGIC;
		O_addr: out STD_LOGIC_VECTOR (25 downto 0); -- this isn't a control signal, its a slice of the instruction containing an address if appropriate
		O_stall: out STD_LOGIC
		);
end decode;

architecture Behavioral of decode is

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

	-- FORWARDING CODES

	constant FORWARDING_NONE : std_logic_vector (1 downto 0):= "00";
	constant FORWARDING_EX : std_logic_vector (1 downto 0):= "01";
	constant FORWARDING_MEM : std_logic_vector (1 downto 0):= "10";

	-- signals
	signal stall: STD_LOGIC := '0';
	signal stalled_instruction: STD_LOGIC_VECTOR (31 downto 0);
	signal stalled_pc: STD_LOGIC_VECTOR (31 downto 0);
begin
	
id_process: process (I_clk, I_reset)
	begin
  
  	if I_reset'event and I_reset='1' then
 		--reset
		O_next_pc <= (others => '0');
           	O_rs <= (others => '0');
          	O_rt <= (others => '0');
           	O_rd <= (others => '0');
           	O_dataIMM_SE <= (others => '0');
		O_dataIMM_ZE <= (others => '0');
           	O_regDwe <= '0';
           	O_aluop <= (others => '0');
		O_shamt<= (others => '0');
		O_funct <= (others => '0');
		O_branch <= '0';
		O_jump <= '0';
		O_mem_read <= '0';
		O_mem_write <= '0';
		O_addr <= (others => '0');
		O_stall <= '0';
		stall <= '0';
		stalled_instruction <= (others=>'0');
		stalled_pc <= (others=>'0');
	 elsif I_clk'event and I_clk = '1' then
		if I_en = '1' then
			if stall = '0' then -- if stall = 1 then we would not run normal operation (we'd stall)
		      		if I_dataInst(31 downto 26) = "000000" then -- R type operations (funct)
		                	case I_dataInst(5 downto 0) is -- check functional bits for R type instructions
		
		                  	-- arithmetic
		
		                    	when ADD_FUNCT =>
		                        	O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= I_dataInst(25 downto 21);
		  		        	O_rt <= I_dataInst(20 downto 16);
		  		        	O_rd <= I_dataInst(15 downto 11);	
		  		        	O_shamt <= I_dataInst(10 downto 6);
		  		        	O_funct <= I_dataInst(5 downto 0);
		                    	when SUB_FUNCT =>
		                        	O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= I_dataInst(25 downto 21);
		  		        	O_rt <= I_dataInst(20 downto 16);
		  		        	O_rd <= I_dataInst(15 downto 11);
		  		        	O_shamt <= I_dataInst(10 downto 6);
		  		        	O_funct <= I_dataInst(5 downto 0);			
		                    	when MULT_FUNCT =>
		                        	O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= I_dataInst(25 downto 21);
		  		        	O_rt <= I_dataInst(20 downto 16);
		  		        	O_rd <= I_dataInst(15 downto 11);
		  		        	O_shamt <= I_dataInst(10 downto 6);
		  		        	O_funct <= I_dataInst(5 downto 0);					
		                  	when DIV_FUNCT =>
		          		        O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= I_dataInst(25 downto 21);
		  		        	O_rt <= I_dataInst(20 downto 16);
		  		        	O_rd <= I_dataInst(15 downto 11);
		  		        	O_shamt <= I_dataInst(10 downto 6);
		  		        	O_funct <= I_dataInst(5 downto 0);					
					when SLT_FUNCT =>
		  		        	O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= I_dataInst(25 downto 21);
		  		        	O_rt <= I_dataInst(20 downto 16);
		  		        	O_rd <= I_dataInst(15 downto 11);
		  		        	O_shamt <= I_dataInst(10 downto 6);
		  		        	O_funct <= I_dataInst(5 downto 0);		
			
		  	                -- logical
		
		        	        when AND_FUNCT =>
		  		        	O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= I_dataInst(25 downto 21);
		  		        	O_rt <= I_dataInst(20 downto 16);
		  		        	O_rd <= I_dataInst(15 downto 11);
		  		        	O_shamt <= I_dataInst(10 downto 6);
		  		        	O_funct <= I_dataInst(5 downto 0);				
					when OR_FUNCT =>
		          		        O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= I_dataInst(25 downto 21);
		  		        	O_rt <= I_dataInst(20 downto 16);
		  		        	O_rd <= I_dataInst(15 downto 11);
		  		        	O_shamt <= I_dataInst(10 downto 6);
		  		        	O_funct <= I_dataInst(5 downto 0);
		          	        when NOR_FUNCT =>
		  		        	O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= I_dataInst(25 downto 21);
		  		        	O_rt <= I_dataInst(20 downto 16);
		  		        	O_rd <= I_dataInst(15 downto 11);
		  		        	O_shamt <= I_dataInst(10 downto 6);
		  		        	O_funct <= I_dataInst(5 downto 0);
		  	              	when XOR_FUNCT =>
		        	                O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= I_dataInst(25 downto 21);
		  		        	O_rt <= I_dataInst(20 downto 16);
		  		        	O_rd <= I_dataInst(15 downto 11);
		  		        	O_shamt <= I_dataInst(10 downto 6);
		  		        	O_funct <= I_dataInst(5 downto 0);	
					
		        	        -- transfer
		
		  	               	when MFHI_FUNCT =>
		        	                O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= I_dataInst(25 downto 21);
		  		        	O_rt <= I_dataInst(20 downto 16);
		  		        	O_rd <= I_dataInst(15 downto 11);
		  		        	O_shamt <= I_dataInst(10 downto 6);
		  		        	O_funct <= I_dataInst(5 downto 0);
													
					when MFLO_FUNCT =>
		        	                O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= I_dataInst(25 downto 21);
		  		        	O_rt <= I_dataInst(20 downto 16);
		  		        	O_rd <= I_dataInst(15 downto 11);
		  		        	O_shamt <= I_dataInst(10 downto 6);
		  		        	O_funct <= I_dataInst(5 downto 0);
													
					-- shift
		
		        	       	when SLL_FUNCT =>
		  		        	O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';  
		  		        	O_rs <= I_dataInst(25 downto 21);
		  		        	O_rt <= I_dataInst(20 downto 16);
		  		        	O_rd <= I_dataInst(15 downto 11);
		  		        	O_shamt <= I_dataInst(10 downto 6);
		  		        	O_funct <= I_dataInst(5 downto 0);
													
					when SRL_FUNCT =>
		        	                O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= I_dataInst(25 downto 21);
		  		        	O_rt <= I_dataInst(20 downto 16);
		  		        	O_rd <= I_dataInst(15 downto 11);
		  		        	O_shamt <= I_dataInst(10 downto 6);
		  		        	O_funct <= I_dataInst(5 downto 0);
		
		  	             	when SRA_FUNCT =>
		        	                O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= I_dataInst(25 downto 21);
		  		        	O_rt <= I_dataInst(20 downto 16);
		  		        	O_rd <= I_dataInst(15 downto 11);
		  		        	O_shamt <= I_dataInst(10 downto 6);
		  		        	O_funct <= I_dataInst(5 downto 0);
													
		  	                -- control-flow
		
		        	       	when JR_FUNCT=>
		  		        	O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= I_dataInst(25 downto 21);
		  		        	O_rt <= I_dataInst(20 downto 16);
		  		        	O_rd <= I_dataInst(15 downto 11);
		  		        	O_shamt <= I_dataInst(10 downto 6);
		  		        	O_funct <= I_dataInst(5 downto 0);
		  	              	when others =>
		        	       	end case;
					-- hazard detection
					
					-- required rs operand is result of previous instruction
					if I_dataInst(25 downto 21) = I_id_rd AND I_id_reg_write = '1' then
						-- if forwarding enabled, stall only if prev instr. was a load
						if I_fwd_en = '1' then
							if I_id_mem_read = '1' then -- stall if previous instruction was a load
								O_aluop <= "000000";
								O_rs <= "00000";
								O_rt <= "00000";
								O_rd <= "00000";
								O_shamt <= "00000";
								O_funct <= ADD_FUNCT;
								O_stall <= '1';
								stall <= '1';
								stalled_instruction <= I_dataInst;
								stalled_pc <= I_pc;
							else
								O_stall <= '0';
								stall <= '0';
								stalled_instruction <= (others=>'0');
								stalled_pc <= (others=>'0');
							end if;
		
						-- if forwarding disabled, stall
						else
							O_aluop <= "000000";
							O_rs <= "00000";
							O_rt <= "00000";
							O_rd <= "00000";
							O_shamt <= "00000";
							O_funct <= ADD_FUNCT;
							O_stall <= '1';
							stall <= '1';
							stalled_instruction <= I_dataInst;
							stalled_pc <= I_pc;
						end if;
					
					-- required rt operand is result of previous instruction
					elsif I_dataInst(20 downto 16) = I_id_rd AND I_id_reg_write = '1' then
						if I_fwd_en = '1' then
							if I_id_mem_read = '1' then -- stall if previous instruction was a load
								O_aluop <= "000000";
								O_rs <= "00000";
								O_rt <= "00000";
								O_rd <= "00000";
								O_shamt <= "00000";
								O_funct <= ADD_FUNCT;
								O_stall <= '1';
								stall <= '1';
								stalled_instruction <= I_dataInst;
								stalled_pc <= I_pc;
							else
								O_stall <= '0';
								stall <= '0';
								stalled_instruction <= (others=>'0');
								stalled_pc <= (others=>'0');
							end if;
		
						-- if forwarding disabled, stall
						else
							O_aluop <= "000000";
							O_rs <= "00000";
							O_rt <= "00000";
							O_rd <= "00000";
							O_shamt <= "00000";
							O_funct <= ADD_FUNCT;
							O_stall <= '1';
							stall <= '1';
							stalled_instruction <= I_dataInst;
							stalled_pc <= I_pc;
						end if;
		
					-- required rs operand is result of prev-prev instruction
					elsif I_dataInst(25 downto 21) = I_ex_rd AND I_ex_reg_write = '1' then
						-- check if forwarding enabled
						if I_fwd_en = '0' then
							O_aluop <= "000000";
							O_rs <= "00000";
							O_rt <= "00000";
							O_rd <= "00000";
							O_shamt <= "00000";
							O_funct <= ADD_FUNCT;
							O_stall <= '1';
							stall <= '1';
							stalled_instruction <= I_dataInst;
							stalled_pc <= I_pc;
						else
							O_stall <= '0';
							stall <= '0';
							stalled_instruction <= (others=>'0');
							stalled_pc <= (others=>'0');
						end if;
		
					-- required rt operand is result of prev-prev instruction
					elsif I_dataInst(20 downto 16) = I_ex_rd AND I_ex_reg_write = '1' then
						-- check if forwarding enabled
						if I_fwd_en = '0' then
							O_aluop <= "000000";
							O_rs <= "00000";
							O_rt <= "00000";
							O_rd <= "00000";
							O_shamt <= "00000";
							O_funct <= ADD_FUNCT;
							O_stall <= '1';
							stall <= '1';
							stalled_instruction <= I_dataInst;
							stalled_pc <= I_pc;
						else 
							O_stall <= '0';
							stall <= '0';
							stalled_instruction <= (others=>'0');
							stalled_pc <= (others=>'0');
						end if;
					end if;
		  	          else
		        	        case I_dataInst(31 downto 26) is
		  	                  		-- arithmetic
		        	       	when ADDI_OPCODE =>
		  		                -- SignExtImm
		  		        	O_regDwe <= '1';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '0';
						O_mem_write <= '0';				
						O_rs <= I_dataInst(25 downto 21);
						O_rd <= I_dataInst(20 downto 16);
						if I_dataInst(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
						O_dataIMM_SE(15 downto 0) <= I_dataInst(15 downto 0);
						O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
						O_dataIMM_ZE(15 downto 0) <= I_dataInst(15 downto 0);
												
		  	               	when SLTI_OPCODE =>
		        	                O_regDwe <= '1';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '0';
						O_mem_write <= '0';
						O_rs <= I_dataInst(25 downto 21);
						O_rd <= I_dataInst(20 downto 16);
		
						if I_dataInst(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
						O_dataIMM_SE(15 downto 0) <= I_dataInst(15 downto 0);
						O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
						O_dataIMM_ZE(15 downto 0) <= I_dataInst(15 downto 0);									
								
		  	                -- logical
		
		        	    	when ANDI_OPCODE =>
		  		        	-- ZeroExtImm
		  		              	O_regDwe <= '1';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '0';
						O_mem_write <= '0';
						O_rs <= I_dataInst(25 downto 21);
						O_rd <= I_dataInst(20 downto 16);
						if I_dataInst(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
						O_dataIMM_SE(15 downto 0) <= I_dataInst(15 downto 0);
						O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
						O_dataIMM_ZE(15 downto 0) <= I_dataInst(15 downto 0);									
								
		
		  	              	when ORI_OPCODE =>
						O_regDwe <= '1';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '0';
						O_mem_write <= '0';
						O_rs <= I_dataInst(25 downto 21);
						O_rd <= I_dataInst(20 downto 16);
						if I_dataInst(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
						O_dataIMM_SE(15 downto 0) <= I_dataInst(15 downto 0);
						O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
						O_dataIMM_ZE(15 downto 0) <= I_dataInst(15 downto 0);									
								
		  	              	when XORI_OPCODE =>
						O_regDwe <= '1';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '0';
						O_mem_write <= '0';
						O_rs <= I_dataInst(25 downto 21);
						O_rd <= I_dataInst(20 downto 16);
						if I_dataInst(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
						O_dataIMM_SE(15 downto 0) <= I_dataInst(15 downto 0);
						O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
						O_dataIMM_ZE(15 downto 0) <= I_dataInst(15 downto 0);									
								
		
		  	                 -- transfer
		
		        	       	when LUI_OPCODE =>
		  		                O_regDwe <= '1';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '0';
						O_mem_write <= '0';
						O_rs <= I_dataInst(25 downto 21);
						O_rd <= I_dataInst(20 downto 16);
						if I_dataInst(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
							O_dataIMM_SE(15 downto 0) <= I_dataInst(15 downto 0);
							O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
							O_dataIMM_ZE(15 downto 0) <= I_dataInst(15 downto 0);									
								
		  	                -- memory
		        	     	when LW_OPCODE | SW_OPCODE=>
		  		                O_regDwe <= '1';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '1';
						O_mem_write <= '0';
		 				O_rs <= I_dataInst(25 downto 21);
						O_rd <= I_dataInst(20 downto 16);
						if I_dataInst(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
						O_dataIMM_SE(15 downto 0) <= I_dataInst(15 downto 0);
						O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
						O_dataIMM_ZE(15 downto 0) <= I_dataInst(15 downto 0);									
								                   
		  	                -- control-flow
		
		        	       	when BEQ_OPCODE=>
						O_regDwe <= '0';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '0';
						O_mem_write <= '0';
										 
						O_rs <= I_dataInst(25 downto 21);
						O_rt <= I_dataInst(20 downto 16);
						if I_dataInst(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
						O_dataIMM_SE(15 downto 0) <= I_dataInst(15 downto 0);
						O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
						O_dataIMM_ZE(15 downto 0) <= I_dataInst(15 downto 0);									
		
		  	                when BNE_OPCODE=>
						O_regDwe <= '0';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '0';
						O_mem_write <= '0';
						
						O_rs <= I_dataInst(25 downto 21);
						O_rt <= I_dataInst(20 downto 16);
						if I_dataInst(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
						O_dataIMM_SE(15 downto 0) <= I_dataInst(15 downto 0);
						O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
						O_dataIMM_ZE(15 downto 0) <= I_dataInst(15 downto 0);									
					
		  	                when J_OPCODE=>
						O_regDwe <= '0';
						O_branch <= '0';
						O_jump <= '1';
						O_mem_read <= '0';
						O_mem_write <= '0';
						O_addr <= I_dataInst(25 downto 0);
			
		        	      	when JAL_OPCODE=>
						O_regDwe <= '0';
						O_branch <= '0';
						O_jump <= '1';
						O_mem_read <= '0';
						O_mem_write <= '0';
						O_addr <= I_dataInst(25 downto 0);
		  	               	when others =>
		        	        end case;
					if I_dataInst(31 downto 26) /= JAL_OPCODE OR I_dataInst(31 downto 26) /= J_OPCODE then
						
						-- required rs operand is result of prev instruction
						if I_dataInst(25 downto 21) = I_id_rd AND I_id_reg_write = '1' then
			
							if I_fwd_en = '1' then
								if I_id_mem_read = '1' then -- stall if previous instruction was a load
									O_aluop <= "000000";
									O_rs <= "00000";
									O_rt <= "00000";
									O_rd <= "00000";
									O_shamt <= "00000";
									O_funct <= ADD_FUNCT;
									O_stall <= '1';
									stalled_instruction <= I_dataInst;
									stalled_pc <= I_pc;
								else
									O_stall <= '0';
									stall <= '0';
									stalled_instruction <= (others=>'0');
									stalled_pc <= (others=>'0');
								end if;
							else
								O_aluop <= "000000";
								O_rs <= "00000";
								O_rt <= "00000";
								O_rd <= "00000";
								O_shamt <= "00000";
								O_funct <= ADD_FUNCT;	
								O_stall <= '1';
								stall <= '1';
								stalled_instruction <= I_dataInst;
								stalled_pc <= I_pc;
							end if;
						
						-- required rt operand is result of prev-prev instruction
						elsif I_dataInst(25 downto 21) = I_ex_rd AND I_ex_reg_write = '1' then
							-- stall if forwarding not enabled
							if I_fwd_en = '0' then
								O_aluop <= "000000";
								O_rs <= "00000";
								O_rt <= "00000";
								O_rd <= "00000";
								O_shamt <= "00000";
								O_funct <= ADD_FUNCT;
								O_stall <= '1';
								stall <= '1';
								stalled_instruction <= I_dataInst;
								stalled_pc <= I_pc;
							else
								O_stall <= '0';
								stall <= '0';
								stalled_instruction <= (others=>'0');
								stalled_pc <= (others=>'0');
							end if;
						end if;		
					end if;
				end if;
				O_next_pc <= I_pc;
				O_aluop <= I_dataInst(31 downto 26);

			-- STALLED INSTRUCTION
			else
		      		if stalled_instruction(31 downto 26) = "000000" then
		                	case stalled_instruction(5 downto 0) is -- check functional bits for R type instructions
		
		                  	-- arithmetic
		
		                    	when ADD_FUNCT =>
		                        	O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= stalled_instruction(25 downto 21);
		  		        	O_rt <= stalled_instruction(20 downto 16);
		  		        	O_rd <= stalled_instruction(15 downto 11);	
		  		        	O_shamt <= stalled_instruction(10 downto 6);
		  		        	O_funct <= stalled_instruction(5 downto 0);
		                    	when SUB_FUNCT =>
		                        	O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= stalled_instruction(25 downto 21);
		  		        	O_rt <= stalled_instruction(20 downto 16);
		  		        	O_rd <= stalled_instruction(15 downto 11);
		  		        	O_shamt <= stalled_instruction(10 downto 6);
		  		        	O_funct <= stalled_instruction(5 downto 0);			
		                    	when MULT_FUNCT =>
		                        	O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= stalled_instruction(25 downto 21);
		  		        	O_rt <= stalled_instruction(20 downto 16);
		  		        	O_rd <= stalled_instruction(15 downto 11);
		  		        	O_shamt <= stalled_instruction(10 downto 6);
		  		        	O_funct <= stalled_instruction(5 downto 0);					
		                  	when DIV_FUNCT =>
		          		        O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= stalled_instruction(25 downto 21);
		  		        	O_rt <= stalled_instruction(20 downto 16);
		  		        	O_rd <= stalled_instruction(15 downto 11);
		  		        	O_shamt <= stalled_instruction(10 downto 6);
		  		        	O_funct <= stalled_instruction(5 downto 0);					
					when SLT_FUNCT =>
		  		        	O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= stalled_instruction(25 downto 21);
		  		        	O_rt <= stalled_instruction(20 downto 16);
		  		        	O_rd <= stalled_instruction(15 downto 11);
		  		        	O_shamt <= stalled_instruction(10 downto 6);
		  		        	O_funct <= stalled_instruction(5 downto 0);		
			
		  	                -- logical
		
		        	        when AND_FUNCT =>
		  		        	O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= stalled_instruction(25 downto 21);
		  		        	O_rt <= stalled_instruction(20 downto 16);
		  		        	O_rd <= stalled_instruction(15 downto 11);
		  		        	O_shamt <= stalled_instruction(10 downto 6);
		  		        	O_funct <= stalled_instruction(5 downto 0);				
					when OR_FUNCT =>
		          		        O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= stalled_instruction(25 downto 21);
		  		        	O_rt <= stalled_instruction(20 downto 16);
		  		        	O_rd <= stalled_instruction(15 downto 11);
		  		        	O_shamt <= stalled_instruction(10 downto 6);
		  		        	O_funct <= stalled_instruction(5 downto 0);
		          	        when NOR_FUNCT =>
		  		        	O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= stalled_instruction(25 downto 21);
		  		        	O_rt <= stalled_instruction(20 downto 16);
		  		        	O_rd <= stalled_instruction(15 downto 11);
		  		        	O_shamt <= stalled_instruction(10 downto 6);
		  		        	O_funct <= stalled_instruction(5 downto 0);
		  	              	when XOR_FUNCT =>
		        	                O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= stalled_instruction(25 downto 21);
		  		        	O_rt <= stalled_instruction(20 downto 16);
		  		        	O_rd <= stalled_instruction(15 downto 11);
		  		        	O_shamt <= stalled_instruction(10 downto 6);
		  		        	O_funct <= stalled_instruction(5 downto 0);	
					
		        	        -- transfer
		
		  	               	when MFHI_FUNCT =>
		        	                O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= stalled_instruction(25 downto 21);
		  		        	O_rt <= stalled_instruction(20 downto 16);
		  		        	O_rd <= stalled_instruction(15 downto 11);
		  		        	O_shamt <= stalled_instruction(10 downto 6);
		  		        	O_funct <= stalled_instruction(5 downto 0);
													
					when MFLO_FUNCT =>
		        	                O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= stalled_instruction(25 downto 21);
		  		        	O_rt <= stalled_instruction(20 downto 16);
		  		        	O_rd <= stalled_instruction(15 downto 11);
		  		        	O_shamt <= stalled_instruction(10 downto 6);
		  		        	O_funct <= stalled_instruction(5 downto 0);
													
					-- shift
		
		        	       	when SLL_FUNCT =>
		  		        	O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';  
		  		        	O_rs <= stalled_instruction(25 downto 21);
		  		        	O_rt <= stalled_instruction(20 downto 16);
		  		        	O_rd <= stalled_instruction(15 downto 11);
		  		        	O_shamt <= stalled_instruction(10 downto 6);
		  		        	O_funct <= stalled_instruction(5 downto 0);
													
					when SRL_FUNCT =>
		        	                O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= stalled_instruction(25 downto 21);
		  		        	O_rt <= stalled_instruction(20 downto 16);
		  		        	O_rd <= stalled_instruction(15 downto 11);
		  		        	O_shamt <= stalled_instruction(10 downto 6);
		  		        	O_funct <= stalled_instruction(5 downto 0);
		
		  	             	when SRA_FUNCT =>
		        	                O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= stalled_instruction(25 downto 21);
		  		        	O_rt <= stalled_instruction(20 downto 16);
		  		        	O_rd <= stalled_instruction(15 downto 11);
		  		        	O_shamt <= stalled_instruction(10 downto 6);
		  		        	O_funct <= stalled_instruction(5 downto 0);
													
		  	                -- control-flow
		
		        	       	when JR_FUNCT=>
		  		        	O_regDwe <= '1';
		  		        	O_branch <= '0';
		  		        	O_jump <= '0';
		  		        	O_mem_read <= '0';
		  		        	O_mem_write <= '0';
		  		        	O_rs <= stalled_instruction(25 downto 21);
		  		        	O_rt <= stalled_instruction(20 downto 16);
		  		        	O_rd <= stalled_instruction(15 downto 11);
		  		        	O_shamt <= stalled_instruction(10 downto 6);
		  		        	O_funct <= stalled_instruction(5 downto 0);
		  	              	when others =>
		        	       	end case;
					-- hazard detection
					
					-- required rs operand is result of previous instruction
					if stalled_instruction(25 downto 21) = I_id_rd AND I_id_reg_write = '1' then
						-- if forwarding enabled, stall only if prev instr. was a load
						if I_fwd_en = '1' then
							if I_id_mem_read = '1' then -- stall if previous instruction was a load
								O_aluop <= "000000";
								O_rs <= "00000";
								O_rt <= "00000";
								O_rd <= "00000";
								O_shamt <= "00000";
								O_funct <= ADD_FUNCT;
								O_stall <= '1';
								stall <= '1';
								stalled_instruction <= stalled_instruction;
								stalled_pc <= stalled_pc;
							else
								O_stall <= '0';
								stall <= '0';
								stalled_instruction <= (others=>'0');
								stalled_pc <= (others=>'0');
							end if;
		
						-- if forwarding disabled, stall
						else
							O_aluop <= "000000";
							O_rs <= "00000";
							O_rt <= "00000";
							O_rd <= "00000";
							O_shamt <= "00000";
							O_funct <= ADD_FUNCT;
							O_stall <= '1';
							stall <= '1';
							stalled_instruction <= stalled_instruction;
							stalled_pc <= stalled_pc;
						end if;
					
					-- required rt operand is result of previous instruction
					elsif stalled_instruction(20 downto 16) = I_id_rd AND I_id_reg_write = '1' then
						if I_fwd_en = '1' then
							if I_id_mem_read = '1' then -- stall if previous instruction was a load
								O_aluop <= "000000";
								O_rs <= "00000";
								O_rt <= "00000";
								O_rd <= "00000";
								O_shamt <= "00000";
								O_funct <= ADD_FUNCT;
								O_stall <= '1';
								stall <= '1';
								stalled_instruction <= stalled_instruction;
								stalled_pc <= stalled_pc;
							else
								O_stall <= '0';
								stall <= '0';
								stalled_instruction <= (others=>'0');
								stalled_pc <= (others=>'0');
							end if;
		
						-- if forwarding disabled, stall
						else
							O_aluop <= "000000";
							O_rs <= "00000";
							O_rt <= "00000";
							O_rd <= "00000";
							O_shamt <= "00000";
							O_funct <= ADD_FUNCT;
							O_stall <= '1';
							stall <= '1';
							stalled_instruction <= stalled_instruction;
							stalled_pc <= stalled_pc;
						end if;
		
					-- required rs operand is result of prev-prev instruction
					elsif stalled_instruction(25 downto 21) = I_ex_rd AND I_ex_reg_write = '1' then
						-- check if forwarding enabled
						if I_fwd_en = '0' then
							O_aluop <= "000000";
							O_rs <= "00000";
							O_rt <= "00000";
							O_rd <= "00000";
							O_shamt <= "00000";
							O_funct <= ADD_FUNCT;
							O_stall <= '1';
							stall <= '1';
							stalled_instruction <= stalled_instruction;
							stalled_pc <= stalled_pc;
						else
							O_stall <= '0';
							stall <= '0';
							stalled_instruction <= (others=>'0');
							stalled_pc <= (others=>'0');
						end if;
		
					-- required rt operand is result of prev-prev instruction
					elsif stalled_instruction(20 downto 16) = I_ex_rd AND I_ex_reg_write = '1' then
						-- check if forwarding enabled
						if I_fwd_en = '0' then
							O_aluop <= "000000";
							O_rs <= "00000";
							O_rt <= "00000";
							O_rd <= "00000";
							O_shamt <= "00000";
							O_funct <= ADD_FUNCT;
							O_stall <= '1';
							stall <= '1';
							stalled_instruction <= stalled_instruction;
							stalled_pc <= stalled_pc;
						else 
							O_stall <= '0';
							stall <= '0';
							stalled_instruction <= (others=>'0');
							stalled_pc <= (others=>'0');
						end if;
					end if;
		  	          else
		        	        case stalled_instruction(31 downto 26) is
		  	                  		-- arithmetic
		        	       	when ADDI_OPCODE =>
		  		                -- SignExtImm
		  		        	O_regDwe <= '1';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '0';
						O_mem_write <= '0';				
						O_rs <= stalled_instruction(25 downto 21);
						O_rd <= stalled_instruction(20 downto 16);
						if stalled_instruction(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
						O_dataIMM_SE(15 downto 0) <= stalled_instruction(15 downto 0);
						O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
						O_dataIMM_ZE(15 downto 0) <= stalled_instruction(15 downto 0);
												
		  	               	when SLTI_OPCODE =>
		        	                O_regDwe <= '1';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '0';
						O_mem_write <= '0';
						O_rs <= stalled_instruction(25 downto 21);
						O_rd <= stalled_instruction(20 downto 16);
		
						if stalled_instruction(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
						O_dataIMM_SE(15 downto 0) <= stalled_instruction(15 downto 0);
						O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
						O_dataIMM_ZE(15 downto 0) <= stalled_instruction(15 downto 0);									
								
		  	                -- logical
		
		        	    	when ANDI_OPCODE =>
		  		        	-- ZeroExtImm
		  		              	O_regDwe <= '1';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '0';
						O_mem_write <= '0';
						O_rs <= stalled_instruction(25 downto 21);
						O_rd <= stalled_instruction(20 downto 16);
						if stalled_instruction(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
						O_dataIMM_SE(15 downto 0) <= stalled_instruction(15 downto 0);
						O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
						O_dataIMM_ZE(15 downto 0) <= stalled_instruction(15 downto 0);									
								
		
		  	              	when ORI_OPCODE =>
						O_regDwe <= '1';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '0';
						O_mem_write <= '0';
						O_rs <= stalled_instruction(25 downto 21);
						O_rd <= stalled_instruction(20 downto 16);
						if stalled_instruction(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
						O_dataIMM_SE(15 downto 0) <= stalled_instruction(15 downto 0);
						O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
						O_dataIMM_ZE(15 downto 0) <= stalled_instruction(15 downto 0);									
								
		  	              	when XORI_OPCODE =>
						O_regDwe <= '1';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '0';
						O_mem_write <= '0';
						O_rs <= stalled_instruction(25 downto 21);
						O_rd <= stalled_instruction(20 downto 16);
						if stalled_instruction(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
						O_dataIMM_SE(15 downto 0) <= stalled_instruction(15 downto 0);
						O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
						O_dataIMM_ZE(15 downto 0) <= stalled_instruction(15 downto 0);									
								
		
		  	                 -- transfer
		
		        	       	when LUI_OPCODE =>
		  		                O_regDwe <= '1';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '0';
						O_mem_write <= '0';
						O_rs <= stalled_instruction(25 downto 21);
						O_rd <= stalled_instruction(20 downto 16);
						if stalled_instruction(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
							O_dataIMM_SE(15 downto 0) <= stalled_instruction(15 downto 0);
							O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
							O_dataIMM_ZE(15 downto 0) <= stalled_instruction(15 downto 0);									
								
		  	                -- memory
		        	     	when LW_OPCODE | SW_OPCODE=>
		  		                O_regDwe <= '1';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '1';
						O_mem_write <= '0';
		 				O_rs <= stalled_instruction(25 downto 21);
						O_rd <= stalled_instruction(20 downto 16);
						if stalled_instruction(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
						O_dataIMM_SE(15 downto 0) <= stalled_instruction(15 downto 0);
						O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
						O_dataIMM_ZE(15 downto 0) <= stalled_instruction(15 downto 0);									
								                   
		  	                -- control-flow
		
		        	       	when BEQ_OPCODE=>
						O_regDwe <= '0';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '0';
						O_mem_write <= '0';
										 
						O_rs <= stalled_instruction(25 downto 21);
						O_rt <= stalled_instruction(20 downto 16);
						if stalled_instruction(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
						O_dataIMM_SE(15 downto 0) <= stalled_instruction(15 downto 0);
						O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
						O_dataIMM_ZE(15 downto 0) <= stalled_instruction(15 downto 0);									
		
		  	                when BNE_OPCODE=>
						O_regDwe <= '0';
						O_branch <= '0';
						O_jump <= '0';
						O_mem_read <= '0';
						O_mem_write <= '0';
						
						O_rs <= stalled_instruction(25 downto 21);
						O_rt <= stalled_instruction(20 downto 16);
						if stalled_instruction(15) = '1' then
							O_dataIMM_SE(31 downto 16) <= "1111111111111111";
						else
							O_dataIMM_SE(31 downto 16) <= "0000000000000000";
						end if;
						O_dataIMM_SE(15 downto 0) <= stalled_instruction(15 downto 0);
						O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
						O_dataIMM_ZE(15 downto 0) <= stalled_instruction(15 downto 0);									
					
		  	                when J_OPCODE=>
						O_regDwe <= '0';
						O_branch <= '0';
						O_jump <= '1';
						O_mem_read <= '0';
						O_mem_write <= '0';
						O_addr <= stalled_instruction(25 downto 0);
			
		        	      	when JAL_OPCODE=>
						O_regDwe <= '0';
						O_branch <= '0';
						O_jump <= '1';
						O_mem_read <= '0';
						O_mem_write <= '0';
						O_addr <= stalled_instruction(25 downto 0);
		  	               	when others =>
		        	        end case;
					if stalled_instruction(31 downto 26) /= JAL_OPCODE OR stalled_instruction(31 downto 26) /= J_OPCODE then
						
						-- required rs operand is result of prev instruction
						if stalled_instruction(25 downto 21) = I_id_rd AND I_id_reg_write = '1' then
			
							if I_fwd_en = '1' then
								if I_id_mem_read = '1' then -- stall if previous instruction was a load
									O_aluop <= "000000";
									O_rs <= "00000";
									O_rt <= "00000";
									O_rd <= "00000";
									O_shamt <= "00000";
									O_funct <= ADD_FUNCT;
									O_stall <= '1';
									stalled_instruction <= stalled_instruction;
									stalled_pc <= stalled_pc;
								else
									O_stall <= '0';
									stall <= '0';
									stalled_instruction <= (others=>'0');
									stalled_pc <= (others=>'0');
								end if;
							else
								O_aluop <= "000000";
								O_rs <= "00000";
								O_rt <= "00000";
								O_rd <= "00000";
								O_shamt <= "00000";
								O_funct <= ADD_FUNCT;	
								O_stall <= '1';
								stall <= '1';
								stalled_instruction <= stalled_instruction;
								stalled_pc <= stalled_pc;
							end if;
						
						-- required rt operand is result of prev-prev instruction
						elsif stalled_instruction(25 downto 21) = I_ex_rd AND I_ex_reg_write = '1' then
							-- stall if forwarding not enabled
							if I_fwd_en = '0' then
								O_aluop <= "000000";
								O_rs <= "00000";
								O_rt <= "00000";
								O_rd <= "00000";
								O_shamt <= "00000";
								O_funct <= ADD_FUNCT;
								O_stall <= '1';
								stall <= '1';
								stalled_instruction <= stalled_instruction;
								stalled_pc <= stalled_pc;
							else
								O_stall <= '0';
								stall <= '0';
								stalled_instruction <= (others=>'0');
								stalled_pc <= (others=>'0');
							end if;
						end if;
					end if;		
				end if;
				O_next_pc <= stalled_pc;
				O_aluop <= stalled_instruction(31 downto 26);
			end if;
		end if;
	end if;
end process;

end Behavioral;