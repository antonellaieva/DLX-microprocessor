library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

entity Adder_Subtractor is 
	generic (
                 N     :        integer:= 4
            );
	Port   (	  
	          A  :	In	std_logic_vector(N-1 downto 0);
		      B  :	In	std_logic_vector(N-1 downto 0);
		      Cin:	In	std_logic;
		      S  :	Out std_logic_vector(N-1 downto 0);
		      Co :	Out std_logic
		   );
end Adder_Subtractor; 

architecture STRUCTURAL of Adder_Subtractor is

  signal CTMP : std_logic_vector(N downto 0);
  signal BTMP : std_logic_vector(N-1 downto 0);

  component FA 
  Port ( 
          A:	In	std_logic;
			 B   :	In	std_logic;
			 Ci  :	In	std_logic;
			 S   :	Out	std_logic;
			 Co  :	Out	std_logic
	    );
  end component; 

begin

PP : process (Cin,A,B)
begin
if (Cin = '0') then
  S <= A+B;
else
   S <= A-B;
end if;
end process;

  
 -- CTMP(0) <=Cin ;

 -- Co <= CTMP(N);
  
  
 -- xor_net: for I in 0 to N-1 generate
--		 BTMP(I) <= B(I) xor Cin ;
--	     end generate;
	 
 -- ADDER1 : for I in 1 to N generate
--	       FAI : FA 
--                     Port Map (A(I-1), BTMP(I-1), CTMP(I-1), S(I-1), CTMP(I)); 
 --          end generate;

end STRUCTURAL;





