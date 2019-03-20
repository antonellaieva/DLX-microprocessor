library IEEE;
use IEEE.std_logic_1164.all;
use WORK.DLX_package.all;

entity mux21_generic is
  
  generic (
    N : integer );
  port (
    A: in std_logic_vector(N-1 downto 0);
    B: in std_logic_vector(N-1 downto 0);
    SEL: in std_logic;
    Y: out std_logic_vector(N-1 downto 0)
    );
end mux21_generic;

architecture behavioral of mux21_generic is
 
begin 
 M: process(SEL,A,B) 
           begin

           if (SEL = '0') then
                 Y <= A;
           else
                 Y <= B;
           end if;

     end process;



end behavioral;


