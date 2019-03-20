library ieee; 
use ieee.std_logic_1164.all;
use WORK.DLX_package.all;
USE ieee.numeric_std.all;

ENTITY pg_block is
	PORT (
		G2, G1, P2, P1 : IN STD_LOGIC;
		P, G : OUT STD_LOGIC);
END pg_block;

ARCHITECTURE behaviour OF pg_block IS

BEGIN
	G <= G2 OR (P2 AND G1);
	P <= P2 AND P1;
END behaviour;
