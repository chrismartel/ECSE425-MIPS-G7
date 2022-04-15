-- ECSE425 W2022
-- Final Project, Group 07
-- Execute Stage

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity execute is

port(
	-- INPUTS

	-- Synchronoucity Inputs
	I_clk : in std_logic;
	I_reset : in std_logic;
	I_en : in std_logic;

	-- Execute Inputs
        I_imm_SE : in  std_logic_vector (31 downto 0);
	I_imm_ZE : in std_logic_vector (31 downto 0);
        I_opcode : in  std_logic_vector (5 downto 0);
	I_shamt: in std_logic_vector (4 downto 0);
	I_funct: in std_logic_vector (5 downto 0);
	I_addr: in std_logic_vector (25 downto 0);
	
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

	-- Forwarding Unit Inputs
	I_fwd_ex_alu_result: in std_logic_vector(31 downto 0); 	-- current output data of ex stage
	I_fwd_mem_read_data: in std_logic_vector(31 downto 0); 	-- current output data read from mem stage
	I_fwd_mem_alu_result: in std_logic_vector(31 downto 0); -- current alu result at mem stage
	I_fwd_mem_read: in std_logic; 				-- if '1' take mem stage read data, if '0' take mem alu result
	
	-- forwarding control bits
	-- FORWARDING_NONE: take input from ID stage
	-- FORWARDING_EX: take input from EX stage
	-- FORWARDING_MEM: take input from MEM stage
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
	O_reg_write: out std_logic				-- ** connect to ex_reg_write input of forwarding unit
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

	-- FORWARDING CODES

	constant FORWARDING_NONE : std_logic_vector (1 downto 0):= "00";
	constant FORWARDING_EX : std_logic_vector (1 downto 0):= "01";
	constant FORWARDING_MEM : std_logic_vector (1 downto 0):= "10";

-- declare signals here
	signal high_register : std_logic_vector (31 downto 0) := (others=>'X');
	signal low_register : std_logic_vector (31 downto 0) := (others=>'X');
	
	signal flush : std_logic := '0';	-- indicates if the current instruction must be flushed or not
	
begin

-- make circuits here
	-- execution stage process
	execute_process: process(I_clk, I_reset)
	begin
		-- asynchronous I_reset active high
		if I_reset'event and I_reset = '1' then
			O_alu_result <= (others=>'X');
			O_updated_next_pc <= (others=>'X');
			O_rt_data <= (others=>'X');
			high_register <= (others=>'X');
			low_register <= (others=>'X');
	
			
			O_rd <= (others=>'X');
			O_mem_read <= '0';
			O_mem_write <= '0';
			O_reg_write <= '0';
			O_jump <= '0';
			O_stall <= '0';
			flush <= '0';
			
		-- synchronous clock active high
		elsif I_clk'event and I_clk = '1' then
			if I_en = '1' then

			-- check for stall instruction

			-- stall when given instruction 'add R0 R0 R0'

			if (I_rs = "00000" and I_rt = "00000" and I_rd = "00000" and I_funct = ADD_FUNCT) or flush = '1' then
				O_stall <= '1';
				-- stall when instruction must be fushed
				if flush = '1' then
					flush <= '0';
				end if;

			-- no stall - execute
			else
				O_stall <= '0';
				-- pass control signals to next stage
				O_rd <= I_rd;
				O_mem_read <= I_mem_read;
				O_mem_write <= I_mem_write;
				O_reg_write <= I_reg_write;
				O_jump <= I_jump;

				-- ALU results
				if I_opcode = "000000" then
					O_branch <= '0';
                			case I_funct is -- check functional bits for R type instructions
                  	  		-- arithmetic
                    			when ADD_FUNCT =>
						if I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_NONE then
							O_alu_result <= std_logic_vector(signed(I_rs_data) + signed(I_rt_data));
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_EX then
							O_alu_result <= std_logic_vector(signed(I_rs_data) + signed(I_fwd_ex_alu_result));
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
								O_alu_result <= std_logic_vector(signed(I_rs_data) + signed(I_fwd_mem_read_data));
							else
								O_alu_result <= std_logic_vector(signed(I_rs_data) + signed(I_fwd_mem_alu_result));
							end if;
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_NONE then
							O_alu_result <= std_logic_vector(signed(I_fwd_ex_alu_result) + signed(I_rt_data));
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
								O_alu_result <= std_logic_vector(signed(I_fwd_ex_alu_result) + signed(I_fwd_mem_read_data));
							else
								O_alu_result <= std_logic_vector(signed(I_fwd_ex_alu_result) + signed(I_fwd_mem_alu_result));
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_NONE then
							if I_fwd_mem_read = '1' then
								O_alu_result <= std_logic_vector(signed(I_fwd_mem_read_data) + signed(I_rt_data));
							else
								O_alu_result <= std_logic_vector(signed(I_fwd_mem_alu_result) + signed(I_rt_data));
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_EX then
							if I_fwd_mem_read = '1' then
								O_alu_result <= std_logic_vector(signed(I_fwd_mem_read_data) + signed(I_fwd_ex_alu_result));
							else
								O_alu_result <= std_logic_vector(signed(I_fwd_mem_alu_result) + signed(I_fwd_ex_alu_result));
							end if;
                    				end if;
						when SUB_FUNCT =>
						if I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_NONE then
							O_alu_result <= std_logic_vector(signed(I_rs_data) - signed(I_rt_data));
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_EX then
							O_alu_result <= std_logic_vector(signed(I_rs_data) - signed(I_fwd_ex_alu_result));
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
								O_alu_result <= std_logic_vector(signed(I_rs_data) - signed(I_fwd_mem_read_data));
							else
								O_alu_result <= std_logic_vector(signed(I_rs_data) - signed(I_fwd_mem_alu_result));
							end if;
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_NONE then
							O_alu_result <= std_logic_vector(signed(I_fwd_ex_alu_result) - signed(I_rt_data));
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
								O_alu_result <= std_logic_vector(signed(I_fwd_ex_alu_result) - signed(I_fwd_mem_read_data));
							else
								O_alu_result <= std_logic_vector(signed(I_fwd_ex_alu_result) - signed(I_fwd_mem_alu_result));
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_NONE then
							if I_fwd_mem_read = '1' then
								O_alu_result <= std_logic_vector(signed(I_fwd_mem_read_data) - signed(I_rt_data));
							else
								O_alu_result <= std_logic_vector(signed(I_fwd_mem_alu_result) - signed(I_rt_data));
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_EX then
							if I_fwd_mem_read = '1' then
								O_alu_result <= std_logic_vector(signed(I_fwd_mem_read_data) - signed(I_fwd_ex_alu_result));
							else
								O_alu_result <= std_logic_vector(signed(I_fwd_mem_alu_result) - signed(I_fwd_ex_alu_result));
							end if;
                    				end if;
						flush <= '0';

                    			when MULT_FUNCT =>
						if I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_NONE then
                                        		low_register <= std_logic_vector(resize(signed(I_rs_data) * signed(I_rt_data),64)(31 downto 0));
                                        		high_register <= std_logic_vector(resize(signed(I_rs_data) * signed(I_rt_data),64)(63 downto 32));						
                                    		elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_EX then
                                        		low_register <= std_logic_vector(resize(signed(I_rs_data) * signed(I_fwd_ex_alu_result),64)(31 downto 0));
                                        		high_register <= std_logic_vector(resize(signed(I_rs_data) * signed(I_fwd_ex_alu_result),64)(63 downto 32));	
                                   		 elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
                                        			low_register <= std_logic_vector(resize(signed(I_rs_data) * signed(I_fwd_mem_read_data),64)(31 downto 0));
                                        			high_register <= std_logic_vector(resize(signed(I_rs_data) * signed(I_fwd_mem_read_data),64)(63 downto 32));	
							else
                                        			low_register <= std_logic_vector(resize(signed(I_rs_data) * signed(I_fwd_mem_alu_result),64)(31 downto 0));
                                        			high_register <= std_logic_vector(resize(signed(I_rs_data) * signed(I_fwd_mem_alu_result),64)(63 downto 32));	
							end if;
                                    		elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_NONE then
                                        		low_register <= std_logic_vector(resize(signed(I_fwd_ex_alu_result) * signed(I_rt_data),64)(31 downto 0));
                                        		high_register <= std_logic_vector(resize(signed(I_fwd_ex_alu_result) * signed(I_rt_data),64)(63 downto 32));	
                                    		elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
                                        			low_register <= std_logic_vector(resize(signed(I_fwd_ex_alu_result) * signed(I_fwd_mem_read_data),64)(31 downto 0));
                                        			high_register <= std_logic_vector(resize(signed(I_fwd_ex_alu_result) * signed(I_fwd_mem_read_data),64)(63 downto 32));	
							else
                                        			low_register <= std_logic_vector(resize(signed(I_fwd_ex_alu_result) * signed(I_fwd_mem_alu_result),64)(31 downto 0));
                                        			high_register <= std_logic_vector(resize(signed(I_fwd_ex_alu_result) * signed(I_fwd_mem_alu_result),64)(63 downto 32));	
							end if;
                                    		elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_NONE then
							if I_fwd_mem_read = '1' then
                                        			low_register <= std_logic_vector(resize(signed(I_fwd_mem_read_data) * signed(I_rt_data),64)(31 downto 0));
                                        			high_register <= std_logic_vector(resize(signed(I_fwd_mem_read_data) * signed(I_rt_data),64)(63 downto 32));	
							else
                                        			low_register <= std_logic_vector(resize(signed(I_fwd_mem_alu_result) * signed(I_rt_data),64)(31 downto 0));
                                        			high_register <= std_logic_vector(resize(signed(I_fwd_mem_alu_result) * signed(I_rt_data),64)(63 downto 32));	
							end if;
                                    		elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_EX then
							if I_fwd_mem_read = '1' then
                                        			low_register <= std_logic_vector(resize(signed(I_fwd_mem_read_data) * signed(I_fwd_ex_alu_result),64)(31 downto 0));
                                        			high_register <= std_logic_vector(resize(signed(I_fwd_mem_read_data) * signed(I_fwd_ex_alu_result),64)(63 downto 32));	
							else
                                        			low_register <= std_logic_vector(resize(signed(I_fwd_mem_alu_result) * signed(I_fwd_ex_alu_result),64)(31 downto 0));
                                        			high_register <= std_logic_vector(resize(signed(I_fwd_mem_alu_result) * signed(I_fwd_ex_alu_result),64)(63 downto 32));	
							end if;
                                    		end if;
						flush <= '0';

                  	  		when DIV_FUNCT =>
						if I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_NONE then
          		              			low_register <= std_logic_vector(signed(I_rs_data) / signed(I_rt_data));
          		              			high_register <= std_logic_vector(signed(I_rs_data) mod signed(I_rt_data));					
                                    		elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_EX then
          		              			low_register <= std_logic_vector(signed(I_rs_data) / signed(I_fwd_ex_alu_result));
          		              			high_register <= std_logic_vector(signed(I_rs_data) mod signed(I_fwd_ex_alu_result));
                                   		 elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
          		              				low_register <= std_logic_vector(signed(I_rs_data) / signed(I_fwd_mem_read_data));
          		              				high_register <= std_logic_vector(signed(I_rs_data) mod signed(I_fwd_mem_read_data));	
							else
          		              				low_register <= std_logic_vector(signed(I_rs_data) / signed(I_fwd_mem_alu_result));
          		              				high_register <= std_logic_vector(signed(I_rs_data) mod signed(I_fwd_mem_alu_result));	
							end if;
                                    		elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_NONE then
          		              			low_register <= std_logic_vector(signed(I_fwd_ex_alu_result) / signed(I_rt_data));
          		              			high_register <= std_logic_vector(signed(I_fwd_ex_alu_result) mod signed(I_rt_data));	
                                    		elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
          		              				low_register <= std_logic_vector(signed(I_fwd_ex_alu_result) / signed(I_fwd_mem_read_data));
          		              				high_register <= std_logic_vector(signed(I_fwd_ex_alu_result) mod signed(I_fwd_mem_read_data));
							else
          		              				low_register <= std_logic_vector(signed(I_fwd_ex_alu_result) / signed(I_fwd_mem_alu_result));
          		              				high_register <= std_logic_vector(signed(I_fwd_ex_alu_result) mod signed(I_fwd_mem_alu_result));
							end if;
                                    		elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_NONE then
							if I_fwd_mem_read = '1' then
          		              				low_register <= std_logic_vector(signed(I_fwd_mem_read_data) / signed(I_rt_data));
          		              				high_register <= std_logic_vector(signed(I_fwd_mem_read_data) mod signed(I_rt_data));
							else
          		              				low_register <= std_logic_vector(signed(I_fwd_mem_alu_result) / signed(I_rt_data));
          		              				high_register <= std_logic_vector(signed(I_fwd_mem_alu_result) mod signed(I_rt_data));
							end if;
                                    		elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_EX then
							if I_fwd_mem_read = '1' then
          		              				low_register <= std_logic_vector(signed(I_fwd_mem_read_data) / signed(I_fwd_ex_alu_result));
          		              				high_register <= std_logic_vector(signed(I_fwd_mem_read_data) mod signed(I_fwd_ex_alu_result));
							else
          		              				low_register <= std_logic_vector(signed(I_fwd_mem_alu_result) / signed(I_fwd_ex_alu_result));
          		              				high_register <= std_logic_vector(signed(I_fwd_mem_alu_result) mod signed(I_fwd_ex_alu_result));
							end if;
                                    		end if;
                        			flush <= '0';

          	          		when SLT_FUNCT =>
						if I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_NONE then
  		                      			if signed(I_rs_data) < signed(I_rt_data) then
  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
        	                			else
  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
        	                			end if;
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_EX then
  		                      			if signed(I_rs_data) < signed(I_fwd_ex_alu_result) then
  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
        	                			else
  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
        	                			end if;
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
	  		                      			if signed(I_rs_data) < signed(I_fwd_mem_read_data) then
	  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
	        	                			else
	  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
	        	                			end if;
							else
	  		                      			if signed(I_rs_data) < signed(I_fwd_mem_alu_result) then
	  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
	        	                			else
	  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
	        	                			end if;
							end if;
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_NONE then
  		                      			if signed(I_fwd_ex_alu_result) < signed(I_rt_data) then
  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
        	                			else
  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
        	                			end if;
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
	  		                      			if signed(I_fwd_ex_alu_result) < signed(I_fwd_mem_read_data) then
	  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
	        	                			else
	  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
	        	                			end if;
							else
	  		                      			if signed(I_fwd_ex_alu_result) < signed(I_fwd_mem_alu_result) then
	  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
	        	                			else
	  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
	        	                			end if;
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_NONE then
							if I_fwd_mem_read = '1' then
	  		                      			if signed(I_fwd_mem_read_data) < signed(I_rt_data) then
	  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
	        	                			else
	  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
	        	                			end if;
							else
	  		                      			if signed(I_fwd_mem_alu_result) < signed(I_rt_data) then
	  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
	        	                			else
	  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
	        	                			end if;
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_EX then
							if I_fwd_mem_read = '1' then
	  		                      			if signed(I_fwd_mem_read_data) < signed(I_fwd_ex_alu_result) then
	  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
	        	                			else
	  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
	        	                			end if;
							else
	  		                      			if signed(I_fwd_mem_alu_result) < signed(I_fwd_ex_alu_result) then
	  	                          				O_alu_result <= std_logic_vector(to_signed(1,32));
	        	                			else
	  	                          				O_alu_result <= std_logic_vector(to_signed(0,32));
	        	                			end if;
							end if;
                    				end if;
						flush <= '0';

  	                  		-- logical
        	            		when AND_FUNCT =>
						if I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_NONE then
							O_alu_result <= I_rs_data and I_rt_data;
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_EX then
							O_alu_result <= I_rs_data and I_fwd_ex_alu_result;
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
								O_alu_result <= I_rs_data and I_fwd_mem_read_data;
							else
								O_alu_result <= I_rs_data and I_fwd_mem_alu_result;
							end if;
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_NONE then
							O_alu_result <= I_fwd_ex_alu_result and I_rt_data;
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
								O_alu_result <= I_fwd_ex_alu_result and I_fwd_mem_read_data;
							else
								O_alu_result <= I_fwd_ex_alu_result and I_fwd_mem_alu_result;
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_NONE then
							if I_fwd_mem_read = '1' then
								O_alu_result <= I_fwd_mem_read_data and I_rt_data;
							else
								O_alu_result <= I_fwd_mem_alu_result and I_rt_data;
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_EX then
							if I_fwd_mem_read = '1' then
								O_alu_result <= I_fwd_mem_read_data and I_fwd_ex_alu_result;
							else
								O_alu_result <= I_fwd_mem_alu_result and I_fwd_ex_alu_result;
							end if;
                    				end if;
						flush <= '0';

					when OR_FUNCT =>
						if I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_NONE then
							O_alu_result <= I_rs_data or I_rt_data;
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_EX then
							O_alu_result <= I_rs_data or I_fwd_ex_alu_result;
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
								O_alu_result <= I_rs_data or I_fwd_mem_read_data;
							else
								O_alu_result <= I_rs_data or I_fwd_mem_alu_result;
							end if;
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_NONE then
							O_alu_result <= I_fwd_ex_alu_result or I_rt_data;
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
								O_alu_result <= I_fwd_ex_alu_result or I_fwd_mem_read_data;
							else
								O_alu_result <= I_fwd_ex_alu_result or I_fwd_mem_alu_result;
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_NONE then
							if I_fwd_mem_read = '1' then
								O_alu_result <= I_fwd_mem_read_data or I_rt_data;
							else
								O_alu_result <= I_fwd_mem_alu_result or I_rt_data;
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_EX then
							if I_fwd_mem_read = '1' then
								O_alu_result <= I_fwd_mem_read_data or I_fwd_ex_alu_result;
							else
								O_alu_result <= I_fwd_mem_alu_result or I_fwd_ex_alu_result;
							end if;
                    				end if;
  						flush <= '0';
                      
          	          		when NOR_FUNCT =>
						if I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_NONE then
							O_alu_result <= I_rs_data nor I_rt_data;
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_EX then
							O_alu_result <= I_rs_data nor I_fwd_ex_alu_result;
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
								O_alu_result <= I_rs_data nor I_fwd_mem_read_data;
							else
								O_alu_result <= I_rs_data nor I_fwd_mem_alu_result;
							end if;
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_NONE then
							O_alu_result <= I_fwd_ex_alu_result nor I_rt_data;
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
								O_alu_result <= I_fwd_ex_alu_result nor I_fwd_mem_read_data;
							else
								O_alu_result <= I_fwd_ex_alu_result nor I_fwd_mem_alu_result;
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_NONE then
							if I_fwd_mem_read = '1' then
								O_alu_result <= I_fwd_mem_read_data nor I_rt_data;
							else
								O_alu_result <= I_fwd_mem_alu_result nor I_rt_data;
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_EX then
							if I_fwd_mem_read = '1' then
								O_alu_result <= I_fwd_mem_read_data nor I_fwd_ex_alu_result;
							else
								O_alu_result <= I_fwd_mem_alu_result nor I_fwd_ex_alu_result;
							end if;
                    				end if;
						flush <= '0';

  	                  		when XOR_FUNCT =>
						if I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_NONE then
							O_alu_result <= I_rs_data xor I_rt_data;
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_EX then
							O_alu_result <= I_rs_data xor I_fwd_ex_alu_result;
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
								O_alu_result <= I_rs_data xor I_fwd_mem_read_data;
							else
								O_alu_result <= I_rs_data xor I_fwd_mem_alu_result;
							end if;
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_NONE then
							O_alu_result <= I_fwd_ex_alu_result xor I_rt_data;
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
								O_alu_result <= I_fwd_ex_alu_result xor I_fwd_mem_read_data;
							else
								O_alu_result <= I_fwd_ex_alu_result xor I_fwd_mem_alu_result;
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_NONE then
							if I_fwd_mem_read = '1' then
								O_alu_result <= I_fwd_mem_read_data xor I_rt_data;
							else
								O_alu_result <= I_fwd_mem_alu_result xor I_rt_data;
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_EX then
							if I_fwd_mem_read = '1' then
								O_alu_result <= I_fwd_mem_read_data xor I_fwd_ex_alu_result;
							else
								O_alu_result <= I_fwd_mem_alu_result xor I_fwd_ex_alu_result;
							end if;
                    				end if;
						flush <= '0';

        	            		-- transfer
  	                  		when MFHI_FUNCT =>
        	                		O_alu_result <= high_register;
						flush <= '0';

  	                  		when MFLO_FUNCT =>
        	                		O_alu_result <= low_register;
						flush <= '0';

  	                  		-- shift
        	            		when SLL_FUNCT =>
						case I_forward_rt is
						when FORWARDING_NONE =>
							O_alu_result <= std_logic_vector(shift_left(unsigned(I_rt_data), to_integer(unsigned(I_shamt))));
						when FORWARDING_EX =>
							O_alu_result <= std_logic_vector(shift_left(unsigned(I_fwd_ex_alu_result), to_integer(unsigned(I_shamt))));
						when FORWARDING_MEM =>
							if I_fwd_mem_read = '1' then
								O_alu_result <= std_logic_vector(shift_left(unsigned(I_fwd_mem_read_data), to_integer(unsigned(I_shamt))));
							else
								O_alu_result <= std_logic_vector(shift_left(unsigned(I_fwd_mem_alu_result), to_integer(unsigned(I_shamt))));
							end if;
						when others =>
						end case;
						flush <= '0';
  		                      		
  	                  		when SRL_FUNCT =>
						case I_forward_rt is
						when FORWARDING_NONE =>
							O_alu_result <= std_logic_vector(shift_right(unsigned(I_rt_data), to_integer(unsigned(I_shamt))));
						when FORWARDING_EX =>
							O_alu_result <= std_logic_vector(shift_right(unsigned(I_fwd_ex_alu_result), to_integer(unsigned(I_shamt))));
						when FORWARDING_MEM =>
							if I_fwd_mem_read = '1' then
								O_alu_result <= std_logic_vector(shift_right(unsigned(I_fwd_mem_read_data), to_integer(unsigned(I_shamt))));
							else
								O_alu_result <= std_logic_vector(shift_right(unsigned(I_fwd_mem_alu_result), to_integer(unsigned(I_shamt))));
							end if;
						when others =>
						end case;
						flush <= '0';

  	                  		when SRA_FUNCT =>
						case I_forward_rt is
						when FORWARDING_NONE =>
	        	                		O_alu_result <= std_logic_vector(shift_right(signed(I_rt_data), to_integer(unsigned(I_shamt))));
						when FORWARDING_EX =>
							O_alu_result <= std_logic_vector(shift_right(signed(I_fwd_ex_alu_result), to_integer(unsigned(I_shamt))));
						when FORWARDING_MEM =>
							if I_fwd_mem_read = '1' then
								O_alu_result <= std_logic_vector(shift_right(signed(I_fwd_mem_read_data), to_integer(unsigned(I_shamt))));
							else
								O_alu_result <= std_logic_vector(shift_right(signed(I_fwd_mem_alu_result), to_integer(unsigned(I_shamt))));
							end if;
						when others =>
						end case;
						flush <= '0';
                    
  	                  		-- control-flow
        	            		when JR_FUNCT=>
						case I_forward_rs is
						when FORWARDING_NONE =>
	        	                		O_updated_next_pc <= I_rs_data;
						when FORWARDING_EX =>
							O_updated_next_pc <= I_fwd_ex_alu_result;
						when FORWARDING_MEM =>
							if I_fwd_mem_read = '1' then
								O_updated_next_pc <= I_fwd_mem_read_data;
							else
								O_updated_next_pc <= I_fwd_mem_alu_result;
							end if;
						when others =>
						end case;
						flush <= '1';

  	                  		when others =>
        	        		end case;
  	          		else
        	        		case I_opcode is
  	                  		-- arithmetic
        	            		when ADDI_OPCODE =>
						-- SignExtImm
						case I_forward_rs is
						when FORWARDING_NONE =>
  		                      			O_alu_result <= std_logic_vector(signed(I_rs_data) + signed(I_imm_SE));
						when FORWARDING_EX =>
  		                      			O_alu_result <= std_logic_vector(signed(I_fwd_ex_alu_result) + signed(I_imm_SE));
						when FORWARDING_MEM =>
							if I_fwd_mem_read = '1' then
  		                      				O_alu_result <= std_logic_vector(signed(I_fwd_mem_read_data) + signed(I_imm_SE));
							else
  		                      				O_alu_result <= std_logic_vector(signed(I_fwd_mem_alu_result) + signed(I_imm_SE));
							end if;
						when others =>
						end case;
						O_branch <= '0';
 						flush <= '0';
                     
  	                  		when SLTI_OPCODE =>
						-- SignExtImm
						case I_forward_rs is
						when FORWARDING_NONE =>
  		                      			if signed(I_rs_data) < signed(I_imm_SE) then
  		                          			O_alu_result <= std_logic_vector(to_signed(1,32));
  		                      			else
  		                          			O_alu_result <= std_logic_vector(to_signed(0,32));
  		                      			end if;
						when FORWARDING_EX =>
  		                      			if signed(I_fwd_ex_alu_result) < signed(I_imm_SE) then
  		                          			O_alu_result <= std_logic_vector(to_signed(1,32));
  		                      			else
  		                          			O_alu_result <= std_logic_vector(to_signed(0,32));
  		                      			end if;
						when FORWARDING_MEM =>
							if I_fwd_mem_read = '1' then
  		                      				if signed(I_fwd_mem_read_data) < signed(I_imm_SE) then
  		                          				O_alu_result <= std_logic_vector(to_signed(1,32));
  		                      				else
  		                          				O_alu_result <= std_logic_vector(to_signed(0,32));
  		                      				end if;
							else
  		                      				if signed(I_fwd_mem_alu_result) < signed(I_imm_SE) then
  		                          				O_alu_result <= std_logic_vector(to_signed(1,32));
  		                      				else
  		                          				O_alu_result <= std_logic_vector(to_signed(0,32));
  		                      				end if;
							end if;
						when others =>
						end case;
						O_branch <= '0';
						flush <= '0';

  	                  		-- logical
        	            		when ANDI_OPCODE =>
  		                      		-- ZeroExtImm
						case I_forward_rs is
						when FORWARDING_NONE =>
  		                      			O_alu_result <= I_rs_data and I_imm_ZE;
						when FORWARDING_EX =>
  		                      			O_alu_result <= I_fwd_ex_alu_result and I_imm_ZE;
						when FORWARDING_MEM =>
							if I_fwd_mem_read = '1' then
  		                      				O_alu_result <= I_fwd_mem_read_data and I_imm_ZE;
							else
  		                      				O_alu_result <= I_fwd_mem_alu_result and I_imm_ZE;
							end if;
						when others =>
						end case;
						O_branch <= '0';
						flush <= '0';
  		                      		
  	                  		when ORI_OPCODE =>
  		                      		-- ZeroExtImm
						case I_forward_rs is
						when FORWARDING_NONE =>
  		                      			O_alu_result <= I_rs_data or I_imm_ZE;
						when FORWARDING_EX =>
  		                      			O_alu_result <= I_fwd_ex_alu_result or I_imm_ZE;
						when FORWARDING_MEM =>
							if I_fwd_mem_read = '1' then
  		                      				O_alu_result <= I_fwd_mem_read_data or I_imm_ZE;
							else
  		                      				O_alu_result <= I_fwd_mem_alu_result or I_imm_ZE;
							end if;
						when others =>
						end case;
						O_branch <= '0';
						flush <= '0';

  	                  		when XORI_OPCODE =>
  		                      		-- ZeroExtImm
						case I_forward_rs is
						when FORWARDING_NONE =>
  		                      			O_alu_result <= I_rs_data xor I_imm_ZE;
						when FORWARDING_EX =>
  		                      			O_alu_result <= I_fwd_ex_alu_result xor I_imm_ZE;
						when FORWARDING_MEM =>
							if I_fwd_mem_read = '1' then
  		                      				O_alu_result <= I_fwd_mem_read_data xor I_imm_ZE;
							else
  		                      				O_alu_result <= I_fwd_mem_alu_result xor I_imm_ZE;
							end if;
						when others =>
						end case;
						O_branch <= '0';
						flush <= '0';

  	                  		-- transfer
        	            		when LUI_OPCODE =>
  		                      		-- load immediate value into 16 upper bits of rt register
  		                      		O_alu_result <= I_imm_ZE(15 downto 0) & std_logic_vector(to_unsigned(0,16));
						O_branch <= '0';
						flush <= '0';

  	                  		-- memory
        	            		when LW_OPCODE | SW_OPCODE=>
						case I_forward_rs is
						when FORWARDING_NONE =>
  		                      			O_alu_result <= std_logic_vector(signed(I_rs_data) + signed(I_imm_SE));
						when FORWARDING_EX =>
  		                      			O_alu_result <= std_logic_vector(signed(I_fwd_ex_alu_result) + signed(I_imm_SE));
						when FORWARDING_MEM =>
							if I_fwd_mem_read = '1' then
								O_alu_result <= std_logic_vector(signed(I_fwd_mem_read_data) + signed(I_imm_SE));
							else
								O_alu_result <= std_logic_vector(signed(I_fwd_mem_alu_result) + signed(I_imm_SE));
							end if;  		              
						when others =>
						end case;
						O_branch <= '0';
						flush <= '0';
  		                      		                    
  	                  		-- control-flow
        	            		when BEQ_OPCODE=>
						if I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_NONE then
  		                      			if I_rs_data = I_rt_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                				O_branch <= '1';
								flush <= '1';
							else
  	                          				O_updated_next_pc <= I_next_pc;
        	                				O_branch <= '0';
								flush <= '0';

        	                			end if;
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_EX then
  		                      			if I_rs_data = I_fwd_ex_alu_result then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                				O_branch <= '1';
								flush <= '1';
        	                			else
  	                          				O_updated_next_pc <= I_next_pc;
        	                				O_branch <= '0';
								flush <= '0';
			
        	                			end if;
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
	  		                      			if I_rs_data = I_fwd_mem_read_data then
	  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));  	                          				
	        	                				O_branch <= '1';
									flush <= '1';
								else
									O_updated_next_pc <= I_next_pc;
	        	                				O_branch <= '0';
									flush <= '0';
	        	                			end if;
							else
	  		                      			if I_rs_data = I_fwd_mem_alu_result then
	  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));  	                          				
	        	                				O_branch <= '1';
									flush <= '1';
								else
									O_updated_next_pc <= I_next_pc;
	        	                				O_branch <= '0';
									flush <= '0';
	        	                			end if;
							end if;
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_NONE then
  		                      			if I_fwd_ex_alu_result = I_rt_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                				O_branch <= '1';
								flush <= '1';
        	                			else
  	                          				O_updated_next_pc <= I_next_pc;
        	                				O_branch <= '0';
								flush <= '0';
        	                			end if;
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
	  		                      			if I_fwd_ex_alu_result = I_fwd_mem_read_data then
	  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
	        	                			    	O_branch <= '1';
									flush <= '1';
								else
	  	                          				O_updated_next_pc <= I_next_pc;
	        	                				O_branch <= '0';
									flush <= '0';
	        	                			end if;
							else
	  		                      			if I_fwd_ex_alu_result = I_fwd_mem_alu_result then
	  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
	        	                			    	O_branch <= '1';
									flush <= '1';
								else
	  	                          				O_updated_next_pc <= I_next_pc;
	        	                				O_branch <= '0';
									flush <= '0';
	        	                			end if;
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_NONE then
							if I_fwd_mem_read = '1' then
	  		                      			if I_fwd_mem_read_data = I_rt_data then
	  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
	        	                				O_branch <= '1';
									flush <= '1';
	        	                			else
	  	                          				O_updated_next_pc <= I_next_pc;
	        	                				O_branch <= '0';
									flush <= '0';
	        	                			end if;
							else
	  		                      			if I_fwd_mem_alu_result = I_rt_data then
	  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
	        	                				O_branch <= '1';
									flush <= '1';
	        	                			else
	  	                          				O_updated_next_pc <= I_next_pc;
	        	                				O_branch <= '0';
									flush <= '0';
	        	                			end if;
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_EX then
							if I_fwd_mem_read = '1' then
	  		                      			if I_fwd_mem_read_data = I_fwd_ex_alu_result then
	  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
	        	                				O_branch <= '1';
									flush <= '1';
	        	                			else
	  	                          				O_updated_next_pc <= I_next_pc;
	        	                				O_branch <= '0';
									flush <= '0';
	        	                			end if;
							else
	  		                      			if I_fwd_mem_alu_result = I_fwd_ex_alu_result then
	  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
	        	                				O_branch <= '1';
									flush <= '1';
	        	                			else
	  	                          				O_updated_next_pc <= I_next_pc;
	        	                				O_branch <= '0';
									flush <= '0';
	        	                			end if;
							end if;
                    				end if;
  	                  		when BNE_OPCODE=>
						if I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_NONE then
  		                      			if I_rs_data /= I_rt_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                				O_branch <= '1';
								flush <= '1';
        	                			else
  	                          				O_updated_next_pc <= I_next_pc;
        	                				O_branch <= '0';
								flush <= '0';
        	                			end if;
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_EX then
  		                      			if I_rs_data /= I_rt_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                				O_branch <= '1';
								flush <= '1';
        	                			else
  	                          				O_updated_next_pc <= I_next_pc;
        	                				O_branch <= '0';
								flush <= '0';
        	                			end if;
						elsif I_forward_rs = FORWARDING_NONE and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
	  		                      			if I_rs_data /= I_rt_data then
	  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
	        	                				O_branch <= '1';
									flush <= '1';
	        	                			else
	  	                          				O_updated_next_pc <= I_next_pc;
	        	                				O_branch <= '0';
									flush <= '0';
	        	                			end if;
							else
	  		                      			if I_rs_data /= I_rt_data then
	  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
	        	                				O_branch <= '1';
									flush <= '1';
	        	                			else
	  	                          				O_updated_next_pc <= I_next_pc;
	        	                				O_branch <= '0';
									flush <= '0';
	        	                			end if;
							end if;
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_NONE then
  		                      			if I_rs_data /= I_rt_data then
  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
        	                				O_branch <= '1';
								flush <= '1';
        	                			else
  	                          				O_updated_next_pc <= I_next_pc;
        	                				O_branch <= '0';
								flush <= '0';
        	                			end if;
						elsif I_forward_rs = FORWARDING_EX and I_forward_rt = FORWARDING_MEM then
							if I_fwd_mem_read = '1' then
	  		                      			if I_rs_data /= I_rt_data then
	  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
	        	                				O_branch <= '1';
									flush <= '1';
	        	                			else
	  	                          				O_updated_next_pc <= I_next_pc;
	        	                				O_branch <= '0';
									flush <= '0';
	        	                			end if;
							else
	  		                      			if I_rs_data /= I_rt_data then
	  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
	        	                				O_branch <= '1';
									flush <= '1';
	        	                			else
	  	                          				O_updated_next_pc <= I_next_pc;
	        	                				O_branch <= '0';
									flush <= '0';
	        	                			end if;
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_NONE then
							if I_fwd_mem_read = '1' then
	  		                      			if I_rs_data /= I_rt_data then
	  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
	        	                				O_branch <= '1';
									flush <= '1';
	        	                			else
	  	                          				O_updated_next_pc <= I_next_pc;
	        	                				O_branch <= '0';
									flush <= '0';
	        	                			end if;
							else
	  		                      			if I_rs_data /= I_rt_data then
	  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
	        	                				O_branch <= '1';
									flush <= '1';
	        	                			else
	  	                          				O_updated_next_pc <= I_next_pc;
	        	                				O_branch <= '0';
									flush <= '0';
	        	                			end if;
							end if;
						elsif I_forward_rs = FORWARDING_MEM and I_forward_rt = FORWARDING_EX then
							if I_fwd_mem_read = '1' then
	  		                      			if I_rs_data /= I_rt_data then
	  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
	        	                				O_branch <= '1';
									flush <= '1';
	        	                			else
	  	                          				O_updated_next_pc <= I_next_pc;
	        	                				O_branch <= '0';
									flush <= '0';
	        	                			end if;
							else
	  		                      			if I_rs_data /= I_rt_data then
	  	                          				O_updated_next_pc <= std_logic_vector(signed(I_next_pc) + signed(I_imm_SE(29 downto 0) & "00"));
	        	                				O_branch <= '1';
									flush <= '1';
	        	                			else
	  	                          				O_updated_next_pc <= I_next_pc;
	        	                				O_branch <= '0';
									flush <= '0';
	        	                			end if;
							end if;
                    				end if;
					when J_OPCODE=>
        	                		O_updated_next_pc <= I_next_pc(31 downto 28) & I_addr & "00";
						flush <= '1';
	
        	            		when JAL_OPCODE=>
  		                      		O_alu_result <= std_logic_vector(signed(I_next_pc) + to_signed(4,32));
  		                      		O_updated_next_pc <= I_next_pc(31 downto 28) & I_addr & "00";
						flush <= '1';
  	                  		when others =>
        	        		end case;
				end if;
			end if;
			end if;
		end if;
	end process;
end arch;
	
