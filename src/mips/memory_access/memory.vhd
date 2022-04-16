-- ECSE425 W2022
-- Final Project, Group 07
-- Memory Access Stage

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
generic(
	ram_size : INTEGER := 32768
);

port(
	I_clk : in std_logic;
	I_reset : in std_logic;
	I_en : in std_logic;
	
	
	-- Control Signals Inputs
	I_rd: in std_logic_vector (4 downto 0); 			-- the destination register where to write the instr. result
	I_branch: in std_logic; 					-- indicates if its is a branch operation (beq, bne)
	I_jump: in std_logic; 						-- indicates if it is a jump instruction (j, jr, jal)
	I_mem_read: in std_logic; 					-- indicates if a value must be read from memory at calculated address
	I_mem_write: in std_logic; 					-- indicates if value in I_rt_data must be written in memory at calculated address
	I_reg_write: in std_logic; 					-- indicates if value calculated in ALU must be written to destination register
	
	-- instruction: in std_logic_vector (31 downto 0); -- instruction opcode
	I_rt_data: in std_logic_vector (31 downto 0); -- the data that needs to be written
	I_alu_result: in std_logic_vector (31 downto 0); -- connected to alu_result in execute, holds address to send data to. If not a load/store, simply passes data forward
	I_stall: in std_logic;
	
	
	-- data_memory relevant signals
	I_data_waitrequest: in std_logic;
	O_data_address: out integer range 0 to ram_size-1;
	O_data_memread: out std_logic;
	O_data_writedata: out std_logic_vector(31 downto 0);
	O_data_memwrite: out std_logic;
	-- data_readdata: in std_logic_vector(31 downto 0);
	
	-- Control Signals Outputs
	O_rd: out std_logic_vector (4 downto 0); 			-- the destination register where to write the instr. result
	O_branch: out std_logic; 					-- indicates if its is a branch operation (beq, bne)
	O_jump: out std_logic; 						-- indicates if it is a jump instruction (j, jr, jal)
	O_mem_read: out std_logic; 					-- indicates if a value must be read from memory at calculated address
	O_mem_write: out std_logic; 					-- indicates if value in I_rt_data must be written in memory at calculated address
	O_reg_write: out std_logic; 					-- indicates if value calculated in ALU must be written to destination register
	
	O_alu_result: out std_logic_vector(31 downto 0);
	O_stall: out std_logic
);
end memory;

architecture arch of memory is
-- dump signals here

begin

-- actual logic here

-- check if opcode matches LW or SW
-- if it does, do memory stuff
-- otherwise, just send stuff along

	memory_process: process(I_clk,I_reset)
	begin
	
		-- asynchronous reset active high
		if I_reset'event and I_reset = '1' then
			O_rd <= (others=>'0');
			O_branch <= '0';
			O_jump <= '0';
			O_mem_read <= '0';
			O_mem_write <= '0';
			O_reg_write <= '0';
			O_alu_result <= (others =>'0');
			O_stall <= '0';
			
		-- synchronous clock active high
		elsif I_clk'event and I_clk = '1' then
			if I_en = '1' then
				-- check opcode
				
				-- check for stall
				if I_stall = '1' then
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
					O_jump <= I_jump;

					
					
					-- check if I_mem_read is high, and performs a read operation
					if I_mem_read = '1' then
						-- fetch data from address I_alu_result
						O_data_address <= to_integer(unsigned(std_logic_vector(I_alu_result)));
						O_data_memread <= '1';
						O_data_memwrite <= '0';

					-- check if I_mem_write is high, and performs a write operation
					elsif I_mem_write = '1' then
						-- write I_rt_data to address I_alu_result
						O_data_address <= to_integer(unsigned(std_logic_vector(I_alu_result)));
						O_data_writedata <= I_rt_data;
						O_data_memwrite <= '1';
						O_data_memread <= '0';

					-- otherwise, simply passes stuff forward
					else
					O_alu_result <= I_alu_result;
					O_data_memread <= '0';
					O_data_memwrite <= '0';
					-- end memread/write check
					end if;
				-- end stall = 1
				end if;
			-- end I_en = 1
			end if;
		-- end clock rising edge
		end if;
		
	end process;

end arch;
