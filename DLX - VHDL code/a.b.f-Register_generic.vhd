library IEEE;
use IEEE.std_logic_1164.all; 

entity FD is
	Generic (N: integer:= 5);
	Port (			
			D:	In	std_logic_vector (N-1 DOWNTO 0);
			ENABLE: In      std_logic;    
                        CK:	In	std_logic;
			RESET:	In	std_logic;
			Q:	Out	std_logic_vector (N-1 DOWNTO 0)
		  );
end FD;


architecture PIPPO of FD is -- flip flop D with syncronous reset

begin
	PSYNCH: process(CK)
	begin
	  if CK'event and CK='1' then -- positive edge triggered:
	    if RESET='0' then -- active high reset 
	      Q <= (others=> '0') ; 
	    elsif(ENABLE='1') then
	      Q <= D; -- input is written on output
	    end if;
	  end if;
	end process;

end PIPPO;







