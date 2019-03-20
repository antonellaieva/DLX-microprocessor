library ieee; 
use ieee.std_logic_1164.all;
use WORK.DLX_package.all;
USE ieee.numeric_std.all;

ENTITY bypass IS
	PORT (s_in1: IN STD_LOGIC;
	      s_in2: IN STD_LOGIC;
	      s_out1: OUT STD_LOGIC;
	      s_out2: OUT STD_LOGIC);
end bypass;

ARCHITECTURE behaviour OF bypass IS

BEGIN
	s_out1 <= s_in1;
	s_out2 <= s_in2;
END behaviour;
