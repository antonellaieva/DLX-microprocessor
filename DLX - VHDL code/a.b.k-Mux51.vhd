library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic
use WORK.DLX_package.all; -- libreria WORK user-defined

entity mux5to1 is
	Generic ( 
		  N: integer := n_data_size
		);
	Port (
                A:	        In	std_logic_vector(N-1 downto 0);
		Double_A:	In	std_logic_vector(N-1 downto 0);
                Minus_A:	In	std_logic_vector(N-1 downto 0);
                Minus_Double_A:	In	std_logic_vector(N-1 downto 0);
		SEL:	        In	std_logic_vector(2 downto 0);
		Y:	        Out	std_logic_vector(N-1 downto 0));
end mux5to1;

architecture behavior of mux5to1 is
       
       begin
       
       P1: process(SEL,Double_A,Minus_A,Minus_Double_A,A) 
           begin

           case SEL is

           when "000" =>
                 Y <= (others =>'0');
           
           when "001" =>
                 Y <= A;
           
           when "010" =>
                 Y <= Minus_A;	

           when "011" =>
                 Y <= Double_A;	

           when "100" =>
                 Y <= Minus_Double_A;	

           when others => Y <= (others => '0');

           end case;

           end process;
           
end behavior;




