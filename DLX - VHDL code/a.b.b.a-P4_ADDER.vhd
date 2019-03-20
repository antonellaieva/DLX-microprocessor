library ieee; 
use ieee.std_logic_1164.all;
use WORK.DLX_package.all;
USE ieee.numeric_std.all;

entity P4_ADDER is 
	
	generic (N: integer:= N_DATA_SIZE);
	Port (	A:	In	std_logic_vector(N-1 downto 0);
		B:	In	std_logic_vector(N-1 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(N-1 downto 0);
		Co:	Out	std_logic
		);
end P4_ADDER;


ARCHITECTURE STRUCTURAL OF P4_ADDER IS

constant NBIT: integer := N_DATA_SIZE;
------------------------------------------------
component CS_SUM_GENERATOR  
	
	generic (N: integer:= N_DATA_SIZE);
	Port (	A:	In	std_logic_vector(N-1 downto 0);
		B:	In	std_logic_vector(N-1 downto 0);
		Ci:	In	std_logic_vector((N/4)-1 downto 0);
		S:	Out	std_logic_vector(N-1 downto 0)
		);
end component;
------------------------------------------------
component CS_CARRY_GEN 
	GENERIC (N : integer := N_DATA_SIZE);
	PORT (A : IN STD_LOGIC_VECTOR(N-1 downto 0);
	      B : IN STD_LOGIC_VECTOR(N-1 downto 0);
              Cin : IN STD_LOGIC;
      	      Cout : OUT STD_LOGIC_VECTOR(N/4-1 downto 0));
END component;
------------------------------------------------

signal C_vector, C_vect_IN_SUM: STD_LOGIC_VECTOR(N/4-1 downto 0);


begin

C_GEN: CS_CARRY_GEN
	generic map(NBIT)
	port map(A,B,Ci, C_vector);

C_vect_IN_SUM <= C_vector(N/4-2 downto 0) & Ci;

S_GEN: CS_SUM_GENERATOR
	generic map(NBIT)
	port map(A,B, C_vect_IN_SUM, S);

Co <= C_vector(N/4-1);

end STRUCTURAL;








