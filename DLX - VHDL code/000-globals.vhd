library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package DLX_package is
  --constants CU
 constant MICROCODE_MEM_SIZE :     integer := 62;
--------------------------------------------------------------------------------------------------------------------------------------------------------  
  --constants IRAM  
 constant IRAM_DEPTH: integer := 512;   --it contains IRAM_DEPTH/4 instructions
 constant n_op : integer := 6;
--------------------------------------------------------------------------------------------------------------------------------------------------------  
 --constant DRAM  
 constant DRAM_DEPTH: integer := 2048;
 constant STACK_DEPTH : integer := 64; 
--------------------------------------------------------------------------------------------------------------------------------------------------------     
  --constant for parallelism
  constant N_DATA_SIZE : integer := 32;           --Number of bits of the architecture
--------------------------------------------------------------------------------------------------------------------------------------------------------  
  --constants RF WINDOWING
  constant address_RF_DATA_RAM  : integer := 8;   -- Width of the addressing dedicated to the RF (for SPILL and FILL operations)
  constant N_reg_block          : integer :=8; --number of registers in each block
  constant F                    : integer :=8; --number of windows
  constant F_1                  : integer :=7;  --insert : F-1  
  constant M                    : integer :=8; --number of registers in the global block;
  constant N2F                  : integer :=128; --insert the product: 2*N*F
  constant N2F_1                : integer :=127;   
  constant N2F_3N               : integer :=104;  --insert the value: 2*N*F-3*N

  --constants RF FIXED
  constant RF_DEPTH  : integer := 32;
--------------------------------------------------------------------------------------------------------------------------------------------------------
  --constants ALU
  constant n_bit_carry_select : integer := 4;     -- Number of bits for each Carry_select_block
--------------------------------------------------------------------------------------------------------------------------------------------------------  
  --functions
  function log2(input :integer) return integer;	
  function log2r(input :integer) return integer;	
--------------------------------------------------------------------------------------------------------------------------------------------------------  
  --ALU types - R type instructions
  type TYPE_OP is (ADD, SUB, MULT, BITAND, BITOR, BITXOR, FUNCR_LOGIC, FUNCR_ARITH, FUNCL_LOGIC, NOP);
 
--------------------------------------------------------------------------------------------------------------------------------------------------------
 --INSTRUCTIONS types 
 type TYPE_INSTRUCTION is ( sll_R , srl_R , sra_R , add_R, addu_R, sub_R, subu_R, and_R , or_R , xor_R, seq_R , sne_R , slt_R, sgt_R, sle_R, sge_R,
 movi2s_R ,movs2i_R , movf_R, movd_R, movfp2i_R, movi2fp_R ,movi2t_R , movt2i_R, sltu_R, sgtu_R, sleu_R, sgeu_R, j, jal, beqz, bnez, bfpt,
 bfpf, addi, addui, subi, subui, andi, ori, xori, lhi, rfe, trap, jrjr, jalr_jr, slli, nop, srli, srai, seqi, snei, slti, sgti, slei, sgei,
 lb, lh, lw, lbu, lhu, lf, ld, sb, sh, sw, sf, sd, itlb, sltui, sgtui, sleui, sgeui, call_i, ret_i, mult );
 
--------------------------------------------------------------------------------------------------------------------------------------------------------

end DLX_package;


package body DLX_package is

       --operation with truncation
        function log2( input:integer ) return integer is
	 variable temp,log:integer;
	 begin
	  temp:=input;
	  log:=-1;
	  while (temp /= 0) loop
	   temp:=temp/2;
	   log:=log+1;
	   end loop;
	   return log;
       end function log2;


         --operation with rounding
        function log2r(input : integer) return integer is
	  variable x : integer := 1;
	  begin
	  x:= input;
	  
	  if (x = 1) then
	     return 1;
	  elsif (x > 1 and x <= 2) then
	     return 1;
	  elsif (x > 2 and x <= 4) then 
	     return 2;
	  elsif (x > 4 and x <= 8) then
	     return 3;
	  elsif (x > 8 and x <= 16) then 
	     return 4; 
	  elsif (x > 16 and x <= 32) then
	       return 5; 
	  elsif (x > 32 and x <= 64) then 
	       return 6; 
	  elsif (x > 64 and x <= 128) then 
	       return 7;
	  elsif (x > 128 and x <= 256) then 
	       return 8;
	  elsif (x > 256 and x <= 512) then 
	       return 9;
	  elsif (x > 512 and x <= 1024) then 
	       return 10;
	  elsif (x > 1024 and x <= 2048) then 
	       return 11;
          elsif (x > 2049 and x <= 4096) then
               return 12;
          elsif (x > 4097 and x <= 8192) then
               return 13;
          elsif (x > 8193 and x <= 16384) then
               return 14;
          elsif (x > 16385 and x <= 32768) then
               return 15;
          elsif (x > 32769 and x <= 65536) then
               return 16;
          elsif (x > 65537 and x <= 131072) then
               return 17;
          elsif (x > 131073 and x <= 262144) then
              return 18;
          elsif (x > 262145 and x <= 524288) then
              return 19;
          elsif (x > 524289 and x <= 1048576) then
              return 20;
	  end if;	
	 
	end function log2r;

end DLX_package;
