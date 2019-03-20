library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; 
use WORK.DLX_package.all; 


entity boothmul is
     generic (
               N : integer:=n_data_size
             );
     port    (
               A : IN  std_logic_vector (N-1 downto 0); 
               B : IN  std_logic_vector (N-1 downto 0);
               P : OUT std_logic_vector (2*N-1 downto 0)
             );     
end entity;

architecture struct_beahv of boothmul is

component mux5to1
	Generic ( 
		  N: integer :=n_data_size
		);
	Port (
                A:	        In	std_logic_vector(N-1 downto 0);
		Double_A:	In	std_logic_vector(N-1 downto 0);
                Minus_A:	In	std_logic_vector(N-1 downto 0);
                Minus_Double_A:	In	std_logic_vector(N-1 downto 0);
		SEL:	        In	std_logic_vector(2 downto 0);
		Y:	        Out	std_logic_vector(N-1 downto 0));
end component;

component encoder 
    
     port  (
	        B: in std_logic_vector(2 downto 0);
	        S: out std_logic_vector(2 downto 0)
            );
end component; 

component RCA 
	generic (
                 N     :        integer:= n_data_size
                );
	Port (	A:	In	std_logic_vector(N-1 downto 0);
		B:	In	std_logic_vector(N-1 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(N-1 downto 0);
		Co:	Out	std_logic);
end component;

component shifter
     generic (
               N : integer:=n_data_size
             );
     port    (
               A1 : IN  std_logic_vector (N-1 downto 0);
               A2 : IN  std_logic_vector (N-1 downto 0);
               A3 : IN  std_logic_vector (N-1 downto 0); 
               A4 : IN  std_logic_vector (N-1 downto 0);
               B1 : OUT std_logic_vector (N-1 downto 0);
               B2 : OUT std_logic_vector (N-1 downto 0);       
               B3 : OUT std_logic_vector (N-1 downto 0);
               B4 : OUT std_logic_vector (N-1 downto 0)
             );     
end component; 

type SignalVector is array (N/2 downto 0) of std_logic_vector(2*N+3 downto 0);
type SignalVector_2 is array (N/2-1 downto 0) of std_logic_vector(2*N+3 downto 0);

signal A_tmp              : SignalVector;        --2*N it is the maximum size reached by A
signal Double_A_tmp       : SignalVector;
signal Minus_A_tmp        : SignalVector;
signal Minus_Double_A_tmp : SignalVector;
signal S_tmp              : std_logic_vector((N/2+1)*3-1 downto 0);
signal MUXtoRCA           : SignalVector;
signal RCAtoRCA           : SignalVector_2;
signal B_tmp              : std_logic_vector(N downto 0);
signal B_tmp_1            :std_logic_vector(2 downto 0);
begin 

B_tmp_1<= B(1 downto 0) & '0';
B_tmp <= "00" & B(N-1 downto 1) ;


A_tmp(0)(N+1 downto 0) <="00" & A ;                 --these signals are necessary for the parallelism of the used components
A_tmp(0)(2*N+3 downto N+2) <= (others =>'0');

Double_A_tmp(0)(N+2 downto 0) <="00" & A &'0';
Double_A_tmp(0)(2*N+3 downto N+3) <= (others =>'0');

Minus_A_tmp(0) <= (std_logic_vector(unsigned( not A_tmp(0) )+ 1));                                            

Minus_Double_A_tmp(0) <= (std_logic_vector(unsigned( not Double_A_tmp(0))+ 1));





MUX_0 : mux5to1    
	Generic Map (N => 2*N+4)      
	Port Map (A=> A_tmp(0) ,Double_A=> Double_A_tmp(0),Minus_A=> Minus_A_tmp(0) ,Minus_Double_A=> Minus_Double_A_tmp(0) ,SEL=> S_tmp(2 downto 0), Y => MUXtoRCA(0));  

ENC_0 : encoder Port Map (B =>B_tmp_1,S => S_tmp(2 downto 0));

STAGE_GENERATION: for I in 1 to N/2 generate
                      
                      stage_0: if I=1 generate
                      rca_0 : RCA
                      Generic Map ( N => 2*N+4 ) 
		      Port Map ( A => MUXtoRCA(I), B => MUXtoRCA(I-1),Ci => '0',S =>RCAtoRCA(I-1));
                      
                      end generate stage_0;

                      stage_i: if (I>1 and I<(N/2+1)) generate
                      rca_i : RCA
                      Generic Map ( N => 2*N+4 ) 
		      Port Map ( A => MUXtoRCA(I), B => RCAtoRCA(I-2),Ci => '0',S =>RCAtoRCA(I-1));
                      
                      end generate stage_i;		 


                      shift_i: shifter
                      Generic Map(N => 2*N+4)
                      Port Map ( A1 => A_tmp(I-1), A2 => Double_A_tmp(I-1), A3 => Minus_A_tmp(I-1), A4 => Minus_Double_A_tmp(I-1), B1 => A_tmp(I), B2 => Double_A_tmp(I) ,B3 => Minus_A_tmp (I) ,B4 => Minus_Double_A_tmp(I));
                    

		      mux_i: mux5to1    
		      Generic Map(N => 2*N+4)
                      Port Map ( A=> A_tmp(I), Double_A=> Double_A_tmp(I), Minus_A=> Minus_A_tmp(I) , Minus_Double_A=> Minus_Double_A_tmp(I) ,SEL=> S_tmp((I*3+2) downto I*3), Y => MUXtoRCA(I) );
		      
                      enc_i: encoder
                      Port Map ( B=>B_tmp(2*I downto 2*(I-1) ), S => S_tmp(I*3+2 downto I*3) ); 
		
             

                     end generate STAGE_GENERATION;



 P <= RCAtoRCA(N/2-1)(2*N-1 downto 0);

end struct_beahv ;
