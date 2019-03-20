library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use WORK.DLX_package.all;

entity addressing is 
generic (
           F : integer :=F;
           N : integer :=N_reg_block;
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
end addressing;


architecture arch of addressing is

signal constant_N2F_3N : std_logic_vector(log2r(2*N*F+M)-1 downto 0);
type SignalVector is array (F-1 downto 1) of std_logic_vector(log2r(2*N*F+M)-1 downto 0);
signal KN_matrix : signalvector;
signal regtomux0: std_logic_vector(log2r(2*N*F+M)-1 downto 0);
signal mux0tomux1,mux1tomux2 : std_logic_vector(log2r(2*N*F+M)-1 downto 0);
signal mux2toadd: std_logic_vector(log2r(2*N*F+M)-1 downto 0);
signal virtual_address_ext: std_logic_vector(log2r(2*N*F+M)-1 downto 0); 
signal GLOB:std_logic;
signal THIRD_BLOCK_LAST_WINDOW :std_logic;
signal THIRD_BLOCK : std_logic;
signal KNmatrix_to_mux1: std_logic_vector ((F)*log2r(2*N*F+M)-1 downto 0); --it is the input signal if the generic mutiplexer, it contains all the F inputs
signal zeros: std_logic_vector (log2r(2*N*F+M)-1 downto log2r(3*N+M));
signal or_net0: std_logic_vector(log2r(2*N*F+M)-1 downto log2r(N)+2);
signal or_net1: std_logic_vector(log2r(2*N*F+M)-1 downto log2r(N)+1);
signal real_address_sig :std_logic_vector(log2r(2*N*F+M)-1 downto 0);

component MuxNto1 is
	generic
	(
		INPUT_WIDTH			: integer 	:= 8;
		INPUT_COUNT 	    : integer 	:= 8;
		SEL_WIDTH 			: integer 	:= 3
	);
	port
	(
		Inputs 				: in   std_logic_vector((INPUT_WIDTH*INPUT_COUNT)-1 downto 0);
		Sel 				: in   std_logic_vector(SEL_WIDTH-1 downto 0);
		Output 				: out  std_logic_vector(INPUT_WIDTH-1 downto 0)
	);
end component; 

component MUX21_GENERIC is
	Generic (
		      N: integer:= 4
		    );
	Port   (	
	          A:	    In	std_logic_vector(N-1 downto 0) ;
		      B:	    In	std_logic_vector(N-1 downto 0);
		      SEL:	    In	std_logic;
		      Y:	    Out	std_logic_vector(N-1 downto 0)
		   );
	end component;

component Adder_Subtractor is 
	generic (
                 N     :        integer:= 4
            );
	Port   (	  
	          A  :	In	std_logic_vector(N-1 downto 0);
		      B  :	In	std_logic_vector(N-1 downto 0);
		      Cin:	In	std_logic;
		      S  :	Out std_logic_vector(N-1 downto 0);
		      Co :	Out std_logic
		   );
end component; 	
	
begin 

--constants
constant_N2F_3N <= std_logic_vector(to_unsigned(N2F_3N, log2r(2*N*F+M)));

zeros<= (others=>'0');


--connections
virtual_address_ext<= zeros & VIRTUAL_ADDRESS;  --extension of the VIRTUAL ADDRESS on the number of bits needed for the real one

constants_generation: for i in 1 to  F-1  generate   --it generates all the quantity needed to add for each number of window
                          KN_matrix(i) <= std_logic_vector(to_unsigned(2*N*i,log2r(2*N*F+M)));
		                end generate;

regtomux0<=(KN_matrix(1));

KNmatrix_to_mux1(log2r(2*N*F+M) -1 downto 0)<= (others=>'0'); --the first input of the mux1 should be zero ( when CWP = 0 )
KNmatrix_to_mux1(F*log2r(2*N*F+M) -1 downto (F-1)*log2r(2*N*F+M))<= mux0tomux1 ; -- --the last input of the mux1 should be the output of MUX0

		   
generic_mux_inputs: for i in 1 to F-2 generate
                        KNmatrix_to_mux1((i+1)*log2r(2*N*F+M) -1 downto (i)*log2r(2*N*F+M)) <= KN_matrix(i);             
			           end generate; 
			 
UMUX_0: MUX21_GENERIC --it is used to select the correct portion of address in case of third block of each window: the value is different only in the last window;
			generic Map (N=>log2r(2*N*F+M))
			port Map (B=>regtomux0,A=>KN_matrix(F-1),SEL=>THIRD_BLOCK_LAST_WINDOW,Y=>mux0tomux1); 


UMUX_1: MuxNto1  --it is used to select the portion of address to add to the virtual address in order to obtain the address of a window, according to the value of the window itself 
			generic Map (INPUT_COUNT=>F,INPUT_WIDTH=>log2r(2*N*F+M),SEL_WIDTH=>log2r(F))
			port Map    (Inputs=> KNmatrix_to_mux1, Sel => CWP_portion , Output => mux1tomux2 );

UMUX_2: MUX21_GENERIC --it is used to select the correct portion of address,in case of window or in case of global block,according to GLOB signal
         generic Map (N=>log2r(2*N*F+M))
		   port Map (A=>mux1tomux2,B=>constant_N2F_3N,SEL=>glob,Y=>mux2toadd );

UADDER_SUB : Adder_Subtractor
		   generic Map (N=>log2r(2*N*F+M))
		   port Map  (A=>virtual_address_ext,B=>mux2toadd,Cin=> THIRD_BLOCK_LAST_WINDOW,S=>real_address_sig);

--Address_cheking

ADDR_CHECK: process(real_address_sig)
           begin
               if(real_address_sig > std_logic_vector(to_unsigned(2*N*F+M-1,log2r(2*N*F+M))) ) then
                  REAL_ADDRESS <= (others => '0');
               else
                  REAL_ADDRESS <= real_address_sig;
               end if;   
           end process;

THIRD_BLOCK_LAST_WINDOW <= TC_CWP and THIRD_BLOCK; --it is equal to 1 when the virtual address points to the third block and the CWP points to the last window



or_net0(log2r(N)+2) <= virtual_address_ext(log2r(N)+1) or virtual_address_ext(log2r(N)+2);

or_network0: for i in log2r(N)+3 to log2r(2*N*F+M)-1 generate
					     or_net0(i)<= or_net0(i-1) or virtual_address_ext(i);
				 end generate;
				
THIRD_BLOCK	<= (NOT GLOB) and (or_net0(log2r(2*N*F+M)-1));



or_net1(log2r(N)+ 1) <= virtual_address_ext(log2r(N)+1) and virtual_address_ext(log2r(N));

or_network1: for i in log2r(N)+2 to log2r(2*N*F+M)- 1 generate
					     or_net1(i)<= or_net1(i-1) or virtual_address_ext(i);
				 end generate;

GLOB <= or_net1(log2r(2*N*F+M)-2);	  

	  
end arch;
