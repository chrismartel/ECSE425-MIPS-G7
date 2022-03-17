library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity execute is

port(
	-- INPUTS (from ID stage)
	clk : in std_logic;
	reset : in std_logic;

	instruction: in std_logic_vector (31 downto 0);
	rs_data_in: in std_logic_vector (31 downto 0);
	rt_data_in: in std_logic_vector (31 downto 0);
	next_pc: in std_logic_vector (31 downto 0); -- pc + 4

	-- control signals (passed from decode stage to wb stage)
	rd_in: in std_logic_vector (4 downto 0); 			-- the destination register where to write the instr. result
	branch_in: in std_logic; 					-- indicates if its is a branch operation (beq, bne)
	jump_in: in std_logic; 						-- indicates if it is a jump instruction (j, jr, jal)
	mem_read_in: in std_logic; 					-- indicates if a value must be read from memory at calculated address
	mem_write_in: in std_logic; 					-- indicates if value in rt_data_in must be written in memory at calculated address
	reg_write_in: in std_logic; 					-- indicates if value calculated in ALU must be written to destination register
	mem_to_reg_in: in std_logic; 					-- indicates if value loaded from memory must be writte to destination register

	-- OUTPUTS (To MEM stage)
	alu_result: out std_logic_vector (31 downto 0); 		-- ** connect to prev_alu_result for forwarding puproses
	updated_pc: out std_logic_vector (31 downto 0);
	rt_data_out: out std_logic_vector (31 downto 0);

	-- control signals
	rd_out: out std_logic_vector (4 downto 0); -- ** connect to ex_rd input of forwarding unit
	branch_out: out std_logic;
	jump_out: out std_logic;
	mem_read_out: out std_logic;
	mem_write_out: out std_logic;
	reg_write_out: out std_logic; 				-- ** connect to ex_reg_write input of forwarding unit
	mem_to_reg_out: out std_logic;

	-- FORWARDING (from forwarding unit)
	ex_data: in std_logic_vector(31 downto 0); 	-- current output data of ex stage
	mem_data: in std_logic_vector(31 downto 0); 		-- current output data of mem stage
	
	-- forwarding control bits
	-- "00": take input from ID stage
	-- "01": take input from EX stage
	-- "10": take input from MEM stage
	forward_rs: in std_logic_vector(1 downto 0);		-- forwarding control bits of rs register
	forward_rt: in std_logic_vector(1 downto 0)		-- forwarding control bits of rt register
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
	signal forward_rs_data : std_logic_vector (31 downto 0); 
	signal forward_rt_data : std_logic_vector (31 downto 0);
begin
-- make circuits here
	
	-- fowarding operands data asynchronously
	forward_process: process(forward_rs, forward_rt, reset)
	begin
		if reset'event and reset = '1' then
			forward_rs_data <= (others=>'0');
			forward_rt_data <= (others=>'0');

		else
			-- rs operand forwarding
			if forward_rs'event then
				case forward_rs is
				when "00" =>
					forward_rs_data <= rs_data_in;
				when "01" =>
					forward_rs_data <= ex_data;
				when "10" =>
					forward_rs_data <= mem_data;
				when others =>
				end case;
			end if;
			
			-- rt operand forwarding
			if forward_rt'event then
			-- rt input
			case forward_rt is
				when "00" =>
					forward_rt_data <= rt_data_in;
				when "01" =>
					forward_rt_data <= ex_data;
				when "10" =>
					forward_rt_data <= mem_data;
				when others =>
				end case;
			end if;
		end if;
	end process;

	-- execution stage process
	execute_process: process(clk, reset)
	begin
		-- asynchronous reset active high
		if reset'event and reset = '1' then
			alu_result <= (others=>'0');
			updated_pc <= (others=>'0');
			rt_data_out <= (others=>'0');
			high_register <= (others=>'0');
			low_register <= (others=>'0');
			
			rd_out <= (others=>'0');
			mem_read_out <= '0';
			mem_write_out <= '0';
			branch_out <= '0';
			reg_write_out <= '0';
			mem_to_reg_out <= '0';
			jump_out <= '0';
			
		-- synchronous clock active high
		elsif clk'event and clk = '1' then

			-- pass control signals to next stage
			rd_out <= rd_in;
			mem_read_out <= mem_read_in;
			mem_write_out <= mem_write_in;
			branch_out <= branch_in;
			reg_write_out <= reg_write_in;
			mem_to_reg_out <= mem_to_reg_in;

			-- ALU results
			if instruction(31 downto 26) = "000000" then
                		case instruction(5 downto 0) is -- check functional bits for R type instructions
                    		-- arithmetic
                    		when ADD_FUNCT =>
                        		alu_result <= std_logic_vector(signed(forward_rs_data) + signed(forward_rt_data));
                        
                    		when SUB_FUNCT =>
                        		alu_result <= std_logic_vector(signed(forward_rs_data) - signed(forward_rt_data));

                    		when MULT_FUNCT =>
                        		low_register <= std_logic_vector(resize(signed(forward_rs_data) * signed(forward_rt_data),64)(31 downto 0));
                        		high_register <= std_logic_vector(resize(signed(forward_rs_data) * signed(forward_rt_data),64)(63 downto 32));

                    		when DIV_FUNCT =>
                        		low_register <= std_logic_vector(signed(forward_rs_data) / signed(forward_rt_data));
                        		high_register <= std_logic_vector(signed(forward_rs_data) mod signed(forward_rt_data));
                        
                    		when SLT_FUNCT =>
                        		if signed(forward_rs_data) < signed(forward_rt_data) then
                            			alu_result <= std_logic_vector(to_signed(1,32));
                        		else
                            			alu_result <= std_logic_vector(to_signed(0,32));
                        		end if;

                    		-- logical
                    		when AND_FUNCT =>
                        		alu_result <= forward_rs_data and forward_rt_data;
				when OR_FUNCT =>
                        		alu_result <= forward_rs_data or forward_rt_data;
                        
                    		when NOR_FUNCT =>
                        		alu_result <= forward_rs_data nor forward_rt_data;

                    		when XOR_FUNCT =>
                        		alu_result <= forward_rs_data xor forward_rt_data;

                    		-- transfer
                    		when MFHI_FUNCT =>
                        		alu_result <= high_register;

                    		when MFLO_FUNCT =>
                        		alu_result <= low_register;

                    		-- shift
                    		when SLL_FUNCT =>
                        		alu_result <= std_logic_vector(shift_left(unsigned(forward_rt_data), to_integer(unsigned(instruction(10 downto 6)))));

                    		when SRL_FUNCT =>
                        		alu_result <= std_logic_vector(shift_right(unsigned(forward_rt_data), to_integer(unsigned(instruction(10 downto 6)))));

                    		when SRA_FUNCT =>
                        		alu_result <= std_logic_vector(shift_right(signed(forward_rt_data), to_integer(unsigned(instruction(10 downto 6)))));
                    
                    		-- control-flow
                    		when JR_FUNCT=>
                        		updated_pc <= forward_rs_data;

                    		when others =>
                		end case;
            		else
                		case instruction(31 downto 26) is
                    		-- arithmetic
                    		when ADDI_OPCODE =>
                        		-- SignExtImm
                        		alu_result <= std_logic_vector(signed(forward_rs_data) + resize(signed(instruction(15 downto 0)),32));
                        
                    		when SLTI_OPCODE =>
                        		-- SignExtImm
                        		if signed(forward_rs_data) < signed(instruction(15 downto 0)) then
                            		alu_result <= std_logic_vector(to_signed(1,32));
                        		else
                            		alu_result <= std_logic_vector(to_signed(0,32));
                        		end if;

                    		-- logical
                    		when ANDI_OPCODE =>
                        		-- ZeroExtImm
                        		alu_result <= forward_rs_data and std_logic_vector(resize(unsigned(instruction(15 downto 0)),32));

                    		when ORI_OPCODE =>
                        		-- ZeroExtImm
                        		alu_result <= forward_rs_data or std_logic_vector(resize(unsigned(instruction(15 downto 0)),32));

                    		when XORI_OPCODE =>
                        		-- ZeroExtImm
                        		alu_result <= forward_rs_data xor std_logic_vector(resize(unsigned(instruction(15 downto 0)),32));

                    		-- transfer
                    		when LUI_OPCODE =>
                        		-- load immediate value into 16 upper bits of rt register
                        		alu_result <= instruction(15 downto 0) & std_logic_vector(to_unsigned(0,16));

                    		-- memory
                    		when LW_OPCODE | SW_OPCODE=>
                        		alu_result <= std_logic_vector(to_signed(to_integer(signed(forward_rs_data)) + to_integer(signed(instruction(15 downto 0))),32));
                    
                    		-- control-flow
                    		when BEQ_OPCODE=>
                        		if forward_rs_data = forward_rt_data then
                            			updated_pc <= std_logic_vector(signed(next_pc) + resize(signed(instruction(15 downto 0) & "00"),32));
                        		--else
                            			--updated_pc <= pc;
                        		end if;
                    		when BNE_OPCODE=>
                        		if forward_rs_data /= forward_rt_data then
                            			updated_pc <= std_logic_vector(signed(next_pc) + resize(signed(instruction(15 downto 0) & "00"),32));
                        		--else
                            			--updated_pc <= pc;
                        		end if;
                    		when J_OPCODE=>
                        		updated_pc <= next_pc(31 downto 28) & instruction(25 downto 0) & "00";

                    		when JAL_OPCODE=>
                        		alu_result <= std_logic_vector(signed(next_pc) + shift_left(to_signed(4,32),2));
                        		updated_pc <= next_pc(31 downto 28) & instruction(25 downto 0) & "00";
                    		when others =>
                		end case;
			end if;
		end if;
	end process;
end arch;
	