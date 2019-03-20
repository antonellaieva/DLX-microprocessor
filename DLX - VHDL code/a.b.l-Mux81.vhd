library IEEE;
use IEEE.std_logic_1164.all;
use WORK.DLX_package.all;

entity mux81 is
  
  generic (
            N : integer :=n_data_size
          );
  port 
       (
    	    A:   in std_logic_vector (0 to N-1);
          B:   in std_logic_vector (0 to N-1);
          C:   in std_logic_vector (0 to N-1);
          D:   in std_logic_vector (0 to N-1);
          E:   in std_logic_vector (0 to N-1);
          F:   in std_logic_vector (0 to N-1); 
          G:   in std_logic_vector (0 to N-1); 
          H:   in std_logic_vector (0 to N-1);
          SEL: in std_logic_vector (0 to 2);
          Y:   out std_logic_vector(0 to N-1)
       );
end mux81;

architecture behavioral of mux81 is
 begin
 MUX_PROCESS: process (A,B,C,D,E,F,G,H,SEL)
      
       begin
        Y<=(others=>'0'); 
        case SEL is
	     when "000" => Y<=A;
        when "001" => Y<=B;
        when "010" => Y<=C; 
        when "011" => Y<=D; 
        when "100" => Y<=E;
        when "101" => Y<=F;
        when "110" => Y<=G; 
        when "111" => Y<=H; 
        when others => null;
        end case; 
  end process MUX_PROCESS;
end behavioral;


