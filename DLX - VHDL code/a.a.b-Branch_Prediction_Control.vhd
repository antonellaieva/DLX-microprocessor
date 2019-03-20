library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity BHT is
 port(
             Clk          : IN std_logic;
	     Rst          : IN std_logic;
             BRANCH       : IN  std_logic;
             OPCODE_PIPE  : IN  std_logic;    --arriva dall' execution stage
             COME_BACK    : OUT  std_logic;
             HISTORY      : OUT  std_logic   		
	 );
end ;

architecture arch of BHT is

  type State is (RESET, S_00,S_11);
  signal PS, NS : State;

 
  begin 
  
  -----------------------------------
     Next_State : process(OPCODE_PIPE,BRANCH,PS)
		      begin
			        NS <= S_00; --default value for NS
                                case PS is
			        when S_00 =>   if (OPCODE_PIPE='1') then
                                                                    if ( BRANCH='1') then  NS <= S_11;
	                                           		    else                   NS <= S_00;
                                                                    end if;
                                              
                                               else                 NS <= S_00;                                    
                                              
                                               end if; 
	       
	                    
                                               
                               when S_11 =>  if (OPCODE_PIPE='1') then
                                                                    if ( BRANCH='1') then  NS <= S_11;
	                                           		    else                   NS <= S_00;
                                                                    end if;
                                              
                                               else                 NS <= S_11;                                    
                                              
                                               end if; 
										when others  => 	  NS <= S_00;   			  
                       end case; 
                     end process;

     State_Register: process(Clk)
		      begin
		      if(Clk'EVENT and Clk = '1') then
		         if (Rst = '0') then
			       PS <= S_00;
			 else
			       PS <= NS;
		         end if;
		      end if;
		 end process State_Register;

     
     Output : process(OPCODE_PIPE,BRANCH,PS)
                  
		  begin
                  HISTORY <= '0';
                  COME_BACK <='0';
                 	case PS is
			           when S_00 =>    HISTORY <= '0';
                                                   if (OPCODE_PIPE='1') then
		                                             if ( BRANCH='1') then COME_BACK <='1';
                                                            end if;       
                                                   else                                         
                                                            COME_BACK <='0'  ;
                                                   end if;          
                                                    
			          
			           when S_11 =>    HISTORY <= '1';
                                                   if (OPCODE_PIPE='1') then
		                                            if ( BRANCH='0') then COME_BACK <='1';
                                                            end if;       
                                                   else                                         
                                                            COME_BACK <='0'  ;
                                                   end if;
		          	when others  => 	 HISTORY <= '0';
						         COME_BACK <='0';   	
					  end case;
					  
	   	  end process;
       
 end arch;

