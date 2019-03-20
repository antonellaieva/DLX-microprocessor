library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use WORK.DLX_package.all;

entity cansave is
	generic ( 
				  F    : integer :=F;
				  F_1  : integer :=F_1			 
			 );
	port     
			  (
					 CWP        : IN std_logic_vector(log2(F)-1 downto 0) ;
					 SWP        : IN std_logic_vector(log2(F)-1 downto 0);
					 CANSAVE    : OUT std_logic
			  );
end cansave;

architecture arch of cansave is


signal F1           : std_logic_vector (log2r(F)-1 downto 0);

signal sum          : std_logic_vector (log2r(F)-1 downto 0);

signal  outmux_CWP  : std_logic_vector (log2r(F)-1 downto 0);
signal  exnor_net_0 : std_logic_vector(log2r(F)-1 downto 0);
signal  and_net_0   : std_logic_vector(log2r(F)-2 downto 0);
signal  exnor_net_1 : std_logic_vector(log2r(F)-1 downto 0);
signal  and_net_1   : std_logic_vector(log2r(F)-2 downto 0);

signal  zeros_1     : std_logic_vector(log2r(F)-1 downto 0);
signal  sel_f       : std_logic;

component MUX21_GENERIC IS 
  generic (
    N : integer );
  port (
    A: in std_logic_vector(N-1 downto 0);
    B: in std_logic_vector(N-1 downto 0);
    SEL: in std_logic;
    Y: out std_logic_vector(N-1 downto 0)
    );
end component;

begin

--useful signal------------------------------------------------------------------------------------
zeros_1 <=(others=>'0');
F1 <= std_logic_vector(to_unsigned(F_1,log2r(F))); --to convert the value of the register into a signal



--counter that allows to know the next value of CWP------------------------------------------------
sum<= CWP+1; 



--control signal that selects CWP+1 = 0, in the case of last window--------------------------------
exnor_network_0:  for i in 0 to log2r(F)-1  generate
				           exnor_net_0(i)<= CWP(i) xnor F1(i);
			         end generate;

and_net_0(0)<=  exnor_net_0(0) and exnor_net_0(1);

and_network_0: for i in 1 to log2r(F)-2  generate
				        and_net_0(i)<= and_net_0(i-1) and exnor_net_0(i+1);
			      end generate;
            
sel_f<=and_net_0(log2r(F)-2);


--multiplexer that allows to choose the real CWP+1 or the 0-----------------------------------------
UM: mux21_generic
      generic map(N=>log2r(F))
      port map   (B=>zeros_1,A=>sum,SEL=>sel_f,Y=>outmux_CWP);
	
--comparison between SWP and CWP+1------------------------------------------------------------------	  
exnor_network_1: for i in 0 to log2r(F)-1  generate
				 exnor_net_1(i)<= outmux_CWP(i) xnor SWP(i);
			     end generate;

and_net_1(0)<=exnor_net_1(0) and exnor_net_1(1);


and_network_1: for i in 1 to log2r(F)-2  generate
				and_net_1(i)<= and_net_1(i-1) and exnor_net_1(i+1);
			 end generate;


--Flag that says if they are equal------------------------------------------------------------------
CANSAVE <=not (and_net_1(log2r(F)-2));

end arch;
