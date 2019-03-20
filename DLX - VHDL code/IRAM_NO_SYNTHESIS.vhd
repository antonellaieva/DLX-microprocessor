library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all; 
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use WORK.DLX_package.all;


-- Instruction memory for DLX
-- Memory filled by a process which reads from a file
-- file name is "test.asm.mem"
entity IRAM is
  generic (
    RAM_DEPTH : integer := IRAM_DEPTH;
    I_SIZE : integer := 32);
  port (
    Rst  : in  std_logic;
    Addr : in  std_logic_vector(log2r(IRAM_DEPTH) - 1 downto 0);
    Dout : out std_logic_vector(I_SIZE - 1 downto 0)
    );

end IRAM;

architecture IRam_Bhe of IRAM is
 
  subtype REG_ADDR is natural range 0 to IRAM_DEPTH -1; -- using natural type
  type RAMtype is array(REG_ADDR) of std_logic_vector(I_SIZE/4 - 1 downto 0);
  signal IRAM_mem : RAMtype;
  ------------------------------------------------------------------------------------
  signal Dout0, Dout1, Dout2, Dout3 : std_logic_vector(I_SIZE/4 -1 downto 0);
  signal ADDR1,ADDR2,ADDR3 : std_logic_vector(log2r(IRAM_DEPTH)-1 downto 0);

begin  -- IRam_Bhe

  ADDR1 <= ADDR+std_logic_vector(to_unsigned(1,log2r(IRAM_DEPTH)));
  ADDR2 <= ADDR+std_logic_vector(to_unsigned(2,log2r(IRAM_DEPTH)));
  ADDR3 <= ADDR+std_logic_vector(to_unsigned(3,log2r(IRAM_DEPTH)));

  Dout0 <= IRAM_mem(to_integer(unsigned(ADDR)));
  Dout1 <= IRAM_mem(to_integer(unsigned(ADDR1)));
  Dout2 <= IRAM_mem(to_integer(unsigned(ADDR2)));
  Dout3 <= IRAM_mem(to_integer(unsigned(ADDR3)));
  
  Dout <= Dout0 & Dout1 & Dout2 & Dout3;

  -- purpose: This process is in charge of filling the Instruction RAM with the firmware
  -- type   : combinational
  -- inputs : Rst
  -- outputs: IRAM_mem
  FILL_MEM_P: process (Rst)
    file mem_fp: text;
    variable file_line : line;
    variable index : integer := 0;
    variable tmp_data_u : std_logic_vector(I_SIZE-1 downto 0);
  begin  -- process FILL_MEM_P
    if (Rst = '0') then

      for i in 0 to (IRAM_DEPTH)-1 loop
	    IRAM_mem(i) <= (others => '0');		
      end loop;
     
     file_open(mem_fp,"Exam_test_official.mem",READ_MODE);
     --file_open(mem_fp,"fill_spill.mem.txt",READ_MODE);
     -- file_open(mem_fp,"Branch.mem.txt",READ_MODE);
     -- file_open(mem_fp,"all_general_test.mem.txt",READ_MODE);   
      while (not endfile(mem_fp)) loop  
        readline(mem_fp,file_line);
        hread(file_line,tmp_data_u);
        IRAM_mem(index) <= tmp_data_u(I_SIZE -1 downto 3*I_SIZE/4);       
        index := index + 1;
        IRAM_mem(index) <= tmp_data_u(3*I_SIZE/4 -1 downto 2*I_SIZE/4); 
        index := index + 1;
        IRAM_mem(index) <= tmp_data_u(2*I_SIZE/4 -1 downto I_SIZE/4);  
        index := index + 1;
        IRAM_mem(index) <= tmp_data_u(I_SIZE/4 -1 downto 0);  
        index := index + 1;
      end loop;
      --file_close(mem_fp);
    end if;
    
  end process FILL_MEM_P;

end IRam_Bhe;
