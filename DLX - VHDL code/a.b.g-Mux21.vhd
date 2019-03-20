library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic
use WORK.DLX_package.all; -- libreria WORK user-defined

entity MUX21 is
	Port (	A:	In	std_logic;
		B:	In	std_logic;
		S:	In	std_logic;
		Y:	Out	std_logic);
end MUX21;

architecture BEHAVIORAL of MUX21 is

begin

 MUX_PROCESS21: process (A,B,S)
  begin
     Y<='0'; 
      case S is
	when '0' => Y<=A;
        when '1' => Y<=B;
	when others => null;
    end case; 
  end process MUX_PROCESS21;


end BEHAVIORAL;



