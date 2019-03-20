library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use WORK.DLX_package.all;


entity DRAM is
  generic  (
               D_RAM_DEPTH : integer := DRAM_DEPTH ;
	       DATA_SIZE : integer := N_DATA_SIZE/4
           );
  port     (
                  Rst         : in  std_logic;
                  Clk         : in  std_logic;
	          En	      : in  std_logic;
	          Rd	      : in  std_logic;
	          Wr	      : in  std_logic;
                  Spill       : in  std_logic;
                  Fill        : in  std_logic;
                  Rword       : in  std_logic;
                  Rbyte       : in  std_logic;
                  Addr_FS     : in  std_logic_vector(address_RF_DATA_RAM-1 downto 0);
                  Addr        : in  std_logic_vector(log2r(D_RAM_DEPTH)- 1 downto 0);
                  Din         : in  std_logic_vector(4*DATA_SIZE - 1 downto 0);
                  Din_SPILL   : in  std_logic_vector(4*DATA_SIZE - 1 downto 0);              
                  Dout        : out std_logic_vector(4*DATA_SIZE - 1 downto 0);
                  Dout_FILL   : out std_logic_vector(4*DATA_SIZE - 1 downto 0);
                  Dout_byte   : out std_logic_vector(DATA_SIZE - 1 downto 0);
                  Dout_word   : out std_logic_vector(2*DATA_SIZE - 1 downto 0)
           );

end DRAM;

architecture DRAM_Bhe of DRAM is
  ----------------------------------------------------------------------------------------------------------------------------
  -- DRAM MEMORY declaration and signals
  ----------------------------------------------------------------------------------------------------------------------------
        
  subtype REG_ADDR is natural range 0 to (D_RAM_DEPTH)-1; -- using natural type
  type REG_ARRAY is array(REG_ADDR) of std_logic_vector(DATA_SIZE-1 downto 0);
  signal RAM_mem : REG_ARRAY;  

  signal Dout_signal0 : std_logic_vector(DATA_SIZE - 1 downto 0);
  signal Dout_signal1 : std_logic_vector(DATA_SIZE - 1 downto 0);
  signal Dout_signal2 : std_logic_vector(DATA_SIZE - 1 downto 0);
  signal Dout_signal3 : std_logic_vector(DATA_SIZE - 1 downto 0);
  signal ADDR1        : std_logic_vector(log2r(DRAM_DEPTH)-1 downto 0);	
  signal ADDR2        : std_logic_vector(log2r(DRAM_DEPTH)-1 downto 0);
  signal ADDR3        : std_logic_vector(log2r(DRAM_DEPTH)-1 downto 0);
  ----------------------------------------------------------------------------
  signal ADDR_FS_full0: std_logic_vector(log2r(DRAM_DEPTH)-1 downto 0);
  signal ADDR_FS_full1: std_logic_vector(log2r(DRAM_DEPTH)-1 downto 0);
  signal ADDR_FS_full2: std_logic_vector(log2r(DRAM_DEPTH)-1 downto 0);
  signal ADDR_FS_full3: std_logic_vector(log2r(DRAM_DEPTH)-1 downto 0);
  signal Dout_FILL0 : std_logic_vector(DATA_SIZE - 1 downto 0);
  signal Dout_FILL1 : std_logic_vector(DATA_SIZE - 1 downto 0);
  signal Dout_FILL2 : std_logic_vector(DATA_SIZE - 1 downto 0);
  signal Dout_FILL3 : std_logic_vector(DATA_SIZE - 1 downto 0);
   
  signal ones : std_logic_vector(log2r(DRAM_DEPTH)-1  downto address_RF_DATA_RAM);



  begin 

  ----------------------------------------------------------------------------------------------------------------------------
  -- DRAM management
  ----------------------------------------------------------------------------------------------------------------------------

  ADDR1 <= ADDR+std_logic_vector(to_unsigned(1,log2r(DRAM_DEPTH)));
  ADDR2 <= ADDR+std_logic_vector(to_unsigned(2,log2r(DRAM_DEPTH)));
  ADDR3 <= ADDR+std_logic_vector(to_unsigned(3,log2r(DRAM_DEPTH)));
  --------------------------------------------------------------------------------
  ones <= (others => '1');
  ADDR_FS_full0 <= ones & Addr_FS;
  ADDR_FS_full1 <= ADDR_FS_full0+std_logic_vector(to_unsigned(1,log2r(DRAM_DEPTH)));
  ADDR_FS_full2 <= ADDR_FS_full1+std_logic_vector(to_unsigned(1,log2r(DRAM_DEPTH)));
  ADDR_FS_full3 <= ADDR_FS_full2+std_logic_vector(to_unsigned(1,log2r(DRAM_DEPTH)));
  
  WRITING_P: process(clk)
              begin
                 if (clk'event and clk = '1') then
             	        if (Rst='0' ) then --reset signal, that fills all the memory with zeros
				for i in 0 to (D_RAM_DEPTH)-1 loop
					RAM_mem(i) <= (others => '0');		
				end loop;
                        elsif(En = '1') then   ----------------------Synchronous writing-------------------------
			        if ( Wr = '1' and Rword = '0' and Rbyte = '0') then
					RAM_mem(to_integer(unsigned(ADDR)))  <= Din(4*DATA_SIZE - 1 downto 3*DATA_SIZE);	
			                RAM_mem(to_integer(unsigned(ADDR1))) <= Din(3*DATA_SIZE - 1 downto 2*DATA_SIZE);	
			                RAM_mem(to_integer(unsigned(ADDR2))) <= Din(2*DATA_SIZE - 1 downto DATA_SIZE);
			                RAM_mem(to_integer(unsigned(ADDR3))) <= Din(DATA_SIZE - 1 downto 0);			
				elsif( Wr = '1' and Rword = '1') then	
			                RAM_mem(to_integer(unsigned(ADDR))) <= Din(2*DATA_SIZE - 1 downto DATA_SIZE);
			                RAM_mem(to_integer(unsigned(ADDR1))) <= Din(DATA_SIZE - 1 downto 0);			
				elsif( Wr = '1' and Rbyte = '1') then
			                RAM_mem(to_integer(unsigned(ADDR))) <= Din(DATA_SIZE - 1 downto 0);		
				elsif( SPILL = '1' ) then
					RAM_mem(to_integer(unsigned(ADDR_FS_full0))) <= Din_SPILL(4*DATA_SIZE - 1 downto 3*DATA_SIZE);	
			                RAM_mem(to_integer(unsigned(ADDR_FS_full1))) <= Din_SPILL(3*DATA_SIZE - 1 downto 2*DATA_SIZE);	
			                RAM_mem(to_integer(unsigned(ADDR_FS_full2))) <= Din_SPILL(2*DATA_SIZE - 1 downto DATA_SIZE);
			                RAM_mem(to_integer(unsigned(ADDR_FS_full3))) <= Din_SPILL(DATA_SIZE - 1 downto 0);			
				end if; 
                         end if;
                end if;
             end process;

  
  READING_P: process (En, RD, WR,Din,Fill,Spill,RAM_mem,ADDR,ADDR1,ADDR2,ADDR3,Rword,Rbyte,ADDR_FS_full0,ADDR_FS_full1,ADDR_FS_full2,ADDR_FS_full3)
  begin
        Dout_signal0 <= (others => 'Z');
        Dout_signal1 <= (others => 'Z');
        Dout_signal2 <= (others => 'Z');
        Dout_signal3 <= (others => 'Z');
        Dout_byte <= (others => 'Z');
        --------------------------------
        Dout_FILL0 <= (others => 'Z');
        Dout_FILL1 <= (others => 'Z');
        Dout_FILL2 <= (others => 'Z');
        Dout_FILL3 <= (others => 'Z');

	if (En = '1' ) then
                        ---------------------Asynchronous reading------------------------	
			if (RD = '1'and Rword = '0' and Rbyte = '0') then
                                Dout_signal0 <= RAM_mem(to_integer(unsigned(ADDR)));
                                Dout_signal1 <= RAM_mem(to_integer(unsigned(ADDR1)));
                                Dout_signal2 <= RAM_mem(to_integer(unsigned(ADDR2)));
                                Dout_signal3 <= RAM_mem(to_integer(unsigned(ADDR3)));
                        
		        elsif (RD = '1' and Rbyte = '1') then
                                Dout_byte <= RAM_mem(to_integer(unsigned(ADDR)));
                       
                        elsif (RD = '1' and Rword = '1') then
                                Dout_signal0 <= RAM_mem(to_integer(unsigned(ADDR)));
                                Dout_signal1 <= RAM_mem(to_integer(unsigned(ADDR1)));
                        
                        elsif (FILL = '1') then
                                Dout_FILL0 <= RAM_mem(to_integer(unsigned(ADDR_FS_full0)));
                                Dout_FILL1 <= RAM_mem(to_integer(unsigned(ADDR_FS_full1)));
                                Dout_FILL2 <= RAM_mem(to_integer(unsigned(ADDR_FS_full2)));
                                Dout_FILL3 <= RAM_mem(to_integer(unsigned(ADDR_FS_full3)));
                        end if;
	end if; --if enable

  end process; 

  Dout <= Dout_signal0 & Dout_signal1 & Dout_signal2 & Dout_signal3;
  Dout_word <= Dout_signal0 & Dout_signal1;
  -------------------------------------------------------------------
  Dout_FILL <= Dout_FILL0 & Dout_FILL1 & Dout_FILL2 & Dout_FILL3;
  
end DRAM_Bhe;