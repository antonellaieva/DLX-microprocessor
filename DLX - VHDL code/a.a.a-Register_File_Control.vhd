library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

entity Register_File_Control is
  generic (
    RF_address_mem     : integer := address_RF_DATA_RAM;
    RF_window_size     : integer := log2r(F);
    RF_section         : integer := 2*N_reg_block
  );
  port (
    Clk                : in  std_logic;  -- Clock
    Rst                : in  std_logic;  -- Reset:Active-Low
    CALL               : in  std_logic;
    RET                : in  std_logic;
    SWP                : in  std_logic_vector(RF_window_size -1 downto 0);
    CWP                : in  std_logic_vector(RF_window_size -1 downto 0);
    FILL               : in std_logic;
    SPILL              : in std_logic;
    PC_block           : out std_logic;
    CALL_stack         : out std_logic;
    RET_stack         : out std_logic;
    Call_jump          : out std_logic;
    MEM_ADDRESS        : out std_logic_vector(RF_address_mem -1 downto 0)
	 );
end Register_File_Control;

architecture arch_CU_RF of Register_File_Control is

  -------------------------------------------------------------------------------------------------------------------------------------------
  -- Components
  -------------------------------------------------------------------------------------------------------------------------------------------

component mux21_generic is
  
  generic (
    N : integer );
  port (
    A: in std_logic_vector(0 to N-1);
    B: in std_logic_vector(0 to N-1);
    SEL: in std_logic;
    Y: out std_logic_vector(0 to N-1)
    );
end component;

component flipflop IS 
PORT 
( D, Clock: IN STD_LOGIC ;
  RESET  : IN STD_LOGIC;
  Q: OUT STD_LOGIC
) ;
end component;


  -------------------------------------------------------------------------------------------------------------------------------------------
  -- Signals
  -------------------------------------------------------------------------------------------------------------------------------------------

  signal CWPminus       : std_logic_vector(RF_window_size-1 downto 0);
  signal CWPplus2       : std_logic_vector(RF_window_size-1 downto 0);
  signal cansave_CU     : std_logic;
  signal canrestore_CU  : std_logic;
  signal block_call     : std_logic;
  --signal block_ret      : std_logic;
  signal block_cnt      : std_logic;
  signal MEM_ADDRESS_1_tmp : std_logic_vector(RF_address_mem -1 downto 0);
  signal MEM_ADDRESS_tmp : std_logic_vector(RF_address_mem -1 downto 0);
  signal MEM_OUT        : std_logic_vector(RF_address_mem -1 downto 0);
  signal exnor_net0     : std_logic_vector(RF_window_size-1 downto 0);
  signal and_net0       : std_logic_vector(RF_window_size-2 downto 0);
  signal exnor_net1     : std_logic_vector(RF_window_size-1 downto 0);
  signal and_net1       : std_logic_vector(RF_window_size-2 downto 0);
  signal counter        : std_logic_vector(log2r(RF_section) -1 downto 0);
  signal enable         : std_logic;
  signal startcount     : std_logic;
  signal endcount, endcount_delay : std_logic;
  signal Call_jump_EX, Call_jump_MEM : std_logic;
  type State is ( RESET, START, GO_ON_SPILL, GO_ON_FILL, LAST_FILL );
  signal PS, NS : State;

 
  begin 
  
  -------------------------------------------------------------------------------------------------------------------------------------------
  -- CANSAVE_CU
  -------------------------------------------------------------------------------------------------------------------------------------------
     CWPplus2 <= CWP + 2;
  

     Cansave_Control0:    for i in 0 to RF_window_size -1  generate
			       exnor_net0(i)<= CWPplus2(i) xnor SWP(i);
			  end generate;

                         and_net0(0)<=exnor_net0(0) and exnor_net0(1);

     Cansave_Control1:    for i in 1 to RF_window_size -2  generate
			       and_net0(i)<= and_net0(i-1) and exnor_net0(i+1);
			  end generate;
     
     cansave_CU <= and_net0(RF_window_size - 2);

     block_call <= CALL and cansave_CU;

 
  -------------------------------------------------------------------------------------------------------------------------------------------
  -- CANRESTORE_CU
  -------------------------------------------------------------------------------------------------------------------------------------------
     CWPminus <= CWP;

     Canrestore_Control0: for i in 0 to RF_window_size -1  generate
			       exnor_net1(i)<= CWPminus(i) xnor SWP(i);
			  end generate;

                         and_net1(0)<=exnor_net1(0) and exnor_net1(1);

     Canrestore_Control1: for i in 1 to RF_window_size -2  generate
			       and_net1(i)<= and_net1(i-1) and exnor_net1(i+1);
			  end generate;
     
     canrestore_CU <= and_net1(RF_window_size-2);

     --block_ret <= RET and canrestore_CU; 


  -------------------------------------------------------------------------------------------------------------------------------------------
  -- COUNTER FOR SPILL/FILL
  ------------------------------------------------------------------------------------------------------------------------------------------- 
     
  -----------------Control Counter--------------------
     Next_State : process(block_call,PS,Rst,counter,RET,canrestore_CU)
		      begin
			   NS <= RESET; --default value for NS
		           case PS is
			        when RESET => NS <= START;
	       
	                        when START => ------------------------------SPILL--------------------------------
                                              if (block_call = '1') then NS <= GO_ON_SPILL;
	                                           elsif (RET = '1' and canrestore_CU = '1') then NS <= GO_ON_FILL;
															 else NS <= START;
															 end if;
															 
															 if(Rst = '0') then
															    NS <= RESET;
															 end if;
                                              
	                        when GO_ON_SPILL => if (counter = std_logic_vector(to_unsigned(RF_section-2,log2r(RF_section)))) then NS <= START;
	                                            else                                                                              NS <= GO_ON_SPILL;
				                    end if;
                                                    if (Rst = '0') then NS <= RESET;
                                                    end if;
                                
                                when GO_ON_FILL => if (counter = std_logic_vector(to_unsigned(RF_section-3,log2r(RF_section)))) then NS <= LAST_FILL;
	                                           else                                                                              NS <= GO_ON_FILL;
					           end if;
                                                   if (Rst = '0') then NS <= RESET;
                                                   end if;
                               
                               when LAST_FILL =>   if (Rst = '0') then NS <= RESET;
                                                   else                NS <= START;
                                                   end if;
                               end case;
                  end process;

     State_Register: process(Clk)
		      begin
		      if(Clk'EVENT and Clk = '1') then
		         if (Rst = '0') then
			       PS <= RESET;
			 else
			       PS <= NS;
		         end if;
		      end if;
		 end process State_Register;

     
     Output : process(block_call,PS,RET,canrestore_CU)
		  begin
		      startcount <= '0';
		      block_cnt  <= '0';
            
		      case PS is
                                 
			         when RESET => startcount <= '0';
					       block_cnt <= '0';
						 
				 when START => startcount <= '0';
					       if ((block_call = '1') or (RET = '1' and canrestore_CU = '1')) then block_cnt <= '1';
                                               end if;
	                         when GO_ON_SPILL => startcount <= '1';
                                                    block_cnt <= '1';

                                 when GO_ON_FILL => startcount <= '1';
                                                    block_cnt <= '1';
		       when LAST_FILL => block_cnt <= '0';
		       end case;
		  end process;
    

   -----------------  Counter  --------------------
    
   Counter_FILL_SPILL_cycles :  process(Clk, startcount)
					begin
					if startcount ='0' then
					   counter <= std_logic_vector(to_unsigned(0,log2r(RF_section)));
					elsif(Clk'EVENT and Clk = '1' and startcount = '1') then
					   counter <= counter + 1 ;
			                end if;
				end process;
		      
      
  -------------------------------------------------------------------------------------------------------------------------------------------
  -- PROGRAM COUNTER BLOCK
  -------------------------------------------------------------------------------------------------------------------------------------------
    PC_block <= (not block_cnt);

  -------------------------------------------------------------------------------------------------------------------------------------------
  -- STACK MANAGEMENT
  -------------------------------------------------------------------------------------------------------------------------------------------
  --Needed to know the last tick of the SPILL operation
    endcount <= '1' when counter = std_logic_vector(to_unsigned(RF_section-2,log2r(RF_section))) else '0';
    R0: flipflop
            port map(D=> endcount, Clock=>Clk,RESET=>Rst,Q=>endcount_delay);

   

    CALL_stack <= '1' when (CALL = '1' and PS = START and endcount_delay = '0') else '0';
    RET_stack <= '1' when (RET = '1' and PS = START) else '0';
    Call_jump_EX <= '1' when (( block_cnt = '0' and CALL = '1' and PS = START) or (CALL = '1' and SPILL = '1' and endcount_delay = '1')) else '0';

    --Three registers, in order to delay the CALL_JUMP signal and then computing the jump address
   R1: flipflop
            port map(D=>Call_jump_EX, Clock=>Clk,RESET=>Rst,Q=>Call_jump_MEM);

   R2: flipflop
            port map(D=>Call_jump_MEM, Clock=>Clk,RESET=>Rst,Q=>Call_jump);

  -------------------------------------------------------------------------------------------------------------------------------------------
  -- ADDRESS MEMORY FOR FILL AND SPILL OPERATION
  -------------------------------------------------------------------------------------------------------------------------------------------
    Addressing_FILL_SPILL :  process(Clk,Rst,FILL,SPILL)
                             begin

                                 if (Clk'EVENT and Clk = '1') then
                                     if (Rst = '0') then
                                         MEM_ADDRESS_tmp <= std_logic_vector(to_unsigned(0,RF_address_mem));
                                         MEM_ADDRESS_1_tmp <= std_logic_vector(to_unsigned(2**RF_address_mem-4,RF_address_mem));
                                     elsif ( SPILL = '1' ) then
                                         MEM_ADDRESS_tmp <= MEM_ADDRESS_tmp + 4;
                                         MEM_ADDRESS_1_tmp <= MEM_ADDRESS_1_tmp + 4;
                                     elsif ( FILL = '1' ) then
                                         MEM_ADDRESS_tmp <= MEM_ADDRESS_tmp - 4;
                                         MEM_ADDRESS_1_tmp <= MEM_ADDRESS_1_tmp - 4;
                                     end if;

                                 end if;
                       
                             end process;
   
  	 
     UMUX_S : MUX21_GENERIC 
	       generic map (N=>RF_address_mem)
	       port map    (A=>MEM_ADDRESS_1_tmp, B=>MEM_ADDRESS_tmp, SEL=>CALL, Y=>MEM_OUT);
 
 
     MEM_ADDRESS <= MEM_OUT;
   
   
    
 end arch_CU_RF;

