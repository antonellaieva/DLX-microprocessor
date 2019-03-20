library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use WORK.DLX_package.all;

entity counter_cwp is
generic (
           F    : integer :=F
         );
port     
        (
             RESET     : IN std_logic;
	     CLK       : IN std_logic;
	     ENABLE    : IN std_logic; 
             UP_NOTDOWN: IN std_logic;
             COUNT_OUT : OUT std_logic_vector(log2(F)-1 downto 0);
			    TC_UP     : OUT std_logic;
			    TC_DOWN   : OUT std_logic 
			 
        );
end counter_cwp;

architecture behavioral of counter_cwp is

signal temp    : std_logic_vector(log2(F)-1 downto 0);

begin   
        

 counter: process(Clk)
     begin
      if (clk'event and clk='1') then 
	        
			if Reset='0' then
                    temp   <= std_logic_vector( to_unsigned(0,log2(F))); --starting value of cwp  
                    --temp   <= std_logic_vector( to_unsigned(F-1,log2(F))); --starting value of cwp  
	                
			elsif enable='1' then
                 if(UP_NOTDOWN='1') then
								if (temp =std_logic_vector( to_unsigned(F-1,log2(F)))) then
										temp<= (others=>'0');
								else
									 temp  <= temp + 1;
								end if;
                 else
								if (temp = std_logic_vector( to_unsigned(0,log2(F)))) then
										temp<=std_logic_vector( to_unsigned(F-1,log2(F)));
								else
										temp  <= temp -1 ;
								end if;				 
				     end if;
			               
			end if;
  
	end if;
   
   end process;
	
	
	tc_process : process(temp)
	             begin
						 if (temp =std_logic_vector( to_unsigned(F-1,log2(F)))) then
									TC_UP <= '1';
						 else
								 TC_UP <= '0';
						 end if;
					
						 if (temp = std_logic_vector( to_unsigned(0,log2(F)))) then
								TC_DOWN <= '1';
						 else
								TC_DOWN <= '0';
						 end if;	
			    	end process;	 
 
	 COUNT_OUT<=temp;
	 
end behavioral;

