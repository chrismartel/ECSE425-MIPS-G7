LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;                                

ENTITY write_back_tb IS
END write_back_tb;
ARCHITECTURE write_back_arch OF write_back_tb IS
-- constants                                                 
-- signals                                                   
SIGNAL I_alu : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL I_branch : STD_LOGIC;
SIGNAL I_clk : STD_LOGIC;
SIGNAL I_en : STD_LOGIC := '0';
SIGNAL I_jump : STD_LOGIC;
SIGNAL I_mem : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL I_mem_read : STD_LOGIC;
SIGNAL I_rd : STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL I_regDwe : STD_LOGIC;
SIGNAL I_reset : STD_LOGIC;
SIGNAL I_stall : std_logic;
SIGNAL I_datad : STD_LOGIC_VECTOR (31 downto 0);
SIGNAL I_rt :  STD_LOGIC_VECTOR (4 downto 0);
SIGNAL I_rs :  STD_LOGIC_VECTOR (4 downto 0);
SIGNAL I_we : STD_LOGIC;
SIGNAL O_mux : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL O_rd : STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL O_we : STD_LOGIC;
SIGNAL O_datas :  STD_LOGIC_VECTOR (31 downto 0);
SIGNAL O_datat :  STD_LOGIC_VECTOR (31 downto 0);

COMPONENT write_back
	PORT (
	I_alu : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	I_branch : IN STD_LOGIC;
	I_clk : IN STD_LOGIC;
	I_en : IN STD_LOGIC;
	I_jump : IN STD_LOGIC;
	I_mem : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	I_mem_read : IN STD_LOGIC;
	I_rd : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
	I_regDwe : IN STD_LOGIC;
	I_reset : IN STD_LOGIC;
	I_stall : in std_logic;
	O_mux : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	O_rd : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
	O_we : OUT STD_LOGIC
	);
END COMPONENT;
COMPONENT regs
	PORT (
	I_clk : in  STD_LOGIC;
   I_reset : in STD_LOGIC;
   I_en : in  STD_LOGIC;
   I_datad : in  STD_LOGIC_VECTOR (31 downto 0);
   I_rt : in  STD_LOGIC_VECTOR (4 downto 0);
   I_rs : in  STD_LOGIC_VECTOR (4 downto 0);
   I_rd : in  STD_LOGIC_VECTOR (4 downto 0);
   I_we : in  STD_LOGIC;
   O_datas : out  STD_LOGIC_VECTOR (31 downto 0);
   O_datat : out  STD_LOGIC_VECTOR (31 downto 0)
	);
END COMPONENT;
CONSTANT clk_period : time := 1 ns;
BEGIN
	i1 : write_back
	PORT MAP (
-- list connections between master ports and signals
	I_alu => I_alu,
	I_branch => I_branch,
	I_clk => I_clk,
	I_en => I_en,
	I_jump => I_jump,
	I_mem => I_mem,
	I_mem_read => I_mem_read,
	I_rd => I_rd,
	I_regDwe => I_regDwe,
	I_reset => I_reset,
	I_stall => I_stall,
	O_mux => O_mux,
	O_rd => O_rd,
	O_we => O_we
	);
	
	i2 : regs
	PORT MAP (
-- list connections between master ports and signals
	I_clk => I_clk,
	I_en => I_en,
	I_reset => I_reset,
	I_datad => I_datad,
	I_rt => I_rt,
	I_rs => I_rs,
	I_rd => I_rd,
	I_we => I_we,
	O_datas => O_datas,
	O_datat => O_datat
	);
clk_process : PROCESS
BEGIN
	I_clk <= '0';
	WAIT FOR clk_period/2;
	I_clk <= '1';
	WAIT FOR clk_period/2;
END PROCESS;
init : PROCESS                                               
-- variable declarations                                     
BEGIN                
	I_en <= '1';                                        
        -- code that executes only once                      
	I_reset <= '1';
	I_jump <= '0';
	I_branch <= '0';
	I_stall <= '0';

	WAIT FOR clk_period;
	I_reset <= '0';
	I_en <= '0';
	WAIT FOR clk_period;
	
	report "Test 1";
	I_en <= '1';
	I_regDwe <= '1';
	I_mem_read <= '0';
	I_alu <= "11111111111111111111111111111111";
	I_mem <= "00000000000000000000000000000001";
	I_rd <= "00001";
	
	WAIT FOR clk_period;
	assert (O_mux = I_alu) report "Test 1: O_mux != I_alu" severity error;

	WAIT FOR clk_period;
	
	report "Test 2";
	I_datad <= I_alu;
	I_rs <= I_rd;
	I_we <= '1';
	WAIT FOR clk_period;
	assert (O_mux = O_datas) report "Test 2: O_mux != O_datas" severity error;


	report "Test 3";
	WAIT FOR clk_period;
	report "Test 3";
	I_jump <= '1';
	WAIT FOR clk_period;
	assert (O_mux = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX") report "Test 3 Jump: O_mux != Reset Value" severity error;
	I_jump <= '0';

	WAIT FOR clk_period;

	report "Test 4";
	I_en <= '1';
	I_regDwe <= '1';
	I_mem_read <= '1';
	I_rd <= "00010";
	WAIT FOR clk_period;
	assert (O_mux = I_mem) report "Test 4: O_mux != I_mem" severity error;

	
	report "Test 5";
	WAIT FOR clk_period;
	I_datad <= I_mem;
	I_rs <= I_rd;
	I_we <= '1';
	WAIT FOR clk_period;
	assert (O_mux = O_datas) report "Test 5: O_mux != O_datas" severity error;
	WAIT FOR clk_period;

	report "Test 6";
	I_branch <= '1';
	WAIT FOR clk_period;
	assert (O_mux = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX") report "Test 6 Branch: O_mux != Reset Value" severity error;
	I_branch <= '0';
	WAIT FOR clk_period;
	
	report "Test 7";
	I_regDwe <= '0';
	I_mem_read <= '1';
	I_rd <= "00011";
	WAIT FOR clk_period;
	assert (O_mux = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX") report "Test 7: O_mux != Invalid input" severity error;
	wait for clk_period;
	
	report "Test 8";
	I_stall <= '1';
	WAIT FOR clk_period;
	assert (O_mux = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX") report "Test 8 Stall: O_mux != Reset Value" severity error;
	
WAIT;                                                       
END PROCESS;                                           
                                         
END write_back_arch;
