library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use WORK.DLX_package.all;


entity ALU is
  generic ( N : integer := n_data_size;
             N_RCA : integer := n_bit_carry_select 
			  );
  port 	 ( 
           FUNC: IN TYPE_OP;
           ALUSEL : IN std_logic_vector(2 downto 0);
           DATA1, DATA2: IN std_logic_vector(N-1 downto 0);
           ALU_OUTPUT: OUT std_logic_vector(N-1 downto 0);
           EQ_0 : OUT std_logic
         );
end ALU;

architecture BEHAVIOR of ALU is

signal DATA2_IN: std_logic_vector(N-1 downto 0); 
signal NOT_DATA2: std_logic_vector(N-1 downto 0);
signal Cinput: std_logic; 
signal OUTADD,OUTMUL,OUTSHIFT: std_logic_vector(0 to N-1);
signal L_R: std_logic;
signal L_A: std_logic;
signal S_R: std_logic;
signal OUTALU: std_logic_vector(N-1 downto 0);

signal  exnor_net : std_logic_vector(0 to N-1); 
signal  and_net   : std_logic_vector(0 to N-2); 
signal  out_net   : std_logic;

signal msb_net: std_logic;
signal and1: std_logic;
signal or1:std_logic;
signal or2:std_logic;

signal in_mux_1:std_logic_vector(0 to N-2);
signal in_mux_2:std_logic_vector(0 to N-2);
signal in_mux_3:std_logic_vector(0 to N-2);
signal in_mux_4:std_logic_vector(0 to N-2);


--RCA
component P4_ADDER is 	
	generic (N: integer:= N_DATA_SIZE);
	Port (	A:	In	std_logic_vector(N-1 downto 0);
		B:	In	std_logic_vector(N-1 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(N-1 downto 0);
		Co:	Out	std_logic
		);
end component;
--MULTI
component boothmul 
     generic (
               N : integer:=n_data_size
             );
     port    (
               A : IN  std_logic_vector (N-1 downto 0); 
               B : IN  std_logic_vector (N-1 downto 0);
               P : OUT std_logic_vector (2*N-1 downto 0)
             );     
end component;
--SHIFTER
component SHIFTER_GENERIC is
	generic(N: integer:= n_data_size);

	port(	
                A: in std_logic_vector(N-1 downto 0);
		B: in std_logic_vector(4 downto 0);
		LOGIC_ARITH: in std_logic;	-- 1 = logic, 0 = arith
		LEFT_RIGHT: in std_logic;	-- 1 = left, 0 = right
		SHIFT_ROTATE: in std_logic;	-- 1 = shift, 0 = rotate
		OUTPUT: out std_logic_vector(N-1 downto 0)
	     );
end component;
begin
ADDER: P4_ADDER
				generic map(N)
				port map(Ci=>Cinput,A=>DATA1, B=>DATA2_IN,S=>OUTADD);
MUL:  boothmul  
				generic map(N/2)
				port map(A=>DATA1(15 downto 0),B=>DATA2(15 downto 0),P=>OUTMUL);

SHIFT: SHIFTER_GENERIC
				generic map(N)
				port map(A=>DATA1,B=>DATA2(4 DOWNTO 0),LOGIC_ARITH=>L_A,LEFT_RIGHT=>L_R,SHIFT_ROTATE=>S_R,OUTPUT=>OUTSHIFT); 


NOT_DATA2<= NOT(DATA2);				
				
----------------------------------------------------------------------------------
P_ALU: process (FUNC, DATA1, DATA2,OUTADD,OUTMUL,OUTSHIFT,NOT_DATA2,L_A,L_R)
  
  begin
    Cinput<='0';
    S_R<='1';
    DATA2_IN<=(others=>'0');
    OUTALU <=(others=>'0');
	 L_A<='0';
	 L_R<='0';
    case FUNC is
	when ADD 	=>  DATA2_IN<=DATA2;
	                    Cinput <= '0';
                            OUTALU <= OUTADD; 
        
        when SUB 	=>        DATA2_IN<=NOT_DATA2;
                            Cinput <= '1';
                            OUTALU <= OUTADD; 
        
        when MULT 	=>  OUTALU <= OUTMUL;

        when BITAND 	=>  OUTALU <= (DATA1 AND DATA2);
	when BITOR 	=>  OUTALU <= (DATA1 OR DATA2);
        when BITXOR 	=>  OUTALU <= (DATA1 XOR DATA2);
	
        when FUNCR_LOGIC 	=>  L_A    <='1'; 
                                    L_R    <= '0';
                                    OUTALU <= OUTSHIFT;
 
	when FUNCR_ARITH 	=> L_A    <= '0';
                                   L_R    <= '0';
                                   OUTALU <= OUTSHIFT;

        WHEN FUNCL_LOGIC         =>  L_A    <='1'; 
                                    L_R    <= '1';
                                    OUTALU <= OUTSHIFT;
             
         when NOP        =>  OUTALU <= (others=>'0');
	
         when others =>     DATA2_IN<=(others=>'0');
                           OUTALU <=(others=>'0');
    end case; 
  end process P_ALU;
---------------------------------------------------------------------------------
exnor_network: for i in 0 to N-1 generate
				         exnor_net(i)<= OUTALU(i) xnor '0';
			        end generate;

and_net(0)<=exnor_net(0) and exnor_net(1);

and_network: for i in 1 to N-2  generate
				  and_net(i)<= and_net(i-1) and exnor_net(i+1);
			    end generate;
            
out_net<=(and_net(N-2));



EQ_0 <= out_net;

and1<= msb_net and (not(out_net));
or1<=  and1 or out_net;
or2<=  (not(msb_net)) or out_net;
---------------------------------------------------------------------------------
in_mux_1<=  (others=>'0');
in_mux_2<=  (others=>'0');
in_mux_3<=  (others=>'0');
in_mux_4<=  (others=>'0');

msb_net <=  OUTALU(31);

OUT_PROCESS: process (OUTALU,FUNC,ALUSEL,in_mux_1,in_mux_2,in_mux_3,in_mux_4,out_net,or1,or2,msb_net)


begin
ALU_OUTPUT<=(others=>'0');







 case ALUSEL is
	when "000" 	=>  ALU_OUTPUT <=  OUTALU;
        
        when "001" 	=>  ALU_OUTPUT <=  in_mux_1 & or1;
        
        when "010"	=>  ALU_OUTPUT <=  in_mux_2 & or2;

        when "011" 	=>  ALU_OUTPUT <= in_mux_3 & (out_net);
	
        when "100" 	=>  ALU_OUTPUT <= in_mux_4 &  (not(out_net));
       
        when "110" 	=>  ALU_OUTPUT <= in_mux_4 & (not(out_net) and (not(msb_net)));
        
        when "101" 	=>  ALU_OUTPUT <= in_mux_4 & ((not(out_net)) and ((msb_net))) ; 
       
	when others => null;
    end case; 


end process OUT_PROCESS;

end BEHAVIOR;

