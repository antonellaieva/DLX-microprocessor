library ieee;
use ieee.std_logic_1164.all;
use WORK.DLX_package.all;


entity DLX is
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
end DLX;



architecture dlx_rtl of DLX is

 --------------------------------------------------------------------
 -- Components Declaration
 --------------------------------------------------------------------

  ----CONTROL UNIT----
  component dlx_cu
  generic (
    MICROCODE_MEM_SIZE :     integer := MICROCODE_MEM_SIZE;
    IRAM_DEPTH         :     integer := IRAM_DEPTH;    
    FUNC_SIZE          :     integer := 11;  -- Func Field Size for R-Type Ops
    OP_CODE_SIZE       :     integer := 6;  -- Op Code Size
    IR_SIZE            :     integer := 32;  -- Instruction Register Size    
    CW_SIZE            :     integer := 22);  -- Control Word Size
  port (
    Clk                : in  std_logic;  -- Clock
    Rst                : in  std_logic;  -- Reset:Active-Low
    -- Instruction Register
    IR_IN              : in  std_logic_vector(IR_SIZE - 1 downto 0);
    IR_EN              : out std_logic;


    -- Address Mem
    Address_IRAM       : in std_logic_vector(log2r(IRAM_DEPTH)-1 downto 0);
    ADDR_FS_bus        : out std_logic_vector(address_RF_DATA_RAM-1 downto 0);
    FILL               : in std_logic;
    SPILL              : in std_logic;
    SWP_in             : in std_logic_vector(log2r(F)-1 downto 0);
    CWP_in             : in std_logic_vector(log2r(F)-1 downto 0);
    CALL_stack         : out std_logic;
    RET_stack         : out std_logic;
    Call_jump          : out std_logic;
    
    -- IF Control Signal
    PC_EN              : out std_logic;
    COME_BACK          : out std_logic;
    ----------------------------------
    BRANCH_OUT         : out std_logic;

    -- ID Control Signals 
    EN_Dec             : out std_logic;  -- Registers Enable  
    RF1                : out std_logic;
    RF2                : out std_logic;
    CALL               : out std_logic;
    RET                : out std_logic;
    SIGN_SEL           : out std_logic;  
    IMM26_SEL          : out std_logic;
    Write_sel           : out std_logic;
    ZERO_sel_out       : out std_logic;
    
  
    -- EX Control Signals
    EN_Ex              : out std_logic;  -- Registers Enable  
    MUXA_SEL           : out std_logic;  -- MUX-A Sel
    MUXB_SEL           : out std_logic;  -- MUX-B Sel 
    ----------------------------------
    Equ_0              : in std_logic;
    ALU_OPCODE_out     : out TYPE_OP;    -- ALU Operation Code
    ALUsel_out         : out std_logic_vector(2 downto 0); -- ALU selection operation

    -- MEM Control signals
    EN_Mem             : out std_logic;  
    RM                 : out std_logic; 
    WM                 : out std_logic;  
    Byte               : out std_logic;
    Word               : out std_logic;
    Sign               : out std_logic;

    -- WB Control signals
    JUMP               : out std_logic;
    WB_MUX_SEL0        : out std_logic;  -- Write Back MUX Sel
    WB_MUX_SEL1        : out std_logic;
    WF                 : out std_logic);

end component;


  ----DATAPATH----
component DATAPATH
generic ( 
                   N : integer :=  N_DATA_SIZE ;
                   N_RCA : integer := n_bit_carry_select; 
                   D_RAM_DEPTH : integer := DRAM_DEPTH ;
                   I_SIZE : integer := N_DATA_SIZE
	          );
         port 
             (
	         -------------------INPUT-----------------------
	         Clk 	   : in std_logic;
	         Rst 	   : in std_logic;  --ACTIVE LOW
                 Pcout     : in std_logic_vector(N-1 downto 0);
                 IRout     : In std_logic_vector(N-1 downto 0);        
                 --ADDR_FS_bus  : In std_logic_vector(address_RF_DATA_RAM-1 downto 0);
                 Datamemtomux0_i : in std_logic_vector(N_DATA_SIZE -1 downto 0);
                 Datamemtomux1_byte_i : in std_logic_vector(N_DATA_SIZE/4 -1 downto 0);
                 Datamemtomux2_word_i : in std_logic_vector(N_DATA_SIZE/2 -1 downto 0);
                 MEM_FILL_bus_i : in std_logic_vector(N_DATA_SIZE -1 downto 0);


                 -------------------OUTPUT----------------------
                 Mux1toPc    : Out std_logic_vector(N-1 downto 0);                
                 RcatoIRAM   : out std_logic_vector(N-1 downto 0);
                 FILL        : out std_logic;
                 SPILL       : out std_logic;
                 SWP_out     : out std_logic_vector(log2r(F)-1 downto 0);
                 CWP_out     : out std_logic_vector(log2r(F)-1 downto 0);
                 Op_outtoS4o : out std_logic_vector(N_DATA_SIZE -1 downto 0);
                 Metodatamem_o : out std_logic_vector(N_DATA_SIZE -1 downto 0);              
                 MEM_SPILL_bus_o : out std_logic_vector(N_DATA_SIZE -1 downto 0);

		 -------------------STACK----------------------
		 STACK_data_in      : out std_logic_vector(N_DATA_SIZE -1 downto 0);
    		 STACK_data_out     : in std_logic_vector(N_DATA_SIZE -1 downto 0);
		 Call_jump          : in std_logic;
                 
                 ---------------CONTROL_SIGNALS-----------------
                 -- IF Control Signal  
                 comeback  : in std_logic;
                 BRANCH_sel: in std_logic;

                 -- ID Control Signals 
                 EN2       : in std_logic; 
                 RF1       : in std_logic;
                 RF2       : in std_logic;
                 CALL      : in std_logic;
                 RET       : in std_logic;             
                 SIGN      : in std_logic;
                 IMM26     : in std_logic;
                 Write_sel  : in std_logic;
                 Zero_sel  : in std_logic;

                 -- EX Control Signals  
                 EN3       : in std_logic;
                 S1        : in std_logic;
                 S2        : in std_logic;
                 ----------------------------------------------
                 Equal_zero   : out std_logic;
                 ALU_OPCODE   : in type_op;
                 ALUsel       : in std_logic_vector(2 downto 0);  
                 
                 -- MEM Control signals
                 EN4      : in std_logic;
                 byte     : in std_logic;
                 word     : in std_logic;
                 si       : in std_logic;

                 -- WB Control signals 
                 JUMP     : in std_logic;                
                 S4       : in std_logic; 
                 S5       : in std_logic; 
                 WF       : in std_logic 
                 
               );
end component;





  ----------------------------------------------------------------
  -- Signals Declaration
  ----------------------------------------------------------------
  
  -- Instruction Register (IR) and Program Counter (PC) declaration
  signal IR : std_logic_vector(IR_SIZE - 1 downto 0);
  signal PC : std_logic_vector(PC_SIZE - 1 downto 0);
  signal Address_IRAM_sig : std_logic_vector(log2r(IRAM_DEPTH) - 1 downto 0);

  -- Datapath Bus signals
  signal PC_BUS : std_logic_vector(PC_SIZE -1 downto 0);
  signal PC_BRANCH_BUS : std_logic_vector(PC_SIZE -1 downto 0);
  signal PC_IRam : std_logic_vector(PC_SIZE-1 downto 0);
  signal Fi : std_logic;
  signal Sp : std_logic;
  signal SWP: std_logic_vector(log2r(F)-1 downto 0);
  signal CWP: std_logic_vector(log2r(F)-1 downto 0);
  signal Op_outtoS4   : std_logic_vector(N_DATA_SIZE -1 downto 0);

  --STACK signals
  signal Call_jump : std_logic;

  -- Control Unit Bus signals
  signal IR_EN        : std_logic;
  signal PC_EN        : std_logic;
  signal COMEBACK     : std_logic;
  signal BRANCH_sel    : std_logic;
  -------------------------                            
  signal EN_Dec       : std_logic;  -- Registers Enable  
  signal RF1          : std_logic;
  signal RF2          : std_logic;
  signal CALL_sig     : std_logic;
  signal RET_sig      : std_logic;
  signal SIGN_SEL     : std_logic;  
  signal IMM26_SEL    : std_logic;
  signal WR_sel       : std_logic;
  signal Zero_sel     : std_logic;
  -------------------------  
  signal EN_Ex        : std_logic; 
  signal MUXA_SEL     : std_logic;  -- MUX-A Sel
  signal MUXB_SEL     : std_logic;  -- MUX-B Sel 
  signal EQ0          : std_logic;
  signal ALU_OPCODE   : TYPE_OP;    -- ALU Operation Code
  signal ALUsel       : std_logic_vector(2 downto 0); -- ALU selection operation
  -------------------------
  signal EN_Mem       : std_logic; 
  signal B            : std_logic;
  signal W            : std_logic;
  signal S            : std_logic;
  -------------------------
  signal JUMP         : std_logic;
  signal WB_MUX_SEL0  : std_logic;  -- Write Back MUX Sel
  signal WB_MUX_SEL1  : std_logic;
  signal WF           : std_logic;



  begin  -- DLX

-------------------------------------------------------------------------------------------------------------------------------------
  -- INSTRUCTION REGISTER
-------------------------------------------------------------------------------------------------------------------------------------
    -- purpose: Instruction Register Process
    -- type   : sequential
    -- inputs : Clk, Rst, IRam_DOut, IR_LATCH_EN_i
    -- outputs: IR_IN_i
    IR_P: process (Clk, Rst)
    begin  -- process IR_P
      if Rst = '0' then                 -- asynchronous reset (active low)
           IR <= (others => '0');
      elsif Clk'event and Clk = '1' then  -- rising clock edge
        if (IR_EN = '1') then
           IR <= IRam_DOut;
        end if;
      end if;
    end process IR_P;



-------------------------------------------------------------------------------------------------------------------------------------
  -- PROGRAM COUNTER
-------------------------------------------------------------------------------------------------------------------------------------
    -- purpose: Program Counter Process
    -- type   : sequential
    -- inputs : Clk, Rst, PC_BUS
    -- outputs: IRam_Addr
    PC_P: process (Clk, Rst)
    begin  -- process PC_P
      if Rst = '0' then                 -- asynchronous reset (active low)
        PC <= (others => '0');
      elsif Clk'event and Clk = '1' then  -- rising clock edge
        if (PC_EN = '1') then
          PC <= PC_BUS;
        end if;
      end if;
    end process PC_P;

    
    -- purpose: Mux for Current Instruction Process
    -- type   : combinational
    -- inputs : BRANCH_sel, PC_BRANCH_BUS, PC
    -- outputs: PC_IRam
    PC_BRANCH : process(BRANCH_sel, PC_BRANCH_BUS, RET_sig, STACK_data_out, PC)
    begin
        if (BRANCH_sel = '1') then
	PC_IRam <= PC_BRANCH_BUS;      
        elsif (RET_sig = '1') then
	PC_IRam <= STACK_data_out;
	else
        PC_IRam <= PC;
        end if;
    end process;
    
    --The addressing of the IRAM is done using a lower number of bits
     Address_IRAM_sig <= PC_IRam(log2r(IRAM_DEPTH)-1 downto 0);
     Address_IRAM <= Address_IRAM_sig;

-------------------------------------------------------------------------------------------------------------------------------------
  -- CONTROL UNIT
-------------------------------------------------------------------------------------------------------------------------------------
    -- Control Unit Instantiation
    CU_I: dlx_cu
      port map (
          Clk    => Clk,
          Rst    => Rst,
          IR_IN  => IR,
          IR_EN  => IR_EN,
          COME_BACK => COMEBACK,
          Address_IRAM => Address_IRAM_sig,
          PC_EN => PC_EN,  
          BRANCH_OUT => BRANCH_sel,
          ADDR_FS_bus => ADDRESS_FS_bus,
          FILL => Fi,
          SPILL => Sp,
          SWP_in => SWP,
          CWP_in => CWP,
          CALL_stack => CALL_stack,
          RET_stack => RET_stack,
	  Call_jump =>  Call_jump,
          ---------------------------                 
          EN_Dec => EN_Dec,
          RF1 => RF1,
          RF2 => RF2,
          Write_sel => WR_sel,
          CALL => CALL_sig,
          RET => RET_sig,
          SIGN_SEL => SIGN_SEL, 
          IMM26_SEL => IMM26_SEL,
          Zero_sel_out => Zero_sel,
          ---------------------------
          EN_Ex => EN_Ex, 
          MUXA_SEL => MUXA_SEL,
          MUXB_SEL => MUXB_SEL,
          Equ_0 => EQ0,
          ALU_OPCODE_out => ALU_OPCODE,
          ALUsel_out => ALUsel,
          ---------------------------
          EN_Mem => EN_Mem,
          RM => RM, 
          WM => WM, 
          Byte => B,
          Word => W,
          Sign => S,
          ---------------------------
          JUMP => JUMP,
          WB_MUX_SEL0 => WB_MUX_SEL0,  -- Write Back MUX Sel
          WB_MUX_SEL1 => WB_MUX_SEL1,
          WF => WF
      );


  --------------------------------------------------------------------------------------------
  -- DRAM_SIGNALS
  --------------------------------------------------------------------------------------------  

   --Bit selection for the address of the DRAM, since the memory has not length equal to 2**32
   Addr_DRAM <= Op_outtoS4(log2r(DRAM_DEPTH)-1 downto 0); 
   Mword <= W;
   Mbyte <= B;
   Spill <= Sp;
   Fill <= Fi;


-------------------------------------------------------------------------------------------------------------------------------------
  -- DATAPATH
-------------------------------------------------------------------------------------------------------------------------------------
    DATAPATH_I : DATAPATH
      generic map (
             N => N_DATA_SIZE,
             N_RCA => n_bit_carry_select, 
             D_RAM_DEPTH => DRAM_DEPTH,
             I_SIZE => N_DATA_SIZE
           )
      port map (
             -------------------INPUT-----------------------
            Clk       => Clk,
            Rst       => Rst,
            Pcout     => PC,
            IRout     => IR,
	    MEM_FILL_bus_i => MEM_FILL_bus,
            Datamemtomux0_i => Datamemtomux0,
            Datamemtomux1_byte_i => Datamemtomux1_byte, 
            Datamemtomux2_word_i => Datamemtomux2_word,           

            -------------------OUTPUT----------------------
            Mux1toPc  => PC_BUS,        
            RcatoIRAM => PC_BRANCH_BUS,
            --ADDR_FS_bus => ADDRESS_FS_bus,
            FILL => Fi,
            SPILL => Sp,
            SWP_out => SWP,
            CWP_out => CWP,
            Op_outtoS4o => Op_outtoS4,
	    Metodatamem_o => Metodatamem,
	    MEM_SPILL_bus_o => MEM_SPILL_bus,

	    ---------------STACK------------------------
	    STACK_data_in => STACK_data_in,
	    STACK_data_out => STACK_data_out,
	    Call_jump =>  Call_jump,

            ---------------CONTROL_SIGNALS-----------------
            -- IF Control Signal  
            comeback  => COMEBACK,
            BRANCH_sel => BRANCH_sel,

            -- ID Control Signals 
            EN2       => EN_Dec,
            RF1       => RF1,
            RF2       => RF2,
            CALL      => CALL_sig,
            RET       => RET_sig,          
            SIGN      => SIGN_sel,
            IMM26     => IMM26_sel,
            Write_sel  => WR_sel,
            Zero_sel  => Zero_sel,

            -- EX Control Signals  
            EN3       => EN_Ex,
            S1        => MUXA_sel,
            S2        => MUXB_sel,
            Equal_zero => EQ0,
            ALU_OPCODE => ALU_OPCODE,
            ALUsel     => ALUsel,
         
            -- MEM Control signals
            EN4        => EN_Mem,
            Byte       => B,
            Word       => W,
            Si         => S,

            -- WB Control signals
            JUMP     => JUMP,            
            S4       => WB_MUX_SEL0,
            S5       => WB_MUX_SEL1,
            WF       => WF
           );

       
    
end dlx_rtl;
