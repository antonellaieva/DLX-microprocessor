library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
----------------------------------------
entity MuxNto1 is
	generic
	(
		INPUT_WIDTH	    : integer 	:= 8;
		INPUT_COUNT 	    : integer 	:= 8;
		SEL_WIDTH 	    : integer 	:= 3
	);
	port
	(
		Inputs 		    : in   std_logic_vector((INPUT_WIDTH*INPUT_COUNT)-1 downto 0);
		Sel 		    : in   std_logic_vector(2 downto 0);
		Output 	            : out  std_logic_vector(INPUT_WIDTH-1 downto 0)
	);
end entity; -- Mux
----------------------------------------
architecture Arch of MuxNto1 is
 begin
 MUX_PROCESS: process (Inputs,Sel)
      
       begin
        Output <=(others=>'0'); 
        case SEL is
	when "000" => Output<= Inputs( 7 downto 0);
        when "001" => Output<= Inputs( 15 downto 8);
        when "010" => Output<= Inputs( 23 downto 16); 
        when "011" => Output<= Inputs( 31 downto 24); 
        when "100" => Output<= Inputs( 39 downto 32);
        when "101" => Output<= Inputs( 47 downto 40);
        when "110" => Output<= Inputs( 55 downto 48); 
        when "111" => Output<= Inputs( 63 downto 56); 
        when others => null;
        end case; 
  end process MUX_PROCESS;

end architecture; -- Arch
