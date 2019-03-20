library ieee;
use ieee.std_logic_1164.all;
use work.DLX_package.all;


entity DATAPATH is
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
	     
end DATAPATH;

architecture ARCH of DATAPATH is

 --------------------------------------------------------------------
 -- Components Declaration
 --------------------------------------------------------------------
component RF_windowing is
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
end component;
----------------------------------------
component flipflop IS 
PORT 
( D, Clock: IN STD_LOGIC ;
  RESET : IN STD_LOGIC;
  Q: OUT STD_LOGIC
) ;
end component;
-----------------------------------------
component FD is
	Generic (N: integer:= 5);
	Port (			
			D:	In	std_logic_vector (N-1 DOWNTO 0);
			ENABLE :in std_logic;
			CK:	In	std_logic;
			RESET:	In	std_logic;
			Q:	Out	std_logic_vector (N-1 DOWNTO 0)
		  );
end component;
-----------------------------------------
component ALU is
  generic (           
              N     : integer := n_data_size;
              N_RCA : integer := n_bit_carry_select 
           );
  port 	 ( 
           FUNC: IN TYPE_OP;
           ALUSEL : IN std_logic_vector(2 downto 0);
           DATA1, DATA2: IN std_logic_vector(N-1 downto 0);
           ALU_OUTPUT: OUT std_logic_vector(N-1 downto 0);
           EQ_0      : OUT std_logic
         );
end component;
-----------------------------------------
component mux21_generic is
  
  generic (N : integer := n_data_size);
  port (
          A: in std_logic_vector(0 to N-1);
          B: in std_logic_vector(0 to N-1);
          SEL: in std_logic;
          Y: out std_logic_vector(0 to N-1)
       );
end component;
-----------------------------------------
component mux31 is
  
  generic (
            N : integer 
          );
  port 
       (
    	  A:   in std_logic_vector (N-1 downto 0);
          B:   in std_logic_vector (N-1 downto 0);
          C:   in std_logic_vector (N-1 downto 0);
          SEL: in std_logic_vector (1 downto 0);
          Y:   out std_logic_vector(N-1 downto 0)
       );
end component;
-----------------------------------------
component mux41 is
  
  generic (
           N : integer := n_data_size
          );
  port 
       (
    	  A:   in std_logic_vector (0 to N-1);
          B:   in std_logic_vector (0 to N-1);
          C:   in std_logic_vector (0 to N-1);
          D:   in std_logic_vector (0 to N-1);
          SEL: in std_logic_vector (0 to 1);
          Y:   out std_logic_vector(0 to N-1)
       );
end component;
-----------------------------------------
component RCA is 
	generic  (
                  N:integer
                );
	Port    (	
                  A:	In	std_logic_vector(N-1 downto 0);
	   	  B:	In	std_logic_vector(N-1 downto 0);
		  Ci:	In	std_logic;
		  S:	Out	std_logic_vector(N-1 downto 0);
		  Co: out std_logic
                );
end component; 
-----------------------------------------
component mux81 is
  
  generic (N : integer);
  port 
       (
    	    A:   in std_logic_vector (0 to N-1);
          B:   in std_logic_vector (0 to N-1);
          C:   in std_logic_vector (0 to N-1);
          D:   in std_logic_vector (0 to N-1);
          E:   in std_logic_vector (0 to N-1);
          F:   in std_logic_vector (0 to N-1); 
          G:   in std_logic_vector (0 to N-1); 
          H:   in std_logic_vector (0 to N-1);
          SEL: in std_logic_vector (0 to 2);
          Y:   out std_logic_vector(0 to N-1)
       );

end component;

  ----------------------------------------------------------------
  -- Signals Declaration
  ----------------------------------------------------------------

  ----signal 1 stage-----
  signal OutRca1:std_logic_vector   (N-1 downto 0);
  signal fourtoRca1:std_logic_vector   (N-1 downto 0);
  signal comeback1,comeback2: std_logic;
  signal Pcout_sig, Pcout_sig1 : std_logic_vector(N-1 downto 0);
  signal DRIVE_mux : std_logic;
  signal Jump_sig : std_logic;

  ----signal 2 stage-----
  signal Immediate16_s: std_logic_vector(N-1 downto 0);
  signal Immediate16_u: std_logic_vector(N-1 downto 0);
  signal Immediate26_u: std_logic_vector(N-1 downto 0);
  signal Immediate26_s: std_logic_vector(N-1 downto 0);
  signal NpctoIn2 :std_logic_vector (N-1 downto 0);
  signal number_31: std_logic_vector (4 downto 0);
  signal muxadr1: std_logic_vector (4 downto 0);
  signal Muxwr: std_logic_vector (4 downto 0);
  signal Fill_sig : std_logic;
  signal Spill_sig : std_logic;
  signal sign_1      :std_logic_vector(N-1 downto 0);
  signal sign_2      :std_logic_vector(N-1 downto 0);
  signal zeros       :std_logic_vector(N-1 downto 0);
  signal D1toD2      : std_logic_vector(4 downto 0);
  signal D2toD3     : std_logic_vector(4 downto 0);
  signal R1delay    : std_logic_vector(4 downto 0);
  signal RcatoIRAM_sig:std_logic_vector(N-1 downto 0); 
  signal ADDR2_RF : std_logic_vector(4 downto 0);
  signal ADDR1_RF : std_logic_vector(4 downto 0);
  signal ADDWR_RF : std_logic_vector(4 downto 0);
  signal MEM_FILL_bus: std_logic_vector(N-1 downto 0);
  signal MEM_SPILL_bus: std_logic_vector(N-1 downto 0);

  ----signal 3 stage-----
  signal Pc2toPc3: std_logic_vector (N-1 downto 0);
  signal In1toMux4: std_logic_vector (N-1 downto 0);
  signal AtoMux4: std_logic_vector (N-1 downto 0);
  signal BtoMux5: std_logic_vector (N-1 downto 0);
  signal In2toMux5: std_logic_vector (N-1 downto 0);
  signal Mux3Out  : std_logic_vector (N-1 downto 0);
  signal MuxzeroOut  : std_logic_vector (N-1 downto 0);
  signal RFTOA : std_logic_vector (N-1 downto 0);
  signal RFTOB : std_logic_vector (N-1 downto 0);
  signal Outmux4 : std_logic_vector (N-1 downto 0);	
  signal Outmux5 : std_logic_vector (N-1 downto 0);
  signal alutoOp_out  : std_logic_vector (N-1 downto 0);
  signal Op_outtoS4:  std_logic_vector (N-1 downto 0);
  signal Pc3toPc4:    std_logic_vector (N-1 downto 0);
  
  ----signal 4 stage----
  signal Datamemtomux1_u : std_logic_vector (N-1 downto 0);
  signal Datamemtomux1_s : std_logic_vector (N-1 downto 0);
  signal Datamemtomux2_u : std_logic_vector (N-1 downto 0);
  signal Datamemtomux2_s : std_logic_vector (N-1 downto 0);
  signal sign_3      :std_logic_vector(N-1 downto 0);
  signal sign_4      :std_logic_vector(N-1 downto 0);
  signal Mux6tomemout  :   std_logic_vector (N-1 downto 0);
  signal Addr_DRAM     :   std_logic_vector(log2r(D_RAM_DEPTH) -1 downto 0);
  signal PcJumptomux1 :   std_logic_vector  (N-1 downto 0);
  signal Pc4toPc5_mux7    :   std_logic_vector  (N-1 downto 0);
  signal MemouttoMux7 :   std_logic_vector  (N-1 downto 0);
  signal AddresstoMux7 :   std_logic_vector (N-1 downto 0);
  signal Pc5toMux1: std_logic_vector(N-1 downto 0);

  ----signal 5 stage-----
  signal Mux7toRf :   std_logic_vector      (N-1 downto 0); 
  signal DatainRF : std_logic_vector(N-1 downto 0);





    begin 
  --------------------------------------------------------------------------------------------------------------------------------------------------
  --------------------------------------------------------------------------------------------------------------------------------------------------
  --                                                                 FIRST STAGE
  --------------------------------------------------------------------------------------------------------------------------------------------------
  --------------------------------------------------------------------------------------------------------------------------------------------------   
   
  --------------------------------------------------------------------------------------------
  --  ADDER_PROGRAM_COUNTER
  --------------------------------------------------------------------------------------------
   drive_mux_Branch : process(BRANCH_sel,Clk)
		       begin
                       DRIVE_mux <= '0';
                       if(BRANCH_sel = '1') then
                       	 DRIVE_mux <= '1';
                       end if;	           
		      end process;

   MuxBranch:   mux21_generic
             generic map(N)
	     port map(B=>RcatoIRAM_sig, A =>Pcout, Sel=>DRIVE_mux, Y=> Pcout_sig1);

   MuxRETURN:   mux21_generic
             generic map(N)
	     port map(B=>STACK_data_out, A =>Pcout_sig1, Sel=>RET, Y=> Pcout_sig);

   RCA1_PC : RCA
	    generic map(N)
	    port map(A=>Pcout_sig,B =>fourtoRca1,Ci=>'0',S =>OutRca1);

   fourtoRca1 <= "00000000000000000000000000000100";


  --------------------------------------------------------------------------------------------
  --  MUX_PROGRAM_COUNTER
  --------------------------------------------------------------------------------------------
   Jump_sig <= Jump or Call_jump;

   MUX_PC : mux31
            generic map(N)
	    port map(A=>OutRca1, B =>Pc5tomux1 , C=>PcJumptoMux1, Sel(0)=>comeBack1, sel(1)=>Jump_sig, Y=>Mux1toPc );

   RB1: flipflop
            port map(D=>comeback2, Clock=>Clk,RESET=>Rst,Q=>comeback1);

   RB2: flipflop
            port map(D=>comeback, Clock=>Clk,RESET=>Rst,Q=>comeback2);


 
  --------------------------------------------------------------------------------------------
  --  NEXT_PROGRAM_COUNTER REGISTER (NPC)
  --------------------------------------------------------------------------------------------
   Npc: fd 
            generic map(N) 
            port map(D=>OutRca1,ENABLE=>'1',CK=>Clk,RESET=>Rst,Q=>NpctoIn2);

  
  --------------------------------------------------------------------------------------------------------------------------------------------------
  --------------------------------------------------------------------------------------------------------------------------------------------------
  --                                                                  SECOND STAGE
  --------------------------------------------------------------------------------------------------------------------------------------------------
  --------------------------------------------------------------------------------------------------------------------------------------------------   
  
  --------------------------------------------------------------------------------------------
  --  REGISTER_FILE INPUTS MANAGEMENT
  --------------------------------------------------------------------------------------------

    --Multiplexer needed for the selection of the writing address of the RF between an I type and a R type instruction
    MUX_WR0: mux21_generic
             generic map(N=>5)
             port map (A=>IrOut(20 downto 16),B=>Irout(15 downto 11),Sel=>Write_sel,Y=>muxadr1);  



    --Three registers, in order to delay the address coming from IR needed for a write operation in RF
    DELAY1: fd
            generic map(N=>5) 
            port map(D=>muxadr1,enable=>'1',CK=>Clk,RESET=>Rst,Q=>D1toD2); 
    DELAY2: fd 
             generic map(N=>5) 
             port map(D=>D1toD2,enable=>'1',CK=>Clk,RESET=>Rst,Q=>D2toD3); 
    DELAY3:  fd
             generic map(N=>5) 
             port map(D=>D2toD3,ENABLE=>'1',CK=>Clk,RESET=>Rst,Q=>R1delay);  



    --Multiplexer needed for selection of data input in RF (it can be a constant '31' or a generic address)
    MUX_WR1 : mux21_generic
             generic map(N=>5)
             port map (A=>R1delay, B=>number_31, Sel=>S5, Y=>Muxwr );

    number_31<="11111";

  --------------------------------------------------------------------------------------------
  --  REGISTER_FILE
  --------------------------------------------------------------------------------------------
   
    -- RF : RF_fixed 
    --      generic map (N_DATA_SIZE,log2r(RF_DEPTH))
    --      port map (CLK=>Clk,  RESET=>Rst,  RD1=>RF1,  RD2=>RF2,  WR=>WF,  ADD_WR=>Muxwr,  ADD_RD1=>muxadr1,  ADD_RD2=>Irout(20 downto 16),
    --                DATAIN=>DatainRF,  OUT1=>RftoA,  OUT2=>RftoB );

    ADDR2_RF <=  IRout(25 downto 21);
    ADDR1_RF <=  IRout(20 downto 16);
    ADDWR_RF <=  Muxwr;

    RF : RF_windowing
            generic map (N=>N_reg_block ,F=>F, M=>M, P=>N_DATA_SIZE)
            port map (CLK => Clk, RESET => Rst, CALL=> CALL, RET=> RET, RD1=>RF1, RD2=>RF2, WR=> WF, SPILL=>SPILL_sig, FILL=>FILL_sig, ADDRESS_RD1=>ADDR1_RF, 
                      ADDRESS_RD2=> ADDR2_RF, ADDRESS_WR => ADDWR_RF, DATA_IN=>DatainRF, DATA_OUT1=>RftoA, DATA_OUT2=>RftoB, MEM_spilling=> MEM_SPILL_bus_o,
                      MEM_filling => MEM_FILL_bus_i, SWP_o =>SWP_out, CWP_o =>CWP_out);
    
    FILL <= FILL_sig;
    SPILL <= SPILL_sig;


  --------------------------------------------------------------------------------------------
  --  SIGNAL IMMEDIATE EXTENSION
  --------------------------------------------------------------------------------------------

  --Creation of a signal of 32bit , which all the bits have the value of the MSB of the IMM26
     msb_extension_1: for i in 0 to N-1 generate 
                         sign_1(i)<= Irout(25);
                      end generate;
   
  --Creation of a signal of 32bit , which all the bits have the value of the MSB of the IMM16           
     msb_extension_2: for i in 0 to N-1 generate 
                         sign_2(i)<= Irout(15);
                      end generate;

  --Creation of a signal with all bits equal to 0
    zeros <= (others=>'0');    
 
  --Creation of the extended signed/unsigned immediate
     Immediate16_u<=zeros(15 downto 0) & IrOut(15 downto 0);
     Immediate16_s<=sign_2(15 downto 0) & Irout(15 downto 0);
     Immediate26_u<=zeros(5 downto 0) & IrOut(25 downto 0);
     Immediate26_s<=sign_1(5 downto 0) & Irout(25 downto 0);
 
  --Multiplexer for the immediate selection
     MUX_3 : mux41
	    generic map(N)
	    port map( A=>Immediate16_u, B =>Immediate16_s, C=>Immediate26_u, D=>Immediate26_s, Sel(0)=>IMM26, Sel(1)=>SIGN, Y=>Mux3Out );



  --------------------------------------------------------------------------------------------
  --  IMMEDIATE SELECTION (it could be an immediate or a zero)
  --------------------------------------------------------------------------------------------   	
     MUX_BRANCH: mux21_generic
             generic map(N)
             port map (A=> Mux3Out, B=>zeros, Sel=>Zero_sel ,Y=>MuxzeroOut);


 
  -------------------------------------------------------------------------------------------- 
  --  BRANCH_ADDRESS
  --------------------------------------------------------------------------------------------   	       
   
     bpu_dec:  RCA 
               generic map(N)
	       port map(A=>Immediate16_s,B =>NpctoIn2,Ci=>'0',S =>RcatoIRAM_sig);
     
     RcatoIRAM <= RcatoIRAM_sig;
 
  --------------------------------------------------------------------------------------------
  --  REGISTERS FOR STAGE 2 OF THE PIPELINE
  --------------------------------------------------------------------------------------------    
    STACK_data_in <= NpctoIn2;
   
    PC_2_reg:  fd 
               generic map(N) 
               port map(D=>NpctoIn2, ENABLE=>'1', CK=>Clk, RESET=>Rst, Q=>Pc2toPc3 );

    IN1_reg: fd 
               generic map(N) 
               port map(D=>MuxZeroOut, ENABLE=>En2, CK=>Clk, RESET=>Rst, Q=>In1toMux4);

    A_reg:  fd
               generic map(N) 
               port map(D=>RftoA, ENABLE=>En2, CK=>Clk, RESET=>Rst, Q=>Atomux4);

    B_reg:  fd 
               generic map(N) 
               port map(D=>RftoB, enable=>EN2, CK=>Clk, RESET=>Rst, Q=>Btomux5);

    IN2_reg: fd
               generic map(N) 
               port map(D=>NpctoIn2, enable=>EN2, CK=>Clk, RESET=>Rst, Q=>In2tomux5); 
                 
   
  --------------------------------------------------------------------------------------------------------------------------------------------------
  --------------------------------------------------------------------------------------------------------------------------------------------------
  --                                                                 THIRD STAGE
  --------------------------------------------------------------------------------------------------------------------------------------------------
  --------------------------------------------------------------------------------------------------------------------------------------------------   
  
  --------------------------------------------------------------------------------------------
  --  MULTIPLEXERS FOR ALU DATA SELECTION
  -------------------------------------------------------------------------------------------- 
    Mux5_A:   mux21_generic
             generic map(N)
	     port map(B=>In1toMux4, A =>AtoMux4, Sel=>S1, Y=> Outmux4);
     
    Mux4_B:   mux21_generic
             generic map(N)
	     port map(B=>Btomux5, A =>In2toMux5, Sel=>S2, Y=>Outmux5);


  --------------------------------------------------------------------------------------------
  -- ALU
  -------------------------------------------------------------------------------------------- 
     ALU_1:  ALU
            generic map (N,N_RCA)
            port map(FUNC=>ALU_OPCODE, ALUSEL=>ALUsel, DATA1=>Outmux5, DATA2=>Outmux4, ALU_OUTPUT=>alutoOp_out, eq_0=>Equal_zero);

    
  --------------------------------------------------------------------------------------------
  --  REGISTERS FOR STAGE 3 OF THE PIPELINE
  -------------------------------------------------------------------------------------------- 
    PC3:     fd
             generic map(N) 
             port map(D=>Pc2toPc3, ENABLE=>'1', CK=>Clk, RESET=>Rst, Q=>Pc3toPc4 ); 
  
    Op_out:  fd
             generic map(N) 
             port map(D=>AlutoOp_out, ENABLE=>En3, CK=>Clk, RESET=>Rst, Q=>Op_outtoS4 ); 
   
    Me:      fd
             generic map(N) 
             port map(D=>Btomux5, ENABLE=>En3, CK=>Clk, RESET=>Rst, Q=>Metodatamem_o);  

    
   Op_outtoS4o <= Op_outtoS4;

  --------------------------------------------------------------------------------------------------------------------------------------------------
  --------------------------------------------------------------------------------------------------------------------------------------------------
  --                                                                 FOURTH_STAGE
  --------------------------------------------------------------------------------------------------------------------------------------------------
  --------------------------------------------------------------------------------------------------------------------------------------------------   

  --------------------------------------------------------------------------------------------
  -- DRAM
  --------------------------------------------------------------------------------------------  

   --Bit selection for the address of the DRAM, since the memory has not length equal to 2**32
   --Addr_DRAM <= Op_outtoS4(log2r(D_RAM_DEPTH)-1 downto 0); 
   
   --DRAM memory 
   --Data_mem:   Dram
   --            generic map  (D_RAM_DEPTH,N/4)
   --            port  map (Rst=>rst, Clk=>clk, En=>'1', Rd=>Rm, Wr=>Wm, Spill=>Spill_sig, Fill=> Fill_sig, Rword => Word, Rbyte => Byte,
   --                       Addr=>Addr_DRAM, Din=>Metodatamem, Dout=> Datamemtomux0, Dout_byte => Datamemtomux1_byte, Dout_word => Datamemtomux2_word ,
   --                       Addr_FS => ADDR_FS_bus ,Din_SPILL=> MEM_SPILL_bus , Dout_FILL=>MEM_FILL_bus );



  --------------------------------------------------------------------------------------------
  -- DATA MEM SELECTION
  --------------------------------------------------------------------------------------------

  --Sign extension of the data memeory  
   msb_extension_3: for i in 0 to N-1 generate 
                        sign_3(i)<= Datamemtomux1_byte_i(7);
                    end generate;

   msb_extension_4: for i in 0 to N-1 generate 
                        sign_4(i)<= Datamemtomux2_word_i(15);
                    end generate;

   Datamemtomux1_u <= zeros(23 downto 0) & Datamemtomux1_byte_i (7 downto 0); 
   Datamemtomux2_u <= zeros(15 downto 0) & Datamemtomux2_word_i (15 downto 0); 
   Datamemtomux1_s <= sign_3(23 downto 0) & Datamemtomux1_byte_i (7 downto 0) ;
   Datamemtomux2_s <= sign_4(15 downto 0) & Datamemtomux2_word_i (15 downto 0); 


   --Selection of data memeory
   Mux6: mux81
	  generic map(N)
	  port map(A=>Datamemtomux0_i, B=>Datamemtomux2_u, C=>Datamemtomux1_u, D=>zeros, E=>zeros, F=>Datamemtomux2_s, G=>Datamemtomux1_s,
                   H=>zeros, Sel(0)=>Word, Sel(1)=>Byte, Sel(2)=>si, Y=>Mux6tomemout );      



  --------------------------------------------------------------------------------------------
  --  REGISTERS FOR STAGE 4 OF THE PIPELINE
  -------------------------------------------------------------------------------------------- 
   PC_jump:   fd
               generic map(N) 
               port map(D=>AlutoOp_out, ENABLE=>'1', CK=>Clk ,RESET=>Rst ,Q=>PcjumptoMux1 ); 


   PC4:        fd
               generic map(N) 
               port map(D=>Pc3toPc4, ENABLE=>'1', CK=>Clk, RESET=>Rst, Q=>Pc4toPc5_mux7 ); 


   Mem_out:    fd
               generic map(N) 
               port map(D=>Mux6tomemout, ENABLE=>En4, CK=>Clk, RESET=>Rst, Q=>Memouttomux7 ); 


   Address:     fd 
               generic map(N) 
               port map(D=>Op_outtoS4, ENABLE=>En4, CK=>Clk, RESET=>Rst, Q=>AddresstoMux7); 
  

   PC5:        fd
               generic map(N) 
               port map(D=>Pc4toPc5_mux7, ENABLE=>'1', CK=>Clk, RESET=>Rst, Q=>Pc5toMux1 ); 


   
  --------------------------------------------------------------------------------------------------------------------------------------------------
  --------------------------------------------------------------------------------------------------------------------------------------------------
  --                                                                 FIFTH_STAGE
  --------------------------------------------------------------------------------------------------------------------------------------------------
  --------------------------------------------------------------------------------------------------------------------------------------------------   

  --------------------------------------------------------------------------------------------
  -- MULTIPLEXER FOR WRITE BACK
  --------------------------------------------------------------------------------------------
    Mux7:      mux31
               generic map(N)
	       port map(A=>AddresstoMux7, B =>Memouttomux7, C=>Pc4toPc5_mux7, Sel(0)=>S4, Sel(1)=>S5, Y=>Mux7toRf);      
    
    Mux8:   mux21_generic
             generic map(N)
	     port map(B=>Pc3toPc4, A =>Mux7toRf, Sel=>S5, Y=>DatainRF);    



   
         
               
               
              
    
end ARCH ;
