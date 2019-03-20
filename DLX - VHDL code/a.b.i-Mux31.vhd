library IEEE;
use IEEE.std_logic_1164.all;
use WORK.DLX_package.all;

entity mux31 is
  
  generic (
            N : integer 
          );
  port 
       (
    	  A:   in std_logic_vector (N-1 downto 0);
          B:   in std_logic_vector (N-1 downto 0);
          C:   in std_logic_vector (N-1 downto 0);
          SEL: in std_logic_vector (1 downto 0);
          Y:   out std_logic_vector(N-1 downto 0)
       );
end mux31;

architecture behavioral of mux31 is
begin
 MUX_PROCESS: process (A,B,C,SEL)
      
              
   
  begin
     Y<=(others=>'0');  
      case SEL is
	when "00" => Y<=A;
        when "01" => Y<=B;
        when "10" => Y<=C; 
     
	when others => null;
    end case; 
  end process MUX_PROCESS;
end behavioral;


