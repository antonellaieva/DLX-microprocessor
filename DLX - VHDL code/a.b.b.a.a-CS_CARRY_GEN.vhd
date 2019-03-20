library ieee; 
use ieee.std_logic_1164.all;
use WORK.DLX_package.all;
USE ieee.numeric_std.all;

ENTITY CS_CARRY_GEN IS
	GENERIC (N : integer := N_DATA_SIZE);
	PORT (A : IN STD_LOGIC_VECTOR(N-1 downto 0);
	      B : IN STD_LOGIC_VECTOR(N-1 downto 0);
              Cin : IN STD_LOGIC;
      	      Cout : OUT STD_LOGIC_VECTOR(N/4-1 downto 0));
END CS_CARRY_GEN;

ARCHITECTURE STRUCTURAL OF CS_CARRY_GEN IS

	component gen_block
	PORT (
			G2, G1, P2 : IN STD_LOGIC;
			G : OUT STD_LOGIC);
	end component;

	component pg_block
	PORT (
			G2, G1, P2, P1 : IN STD_LOGIC;
			G, P : OUT STD_LOGIC);
	end component;
	
	component bypass
	PORT (s_in1: IN STD_LOGIC;
			s_in2: IN STD_LOGIC;
			s_out1: OUT STD_LOGIC;
			s_out2: OUT STD_LOGIC);
	end component;		       
	
	type SignalVector is array (log2(N)-1 downto 0) of std_logic_vector(N-1 downto 0);
	signal wires : SignalVector;
	
	signal g_wires : std_logic_vector(N-1 downto 0);
	signal p_wires : std_logic_vector(N-1 downto 0);
	signal filo : std_logic;

BEGIN
	
	g_wires(N-1 downto 0) <= A AND B; -- assegno il generate 
	p_wires(N-1 downto 0) <= A XOR B; -- assegno il propagate
	
	righe : for riga in 1 to log2(N) generate 
		riga1 :  if riga = 1 generate
				
				PG1 : for colonna in (N/2)-1 downto 1 generate
				PGA : pg_block  
				Port Map (g_wires((colonna+1)*2-1), g_wires((colonna+1)*2-2), p_wires((colonna+1)*2-1), 
					  p_wires((colonna+1)*2-2), wires(0)((colonna+1)*2-1), wires(0)((colonna+1)*2-2));
				end generate;
				
				GA1 : gen_block
				Port Map (g_wires(0), Cin, p_wires(0), filo);
				
				GA2 : gen_block
				Port Map (g_wires(1), filo, p_wires(1), wires(0)(1));
		end generate riga1;

		riga2 : if riga = 2 generate
		
				PG2 : for colonna in (N/4)-1 downto 1 generate
				PGB : pg_block  
				Port Map (wires(0)((colonna+1)*4-1), wires(0)((colonna+1)*4-3), wires(0)((colonna+1)*4-2),
					  wires(0)((colonna+1)*4-4), wires(1)((colonna+1)*4-1), wires(1)((colonna+1)*4-2)); 
				end generate;
				
				G2 : gen_block
				Port Map (wires(0)(3), wires(0)(1), wires(0)(2), wires(1)(3));
				
		end generate riga2;

                riga3 : if riga = 3 generate
				
				PG3 : for colonna in 0 to ((N/8)-2) generate
				PGC : pg_block  
				Port Map (wires(1)(N-1-8*colonna), wires(1)(N-1-8*colonna-4), 
					  wires(1)(N-2-8*colonna), wires(1)(N-2-8*colonna-4), 
					  wires(2)(N-1-8*colonna), wires(2)(N-2-8*colonna)); 
				end generate;
				
				PG3_1 : for colonna in 0 to ((N/8)-1) generate
				BP : bypass 
				Port Map (wires(1)(N-1-8*colonna-4), 
					  wires(1)(N-2-8*colonna-4), 
					  wires(2)(N-1-8*colonna-4),
					  wires(2)(N-2-8*colonna-4)); 
				end generate;
				
				G3 : gen_block
				Port Map (wires(1)(7), wires(1)(6), wires(1)(3), wires(2)(7));
				
		end generate riga3;
		
		upper_righe : if (riga > 3) generate
		
				PG_up1 : for colonna in 0 to (((N/8)-(2**(riga-3)))/2)-(riga-3)   generate
				PG_up1_1 : for index in 0 to 2**(riga-3)-1 generate
				PGD : pg_block  
				Port Map (wires(riga-2)(N-1-(2**(riga))*colonna-4*index), 
					  wires(riga-2)(N-1-(2**(riga))*colonna-(2**(riga-1))), 
					  wires(riga-2)(N-2-(2**(riga))*colonna-4*index), 
					  wires(riga-2)(N-2-(2**(riga))*colonna-(2**(riga-1))), 
					  wires(riga-1)(N-1-(2**(riga))*colonna-4*index), 
					  wires(riga-1)(N-2-(2**(riga))*colonna-4*index)); 
				end generate;
				end generate;
				
				PG_up2 : for colonna in 0 to (((N/8)-(2**(riga-3)))/2)-(riga-3) generate
				PG_up2_1 : for index in 0 to (2**(riga-3))-1 generate
				BP1: bypass
				port map (wires(riga-2)(N-1-(2**(riga))*colonna-2**(riga-1)-4*index),
                                          wires(riga-2)(N-2-(2**(riga))*colonna-2**(riga-1)-4*index),
					  wires(riga-1)(N-1-(2**(riga))*colonna-2**(riga-1)-4*index),
                                          wires(riga-1)(N-2-(2**(riga))*colonna-2**(riga-1)-4*index));
				end generate;
				end generate;
			
				last_bypass : for index in 0 to 2**(riga-3)-1 generate
				BP2 : bypass
				Port Map (wires(riga-2)(2**(riga-1)-1-4*index),
                                          wires(riga-2)(2**(riga-1)-2-4*index),
                                          wires(riga-1)(2**(riga-1)-1-4*index), 
					  wires(riga-1)(2**(riga-1)-2-4*index));
				end generate;
				
				G_up : for index in 0 to 2**(riga-3)-1 generate
				GD : gen_block
				Port Map (wires(riga-2)(2**(riga)-1-4*index),
                                          wires(riga-2)(2**(riga)-2-4*index),
                                          wires(riga-2)(2**(riga)-1-(2**(riga-1))), 
					  wires(riga-1)(2**(riga)-1-4*index));
				end generate;
		end generate upper_righe;

	end generate righe;

Carry_out : for index in 1 to (N/4) generate	
	         	Cout(index-1) <= wires(log2(N)-1)(4*index-1);
	      		end generate;	
                         
END STRUCTURAL;


