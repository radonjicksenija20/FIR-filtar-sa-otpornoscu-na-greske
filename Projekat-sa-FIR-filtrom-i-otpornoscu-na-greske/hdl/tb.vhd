library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use work.txt_util.all;
use work.util_pkg.all;

entity tb is
    generic(fir_ord : natural :=5;
            input_data_width : natural := 16;
            output_data_width : natural := 16;
            number_samples_g:positive:=500;
            M : integer :=21);
--  Port ( );
end tb;

architecture Behavioral of tb is
    constant period : time := 20 ns;
    signal clk : std_logic;
    file input_test_vector : text open read_mode is "C:\Users\ksenija\Desktop\Fir_projekat\Projekat-sa-FIR-filtrom-i-otpornoscu-na-greske\matlab\input.txt";
    file output_check_vector : text open read_mode is "C:\Users\ksenija\Desktop\Fir_projekat\Projekat-sa-FIR-filtrom-i-otpornoscu-na-greske\matlab\expected.txt";
    file input_coef : text open read_mode is "C:\Users\ksenija\Desktop\Fir_projekat\Projekat-sa-FIR-filtrom-i-otpornoscu-na-greske\matlab\coef.txt";
    signal reset :  std_logic;
    signal start :  std_logic;    
    signal we_bram1_i : std_logic; 
    signal coef_i : STD_LOGIC_VECTOR (input_data_width-1 downto 0);
    signal coef_addr_i : std_logic_vector(log2c(fir_ord+1)-1 downto 0);
    signal  we_i_coeff:  std_logic;
    signal data_i : STD_LOGIC_VECTOR (input_data_width-1 downto 0);
    signal addr_data_i : std_logic_vector(log2c(number_samples_g+1)-1 downto 0); 
    signal data_o : STD_LOGIC_VECTOR (output_data_width-1 downto 0);
    signal addr_data_o : std_logic_vector(log2c(number_samples_g+1)-1 downto 0);
    signal ready_o : STD_LOGIC;
      
    signal start_check : std_logic := '0';
    signal j : integer := 0;
    

begin
   
    top_structure:
    entity work.top_structure(behavioral)
    generic map(fir_ord=>fir_ord,
                input_data_width => input_data_width,
                output_data_width => output_data_width,
                number_samples_g => number_samples_g,
                M => M)               
    port map(clk => clk,
             reset => reset,
             start => start,
             we_bram1_i => we_bram1_i,
             coef_i => coef_i,
             coef_addr_i => coef_addr_i,
             we_i_coeff => we_i_coeff,
             data_i => data_i,
             addr_data_i => addr_data_i,
             data_o => data_o,
             addr_data_o => addr_data_o,
             ready_o => ready_o
             );
           
    clk_process:
    process
    begin
        clk <= '0';
        wait for period/2;
        clk <= '1';
        wait for period/2;
    end process;
    
    stim_process:
    process
        variable tv : line;
    begin
        start <= '0';
        start_check <= '0';
        reset <= '1', '0' after 50ns; 
        --upis koeficijenata
        coef_i <= (others=>'0');
        wait until falling_edge(clk);
  
        for i in 0 to fir_ord loop
            we_i_coeff <= '1';
            coef_addr_i <= std_logic_vector(to_unsigned(i,log2c(fir_ord+1)));
            readline(input_coef,tv);
            coef_i <= to_std_logic_vector(string(tv));
            wait until falling_edge(clk);
        end loop;
        
       --ulaz, obirci za filtriranje 
       while not endfile(input_test_vector) loop
            we_bram1_i <= '1';
            readline(input_test_vector,tv);
            data_i <= to_std_logic_vector(string(tv));
            addr_data_i <= std_logic_vector(TO_UNSIGNED(j, log2c(number_samples_g+1)));
            j <= j + 1;
            wait until falling_edge(clk);
            --start_check <= '1';
        end loop;
       
        we_bram1_i <= '0';
        start <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        start <= '0';
        start_check <= '1';
        wait;
    end process;
    
    
    reading_process: 
    process 
        begin
            wait until rising_edge(clk);  --jer ready pada na 0 jedan takt nakon starta
            wait until rising_edge(clk);
            wait until ready_o = '1';
            wait until falling_edge(clk);
            for i in 0 to number_samples_g-1 loop
                 addr_data_o <= std_logic_vector(to_unsigned(i, log2c(number_samples_g)));
                 start_check <= '1';
                 wait until falling_edge(clk);
             end loop;
          wait;  
    end process; 


     check_process: 
     process 
      variable check_v : line;
      variable tmp : std_logic_vector(output_data_width-1 downto 0);
     begin    
        wait until start_check = '1';
        wait until falling_edge(clk);
       -- wait until falling_edge(clk);     
     while not endfile(output_check_vector) loop
            wait until rising_edge(clk);
            readline(output_check_vector,check_v);
            tmp := to_std_logic_vector(string(check_v));
            if(abs(signed(tmp) - signed(data_o)) > "000000000000000000000011")then
                report "result mismatch!" severity failure;
            end if;
        end loop; 
        report "result matched!" severity failure;  
    end process;
    
 
    
  
end Behavioral;