library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use WORK.DLX_package.all;


entity canrestore is
generic ( 
           F    : integer :=F 
	      );
	   
port     
        (
             CWP        : IN std_logic_vector(log2r(F)-1 downto 0) ;
				 SWP        : IN std_logic_vector(log2r(F)-1 downto 0);
				 CANRESTORE : OUT std_logic
        );
end canrestore;

architecture structural of canrestore is
   
signal  exnor_net : std_logic_vector(log2r(F)-1 downto 0); 
signal  and_net   : std_logic_vector(log2r(F)-1 downto 0); 

begin

exnor_network: for i in 0 to log2r(F)-1 generate
				 exnor_net(i)<= CWP(i) xnor SWP(i);
			     end generate;

and_net(0)<=exnor_net(0) and exnor_net(1);

and_network: for i in 1 to log2r(F)-2  generate
				and_net(i)<= and_net(i-1) and exnor_net(i+1);
			 end generate;
            
CANRESTORE<=not(and_net(log2r(F)-2));

			
end structural;



