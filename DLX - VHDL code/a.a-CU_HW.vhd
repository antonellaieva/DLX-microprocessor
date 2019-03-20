library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use WORK.DLX_package.all;

entity dlx_cu is
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
    RET_stack          : out std_logic;
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

end dlx_cu;

architecture dlx_cu_hw of dlx_cu is
  -------------------------------------------------------------------------------------------------------------------------------------------
  -- Components
  -------------------------------------------------------------------------------------------------------------------------------------------
  component FD is
	Generic (N: integer:= 5);
	Port (			
			D:	In	std_logic_vector (N-1 DOWNTO 0);
			ENABLE: In      std_logic;    
                        CK:	In	std_logic;
			RESET:	In	std_logic;
			Q:	Out	std_logic_vector (N-1 DOWNTO 0)
		  );
  end component;
  -----------------------------------------------------------------------
 component flipflop IS 
  PORT 
  ( D, Clock: IN STD_LOGIC ;
    RESET  : IN STD_LOGIC;
    Q: OUT STD_LOGIC
  ) ;
 end component;
 ------------------------------------------------------------------------
 component Register_File_Control
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
  end component;
 

  -------------------------------------------------------------------------------------------------------------------------------------------
  -- Signals
  -------------------------------------------------------------------------------------------------------------------------------------------
 
  -- management of the Decode LUT
  signal IR_opcode : std_logic_vector(OP_CODE_SIZE -1 downto 0);  -- OpCode part of IR
  signal IR_op_sig : std_logic_vector(OP_CODE_SIZE -1 downto 0);
  signal IR_func : std_logic_vector(FUNC_SIZE -1 downto 0);   -- Func part of IR when Rtype
  signal IR_fu_sig : std_logic_vector(FUNC_SIZE -1 downto 0); 
  signal cw,cw0   : std_logic_vector(CW_SIZE - 1 downto 0); -- full control word read from cw_mem
  signal nop_R : std_logic;
  signal stallJ : std_logic;
  signal TC0,TC1,TC2,TC3 : std_logic;
  signal stallB : std_logic;
  signal TC0b,TC1b,TC2b,TC3b : std_logic;
  signal IR_instruction : TYPE_INSTRUCTION ;
  
  -- control word is shifted to the correct stage
  signal cw1 : std_logic_vector(CW_SIZE - 10 downto 0); -- third stage 
  signal cw2 : std_logic_vector(CW_SIZE - 12 downto 0); -- fourth stage
  signal cw3 : std_logic_vector(CW_SIZE - 20 downto 0); -- fifth stage
  signal ALU_OPCODE : TYPE_OP;
  signal ALUsel    : std_logic_vector(2 downto 0);

  --management of BRANCH unit
  signal HISTORY  : std_logic;
  signal BR_flag  : std_logic;
  signal OPCODE_pipe : std_logic_vector(1 downto 0);
  signal SALTO    : std_logic;
  signal comeback_signal : std_logic;

  --management of REGISTER FILE WINDOWING
  signal PC_block  : std_logic;
  


  -------------------------------------------------------------------------------------------------------------------------------------------
  -- DECODE MEMORY
  -------------------------------------------------------------------------------------------------------------------------------------------
  
  type mem_array is array (integer range 0 to MICROCODE_MEM_SIZE - 1) of std_logic_vector(CW_SIZE - 1 downto 0);

  signal cw_mem : mem_array := ("1110000101011000000001", -- (0) R type
                                "1110000101011000000001", -- (1) MULT
                                "1000011001101000001000", -- (2) J
                                "1000001001101000001011", -- (3) JAL 
                                "1010010011111000000000", -- (4) BEQZ 
                                "1010010011111000000000", -- (5) BNEZ                     
                                "0000000000000000000000", -- (6) BFPT
                                "0000000000000000000000", -- (7) BFPF
                                "1010010001111000000001", -- (8) ADDI
                                "1010000001111000000001", -- (9) ADDUI
                                "1010010001111000000001", -- (10) SUBI
                                "1010000001111000000001", -- (11) SUBUI
                                "1010000001111000000001", -- (12) ANDI
                                "1010000001111000000001", -- (13) ORI
                                "1010000001111000000001", -- (14) XORI
                                "0000000000000000000000", -- (15) LHI
                                "0000000000000000000000", -- (16) RFE
                                "0000000000000000000000", -- (17) TRAP
                                "1010000011111000001000", -- (18) JR
                                "1010000011101000001011", -- (19) JALR
                                "1010000001111000000001", -- (20) SLLI
                                "0000000000010000000000", -- (21) NOP
                                "1010000001111000000001", -- (22) SRLI
                                "1010000001111000000001", -- (23) SRAI
                                "1010010001111000000001", -- (24) SEQI
                                "1010010001111000000001", -- (25) SNEI 
                                "1010010001111000000001", -- (26) SLTI
                                "1010010001111000000001", -- (27) SGTI
                                "1010010001111000000001", -- (28) SLEI
                                "1010010001111000000001", -- (29) SGEI
                                "1001011001101000000000", -- (30) CALL
                                "0000100000000000000000", -- (31) RET
                                "1010010001111101010101", -- (32) LB
                                "0000000000000000000000", -- (33) LH
                                "0000000000000000000000", -- (34)
                                "1010010001111100100101", -- (35) LW 
                                "1010010001111101000101", -- (36) LBU
                                "0000000000000000000000", -- (37) LHU
                                "0000000000000000000000", -- (38) LF
                                "0000000000000000000000", -- (39) LD
                                "1110010001111011000000", -- (40) SB
                                "0000000000000000000000", -- (41) SH
                                "0000000000000000000000", -- (42) 
                                "1110010001111010100000", -- (42) SW                    
                                "0000000000000000000000", -- (44)
                                "0000000000000000000000", -- (45)
                                "0000000000000000000000", -- (46) SF
                                "0000000000000000000000", -- (47) SD
                                "0000000000000000000000", -- (48) ITLB
                                "0000000000000000000000", -- (49) 
                                "0000000000000000000000", -- (50)
                                "0000000000000000000000", -- (51)
                                "0000000000000000000000", -- (52)
                                "0000000000000000000000", -- (53)
                                "0000000000000000000000", -- (54) 
                                "0000000000000000000000", -- (55) 
                                "0000000000000000000000", -- (56) 
                                "0000000000000000000000", -- (57) 
                                "1010000001111000000001", -- (58) SLTUI
                                "1010000001111000000001", -- (59) SGTUI
                                "1010000001111000000001", -- (60) SLEUI
                                "1010000001111100000001"  -- (61) SGEUI
                               );


   component BHT
   port(
	     Clk          : IN std_logic;
	     Rst          : IN std_logic;
	     BRANCH       : IN  std_logic;
	     OPCODE_PIPE  : IN  std_logic;    --coming from the execution stage
	     COME_BACK    : OUT  std_logic;
	     HISTORY      : OUT  std_logic   		
	 );
   end component;

 
begin 

  -------------------------------------------------------------------------------------------------------------------------------------------
  -- CONTROL WORD PIPELINE
  -------------------------------------------------------------------------------------------------------------------------------------------
  IR_opcode <= IR_IN(IR_SIZE -1 downto IR_SIZE - OP_CODE_SIZE);
  IR_func  <= IR_IN(FUNC_SIZE - 1 downto 0);
  

  cw0 <= cw_mem(conv_integer(IR_opcode));
  Control_word: for i in 0 to CW_SIZE -1  generate
	            cw(i)<= cw0(i) and nop_R and stallJ and stallB;
	        end generate;


  IR_op0: for i in 0 to OP_CODE_SIZE-1 generate
                    IR_op_sig(i) <= IR_opcode(i) and stallJ and stallB;
              end generate;

  
  IR_func1: for i in 0 to FUNC_SIZE-1 generate
                    IR_fu_sig(i) <= IR_func(i) and stallJ and stallB;
              end generate;


  -- process to pipeline control words
  CW_PIPE: process (Clk, Rst)
  begin  -- process Clk
    if Rst = '0' then                  -- asynchronous reset (active low)
      cw1 <= (others => '0');
      cw2 <= (others => '0');
      cw3 <= (others => '0');

    elsif Clk'event and Clk = '1' then  -- rising clock edge
      cw1 <= cw(CW_SIZE - 10 downto 0);
      cw2 <= cw1(CW_SIZE - 12 downto 0);
      cw3 <= cw2(CW_SIZE - 20 downto 0);
    end if;
  end process CW_PIPE;


  -- stage two control signals
  EN_Dec        <= cw(CW_SIZE - 1);
  RF1           <= cw(CW_SIZE - 2);
  RF2           <= cw(CW_SIZE - 3);
  CALL          <= cw(CW_SIZE - 4);
  RET           <= cw(CW_SIZE - 5);
  SIGN_SEL      <= cw(CW_SIZE - 6);
  IMM26_SEL     <= cw(CW_SIZE - 7);
  Write_SEL      <= cw(CW_SIZE - 8);
  ZERO_sel_out  <= cw(CW_SIZE - 9);

  -- stage three control signals
  EN_Ex         <= cw1(CW_SIZE - 10);
  MUXA_SEL      <= cw1(CW_SIZE - 11);
  MUXB_SEL      <= cw1(CW_SIZE - 12);

  -- stage four control signals
  EN_Mem        <= cw2(CW_SIZE - 13);
  RM            <= cw2(CW_SIZE - 14);
  WM            <= cw2(CW_SIZE - 15);
  Byte          <= cw2(CW_SIZE - 16);
  Word          <= cw2(CW_SIZE - 17);
  Sign          <= cw2(CW_SIZE - 18);
  JUMP          <= cw2(CW_SIZE - 19);

  -- stage five control signals
  WB_MUX_SEL0   <= cw3(CW_SIZE - 20);
  WB_MUX_SEL1   <= cw3(CW_SIZE - 21);
  WF            <= cw3(CW_SIZE - 22);
   

  

  -------------------------------------------------------------------------------------------------------------------------------------------
  -- ALU_OPCODE_BLOCK
  -------------------------------------------------------------------------------------------------------------------------------------------
  -- purpose: Generation of ALU OpCode
  -- type   : combinational
  -- inputs : IR_i
  -- outputs: aluOpcode
   ALU_OPCODE_PROCESS : process (IR_op_sig, IR_fu_sig)
   begin  -- process ALU_OP_CODE_P
	ALU_OPCODE <= NOP;
	ALUsel     <= "000";
        nop_R      <= '1';
	case (conv_integer(IR_op_sig)) is  
	        -- case of R type requires analysis of FUNC
		when 0 =>
			case (conv_integer(IR_fu_sig)) is
				when 4  => ALU_OPCODE <= FUNCL_LOGIC;
                                           ALUsel     <= "000"; --sll
				when 6  => ALU_OPCODE <= FUNCR_LOGIC;
                                           ALUsel     <= "000"; --srl
                                when 7  => ALU_OPCODE <= FUNCR_ARITH;
                                           ALUsel     <= "000"; --sra
				when 32 => ALU_OPCODE <= ADD;
                                           ALUsel     <= "000"; --add
				when 33 => ALU_OPCODE <= ADD;
                                           ALUsel     <= "000"; --addu
				when 34 => ALU_OPCODE <= SUB;
                                           ALUsel     <= "000"; --sub                                
				when 35 => ALU_OPCODE <= SUB;
                                           ALUsel     <= "000"; --subu
				when 36 => ALU_OPCODE <= BITAND;
                                           ALUsel     <= "000"; --and
				when 37 => ALU_OPCODE <= BITOR;
                                           ALUsel     <= "000"; --or
				when 38 => ALU_OPCODE <= BITXOR;
                                           ALUsel     <= "000"; --xor
				when 40 => ALU_OPCODE <= SUB;
                                           ALUsel     <= "011"; --seq
				when 41 => ALU_OPCODE <= SUB;
                                           ALUsel     <= "100"; --sne
				when 42 => ALU_OPCODE <= SUB;
                                           ALUsel     <= "101"; --slt
                                when 43 => ALU_OPCODE <= SUB;
                                           ALUsel     <= "110"; --sgt
				when 44 => ALU_OPCODE <= SUB;
                                           ALUsel     <= "001"; --sle
				when 45 => ALU_OPCODE <= SUB;
                                           ALUsel     <= "010"; --sge
				when 48 => ALU_OPCODE <= NOP;
                                           ALUsel     <= "000"; --movi2s
				when 49 => ALU_OPCODE <= NOP;
                                           ALUsel     <= "000"; --movs2i  
				when 50 => ALU_OPCODE <= NOP;
                                           ALUsel     <= "000"; --movf 
				when 51 => ALU_OPCODE <= NOP;
                                           ALUsel     <= "000"; --movd
				when 52 => ALU_OPCODE <= NOP;
                                           ALUsel     <= "000"; --movfp2i
				when 53 => ALU_OPCODE <= NOP;
                                           ALUsel     <= "000"; --movi2fp
				when 54 => ALU_OPCODE <= NOP;
                                           ALUsel     <= "000"; --movi2t
				when 55 => ALU_OPCODE <= NOP;
                                           ALUsel     <= "000"; --movt2i 
				when 58 => ALU_OPCODE <= SUB;
                                           ALUsel     <= "101"; --sltu
				when 59 => ALU_OPCODE <= SUB;
                                           ALUsel     <= "110"; --sgtu
				when 60 => ALU_OPCODE <= SUB;
                                           ALUsel     <= "001"; --sleu
				when 61 => ALU_OPCODE <= SUB;
                                           ALUsel     <= "010"; --sgeu
				when others => nop_R <= '0'; 
			end case;
                -- other instructions
      when 1  => ALU_OPCODE <= MULT;   -- mult
      when 2  => ALU_OPCODE <= ADD;    -- j
      when 3  => ALU_OPCODE <= ADD;    -- jal
      when 4  => ALU_OPCODE <= ADD;    -- beqz
      when 5  => ALU_OPCODE <= ADD;    -- bnez
      when 8  => ALU_OPCODE <= ADD;    -- addi
      when 9  => ALU_OPCODE <= ADD;    -- addui
      when 10 => ALU_OPCODE <= SUB;    --subi
      when 11 => ALU_OPCODE <= SUB;    --subui
      when 12 => ALU_OPCODE <= BITAND; --andi
      when 13 => ALU_OPCODE <= BITOR;  --ori
      when 14 => ALU_OPCODE <= BITXOR; --xori
      when 19 => ALU_OPCODE <= ADD; --jr
      when 20 => ALU_OPCODE <= FUNCL_LOGIC; --slli
      when 21 => ALU_OPCODE <= NOP;    --nop
      when 22 => ALU_OPCODE <= FUNCR_LOGIC; --srli
      when 23 => ALU_OPCODE <= FUNCR_ARITH; --srai
      when 24 => ALU_OPCODE <= SUB;    --seqi
                 ALUsel     <= "011";
      when 25 => ALU_OPCODE <= SUB;    --snei
                 ALUsel     <= "100";
      when 26 => ALU_OPCODE <= SUB;    --slti
                 ALUsel     <= "101";
      when 27 => ALU_OPCODE <= SUB;    --sgti
                 ALUsel     <= "110";
      when 28 => ALU_OPCODE <= SUB;    --slei
                 ALUsel     <= "001";
      when 29 => ALU_OPCODE <= SUB;    --sgei
                 ALUsel     <= "010"; 
      when 30 => ALU_OPCODE <= ADD;
                 ALUsel     <= "000"; --call
      when 32 => ALU_OPCODE <= ADD;    --lb
      when 35 => ALU_OPCODE <= ADD;    --lw
      when 36 => ALU_OPCODE <= ADD;    --lbu
      when 40 => ALU_OPCODE <= ADD;    --sb
      when 43 => ALU_OPCODE <= ADD;    --sw
      when 58 => ALU_OPCODE <= SUB;    --sltui
                 ALUsel     <= "101";
      when 59 => ALU_OPCODE <= SUB;    --sgtui
                 ALUsel     <= "110";
      when 60 => ALU_OPCODE <= SUB;    --sleui
                 ALUsel     <= "001";
      when 61 => ALU_OPCODE <= SUB;    --sgeui
                 ALUsel     <= "010";
      when others => ALU_OPCODE <= NOP;
 end case;
end process ALU_OPCODE_PROCESS;


   
   ALU_delay: process (Clk, Rst)
    begin  -- process PC_P
      if Rst = '0' then                 -- asynchronous reset (active low)
        ALU_OPCODE_out <= NOP;
        ALUsel_out <= "000";
      elsif Clk'event and Clk = '1' then  -- rising clock edge
        ALU_OPCODE_out <= ALU_OPCODE;
        ALUsel_out <= ALUsel;
      end if;
    end process ALU_delay;


  -------------------------------------------------------------------------------------------------------------------------------------------
  -- STALL MANAGEMENT BLOCK
  -------------------------------------------------------------------------------------------------------------------------------------------
  --JUMP---------------------------------------------------------------------------------
  STALL_blockJ : process(IR_op_sig)
                begin
                TC0 <= '0';
                if(IR_op_sig = std_logic_vector(to_unsigned(2,OP_CODE_SIZE))) then
                    TC0 <= '1';
                elsif (IR_op_sig = std_logic_vector(to_unsigned(18,OP_CODE_SIZE))) then
                    TC0 <= '1';
                elsif (IR_op_sig = std_logic_vector(to_unsigned(19,OP_CODE_SIZE))) then
                    TC0 <= '1';
                end if;
                end process;

   --Sequence of flip-flop in order to count the number of stall periods
   DELAY1: flipflop
            port map(D=>TC0, Clock=>Clk, RESET=>Rst, Q=>TC1);  
                     
   DELAY2: flipflop
            port map(D=>TC1, Clock=>Clk, RESET=>Rst, Q=>TC2);  
   
   DELAY3: flipflop
            port map(D=>TC2, Clock=>Clk, RESET=>Rst, Q=>TC3);  


   --Logic circuit used in order to stall the next instruction (bringing at 0 the entire CW)
   stallJ <= (not TC1) and (not TC2) and (not TC3);

   
   --BRANCH---------------------------------------------------------------------------------
   STALL_blockB : process(comeback_signal)
                begin
                TC0b <= '0';
                if(comeback_signal = '1') then
                    TC0b <= '1';
                end if;
                end process;

   --Sequence of flip-flop in order to count the number of stall periods
   DELAY1b: flipflop
            port map(D=>TC0b, Clock=>Clk, RESET=>Rst, Q=>TC1b);  
                     
   DELAY2b: flipflop
            port map(D=>TC1b, Clock=>Clk, RESET=>Rst, Q=>TC2b);  

   DELAY3b: flipflop
            port map(D=>TC2b, Clock=>Clk, RESET=>Rst, Q=>TC3b);  



   --Logic circuit used in order to stall the next instruction (bringing at 0 the entire CW)
   stallB <= (not TC1b) and (not TC2b) and (not TC0b) and (not TC3b);
   

  -------------------------------------------------------------------------------------------------------------------------------------------
  -- PC_IR_BLOCKING
  -------------------------------------------------------------------------------------------------------------------------------------------  

  Enable_PC_IR: process(Address_IRAM,Rst,PC_block)
              begin
	        PC_EN <= '1';
	        IR_EN <= '1';
	        if(Address_IRAM = std_logic_vector(to_unsigned(IRAM_DEPTH-4,log2r(IRAM_DEPTH)) ) ) then
	            PC_EN <= '0';
                    IR_EN <= '0';
	        end if;
	        if(Rst = '0') then 
	            PC_EN <= '0';
		    IR_EN <= '0';
	        end if;
                if(PC_block = '0') then 
	            PC_EN <= '0';
		    IR_EN <= '0';
	        end if;
             end process;


  -------------------------------------------------------------------------------------------------------------------------------------------
  -- RF_WINDOWING MANAGEMENT
  ------------------------------------------------------------------------------------------------------------------------------------------- 
   RF_controller: Register_File_Control
                  generic map(RF_address_mem =>address_RF_DATA_RAM, RF_window_size=> log2r(F), RF_section => 2*N_reg_block)
                  port map(Clk=> Clk, Rst=>Rst, CALL=>cw(CW_SIZE - 4), RET=>cw(CW_SIZE - 5), SWP => SWP_in ,CWP=> CWP_in, FILL=>FILL, SPILL=> SPILL, CALL_stack => CALL_stack, RET_stack => RET_stack,
                           PC_block=> PC_block, MEM_ADDRESS=>ADDR_FS_bus, Call_jump => Call_jump );  


  -------------------------------------------------------------------------------------------------------------------------------------------
  -- BRANCH CONTROLLER
  -------------------------------------------------------------------------------------------------------------------------------------------
  
   --DECODE STAGE_BLOCK1: Branch prediction unit, according to the current state (HISTORY) it decides to jump unconditionally
     BR_flag <= ( (NOT(IR_op_sig(0))) AND (NOT(IR_op_sig(1))) AND (IR_op_sig(2)) AND (NOT(IR_op_sig(3))) AND (NOT(IR_op_sig(4))) AND (NOT(IR_op_sig(5)))  )  or
               ( (IR_op_sig(0)) AND (NOT(IR_op_sig(1))) AND (IR_op_sig(2)) AND (NOT(IR_op_sig(3))) AND (NOT(IR_op_sig(4))) AND (NOT(IR_op_sig(5))) );

     decode_bpu: process (BR_flag,HISTORY)
                      begin
                          if(BR_flag = '1') then
	                           if (HISTORY='1') then  
                                            BRANCH_OUT <='1';
                                   else
                                            BRANCH_OUT<='0';
                                   end if;
                          else 
                                  BRANCH_OUT<='0';   
                          end if; 
                  end process decode_bpu;


   --DECODE STAGE_BLOCK2: Delay of BRANCH flag control signal and the type of the BR instruction
      OPCODE_P : fd
                generic map(N => 2)
                port map (D(1)=>BR_flag, D(0)=>IR_op_sig(0), enable=>'1', CK=>Clk, RESET=>Rst, Q=>OPCODE_pipe); 




   --EXECUTE_STAGE_BLOCK2 : Updating of the real action of the BRANCH that is pipelined in the datapath in order to finish all previous instructions
     SALTO <= OPCODE_pipe(1) and (Equ_0 xor OPCODE_pipe(0));    




   --EXECUTE_STAGE_BLOCK1: Branch prediction unit, according to the current state (HISTORY) it decides to jump unconditionally
     Branch_FSM : BHT 
      port map(
             Clk          => Clk,
	     Rst          => Rst,
	     BRANCH       => SALTO,
	     OPCODE_PIPE  => OPCODE_pipe(1),
	     COME_BACK    => comeback_signal,
	     HISTORY      => HISTORY );

     COME_BACK <= comeback_signal;
     
  
  -------------------------------------------------------------------------------------------------------------------------------------------
  -- INSTRUCTION TYPE: this part is done just for better understande the functionality during the simulation
  -------------------------------------------------------------------------------------------------------------------------------------------
  
  INSTRUCTION_LABEL : process (IR_op_sig, IR_fu_sig)
   begin 
   IR_instruction <= nop;
	case (conv_integer(IR_op_sig)) is
	        -- case of R type requires analysis of FUNC
		when 0 =>
			case (conv_integer(IR_fu_sig)) is
				when 4  => IR_instruction <= sll_R; 
				when 6  => IR_instruction <= srl_R;
                                when 7  => IR_instruction <= sra_R;
				when 32 => IR_instruction <= add_R;
                                when 33 => IR_instruction <= addu_R;
				when 34 => IR_instruction <= sub_R;                                  
				when 35 => IR_instruction <= subu_R;
				when 36 => IR_instruction <= and_R;
				when 37 => IR_instruction <= or_R;
				when 38 => IR_instruction <= xor_R;
				when 40 => IR_instruction <= seq_R;
				when 41 => IR_instruction <= sne_R;
				when 42 => IR_instruction <= slt_R;
                                when 43 => IR_instruction <= sgt_R;
				when 44 => IR_instruction <= sle_R;
				when 45 => IR_instruction <= sge_R;
				when 48 => IR_instruction <= movi2s_R;
				when 49 => IR_instruction <= movs2i_R;
				when 50 => IR_instruction <= movf_R;
				when 51 => IR_instruction <= movd_R;
				when 52 => IR_instruction <= movfp2i_R;
				when 53 => IR_instruction <= movi2fp_R;
				when 54 => IR_instruction <= movi2t_R;
				when 55 => IR_instruction <= movt2i_R; 
                                when 58 => IR_instruction <= sltu_R;
                                when 59 => IR_instruction <= sgtu_R;
                                when 60 => IR_instruction <= sleu_R;
                                when 61 => IR_instruction <= sgeu_R;
				when others => IR_instruction <= nop;  
			end case;
                -- other instructions
                when 1  => IR_instruction <= mult;
		when 2  => IR_instruction <= j;
		when 3  => IR_instruction <= jal;
		when 4  => IR_instruction <= beqz;
                when 5  => IR_instruction <= bnez;
                when 8  => IR_instruction <= addi;
                when 9  => IR_instruction <= addui;
                when 10 => IR_instruction <= subi;
                when 11 => IR_instruction <= subui;
                when 12 => IR_instruction <= andi;
                when 13 => IR_instruction <= ori;
                when 14 => IR_instruction <= xori;
                when 20 => IR_instruction <= slli;
                when 21 => IR_instruction <= nop;
                when 22 => IR_instruction <= srli;
                when 24 => IR_instruction <= seqi;
                when 25 => IR_instruction <= snei;
                when 26 => IR_instruction <= slti;
                when 27 => IR_instruction <= sgti;
                when 28 => IR_instruction <= slei;
                when 29 => IR_instruction <= sgei;
                when 30 => IR_instruction <= call_i;
                when 31 => IR_instruction <= ret_i;
                when 32 => IR_instruction <= lb;
                when 35 => IR_instruction <= lw;
                when 36 => IR_instruction <= lbu;
                when 40 => IR_instruction <= sb;
                when 43 => IR_instruction <= sw;
                when 58 => IR_instruction <= sltui;
                when 59 => IR_instruction <= sgtui;
                when 60 => IR_instruction <= sleui;
                when 61 => IR_instruction <= sgeui;
		when others => IR_instruction <= nop;
	 end case;
	end process INSTRUCTION_LABEL;


end dlx_cu_hw;
