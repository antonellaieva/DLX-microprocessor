library IEEE;
use IEEE.std_logic_1164.all;
use WORK.DLX_package.all;

entity mux41 is
  
  generic (
            N : integer 
          );
  port 
       (
    	  A:   in std_logic_vector (0 to N-1);
          B:   in std_logic_vector (0 to N-1);
          C:   in std_logic_vector (0 to N-1);
          D:   in std_logic_vector (0 to N-1);
          SEL: in std_logic_vector (0 to 1);
          Y:   out std_logic_vector(0 to N-1)
       );
end mux41;

architecture behavioral of mux41 is
begin
 MUX_PROCESS: process (A,B,C,D,SEL)
      
              
   
  begin
     Y<=(others=>'0'); 
      case SEL is
	when "00" => Y<=A;
        when "01" => Y<=B;
        when "10" => Y<=C; 
        when "11" => Y<=D; 
	when others => null;
    end case; 
  end process MUX_PROCESS;
end behavioral;


