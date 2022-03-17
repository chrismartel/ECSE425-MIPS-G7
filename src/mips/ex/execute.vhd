library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity execute is

port(
	-- INPUTS
	clk : in std_logic;
	reset : in std_logic;

	instruction: in std_logic_vector (31 downto 0);
	rs_data_in: in std_logic_vector (31 downto 0);
	rt_data_in: in std_logic_vector (31 downto 0);
	next_pc: in std_logic_vector (31 downto 0); -- pc + 4

	-- control signals (passed from decode stage to wb stage)
	destination_register_in: in std_logic_vector (4 downto 0); 	-- the destination register where to write the instr. result
	branch_in: in std_logic; 					-- indicates if its is a branch operation (beq, bne)
	jump_in: in std_logic; 						-- indicates if it is a jump instruction (j, jr, jal)
	mem_read_in: in std_logic; 					-- indicates if a value must be read from memory at calculated address
	mem_write_in: in std_logic; 					-- indicates if value in rt_data_in must be written in memory at calculated address
	reg_write_in: in std_logic; 					-- indicates if value calculated in ALU must be written to destination register
	mem_to_reg_in: in std_logic; 					-- indicates if value loaded from memory must be writte to destination register

	-- OUTPUTS
	alu_result: out std_logic_vector (31 downto 0);
	updated_pc: out std_logic_vector (31 downto 0);
	rt_data_out: out std_logic_vector (31 downto 0);

	-- control signals
	destination_register_out: out std_logic_vector (4 downto 0);
	branch_out: out std_logic;
	jump_out: out std_logic;
	mem_read_out: out std_logic;
	mem_write_out: out std_logic;
	reg_write_out: out std_logic;
	mem_to_reg_out: out std_logic
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
begin
-- make circuits here
	
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
			
			destination_register_out <= (others=>'0');
			mem_read_out <= '0';
			mem_write_out <= '0';
			branch_out <= '0';
			reg_write_out <= '0';
			mem_to_reg_out <= '0';
			jump_out <= '0';
			
		-- synchronous clock active high
		elsif clk'event and clk = '1' then

			-- pass control signals to next stage
			destination_register_out <= destination_register_in;
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
                        		alu_result <= std_logic_vector(signed(rs_data_in) + signed(rt_data_in));
                        
                    		when SUB_FUNCT =>
                        		alu_result <= std_logic_vector(signed(rs_data_in) - signed(rt_data_in));

                    		when MULT_FUNCT =>
                        		low_register <= std_logic_vector(resize(signed(rs_data_in) * signed(rt_data_in),64)(31 downto 0));
                        		high_register <= std_logic_vector(resize(signed(rs_data_in) * signed(rt_data_in),64)(63 downto 32));

                    		when DIV_FUNCT =>
                        		low_register <= std_logic_vector(signed(rs_data_in) / signed(rt_data_in));
                        		high_register <= std_logic_vector(signed(rs_data_in) mod signed(rt_data_in));
                        
                    		when SLT_FUNCT =>
                        		if signed(rs_data_in) < signed(rt_data_in) then
                            			alu_result <= std_logic_vector(to_signed(1,32));
                        		else
                            			alu_result <= std_logic_vector(to_signed(0,32));
                        		end if;

                    		-- logical
                    		when AND_FUNCT =>
                        		alu_result <= rs_data_in and rt_data_in;

                    		when OR_FUNCT =>
                        		alu_result <= rs_data_in or rt_data_in;
                        
                    		when NOR_FUNCT =>
                        		alu_result <= rs_data_in nor rt_data_in;

                    		when XOR_FUNCT =>
                        		alu_result <= rs_data_in xor rt_data_in;

                    		-- transfer
                    		when MFHI_FUNCT =>
                        		alu_result <= high_register;

                    		when MFLO_FUNCT =>
                        		alu_result <= low_register;

                    		-- shift
                    		when SLL_FUNCT =>
                        		alu_result <= std_logic_vector(shift_left(unsigned(rt_data_in), to_integer(unsigned(instruction(10 downto 6)))));

                    		when SRL_FUNCT =>
                        		alu_result <= std_logic_vector(shift_right(unsigned(rt_data_in), to_integer(unsigned(instruction(10 downto 6)))));

                    		when SRA_FUNCT =>
                        		alu_result <= std_logic_vector(shift_right(signed(rt_data_in), to_integer(unsigned(instruction(10 downto 6)))));
                    
                    		-- control-flow
                    		when JR_FUNCT=>
                        		updated_pc <= rs_data_in;

                    		when others =>
                		end case;
            		else
                		case instruction(31 downto 26) is
                    		-- arithmetic
                    		when ADDI_OPCODE =>
                        		-- SignExtImm
                        		alu_result <= std_logic_vector(signed(rs_data_in) + resize(signed(instruction(15 downto 0)),32));
                        
                    		when SLTI_OPCODE =>
                        		-- SignExtImm
                        		if signed(rs_data_in) < signed(instruction(15 downto 0)) then
                            		alu_result <= std_logic_vector(to_signed(1,32));
                        		else
                            		alu_result <= std_logic_vector(to_signed(0,32));
                        		end if;

                    		-- logical
                    		when ANDI_OPCODE =>
                        		-- ZeroExtImm
                        		alu_result <= rs_data_in and std_logic_vector(resize(unsigned(instruction(15 downto 0)),32));

                    		when ORI_OPCODE =>
                        		-- ZeroExtImm
                        		alu_result <= rs_data_in or std_logic_vector(resize(unsigned(instruction(15 downto 0)),32));

                    		when XORI_OPCODE =>
                        		-- ZeroExtImm
                        		alu_result <= rs_data_in xor std_logic_vector(resize(unsigned(instruction(15 downto 0)),32));

                    		-- transfer
                    		when LUI_OPCODE =>
                        		-- load immediate value into 16 upper bits of rt register
                        		alu_result <= instruction(15 downto 0) & std_logic_vector(to_unsigned(0,16));

                    		-- memory
                    		when LW_OPCODE | SW_OPCODE=>
                        		alu_result <= std_logic_vector(to_signed(to_integer(signed(rs_data_in)) + to_integer(signed(instruction(15 downto 0))),32));
                    
                    		-- control-flow
                    		when BEQ_OPCODE=>
                        		if rs_data_in = rt_data_in then
                            			updated_pc <= std_logic_vector(signed(next_pc) + resize(signed(instruction(15 downto 0) & "00"),32));
                        		--else
                            			--updated_pc <= pc;
                        		end if;
                    		when BNE_OPCODE=>
                        		if rs_data_in /= rt_data_in then
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
	