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
		-- hazard detection
		I_id_rd: in std_logic_vector (4 downto 0);
		I_id_reg_write: in std_logic;
		I_ex_rd: in std_logic_vector (4 downto 0);
		I_ex_reg_write: in std_logic;
		I_mem_rd: in std_logic_vector (4 downto 0);
		I_mem_reg_write: in std_logic;
			  
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
		O_mem_to_reg: out STD_LOGIC;
		O_addr: out STD_LOGIC_VECTOR (25 downto 0)
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
	
begin
	
id_process: process (I_clk, I_reset)
	begin
  
  	if I_reset'event and I_reset='1' then
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
		O_mem_to_reg <= '0';
		O_addr <= (others => '0');
	 elsif I_clk'event and I_clk = '1' then
      		if I_dataInst(31 downto 26) = "000000" then
                	case I_dataInst(5 downto 0) is -- check functional bits for R type instructions
                  	-- arithmetic
                    	when ADD_FUNCT =>
                        			O_regDwe <= '1';

											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';


                  
                    	when SUB_FUNCT =>
                        				O_regDwe <= '1';
	
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';

                    	when MULT_FUNCT =>
                        				O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';

                  	when DIV_FUNCT =>
          		              		O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
			when SLT_FUNCT =>
  		                      			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';

  	                  		-- logical
        	        when AND_FUNCT =>
  		                      			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';

			when OR_FUNCT =>
          		              		O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';

                        
          	        when NOR_FUNCT =>
  		                      			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';


  	              	when XOR_FUNCT =>
        	                			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';

	
        	            		-- transfer
  	               	when MFHI_FUNCT =>
        	                			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';  	                  		when MFLO_FUNCT =>
        	                			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
					-- shift
        	       	when SLL_FUNCT =>
  		                      			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';  	                  		when SRL_FUNCT =>
        	                			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';


  	             	when SRA_FUNCT =>
        	                			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
  	                  		-- control-flow
        	       	when JR_FUNCT=>
  		                      		O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											

  	              	when others =>
        	       	end case;
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
											O_mem_to_reg <= '0';
											
											
  	               	when SLTI_OPCODE =>
        	                			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											--O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));

  	                  		-- logical
        	    	when ANDI_OPCODE =>
  		                      		-- ZeroExtImm
  		                      		O_regDwe <= '1';
									--		I_id_reg_write <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';

  	              	when ORI_OPCODE =>
											O_regDwe <= '1';
									--		I_id_reg_write <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';

  	              	when XORI_OPCODE =>
											O_regDwe <= '1';
									--		I_id_reg_write <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';

  	                  		-- transfer
        	       	when LUI_OPCODE =>
  		                      		O_regDwe <= '1';
									--		I_id_reg_write <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';


  	                  		-- memory
        	     	when LW_OPCODE | SW_OPCODE=>
  		                      		O_regDwe <= '1';
									--		I_id_reg_write <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '1';
											O_mem_write <= '0';
											O_mem_to_reg <= '1';

                    
  	                  		-- control-flow
        	       	when BEQ_OPCODE=>
									 	 	O_regDwe <= '0';
									--		I_id_reg_write <= '0';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
										 
--  		                      		if O_datas = O_datat then
--  	                          			O_regDwe <= '0';
--												I_id_reg_write <= '0';
--												O_branch <= '1';
--												O_jump <= '0';
--												O_mem_read <= '0';
--												O_mem_write <= '0';
--												O_mem_to_reg <= '0';
--        	                			else
--  	                          			O_regDwe <= '0';
--												I_id_reg_write <= '0';
--												O_branch <= '0';
--												O_jump <= '0';
--												O_mem_read <= '0';
--												O_mem_write <= '0';
--												O_mem_to_reg <= '0';
--											end if;
--											I_ren <= '0';
  	                when BNE_OPCODE=>
											O_regDwe <= '0';
									--		I_id_reg_write <= '0';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											
--										I_ren <= '1';
--										I_we <= '0';
--        	                		if O_datas /= O_datat then
--  	                          			O_regDwe <= '0';
--												I_id_reg_write <= '0';
--												O_branch <= '1';
--												O_jump <= '0';
--												O_mem_read <= '0';
--												O_mem_write <= '0';
--												O_mem_to_reg <= '0';
--        	                		else
--  	                          			O_regDwe <= '0';
--												I_id_reg_write <= '0';
--												O_branch <= '0';
--												O_jump <= '0';
--												O_mem_read <= '0';
--												O_mem_write <= '0';
--												O_mem_to_reg <= '0';
--        	                		end if;
--										I_ren <= '0';
  	                when J_OPCODE=>
												O_regDwe <= '0';
									--			I_id_reg_write <= '0';
												O_branch <= '0';
												O_jump <= '1';
												O_mem_read <= '0';
												O_mem_write <= '0';
												O_mem_to_reg <= '0';
	
        	      	when JAL_OPCODE=>
												O_regDwe <= '0';
									--			I_id_reg_write <= '0';
												O_branch <= '0';
												O_jump <= '1';
												O_mem_read <= '0';
												O_mem_write <= '0';
												O_mem_to_reg <= '0';
  	               	when others =>
        	        end case;
		end if;
				if I_dataInst(25 downto 21) = I_id_rd AND I_id_reg_write = '1' then
					O_aluop <= "000000";
					O_rs <= "00000";
					O_rt <= "00000";
					O_rd <= "00000";
					O_shamt <= "00000";
					O_funct <= ADD_FUNCT;
				elsif I_dataInst(20 downto 16) = I_id_rd AND I_id_reg_write = '1' then
					O_aluop <= "000000";
					O_rs <= "00000";
					O_rt <= "00000";
					O_rd <= "00000";
					O_shamt <= "00000";
					O_funct <= ADD_FUNCT;
				elsif I_dataInst(25 downto 21) = I_ex_rd AND I_ex_reg_write = '1' then
					O_aluop <= "000000";
					O_rs <= "00000";
					O_rt <= "00000";
					O_rd <= "00000";
					O_shamt <= "00000";
					O_funct <= ADD_FUNCT;
				elsif I_dataInst(25 downto 21) = I_mem_rd AND I_mem_reg_write = '1' then
					O_aluop <= "000000";
					O_rs <= "00000";
					O_rt <= "00000";
					O_rd <= "00000";
					O_shamt <= "00000";
					O_funct <= ADD_FUNCT;
				elsif I_dataInst(20 downto 16) = I_ex_rd AND I_ex_reg_write = '1' then
					O_aluop <= "000000";
					O_rs <= "00000";
					O_rt <= "00000";
					O_rd <= "00000";
					O_shamt <= "00000";
					O_funct <= ADD_FUNCT;
				elsif I_dataInst(20 downto 16) = I_mem_rd AND I_mem_reg_write = '1' then
					O_aluop <= "000000";
					O_rs <= "00000";
					O_rt <= "00000";
					O_rd <= "00000";
					O_shamt <= "00000";
					O_funct <= ADD_FUNCT;
				else 
					
					O_rs <= I_dataInst(25 downto 21);
					O_rt <= I_dataInst(20 downto 16);
					O_rd <= I_dataInst(15 downto 11);
					

					O_shamt <= I_dataInst(10 downto 6);
					O_funct <= I_dataInst(5 downto 0);
					O_addr <= I_dataInst(25 downto 0);
				end if;
		O_next_pc <= I_pc;
		O_aluop <= I_dataInst(31 downto 26);
		if I_dataInst(15) = '1' then
			O_dataIMM_SE(31 downto 16) <= "1111111111111111";
		else
			O_dataIMM_SE(31 downto 16) <= "0000000000000000";
		end if;
		O_dataIMM_SE(15 downto 0) <= I_dataInst(15 downto 0);
		O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
		O_dataIMM_ZE(15 downto 0) <= I_dataInst(15 downto 0);		
	end if;
end process;

end Behavioral;