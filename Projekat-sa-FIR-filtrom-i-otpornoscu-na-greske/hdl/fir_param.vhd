library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.util_pkg.all;

entity fir_param is
    generic(fir_ord : natural :=20;
            input_data_width : natural := 24;
            output_data_width : natural := 24;
            number_samples_g:positive:=4000);
    Port ( clk : in STD_LOGIC;
           reset : in std_logic;
           start_FIR: in std_logic;
                      
           we_o_fir_bram2 : out std_logic;
           we_i_coeff: in std_logic;
           
           coef_i_FIR : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           coef_addr_i_FIR : std_logic_vector(log2c(fir_ord+1)-1 downto 0);
           
           data_i_FIR  : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           addr_data_o_BRAM1_FIR : out std_logic_vector(log2c(number_samples_g+1)-1 downto 0); 
           
           data_o_FIR : out STD_LOGIC_VECTOR (output_data_width-1 downto 0);
           addr_data_o_FIR_BRAM2 : out std_logic_vector(log2c(number_samples_g+1)-1 downto 0);
           ready_o_FIR: out std_Logic);
         
end fir_param;

architecture Behavioral of fir_param is
    type std_2d is array (fir_ord downto 0) of std_logic_vector(2*input_data_width-1 downto 0);
    signal mac_inter : std_2d:=(others=>(others=>'0'));
    type coef_t is array (fir_ord downto 0) of std_logic_vector(input_data_width-1 downto 0);
    signal b_s : coef_t := (others=>(others=>'0')); 
    
    signal counter_BRAM1_FIR_next, counter_BRAM1_FIR_reg : std_logic_vector(log2c(number_samples_g+1)-1 downto 0);
    signal cnt_addr_o_FIR_BRAM2_next, cnt_addr_o_FIR_BRAM2_reg : std_logic_vector(log2c(number_samples_g+1)-1 downto 0);
    
    signal start_flag_next, start_flag_reg : std_logic;
    
    attribute dont_touch :string;
    attribute dont_touch  of mac_inter :signal is "true";
begin

    loading_coeff:process(clk)
    begin
        if(clk'event and clk = '1')then
            if we_i_coeff = '1' then
                b_s(to_integer(unsigned(coef_addr_i_FIR))) <= coef_i_FIR;
            end if;
        end if;
    end process;
    
   reg_proc: process(clk)
    begin
        if(clk'event and clk = '1')then
            if(reset = '1')then
                cnt_addr_o_FIR_BRAM2_reg <= (others=> '0');
                counter_BRAM1_FIR_reg <= (others=> '0');
                start_flag_reg <= '0';
            else
                cnt_addr_o_FIR_BRAM2_reg <= cnt_addr_o_FIR_BRAM2_next;
                counter_BRAM1_FIR_reg <= counter_BRAM1_FIR_next;
                start_flag_reg <= start_flag_next;
            end if;
         end if;
    end process;
  
  
  reading_adresses: process(start_FIR, clk, counter_BRAM1_FIR_reg, cnt_addr_o_FIR_BRAM2_reg, start_flag_reg) 
  begin      
    
          --signals for input FIR
          counter_BRAM1_FIR_next <= counter_BRAM1_FIR_reg;
          start_flag_next <= start_flag_reg;
        
           --signals for output FIR
           ready_o_FIR <= '1';
           we_o_fir_bram2 <= '0';
           cnt_addr_o_FIR_BRAM2_next <= cnt_addr_o_FIR_BRAM2_reg;
           
          if(start_FIR = '1')then
                start_flag_next <= '1';         
          end if;
          
          if(start_flag_reg = '1')then
          
                ready_o_FIR <= '0';
                --control for input
               if(counter_BRAM1_FIR_reg < std_logic_vector(to_unsigned(number_samples_g, log2c(number_samples_g+1)))) then --ide do numb_samples-1
                        addr_data_o_BRAM1_FIR <= counter_BRAM1_FIR_reg; --za citanje iz BRAM1
                        counter_BRAM1_FIR_next <= std_logic_vector(unsigned(counter_BRAM1_FIR_reg) + to_unsigned(1,log2c(number_samples_g+1)));
                       
               end if;
               
               --control for output
               if(counter_BRAM1_FIR_reg > std_logic_vector(to_unsigned(3, log2c(number_samples_g+1)))) then --zbog dodatog registra TRI
                    if(cnt_addr_o_FIR_BRAM2_reg < std_logic_vector(to_unsigned(number_samples_g, log2c(number_samples_g+1)))) then
                        we_o_fir_bram2 <= '1';                      
                        data_o_FIR <= mac_inter(fir_ord - 1)(2*input_data_width-2 downto 2*input_data_width-output_data_width-1);
                        addr_data_o_FIR_BRAM2 <= cnt_addr_o_FIR_BRAM2_reg;
                        cnt_addr_o_FIR_BRAM2_next <= std_logic_vector(unsigned(cnt_addr_o_FIR_BRAM2_reg) + to_unsigned(1,log2c(number_samples_g+1)));
                    else
                        we_o_fir_bram2 <= '0';
                        ready_o_FIR <= '1';
                        cnt_addr_o_FIR_BRAM2_next <= (others => '0');
                        counter_BRAM1_FIR_next <= (others => '0');
                        start_flag_next <= '0';    
                    end if;
                end if;
           end if;
  end process;

   
    first_section:
    entity work.mac(behavioral)
    generic map(input_data_width=>input_data_width)
    port map(clk=>clk,
             u_i=>data_i_FIR,
             b_i=>b_s(fir_ord),
             sec_i=>(others=>'0'),
             sec_o=>mac_inter(0));
                     
    other_sections:
    for i in 1 to fir_ord-1 generate
        fir_section:
        entity work.mac(behavioral)
        generic map(input_data_width=>input_data_width)
        port map(clk=>clk,
                 u_i=>data_i_FIR,
                 b_i=>b_s(fir_ord-i),
                 sec_i=>mac_inter(i-1),
                 sec_o=>mac_inter(i));
    end generate;

    
end Behavioral;