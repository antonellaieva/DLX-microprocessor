library ieee; 
use ieee.std_logic_1164.all;
use WORK.DLX_package.all;
USE ieee.numeric_std.all;

entity MUX21_GENERIC_P4 is
        Generic (N: integer:= N_DATA_SIZE);
	Port (	A:	In	std_logic_vector(N-1 downto 0);
                B:	In	std_logic_vector(N-1 downto 0);
		SEL:	In	std_logic;
		Y:	Out	std_logic_vector(N-1 downto 0)
                );
end MUX21_GENERIC_P4;


architecture BEHAVIORAL of MUX21_GENERIC_P4 is

begin
	pmux: process(A,B,SEL)
	begin
		if SEL='1' then
			Y <= A;
		else
			Y <= B;
		end if;

	end process;

end BEHAVIORAL;
