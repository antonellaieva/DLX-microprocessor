library ieee; 
use ieee.std_logic_1164.all;
use WORK.DLX_package.all;
USE ieee.numeric_std.all;

entity Carry_Select_block is 
	Port (	A:	In	std_logic_vector(3 downto 0);
		B:	In	std_logic_vector(3 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(3 downto 0)
		--Co:	Out	std_logic;
		);
end Carry_Select_block;

architecture STRUCTURAL of Carry_Select_block is

constant NBIT: integer := 4;
signal sum_carry0, sum_carry1: std_logic_vector(3 downto 0);
signal co_0, co_1: std_logic;

component RCA is 
	generic ( N: integer:= n_data_size );
	Port (	A:	In	std_logic_vector(N-1 downto 0);
		B:	In	std_logic_vector(N-1 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(N-1 downto 0);
		Co:	Out	std_logic);
end component; 

component MUX21_GENERIC_P4 
        Generic (N: integer:= N_DATA_SIZE);
	Port (	A:	In	std_logic_vector(N-1 downto 0);
                B:	In	std_logic_vector(N-1 downto 0);
		SEL:	In	std_logic;
		Y:	Out	std_logic_vector(N-1 downto 0)
                );
end component;

begin

RCA_0: RCA 
	generic map (NBIT)
	port map (A, B, '0', sum_carry0, co_0);

RCA_1: RCA
	generic map (NBIT)
	port map (A, B, '1', sum_carry1, co_1);

mux: MUX21_GENERIC_P4
	generic map (NBIT)
	port map (sum_carry1, sum_carry0, Ci, S);

end STRUCTURAL;



