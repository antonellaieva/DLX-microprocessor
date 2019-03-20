library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; 
use WORK.DLX_package.all; 


entity shifter is
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
end entity;

architecture struct of shifter is

  begin
  
  B1 <= A1((N-3)downto 0) & "00";
  B2 <= A2((N-3)downto 0) & "00";
  B3 <= A3((N-3)downto 0) & "00";
  B4 <= A4((N-3)downto 0) & "00";

end struct;
