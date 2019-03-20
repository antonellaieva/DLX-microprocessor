library ieee; 
use ieee.std_logic_1164.all;
use WORK.DLX_package.all;
USE ieee.numeric_std.all;


entity CS_SUM_GENERATOR is 
	
	generic (N: integer:= N_DATA_SIZE);
	Port (	A:	In	std_logic_vector(N-1 downto 0);
		B:	In	std_logic_vector(N-1 downto 0);
		Ci:	In	std_logic_vector((N/4)-1 downto 0);
		S:	Out	std_logic_vector(N-1 downto 0)
		--Co:	Out	std_logic;
		);
end CS_SUM_GENERATOR;

architecture STRUCTURAL of CS_SUM_GENERATOR is



component Carry_Select_block 
	Port (	A:	In	std_logic_vector(3 downto 0);
		B:	In	std_logic_vector(3 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(3 downto 0)
		--Co:	Out	std_logic;
		);
end component;

begin

CSA: for I in 1 to N/4 generate
  CS_I: Carry_Select_block
	port map (A(4*(I-1)+3 downto 4*(I-1)), B(4*(I-1)+3 downto 4*(I-1)), Ci(I-1), S(4*(I-1)+3 downto 4*(I-1)));
  end generate;
	
end STRUCTURAL;


