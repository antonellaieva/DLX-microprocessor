library IEEE;
use IEEE.std_logic_1164.all;
use WORK.DLX_package.all;

entity encoder is 
 
   port   (
              B: IN std_logic_vector (2 downto 0);
              S: OUT std_logic_vector(2 downto 0)
           );
end entity;

architecture behavior of encoder is

begin

  P: process (B)
     begin

      case B is

      when "000" | "111" => S <= "000";							--Selects '0'	
     
      when "001" | "010" => S <= "001";							--Selects 'A'
   
      when "101" | "110" => S <= "010"	;	 
	
      when "011"         => S <= "011";                              --Selects "2A"

      when "100"         => S <= "100";
    
      when others        => S <= "000";
		 
	 end case;
end process;

end behavior;
