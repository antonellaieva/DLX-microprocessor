library IEEE;
use IEEE.std_logic_1164.all;
use WORK.DLX_package.all;

entity tb_dlx is
end tb_dlx;

architecture TEST of tb_dlx is

    component DLX_and_MEM 
	  generic (
	    IR_SIZE      : integer := N_DATA_SIZE;       -- Instruction Register Size
	    PC_SIZE      : integer := N_DATA_SIZE       -- Program Counter Size
	    );       
	  port (
	    Clk : in std_logic;
	    Rst : in std_logic);                -- Active Low
    end component;
    
    signal Clock: std_logic := '0';
    signal Reset: std_logic := '1';

begin


        -- instance of DLX
	U1: DLX_and_MEM
        Generic Map (N_DATA_SIZE, N_DATA_SIZE)
	Port Map (Clock, Reset);
	

        PCLOCK : process(Clock)
	begin
		Clock <= not(Clock) after 0.5 ns;	
	end process;
	
	Reset <= '0', '1' after 1.5 ns; -- '0' after 14 ns, '1' after 15 ns;
       

end TEST;

