library ieee; 
use ieee.std_logic_1164.all;
use WORK.DLX_package.all;
USE ieee.numeric_std.all;

ENTITY gen_block is
	PORT (
		G2, G1, P2 : IN STD_LOGIC;
		G : OUT STD_LOGIC);
END gen_block;

ARCHITECTURE behaviour OF gen_block IS

BEGIN
	G <= G2 OR (P2 AND G1);
END behaviour;
