library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use WORK.DLX_package.all;


entity STACK is
  generic  (
               STACK_DEPTH : integer := STACK_DEPTH ;
	       DATA_SIZE : integer := N_DATA_SIZE
           );
  port     (
                  Rst         : in  std_logic;
                  Clk         : in  std_logic;
	          Rd	      : in  std_logic;
	          Wr	      : in  std_logic;
                  Din         : in  std_logic_vector(DATA_SIZE - 1 downto 0);            
                  Dout        : out std_logic_vector(DATA_SIZE - 1 downto 0)
           );

end STACK;

architecture STACK_Bhe of STACK is
  ----------------------------------------------------------------------------------------------------------------------------
  -- DRAM MEMORY declaration and signals
  ----------------------------------------------------------------------------------------------------------------------------
        
  subtype REG_ADDR is natural range 0 to (STACK_DEPTH)-1; -- using natural type
  type REG_ARRAY is array(REG_ADDR) of std_logic_vector(DATA_SIZE-1 downto 0);
  signal STACK_mem : REG_ARRAY;  

  signal ADDR_WR        : std_logic_vector(log2r(STACK_DEPTH)-1 downto 0);
  signal ADDR_RD        : std_logic_vector(log2r(STACK_DEPTH)-1 downto 0);


  begin 

  ----------------------------------------------------------------------------------------------------------------------------
  -- STACK management
  ----------------------------------------------------------------------------------------------------------------------------
  
  WRITING_P: process(clk)
              begin
                 if (clk'event and clk = '1') then
             	        if (Rst='0' ) then --reset signal, that fills all the memory with zeros
				for i in 0 to (STACK_DEPTH)-1 loop
					STACK_mem(i) <= (others => '0');	
					ADDR_WR <= (others => '0');
					ADDR_RD <= (others => '1');
				end loop;
                        elsif(Wr = '1') then   ----------------------Synchronous writing-------------------------
				ADDR_WR <= ADDR_WR +1;
				ADDR_RD <= ADDR_RD +1;
				STACK_mem(to_integer(unsigned(ADDR_WR)))  <= Din;	
			elsif(Rd = '1') then
				ADDR_WR <= ADDR_WR -1;
				ADDR_RD <= ADDR_RD -1;
			end if;    	
                end if;
             end process;

  
  READING_P: process (ADDR_RD,Rd)
  begin
	if (Rd = '1' ) then
        ---------------------Asynchronous reading------------------------	
                Dout <= STACK_mem(to_integer(unsigned(ADDR_RD)));
	else 
		Dout <= (others => '0');
	end if; --if RD

  end process; 
  
end STACK_Bhe;
