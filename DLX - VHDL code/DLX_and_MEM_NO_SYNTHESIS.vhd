library ieee;
use ieee.std_logic_1164.all;
use WORK.DLX_package.all;


entity DLX_and_MEM is
  generic (
    IR_SIZE      : integer := N_DATA_SIZE;       -- Instruction Register Size
    PC_SIZE      : integer := N_DATA_SIZE       -- Program Counter Size
    );       
  port (
    Clk : in std_logic;
    Rst : in std_logic);                -- Active Low
end DLX_and_MEM;



architecture dlx_rtl of DLX_and_MEM is

 --------------------------------------------------------------------
 -- Components Declaration
 --------------------------------------------------------------------

  ----DLX----
  component DLX is
  generic (
    IR_SIZE      : integer := N_DATA_SIZE;       -- Instruction Register Size
    PC_SIZE      : integer := N_DATA_SIZE       -- Program Counter Size
    );       
  port (
    Clk       : in std_logic;
    Rst       : in std_logic;

    --------------------------------IRAM--------------------------------------
    Address_IRAM : out  std_logic_vector(log2r(IRAM_DEPTH) - 1 downto 0);
    IRam_Dout : in std_logic_vector(IR_SIZE - 1 downto 0);

    --------------------------------DRAM--------------------------------------
    Addr_DRAM : out std_logic_vector(log2r(DRAM_DEPTH) -1 downto 0);
    Metodatamem  : out std_logic_vector(N_DATA_SIZE -1 downto 0);
    Datamemtomux0 : in std_logic_vector(N_DATA_SIZE -1 downto 0);
    Datamemtomux1_byte : in std_logic_vector(N_DATA_SIZE/4 -1 downto 0);
    Datamemtomux2_word : in std_logic_vector(N_DATA_SIZE/2 -1 downto 0);
    MEM_SPILL_bus : out std_logic_vector(N_DATA_SIZE -1 downto 0);
    MEM_FILL_bus : in std_logic_vector(N_DATA_SIZE -1 downto 0);
    Mbyte        : out std_logic;
    Mword        : out std_logic;
    RM           : out std_logic; 
    WM           : out std_logic; 
    Spill        : out std_logic;
    Fill         : out std_logic;
    ADDRESS_FS_bus : out std_logic_vector(address_RF_DATA_RAM-1 downto 0);
    --------------------------------STACK--------------------------------------
    STACK_data_in      : out std_logic_vector(N_DATA_SIZE -1 downto 0);
    STACK_data_out     : in std_logic_vector(N_DATA_SIZE -1 downto 0);
    CALL_stack         : out std_logic;
    RET_stack          : out std_logic
  ); 
  end component;


  ----IRAM----
  component IRAM is
  generic (
    RAM_DEPTH : integer := IRAM_DEPTH;
    I_SIZE : integer := 32);
  port (
    Rst  : in  std_logic;
    Addr : in  std_logic_vector(log2r(IRAM_DEPTH) - 1 downto 0);
    Dout : out std_logic_vector(I_SIZE - 1 downto 0)
    ); 
  end component;


  ----DRAM----
  component DRAM is
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
  end component;

	----STACK----
	component STACK is
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

	end component;



  ----------------------------------------------------------------
  -- Signals Declaration
  ----------------------------------------------------------------

	-- IRAM signals declaration
	signal Address_IRAM_sig       :  std_logic_vector(log2r(IRAM_DEPTH) - 1 downto 0);
	signal IRam_Dout_sig          :  std_logic_vector(IR_SIZE - 1 downto 0);

	-- DRAM signals declaration
	signal Addr_DRAM_sig          : std_logic_vector(log2r(DRAM_DEPTH) -1 downto 0);
	signal Metodatamem_sig        : std_logic_vector(N_DATA_SIZE -1 downto 0);
	signal Datamemtomux0_sig      : std_logic_vector(N_DATA_SIZE -1 downto 0);
	signal Datamemtomux1_byte_sig : std_logic_vector(N_DATA_SIZE/4 -1 downto 0);
	signal Datamemtomux2_word_sig : std_logic_vector(N_DATA_SIZE/2 -1 downto 0);
	signal MEM_SPILL_bus_sig      : std_logic_vector(N_DATA_SIZE -1 downto 0);
	signal MEM_FILL_bus_sig       : std_logic_vector(N_DATA_SIZE -1 downto 0);
	signal Mbyte_sig              : std_logic;
	signal Mword_sig              : std_logic;
	signal RM_sig                 : std_logic; 
	signal WM_sig                 : std_logic; 
	signal Spill_sig              : std_logic;
	signal Fill_sig               : std_logic;
	signal ADDRESS_FS_bus_sig     : std_logic_vector(address_RF_DATA_RAM-1 downto 0);

	-- STACK signals declaration
	signal CALL_stack_sig, RET_stack_sig : std_logic;
	signal STACK_data_in, STACK_data_out : std_logic_vector(N_DATA_SIZE -1 downto 0);


  begin  -- DLX
  -------------------------------------------------------------------------------------------------------------------------------------
  -- DLX PROCESSOR 
  -------------------------------------------------------------------------------------------------------------------------------------
    -- DLX Instantiation
    U_DLX: dlx
           port map (
            Clk    => Clk,
            Rst    => Rst,
            ---------------------------    
            Address_IRAM => Address_IRAM_sig,
            IRam_Dout => IRam_Dout_sig,
            ---------------------------                 
            Addr_DRAM => Addr_DRAM_sig,
	    Metodatamem => Metodatamem_sig,
	    Datamemtomux0 => Datamemtomux0_sig,
	    Datamemtomux1_byte => Datamemtomux1_byte_sig,
	    Datamemtomux2_word => Datamemtomux2_word_sig,
	    MEM_SPILL_bus => MEM_SPILL_bus_sig,
	    MEM_FILL_bus => MEM_FILL_bus_sig,
	    Mbyte => Mbyte_sig,
	    Mword => Mword_sig,
	    RM => RM_sig,
	    WM => WM_sig,
	    Spill => Spill_sig,
	    Fill => Fill_sig,
	    ADDRESS_FS_bus => ADDRESS_FS_bus_sig,
		 CALL_stack => CALL_stack_sig,
		 RET_stack => RET_stack_sig,
		 STACK_data_in => STACK_data_in,
		 STACK_data_out => STACK_data_out
           );


  --------------------------------------------------------------------------------------------
  -- IRAM Instantation
  --------------------------------------------------------------------------------------------  
   UIRAM: IRAM
          port map (
	  Rst => Rst,
          Addr => Address_IRAM_sig,
          Dout => IRam_Dout_sig
          );
     

  --------------------------------------------------------------------------------------------
  -- DRAM Instantation
  --------------------------------------------------------------------------------------------  
  UDRAM: DRAM
         port map (
	  Rst => Rst,
          Clk => Clk,
	  En => '1',
	  Rd => RM_sig,
	  Wr => WM_sig,
          Spill => Spill_sig,
          Fill => Fill_sig,
          Rword => Mword_sig,
          Rbyte => Mbyte_sig,
          Addr_FS => ADDRESS_FS_bus_sig,
          Addr => Addr_DRAM_sig,
          Din  => Metodatamem_sig,
          Din_SPILL => MEM_SPILL_bus_sig,           
          Dout => Datamemtomux0_sig,
          Dout_FILL => MEM_FILL_bus_sig,
          Dout_byte => Datamemtomux1_byte_sig,
          Dout_word => Datamemtomux2_word_sig       
         );
    
  --------------------------------------------------------------------------------------------
  -- STACK Instantation
  --------------------------------------------------------------------------------------------  
	USTACK: STACK
		port map (
			Rst => Rst,
			Clk => Clk,
			RD => RET_stack_sig,
			WR => CALL_stack_sig,
			Din => STACK_data_in,
			Dout => STACK_data_out 
		);
end dlx_rtl;
