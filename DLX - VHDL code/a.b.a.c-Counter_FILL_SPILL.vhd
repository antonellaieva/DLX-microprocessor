library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use WORK.DLX_package.all;

entity counter_FILL_SPILL is
generic (
           N    : integer :=N_reg_block; --   NUMBER OF REGISTERS IN A BLOCK
           F    : integer :=F; --
           M    : integer :=M; --
           N2F  : integer :=N2F; --total number of register in the windows (without global block)
           N2F_1: integer :=N2F_1	
	   );
port     
        (
             RESET     : IN std_logic;
			    CLK       : IN std_logic;
			    ENABLE    : IN std_logic; 
             UP_NOTDOWN: IN std_logic;
             CALL      : IN std_logic;
             RET       : IN std_logic;
             POINTER   : OUT std_logic_vector(log2(N2F)-1 downto 0);
				 TC_FILL    : OUT std_logic;
				 TC_SPILL   : OUT std_logic
        );
end counter_FILL_SPILL;

architecture behavioral of counter_FILL_SPILL is

component MUX21_GENERIC 
	Generic (
              N: integer:= n_bit_carry_select
		    );
	Port   (	
	           A:	In	std_logic_vector(N-1 downto 0) ;
		        B:	In	std_logic_vector(N-1 downto 0);
		        SEL:	In	std_logic;
              Y:	Out	std_logic_vector(N-1 downto 0)
            );
end component;

signal temp:     std_logic_vector(log2(N2F)-1 downto 0);
signal temp_1  : std_logic_vector(log2(N2F)-1 downto 0);
signal dec2mux : std_logic;
signal and_net : std_logic_vector(log2(N) downto 1);
signal and_net1 : std_logic_vector(log2(N)-1 downto 1);
signal nor_net : std_logic_vector(log2(N) downto 1);
signal COUNT_OUT : std_logic_vector(log2(N2F)-1 downto 0);


begin   

 counter: process(Clk)
     begin
      if (clk'event and clk='1') then 
	        
			if Reset='0' then
                   temp  <= (others =>'0');
	                temp_1 <= std_logic_vector( to_unsigned(N2F_1,log2(N2F)));
			elsif enable='1' then
                if(UP_NOTDOWN='1') then
					 
							 if (temp = std_logic_vector( to_unsigned(N2F_1,log2(N2F)))) then
								  temp<= (others=>'0');
							 else
								  temp  <= temp + 1;
							 end if;
							 
							 if (temp_1 = std_logic_vector( to_unsigned(N2F_1,log2(N2F)))) then
								  temp_1<= (others=>'0');
							 else
								  temp_1  <= temp_1 + 1;
							 end if;
                else
							 if (temp = std_logic_vector( to_unsigned(0,log2(N2F)))) then
								  temp<=std_logic_vector( to_unsigned(N2F_1,log2(N2F)));
							 else
								  temp  <= temp -1 ;
							 end if;
							 
							 if (temp_1 = std_logic_vector( to_unsigned(0,log2(N2F)))) then
								  temp_1<=std_logic_vector( to_unsigned(N2F_1,log2(N2F)));
							 else
								  temp_1  <= temp_1 -1 ;
							 end if;
			
				    end if;
			end if;
      end if;
   
   
   end process;   
  
--FLAG for COUNT_OUT = '2N-1'  
and_net(1) <= COUNT_OUT(0) and COUNT_OUT(1); 
  
and_network:            
			   for i in 2 to log2(N)  generate
					 and_net(i)<= and_net(i-1) and COUNT_OUT(i);
				end generate;
				 
TC_SPILL<=and_net(log2(N)); --this signal says that the SPILL operation is completed, so the POINTER points to the last register


--FLAG for COUNT_OUT = '0'  
nor_net(1) <= COUNT_OUT(0) nor COUNT_OUT(1);
   
nor_network:
				for i in 2 to log2(N)  generate
					 nor_net(i)<= COUNT_OUT(i-1) nor COUNT_OUT(i);
				end generate;
				
and_net1(1) <= nor_net(1) and nor_net(2); 
  
and_network1:            
			   for i in 2 to log2(N)-1  generate
					 and_net1(i)<= and_net1(i-1) and nor_net(i+1);
				end generate;
			
TC_FILL <= and_net1(log2(N)-1); --this signal says that the FILL operation is completed, so the POINTER points to the first register	  

dec2mux <= CALL;
  	 
 UMUX: MUX21_GENERIC 
       generic map (N=>log2(N2F))
       port map    (A=>temp_1, B=>temp, SEL=>dec2mux, Y=>COUNT_OUT);
 
 
 POINTER <= COUNT_OUT;
 
end behavioral;




 














