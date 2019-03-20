library IEEE;
use IEEE.std_logic_1164.all;
use WORK.DLX_package.all;

entity mux21_generic is
  
  generic (
    N : integer );
  port (
    A: in std_logic_vector(0 to N-1);
    B: in std_logic_vector(0 to N-1);
    SEL: in std_logic;
    Y: out std_logic_vector(0 to N-1)
    );
end mux21_generic;

architecture structural of mux21_generic is

 component MUX21 is
	Port (	A:	In	std_logic;
		B:	In	std_logic;
		S:	In	std_logic;
		Y:	Out	std_logic);
 end component;
 
begin  -- structural

 GEN: for i in 0 to N-1 generate
  MUX: mux21 port map (A(I),
                       B(I),
                       SEL,
                       Y(I));
end generate GEN;


end structural;


