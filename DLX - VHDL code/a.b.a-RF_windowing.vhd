library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use WORK.DLX_package.all;


entity RF_windowing is
generic (
           N: integer := N_reg_block;--NUMBER OF REGISTERS IN A BLOCK
           F: integer := F;
           M: integer := M;
           P: integer := N_DATA_SIZE
         );
port     (
             CLK          : IN std_logic;
	     RESET        : IN std_logic;
	     CALL         : IN std_logic; 
             RD1          : IN std_logic;
             RD2          : IN std_logic;
             WR           : IN std_logic;
             RET          : IN std_logic;
             SPILL        : OUT std_logic;
             FILL         : OUT std_logic;  
             CWP_o        : out std_logic_vector(log2r(F)-1 downto 0);
             SWP_o        : out std_logic_vector(log2r(F)-1 downto 0);
             ADDRESS_RD1  : IN  std_logic_vector(log2r(3*N+M)-1 downto 0); --represent the number of bits    
	     ADDRESS_RD2  : IN  std_logic_vector(log2r(3*N+M)-1 downto 0);
	     ADDRESS_WR   : IN  std_logic_vector(log2r(3*N+M)-1 downto 0);
             DATA_IN      : IN  std_logic_vector(P-1 downto 0);   
             DATA_OUT1    : OUT std_logic_vector(P-1 downto 0);   
             DATA_OUT2    : OUT std_logic_vector(P-1 downto 0);   
             MEM_spilling : OUT std_logic_vector(P-1 downto 0);   
             MEM_filling  : IN  std_logic_vector(P-1 downto 0)             
           );
end RF_windowing;


architecture beahv_struct of RF_windowing is 

--Flag and Control signals
signal CANSAVE_flag : std_logic;
signal CANRESTORE_flag : std_logic;
signal TC_SPILL : std_logic;
signal TC_FILL : std_logic;
signal ENABLE_fill_spill, ENABLE_swp, ENABLE_cwp: std_logic;
signal UP_DOWN_fill_spill, UP_DOWN_swp, UP_DOWN_cwp : std_logic;
signal LAST_WINDOW : std_logic;

--pointer to RF for RD,WR,FILL,SPILL operations
signal RF_FS_address : std_logic_vector(log2r(2*N*F+M)-1 downto 0);
signal ADD_RD1, ADD_RD2, ADD_WR : std_logic_vector(log2r(2*N*F+M)-1 downto 0);

--pointers
signal SWP_pointer, CWP_pointer : std_logic_vector(log2r(2*N*F+M)-1 downto 0);
signal CWP_counter,SWP_counter : std_logic_vector(log2r(F)-1 downto 0);

--Register File
subtype REG_ADDR is natural range 0 to (2*N*F+M)-1; -- using natural type
type REG_ARRAY is array(REG_ADDR) of std_logic_vector(P-1 downto 0); 
signal RF : REG_ARRAY; 

--constants
signal zeros1 : std_logic_vector(log2r(2*N*F+M)-1 downto log2r(2*N*F));
signal zeros0 : std_logic_vector(log2r(N) downto 0);


component addressing
generic (
           F : integer :=F;
           N : integer :=N;
           M : integer :=M;
           N2F_3N : integer :=N2F_3N
          
        );
port     
        (
             VIRTUAL_ADDRESS: IN std_logic_vector(log2r(3*N+M)-1 downto 0);
			    CWP_portion   : IN std_logic_vector(log2r(F)-1 downto 0);
			    TC_CWP        : IN std_logic;
             REAL_ADDRESS : OUT std_logic_vector(log2r(2*N*F+M)-1 downto 0)
	    );
end component;


component canrestore
generic ( 
           F    : integer :=F 
	      );
	   
port     
        (
             CWP        : IN std_logic_vector(log2r(F)-1 downto 0) ;
				 SWP        : IN std_logic_vector(log2r(F)-1 downto 0);
				 CANRESTORE : OUT std_logic
        );
end component;


component cansave
generic ( 
           F    : integer :=F;
			  F_1  : integer :=F_1
		
			 
	    );
port     
        (
             CWP        : IN std_logic_vector(log2r(F)-1 downto 0) ;
			    SWP        : IN std_logic_vector(log2r(F)-1 downto 0);
			    CANSAVE    : OUT std_logic
        );
end component;


component counter_cwp
generic (
           F    : integer :=F
         );
port     
        (
             RESET     : IN std_logic;
	          CLK       : IN std_logic;
	          ENABLE    : IN std_logic; 
             UP_NOTDOWN: IN std_logic;
             COUNT_OUT : OUT std_logic_vector(log2r(F)-1 downto 0);
			    TC_UP     : OUT std_logic;
			    TC_DOWN   : OUT std_logic 
			 
        );
end component;

component counter_swp
generic (
           F    : integer :=F
         );
port     
        (
             RESET     : IN std_logic;
	          CLK       : IN std_logic;
	          ENABLE    : IN std_logic; 
             UP_NOTDOWN: IN std_logic;
             COUNT_OUT : OUT std_logic_vector(log2r(F)-1 downto 0);
			    TC_UP     : OUT std_logic;
			    TC_DOWN   : OUT std_logic 
			 
        );
end component;


component counter_FILL_SPILL
generic (
           N    : integer :=N; --   NUMBER OF REGISTERS IN A BLOCK
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
             POINTER   : OUT std_logic_vector(log2r(N2F)-1 downto 0);
				 TC_FILL    : OUT std_logic;
				 TC_SPILL   : OUT std_logic		 
        );
end component;


begin

--CONSTANTS SETTING
zeros1 <= (others => '0');
zeros0 <= (others => '0');


--FIRST BLOCK 
SPILL_FILL_SWP_block: counter_FILL_SPILL   
                      port map(RESET => RESET, CLK => CLK, ENABLE => ENABLE_fill_spill, UP_NOTDOWN => UP_DOWN_fill_spill, CALL => CALL, 
							          RET => RET, POINTER => RF_FS_address(log2r(2*N*F)-1 downto 0), TC_SPILL => TC_SPILL, TC_FILL => TC_FILL);

RF_FS_address(log2r(2*N*F+M)-1 downto log2r(2*N*F)) <= (others => '0');										 


--SECOND BLOCK
CWP_block : counter_cwp
				port map(RESET => RESET, CLK => CLK, ENABLE => ENABLE_cwp, UP_NOTDOWN => UP_DOWN_cwp, COUNT_OUT => CWP_counter, TC_UP => LAST_WINDOW);
				
CWP_pointer <= zeros1 & CWP_counter & zeros0;
CWP_o <= CWP_counter;



--THIRD BLOCK
SWP_block : counter_swp
				port map(RESET => RESET, CLK => CLK, ENABLE => ENABLE_swp, UP_NOTDOWN => UP_DOWN_swp, COUNT_OUT => SWP_counter);
				
SWP_pointer <= zeros1 & SWP_counter & zeros0;
SWP_o <= SWP_counter;


--FOURTH BLOCK
CANSAVE_block : cansave
                port map(CWP => CWP_counter, SWP => SWP_counter, CANSAVE => CANSAVE_flag);
	
	
	
--FIFTH BLOCK
CANRESTORE_block : canrestore
                   port map(CWP => CWP_counter, SWP => SWP_counter, CANRESTORE => CANRESTORE_flag);


--ADDRESSING_BLOCK1 for READING 1
READ1_ADDR_block : addressing
                   port map(VIRTUAL_ADDRESS => ADDRESS_RD1, CWP_portion => CWP_counter, TC_CWP => LAST_WINDOW, REAL_ADDRESS => ADD_RD1 );
						 
--ADDRESSING_BLOCK2 for READING 2
READ2_ADDR_block : addressing
                   port map(VIRTUAL_ADDRESS => ADDRESS_RD2, CWP_portion => CWP_counter, TC_CWP => LAST_WINDOW, REAL_ADDRESS => ADD_RD2 );

--ADDRESSING_BLOCK3 for WRITING
WRITE_ADDR_block : addressing
                   port map(VIRTUAL_ADDRESS => ADDRESS_WR, CWP_portion => CWP_counter, TC_CWP => LAST_WINDOW, REAL_ADDRESS => ADD_WR );				 
					
					
--MANAGEMENT BLOCK1
RF_CONTROL_COMBINATIONAL0: process(CALL,RET,WR,TC_SPILL,TC_FILL,CANSAVE_flag,CANRESTORE_flag)
     begin 	
	    ENABLE_cwp <= '0';
	    UP_DOWN_cwp <= '0';
            ENABLE_swp <= '0';   
	    UP_DOWN_swp <= '0';
	    ENABLE_fill_spill	<= '0';
	    UP_DOWN_fill_spill <= '0';
	    SPILL <= '0';
	    FILL <= '0';
	  
            if (CALL='1') then 
				    
		if (CANSAVE_flag='0') then  --SPILL operation : we suppose that CALL remains '1' during all this operation = 2*N clock ticks	 
		       ENABLE_fill_spill <= '1';   
		       UP_DOWN_fill_spill <= '1';				
		       SPILL<='1';
				
		       if (TC_SPILL = '1') then --it is equal to 1 before the last store in memory
			     ENABLE_swp <= '1';
			     UP_DOWN_swp <= '1';
		       else
		             ENABLE_cwp <= '0';
			     UP_DOWN_cwp <= '0';			
	               end if;
			 
		 else  -- CALL operation
	                     ENABLE_cwp <= '1';
			     UP_DOWN_cwp <= '1';
			     ENABLE_swp <= '0';   
			     UP_DOWN_swp <= '0';	
			     ENABLE_fill_spill	<= '0';
			     UP_DOWN_fill_spill <= '0';
			     SPILL<='0';
	         end if;
				  
									  
	   end if;
			   
		
	   if (RET='1') then 
					 
		if (CANRESTORE_flag='0') then  --FILL operation : we suppose that RET remains '1' during all this operation = 2*N clock ticks
	               ENABLE_fill_spill<= '1';
		       UP_DOWN_fill_spill <= '0';					
		       FILL<='1';
				
		       if (TC_FILL = '1') then	--it is equal to 1 before the last restore in the RF	  
			     ENABLE_cwp <= '1';
			     UP_DOWN_cwp <= '0';
			     ENABLE_swp <= '1';   
			     UP_DOWN_swp <= '0';
		      else
			     ENABLE_cwp <= '0';
			     UP_DOWN_cwp <= '0';
		      end if;
				
	         else -- RET operation
			      ENABLE_cwp <= '1';
			      UP_DOWN_cwp <= '0';
			      ENABLE_swp <= '0';   
			      UP_DOWN_swp <= '0';
			      ENABLE_fill_spill <= '0';
			      UP_DOWN_fill_spill <= '0';
			      FILL<='0';
							 
	         end if;
		 	
           end if;
			
end process;

	 
--MANAGEMENT BLOCK_WRITING	 
RF_CONTROL_SEQUENTIAL: process(CLK)
  begin  
      if (CLK = '1' and CLK'event) then
                                  if(RESET = '0') then
                                     for I in 0 to 2*N*F+M-1 loop
                                         RF(i) <= (others => '0');
                                     end loop;
                                  end if;
				  if(RET='1' and CANRESTORE_flag = '0') then
					   RF(to_integer( unsigned (RF_FS_address))) <= MEM_filling; 									      						
				  end if;
													 
				  if(WR='1') then
					  RF(  to_integer (unsigned ( ADD_WR)))<= DATA_IN;	 
				  end if;
		end if; 
				   
  end process;	


--MANAGEMENT BLOCK_READING
RF_CONTROL_COMBINATIONAL: process(CALL,CANSAVE_flag,RD1,RD2,ADD_RD1,ADD_RD2,RF_FS_address,RF)
 begin 
            MEM_spilling <= (others => 'Z');
	    DATA_OUT1 <= (others => 'Z');
				  DATA_OUT2 <= (others => 'Z');
				  
				  if(CALL='1' and CANSAVE_flag = '0') then
						MEM_spilling <= RF(to_integer( unsigned (RF_FS_address)));
				  end if;
				  			 
				  if(RD1='1') then  	  
					  DATA_OUT1 <= RF( to_integer(unsigned( ADD_RD1 ) ) );	 
				  end if;
													 
				  if(RD2='1') then  
					  DATA_OUT2 <= RF(to_integer( unsigned (ADD_RD2)));	 
				  end if;
				  				   
  end process;	
        
  
end beahv_struct;




