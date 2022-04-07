library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity execute is

port(
	-- INPUTS

	-- Synchronoucity Inputs
	I_clk : in std_logic;
	I_reset : in std_logic;

	-- Execute Inputs
        I_imm_SE : in  STD_LOGIC_VECTOR (31 downto 0);
	I_imm_ZE : in STD_LOGIC_VECTOR (31 downto 0);
        I_opcode : in  STD_LOGIC_VECTOR (5 downto 0);
	I_shamt: in STD_LOGIC_VECTOR (5 downto 0);
	I_funct: in STD_LOGIC_VECTOR (5 downto 0);
	I_addr: in STD_LOGIC_VECTOR (25 downto 0);
	
	I_rs: in std_logic_vector (4 downto 0);
	I_rt: in std_logic_vector (4 downto 0);
	I_rs_data: in std_logic_vector (31 downto 0);
	I_rt_data: in std_logic_vector (31 downto 0);
	I_next_pc: in std_logic_vector (31 downto 0); -- pc + 4

	-- Control Signals Inputs
	I_rd: in std_logic_vector (4 downto 0); 			-- the destination register where to write the instr. result
	I_branch: in std_logic; 					-- indicates if its is a branch operation (beq, bne)
	I_jump: in std_logic; 						-- indicates if it is a jump instruction (j, jr, jal)
	I_mem_read: in std_logic; 					-- indicates if a value must be read from memory at calculated address
	I_mem_write: in std_logic; 					-- indicates if value in I_rt_data must be written in memory at calculated address
	I_reg_write: in std_logic; 					-- indicates if value calculated in ALU must be written to destination register
	I_mem_to_reg: in std_logic; 					-- indicates if value loaded from memory must be writte to destination register
	
	-- Forwarding Unit Inputs
	I_ex_data: in std_logic_vector(31 downto 0); 	-- current output data of ex stage
	I_mem_data: in std_logic_vector(31 downto 0); 		-- current output data of mem stage
	
	-- forwarding control bits
	-- "00": take input from ID stage
	-- "01": take input from EX stage
	-- "10": take input from MEM stage
	I_forward_rs: in std_logic_vector(1 downto 0);		-- forwarding control bits of rs register
	I_forward_rt: in std_logic_vector(1 downto 0);		-- forwarding control bits of rt register

	-- OUTPUTS
	-- Execute Outputs
	O_alu_result: out std_logic_vector (31 downto 0); 		-- ** connect to prev_O_alu_result for forwarding puproses
	O_updated_next_pc: out std_logic_vector (31 downto 0);
	O_rt_data: out std_logic_vector (31 downto 0);
	O_stall: out std_logic;					-- indicates stall instruction

	-- Control Signals Outputs
	O_rd: out std_logic_vector (4 downto 0); -- ** connect to ex_rd input of forwarding unit
	O_branch: out std_logic;
	O_jump: out std_logic;
	O_mem_read: out std_logic;
	O_mem_write: out std_logic;
	O_reg_write: out std_logic; 				-- ** connect to ex_reg_write input of forwarding unit
	O_mem_to_reg: out std_logic
);
end execute;

architecture arch of execute is
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

-- declare signals here
	signal high_register : std_logic_vector (31 downto 0);
	signal low_register : std_logic_vector (31 downto 0);
	
	-- operands data according on forwarding logic
	signal I_forward_rs_data : std_logic_vector (31 downto 0); 
	signal I_forward_rt_data : std_logic_vector (31 downto 0);
begin

-- make circuits here
	-- execution stage process
	execute_process: process(I_clk, I_reset)
	begin
		-- asynchronous I_reset active high
		if I_reset'event and I_reset = '1' then
			O_alu_result <= (others=>'0');
			O_updated_next_pc <= (others=>'0');
			O_rt_data <= (others=>'0');
			high_register <= (others=>'0');
			low_register <= (others=>'0');
	
			
			O_rd <= (others=>'0');
			O_mem_read <= '0';
			O_mem_write <= '0';
			O_branch <= '0';
			O_reg_write <= '0';
			O_mem_to_reg <= '0';
			O_jump <= '0';

			O_stall <= '0';
			
		-- synchronous clock active high
		elsif I_clk'event and I_clk = '0' then

			-- check for stall instruction

			-- stall when given instruction 'add R0 R0 R0'
			if I_rs = "00000" and I_rt = "00000" and I_rd = "00000" and I_funct = ADD_FUNCT then
				O_stall <= '1';

			-- no stall - execute
			else
				O_stall <= '0';
				-- pass control signals to next stage
				O_rd <= I_rd;
				O_mem_read <= I_mem_read;
				O_mem_write <= I_mem_write;
				O_branch <= I_branch;
				O_reg_write <= I_reg_write;
				O_mem_to_reg <= I_mem_to_reg;

				-- ALU results
				if I_opcode = "000000" then
                			case I_funct is -- check functional bits for R type instructions
                  	  		-- arithmetic
                    			when ADD_FUNCT =>
						if I_forward_rs = "00" and I_forward_rt = "00" then
							O_alu_result <= std_logic_vector(signed(I_rs_data) + signed(I_rt_data));
						elsif I_forward_rs = "00" and I_forward_rt = "01" then
							O_alu_result <= std_logic_vector(signed(I_rs_data) + signed(I_ex_data));
						elsif I_forward_rs = "00" and I_forward_rt = "10" then
							O_alu_result <= std_logic_vector(signed(I_rs_data) + signed(I_mem_data));
						elsif I_forward_rs = "01" and I_forward_rt = "00" then
							O_alu_result <= std_logic_vector(signed(I_ex_data) + signed(I_rt_data));
						elsif I_forward_rs = "01" and I_forward_rt = "10" then
							O_alu_result <= std_logic_vector(signed(I_ex_data) + signed(I_mem_data));
						elsif I_forward_rs = "10" and I_forward_rt = "00" then
							O_alu_result <= std_logic_vector(signed(I_mem_data) + signed(I_rt_data));
						elsif I_forward_rs = "10" and I_forward_rt = "01" then
							O_alu_result <= std_logic_vector(signed(I_mem_data) + signed(I_ex_data));
                    				end if;
						when SUB_FUNCT =>
						if I_forward_rs = "00" and I_forward_rt = "00" then
							O_alu_result <= std_logic_vector(signed(I_rs_data) - signed(I_rt_data));
						elsif I_forward_rs = "00" and I_forward_rt = "01" then
							O_alu_result <= std_logic_vector(signed(I_rs_data) - signed(I_ex_data));
						elsif I_forward_rs = "00" and I_forward_rt = "10" then
							O_alu_result <= std_logic_vector(signed(I_rs_data) - signed(I_mem_data));
						elsif I_forward_rs = "01" and I_forward_rt = "00" then
							O_alu_result <= std_logic_vector(signed(I_ex_data) - signed(I_rt_data));
						elsif I_forward_rs = "01" and I_forward_rt = "10" then
							O_alu_result <= std_logic_vector(signed(I_ex_data) - signed(I_mem_data));
						elsif I_forward_rs = "10" and I_forward_rt = "00" then
							O_alu_result <= std_logic_vector(signed(I_mem_data) - signed(I_rt_data));
						elsif I_forward_rs = "10" and I_forward_rt = "01" then
							O_alu_result <= std_logic_vector(signed(I_mem_data) - signed(I_ex_data));
                    				end if;

                    			when MULT_FUNCT =>
						if I_forward_rs = "00" and I_forward_rt = "00" then
                                        		low_register <= std_logic_vector(resize(signed(I_rs_data) * signed(I_rt_data),64)(31 downto 0));
                                        		high_register <= std_logic_vector(resize(signed(I_rs_data) * signed(I_rt_data),64)(63 downto 32));						
                                    		elsif I_forward_rs = "00" and I_forward_rt = "01" then
                                        		low_register <= std_logic_vector(resize(signed(I_rs_data) * signed(I_ex_data),64)(31 downto 0));
                                        		high_register <= std_logic_vector(resize(signed(I_rs_data) * signed(I_ex_data),64)(63 downto 32));	
                                   		 elsif I_forward_rs = "00" and I_forward_rt = "10" then
                                        		low_register <= std_logic_vector(resize(signed(I_rs_data) * signed(I_mem_data),64)(31 downto 0));
                                        		high_register <= std_logic_vector(resize(signed(I_rs_data) * signed(I_mem_data),64)(63 downto 32));	
                                    		elsif I_forward_rs = "01" and I_forward_rt = "00" then
                                        		low_register <= std_logic_vector(resize(signed(I_ex_data) * signed(I_rt_data),64)(31 downto 0));
                                        		high_register <= std_logic_vector(resize(signed(I_ex_data) * signed(I_rt_data),64)(63 downto 32));	
                                    		elsif I_forward_rs = "01" and I_forward_rt = "10" then
                                        		low_register <= std_logic_vector(resize(signed(I_ex_data) * signed(I_mem_data),64)(31 downto 0));
                                        		high_register <= std_logic_vector(resize(signed(I_ex_data) * signed(I_mem_data),64)(63 downto 32));	
                                    		elsif I_forward_rs = "10" and I_forward_rt = "00" then
                                        		low_register <= std_logic_vector(resize(signed(I_mem_data) * signed(I_rt_data),64)(31 downto 0));
                                        		high_register <= std_logic_vector(resize(signed(I_mem_data) * signed(I_rt_data),64)(63 downto 32));	
                                    		elsif I_forward_rs = "10" and I_forward_rt = "01" then
                                        		low_register <= std_logic_vector(resize(signed(I_mem_data) * signed(I_ex_data),64)(31 downto 0));
                                        		high_register <= std_logic_vector(resize(signed(I_mem_data) * signed(I_ex_data),64)(63 downto 32));	
                                    		end if;

                  	  		when DIV_FUNCT =>
						if I_forward_rs = "00" and I_forward_rt = "00" then
          		              			low_register <= std_logic_vector(signed(I_rs_data) / signed(I_rt_data));
          		              			high_register <= std_logic_vector(signed(I_rs_data) mod signed(I_rt_data));					
                                    		elsif I_forward_rs = "00" and I_forward_rt = "01" then
          		              			low_register <= std_logic_vector(signed(I_rs_data) / signed(I_ex_data));
          		              			high_register <= std_logic_vector(signed(I_rs_data) mod signed(I_ex_data));
                                   		 elsif I_forward_rs = "00" and I_forward_rt = "10" then
          		              			low_register <= std_logic_vector(signed(I_rs_data) / signed(I_mem_data));
          		              			high_register <= std_logic_vector(signed(I_rs_data) mod signed(I_mem_data));	
                                    		elsif I_forward_rs = "01" and I_forward_rt = "00" then
          		              			low_register <= std_logic_vector(signed(I_ex_data) / signed(I_rt_data));
          		              			high_register <= std_logic_vector(signed(I_ex_data) mod signed(I_rt_data));	
                                    		elsif I_forward_rs = "01" and I_forward_rt = "10" then
          		              			low_register <= std_logic_vector(signed(I_ex_data) / signed(I_mem_data));
          		              			high_register <= std_logic_vector(signed(I_ex_data) mod signed(I_mem_data));
                                    		elsif I_forward_rs = "10" and I_forward_rt = "00" then
          		              			low_register <= std_logic_vector(signed(I_mem_data) / signed(I_rt_data));
          		              			high_register <= std_logic_vector(signed(I_mem_data) mod signed(I_rt_data));
                                    		elsif I_forward_rs = "10" and I_forward_rt = "01" then
          		              			low_register <= std_logic_vector(signed(I_mem_data) / signed(I_ex_data));
          		              			high_register <= std_logic_vector(signed(I_mem_data) mod signed(I_ex_data));
                                    		end if;
                        
          	          		when SLT_FUNCT =>
						if I_forward_rs = "00" and I_forward_rt = "00" then
  		                      			if signed(I_rs_data) < signed(I_rt_data) then
  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
        	                			else
  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
        	                			end if;
						elsif I_forward_rs = "00" and I_forward_rt = "01" then
  		                      			if signed(I_rs_data) < signed(I_ex_data) then
  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
        	                			else
  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
        	                			end if;
						elsif I_forward_rs = "00" and I_forward_rt = "10" then
  		                      			if signed(I_rs_data) < signed(I_mem_data) then
  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
        	                			else
  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
        	                			end if;
						elsif I_forward_rs = "01" and I_forward_rt = "00" then
  		                      			if signed(I_ex_data) < signed(I_rt_data) then
  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
        	                			else
  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
        	                			end if;
						elsif I_forward_rs = "01" and I_forward_rt = "10" then
  		                      			if signed(I_ex_data) < signed(I_mem_data) then
  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
        	                			else
  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
        	                			end if;
						elsif I_forward_rs = "10" and I_forward_rt = "00" then
  		                      			if signed(I_mem_data) < signed(I_rt_data) then
  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
        	                			else
  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
        	                			end if;
						elsif I_forward_rs = "10" and I_forward_rt = "01" then
  		                      			if signed(I_mem_data) < signed(I_ex_data) then
  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
        	                			else
  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
        	                			end if;
                    				end if;

  	                  		-- logical
        	            		when AND_FUNCT =>
						if I_forward_rs = "00" and I_forward_rt = "00" then
							O_alu_result <= I_rs_data and I_rt_data;
						elsif I_forward_rs = "00" and I_forward_rt = "01" then
							O_alu_result <= I_rs_data and I_ex_data;
						elsif I_forward_rs = "00" and I_forward_rt = "10" then
							O_alu_result <= I_rs_data and I_mem_data;
						elsif I_forward_rs = "01" and I_forward_rt = "00" then
							O_alu_result <= I_ex_data and I_rt_data;
						elsif I_forward_rs = "01" and I_forward_rt = "10" then
							O_alu_result <= I_ex_data and I_mem_data;
						elsif I_forward_rs = "10" and I_forward_rt = "00" then
							O_alu_result <= I_mem_data and I_rt_data;
						elsif I_forward_rs = "10" and I_forward_rt = "01" then
							O_alu_result <= I_mem_data and I_ex_data;
                    				end if;

					when OR_FUNCT =>
						if I_forward_rs = "00" and I_forward_rt = "00" then
							O_alu_result <= I_rs_data or I_rt_data;
						elsif I_forward_rs = "00" and I_forward_rt = "01" then
							O_alu_result <= I_rs_data or I_ex_data;
						elsif I_forward_rs = "00" and I_forward_rt = "10" then
							O_alu_result <= I_rs_data or I_mem_data;
						elsif I_forward_rs = "01" and I_forward_rt = "00" then
							O_alu_result <= I_ex_data or I_rt_data;
						elsif I_forward_rs = "01" and I_forward_rt = "10" then
							O_alu_result <= I_ex_data or I_mem_data;
						elsif I_forward_rs = "10" and I_forward_rt = "00" then
							O_alu_result <= I_mem_data or I_rt_data;
						elsif I_forward_rs = "10" and I_forward_rt = "01" then
							O_alu_result <= I_mem_data or I_ex_data;
                    				end if;
                        
          	          		when NOR_FUNCT =>
						if I_forward_rs = "00" and I_forward_rt = "00" then
							O_alu_result <= I_rs_data nor I_rt_data;
						elsif I_forward_rs = "00" and I_forward_rt = "01" then
							O_alu_result <= I_rs_data nor I_ex_data;
						elsif I_forward_rs = "00" and I_forward_rt = "10" then
							O_alu_result <= I_rs_data nor I_mem_data;
						elsif I_forward_rs = "01" and I_forward_rt = "00" then
							O_alu_result <= I_ex_data nor I_rt_data;
						elsif I_forward_rs = "01" and I_forward_rt = "10" then
							O_alu_result <= I_ex_data nor I_mem_data;
						elsif I_forward_rs = "10" and I_forward_rt = "00" then
							O_alu_result <= I_mem_data nor I_rt_data;
						elsif I_forward_rs = "10" and I_forward_rt = "01" then
							O_alu_result <= I_mem_data nor I_ex_data;
                    				end if;

  	                  		when XOR_FUNCT =>
						if I_forward_rs = "00" and I_forward_rt = "00" then
							O_alu_result <= I_rs_data xor I_rt_data;
						elsif I_forward_rs = "00" and I_forward_rt = "01" then
							O_alu_result <= I_rs_data xor I_ex_data;
						elsif I_forward_rs = "00" and I_forward_rt = "10" then
							O_alu_result <= I_rs_data xor I_mem_data;
						elsif I_forward_rs = "01" and I_forward_rt = "00" then
							O_alu_result <= I_ex_data xor I_rt_data;
						elsif I_forward_rs = "01" and I_forward_rt = "10" then
							O_alu_result <= I_ex_data xor I_mem_data;
						elsif I_forward_rs = "10" and I_forward_rt = "00" then
							O_alu_result <= I_mem_data xor I_rt_data;
						elsif I_forward_rs = "10" and I_forward_rt = "01" then
							O_alu_result <= I_mem_data xor I_ex_data;
                    				end if;
	
        	            		-- transfer
  	                  		when MFHI_FUNCT =>
        	                		O_alu_result <= high_register;

  	                  		when MFLO_FUNCT =>
        	                		O_alu_result <= low_register;

  	                  		-- shift
        	            		when SLL_FUNCT =>
						case I_forward_rt is
						when "00" =>
							O_alu_result <= std_logic_vector(shift_left(unsigned(I_rt_data), to_integer(unsigned(I_shamt))));
						when "01" =>
							O_alu_result <= std_logic_vector(shift_left(unsigned(I_ex_data), to_integer(unsigned(I_shamt))));
						when "10" =>
							O_alu_result <= std_logic_vector(shift_left(unsigned(I_mem_data), to_integer(unsigned(I_shamt))));
						when others =>
						end case;
  		                      		
  	                  		when SRL_FUNCT =>
						case I_forward_rt is
						when "00" =>
							O_alu_result <= std_logic_vector(shift_right(unsigned(I_rt_data), to_integer(unsigned(I_shamt))));
						when "01" =>
							O_alu_result <= std_logic_vector(shift_right(unsigned(I_ex_data), to_integer(unsigned(I_shamt))));
						when "10" =>
							O_alu_result <= std_logic_vector(shift_right(unsigned(I_mem_data), to_integer(unsigned(I_shamt))));
						when others =>
						end case;

  	                  		when SRA_FUNCT =>
						case I_forward_rt is
						when "00" =>
	        	                		O_alu_result <= std_logic_vector(shift_right(signed(I_rt_data), to_integer(unsigned(I_shamt))));
						when "01" =>
							O_alu_result <= std_logic_vector(shift_right(signed(I_ex_data), to_integer(unsigned(I_shamt))));
						when "10" =>
							O_alu_result <= std_logic_vector(shift_right(signed(I_mem_data), to_integer(unsigned(I_shamt))));
						when others =>
						end case;
                    
  	                  		-- control-flow
        	            		when JR_FUNCT=>
						case I_forward_rs is
						when "00" =>
	        	                		O_updated_next_pc <= I_rs_data;
						when "01" =>
							O_updated_next_pc <= I_ex_data;
						when "10" =>
							O_updated_next_pc <= I_mem_data;
						when others =>
						end case;

  	                  		when others =>
        	        		end case;
  	          		else
        	        		case I_opcode is
  	                  		-- arithmetic
        	            		when ADDI_OPCODE =>
						-- SignExtImm
						case I_forward_rs is
						when "00" =>
  		                      			O_alu_result <= std_logic_vector(signed(I_rs_data) + signed(I_imm_SE));
						when "01" =>
  		                      			O_alu_result <= std_logic_vector(signed(I_ex_data) + signed(I_imm_SE));
						when "10" =>
  		                      			O_alu_result <= std_logic_vector(signed(I_mem_data) + signed(I_imm_SE));
						when others =>
						end case;
                        
  	                  		when SLTI_OPCODE =>
						-- SignExtImm
						case I_forward_rs is
						when "00" =>
  		                      			if signed(I_rs_data) < signed(I_imm_SE) then
  		                          			O_alu_result <= std_logic_vector(to_signed(1,32));
  		                      			else
  		                          			O_alu_result <= std_logic_vector(to_signed(0,32));
  		                      			end if;
						when "01" =>
  		                      			if signed(I_ex_data) < signed(I_imm_SE) then
  		                          			O_alu_result <= std_logic_vector(to_signed(1,32));
  		                      			else
  		                          			O_alu_result <= std_logic_vector(to_signed(0,32));
  		                      			end if;
						when "10" =>
  		                      			if signed(I_mem_data) < signed(I_imm_SE) then
  		                          			O_alu_result <= std_logic_vector(to_signed(1,32));
  		                      			else
  		                          			O_alu_result <= std_logic_vector(to_signed(0,32));
  		                      			end if;
						when others =>
						end case;

  	                  		-- logical
        	            		when ANDI_OPCODE =>
  		                      		-- ZeroExtImm
						case I_forward_rs is
						when "00" =>
  		                      			O_alu_result <= I_rs_data and I_imm_ZE;
						when "01" =>
  		                      			O_alu_result <= I_ex_data and I_imm_ZE;
						when "10" =>
  		                      			O_alu_result <= I_mem_data and I_imm_ZE;
						when others =>
						end case;
  		                      		
  	                  		when ORI_OPCODE =>
  		                      		-- ZeroExtImm
						case I_forward_rs is
						when "00" =>
  		                      			O_alu_result <= I_rs_data or I_imm_ZE;
						when "01" =>
  		                      			O_alu_result <= I_ex_data or I_imm_ZE;
						when "10" =>
  		                      			O_alu_result <= I_mem_data or I_imm_ZE;
						when others =>
						end case;

  	                  		when XORI_OPCODE =>
  		                      		-- ZeroExtImm
						case I_forward_rs is
						when "00" =>
  		                      			O_alu_result <= I_rs_data xor I_imm_ZE;
						when "01" =>
  		                      			O_alu_result <= I_ex_data xor I_imm_ZE;
						when "10" =>
  		                      			O_alu_result <= I_mem_data xor I_imm_ZE;
						when others =>
						end case;

  	                  		-- transfer
        	            		when LUI_OPCODE =>
  		                      		-- load immediate value into 16 upper bits of rt register
  		                      		O_alu_result <= I_imm_ZE(15 downto 0) & std_logic_vector(to_unsigned(0,16));

  	                  		-- memory
        	            		when LW_OPCODE | SW_OPCODE=>
						case I_forward_rs is
						when "00" =>
  		                      			O_alu_result <= std_logic_vector(signed(I_rs_data) + signed(I_imm_SE));
						when "01" =>
  		                      			O_alu_result <= std_logic_vector(signed(I_ex_data) + signed(I_imm_SE));
						when "10" =>
  		                      			O_alu_result <= std_logic_vector(signed(I_mem_data) + signed(I_imm_SE));
						when others =>
						end case;
  		                      		                    
  	                  		-- control-flow
        	            		when BEQ_OPCODE=>
						if I_forward_rs = "00" and I_forward_rt = "00" then
  		                      			if I_rs_data = I_rt_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                			else
  	                          				O_updated_next_pc <= I_next_pc;
        	                			end if;
						elsif I_forward_rs = "00" and I_forward_rt = "01" then
  		                      			if I_rs_data = I_ex_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                			else
  	                          				O_updated_next_pc <= I_next_pc;
        	                			end if;
						elsif I_forward_rs = "00" and I_forward_rt = "10" then
  		                      			if I_rs_data = I_mem_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));  	                          				O_updated_next_pc <= I_next_pc;
        	                			end if;
						elsif I_forward_rs = "01" and I_forward_rt = "00" then
  		                      			if I_ex_data = I_rt_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                			else
  	                          				O_updated_next_pc <= I_next_pc;
        	                			end if;
						elsif I_forward_rs = "01" and I_forward_rt = "10" then
  		                      			if I_ex_data = I_mem_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                			else
  	                          				O_updated_next_pc <= I_next_pc;
        	                			end if;
						elsif I_forward_rs = "10" and I_forward_rt = "00" then
  		                      			if I_mem_data = I_rt_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                			else
  	                          				O_updated_next_pc <= I_next_pc;
        	                			end if;
						elsif I_forward_rs = "10" and I_forward_rt = "01" then
  		                      			if I_mem_data = I_ex_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                			else
  	                          				O_updated_next_pc <= I_next_pc;
        	                			end if;
                    				end if;
  	                  		when BNE_OPCODE=>
						if I_forward_rs = "00" and I_forward_rt = "00" then
  		                      			if I_rs_data /= I_rt_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                			else
  	                          				O_updated_next_pc <= I_next_pc;
        	                			end if;
						elsif I_forward_rs = "00" and I_forward_rt = "01" then
  		                      			if I_rs_data /= I_ex_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));  	                          				O_updated_next_pc <= I_next_pc;
        	                			end if;
						elsif I_forward_rs = "00" and I_forward_rt = "10" then
  		                      			if I_rs_data /= I_mem_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                			else
  	                          				O_updated_next_pc <= I_next_pc;
        	                			end if;
						elsif I_forward_rs = "01" and I_forward_rt = "00" then
  		                      			if I_ex_data /= I_rt_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                			else
  	                          				O_updated_next_pc <= I_next_pc;
        	                			end if;
						elsif I_forward_rs = "01" and I_forward_rt = "10" then
  		                      			if I_ex_data /= I_mem_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                			else
  	                          				O_updated_next_pc <= I_next_pc;
        	                			end if;
						elsif I_forward_rs = "10" and I_forward_rt = "00" then
  		                      			if I_mem_data /= I_rt_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                			else
  	                          				O_updated_next_pc <= I_next_pc;
        	                			end if;
						elsif I_forward_rs = "10" and I_forward_rt = "01" then
  		                      			if I_mem_data /= I_ex_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                			else
  	                          				O_updated_next_pc <= I_next_pc;
        	                			end if;
                    				end if;
					when J_OPCODE=>
        	                		O_updated_next_pc <= I_next_pc(31 downto 28) & I_addr & "00";
	
        	            		when JAL_OPCODE=>
  		                      		O_alu_result <= std_logic_vector(signed(I_next_pc) + to_signed(4,32));
  		                      		O_updated_next_pc <= I_next_pc(31 downto 28) & I_addr & "00";
  	                  		when others =>
        	        		end case;
				end if;
			end if;
		end if;
	end process;
end arch;
	