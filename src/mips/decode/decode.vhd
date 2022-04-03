Entity decode is
    Port ( I_clk : in  STD_LOGIC;
           I_dataInst : in  STD_LOGIC_VECTOR (31 downto 0);
           I_en : in  STD_LOGIC;
			  I_pc: in STD_LOGIC_VECTOR (31 downto 0);
			  O_next_pc: in STD_LOGIC_VECTOR (31 downto 0);
           O_selA : out  STD_LOGIC_VECTOR (5 downto 0);
           O_selB : out  STD_LOGIC_VECTOR (5 downto 0);
           O_selD : out  STD_LOGIC_VECTOR (5 downto 0);
           O_dataIMM_SE : out  STD_LOGIC_VECTOR (31 downto 0);
			  O_dataIMM_ZE : out STD_LOGIC_VECTOR (31 downto 0);
           O_regDwe : out  STD_LOGIC;
           O_aluop : out  STD_LOGIC_VECTOR (5 downto 0);
			  O_shamt: out STD_LOGIC_VECTOR (5 downto 0);
			  O_funct: out STD_LOGIC_VECTOR (6 downto 0);
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

  process (I_clk)
  begin
    if rising_edge(I_clk) and I_en = '1' then

      O_selA <= I_dataInst(25 downto 21);
      O_selB <= I_dataInst(20 downto 16);
      O_selD <= I_dataInst(15 downto 11);
      O_aluop <= I_dataInst(31 downto 26);
		if I_dataInst(15) = '1' then
			O_dataIMM_SE(31 downto 16) <= "1000000000000000";
		else
			O_dataIMM_SE(31 downto 16) <= "0000000000000000";
		end if;
		O_dataIMM_SE(15 downto 0) <= I_dataInst(15 downto 0);
		O_dataIMM_ZE(31 downto 16) <= "0000000000000000";
		O_dataIMM_ZE(15 downto 0) <= I_dataInst(15 downto 0);

      if instruction(31 downto 26) = "000000" then
                			case instruction(5 downto 0) is -- check functional bits for R type instructions
                  	  		-- arithmetic
                    			when ADD_FUNCT =>
                        			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));

                        
                    			when SUB_FUNCT =>
                        				O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));
                    			when MULT_FUNCT =>
                        				O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));
                  	  		when DIV_FUNCT =>
          		              		O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));
          	          		when SLT_FUNCT =>
  		                      			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));
  	                  		-- logical
        	            		when AND_FUNCT =>
  		                      			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));
									when OR_FUNCT =>
          		              		O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));
                        
          	          		when NOR_FUNCT =>
  		                      			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));

  	                  		when XOR_FUNCT =>
        	                			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));
	
        	            		-- transfer
  	                  		when MFHI_FUNCT =>
        	                			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));

  	                  		when MFLO_FUNCT =>
        	                			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));
  	                  		-- shift
        	            		when SLL_FUNCT =>
  		                      			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));;

  	                  		when SRL_FUNCT =>
        	                			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));

  	                  		when SRA_FUNCT =>
        	                			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));
                    
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
        	        		case instruction(31 downto 26) is
  	                  		-- arithmetic
        	            		when ADDI_OPCODE =>
  		                      		-- SignExtImm
  		                      		O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));
											
  	                  		when SLTI_OPCODE =>
        	                			O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));

  	                  		-- logical
        	            		when ANDI_OPCODE =>
  		                      		-- ZeroExtImm
  		                      		O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));
  	                  		when ORI_OPCODE =>
											O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));
  	                  		when XORI_OPCODE =>
											O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));
  	                  		-- transfer
        	            		when LUI_OPCODE =>
  		                      		O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '0';
											O_mem_write <= '0';
											O_mem_to_reg <= '0';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));

  	                  		-- memory
        	            		when LW_OPCODE | SW_OPCODE=>
  		                      		O_regDwe <= '1';
											O_branch <= '0';
											O_jump <= '0';
											O_mem_read <= '1';
											O_mem_write <= '0';
											O_mem_to_reg <= '1';
											O_next_pc <= std_logic_vector(unsigned(I_pc) + unsigned(4));
                    
  	                  		-- control-flow
        	            		when BEQ_OPCODE=>
  		                      		if forward_rs_data = forward_rt_data then
  	                          			O_regDwe <= '0';
												O_branch <= '1';
												O_jump <= '0';
												O_mem_read <= '0';
												O_mem_write <= '0';
												O_mem_to_reg <= '0';
        	                			else
  	                          			O_regDwe <= '0';
												O_branch <= '0';
												O_jump <= '0';
												O_mem_read <= '0';
												O_mem_write <= '0';
												O_mem_to_reg <= '0';
        	                		end if;
  	                  		when BNE_OPCODE=>
        	                		if forward_rs_data /= forward_rt_data then
  	                          			O_regDwe <= '0';
												O_branch <= '1';
												O_jump <= '0';
												O_mem_read <= '0';
												O_mem_write <= '0';
												O_mem_to_reg <= '0';
        	                		else
  	                          			O_regDwe <= '0';
												O_branch <= '0';
												O_jump <= '0';
												O_mem_read <= '0';
												O_mem_write <= '0';
												O_mem_to_reg <= '0';
        	                		end if;
  	                  		when J_OPCODE=>
												O_regDwe <= '0';
												O_branch <= '0';
												O_jump <= '1';
												O_mem_read <= '0';
												O_mem_write <= '0';
												O_mem_to_reg <= '0';
	
        	            		when JAL_OPCODE=>
												O_regDwe <= '0';
												O_branch <= '0';
												O_jump <= '1';
												O_mem_read <= '0';
												O_mem_write <= '0';
												O_mem_to_reg <= '0';
  	                  		when others =>
        	        		end case;
				end if;
    end if;
  end process;

end Behavioral;