
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.util_pkg.all;
use IEEE.NUMERIC_STD.ALL;

entity top_structure is
generic(    fir_ord : natural :=5;
            input_data_width : natural := 24;
            output_data_width : natural := 24;
            number_samples_g:positive:=500;
            M : integer := 21); -- number of modules
    Port ( clk : in STD_LOGIC;
           reset : in std_logic;
           start: in std_logic;
           we_bram1_i : in std_logic;
           
           coef_i : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           coef_addr_i : std_logic_vector(log2c(fir_ord+1)-1 downto 0);
           we_i_coeff: in std_logic;
           
           data_i : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           addr_data_i : in std_logic_vector(log2c(number_samples_g+1)-1 downto 0);           
           data_o : out STD_LOGIC_VECTOR (output_data_width-1 downto 0);
           addr_data_o : in std_logic_vector(log2c(number_samples_g+1)-1 downto 0);
           
           ready_o : out STD_LOGIC);
end top_structure;

architecture Behavioral of top_structure is

 --general signals for BRAM
    signal zero : std_logic;
    signal zero_width_g : std_logic_vector(input_data_width-1 downto 0);
    signal en_mem_s : std_logic;
  --signals between top and BRAM1
    signal addr_data_i_s: std_logic_vector(log2c(number_samples_g+1)-1 downto 0); 
  --signals between top and FIR
    signal coef_addr_i_s : std_logic_vector(log2c(fir_ord+1)-1 downto 0);
  --signals between BRAM1 and FIR
  -- signal data_i_FIR_s : STD_LOGIC_VECTOR (input_data_width-1 downto 0);
   signal data_i_FIR_reg, data_i_FIR_next : STD_LOGIC_VECTOR (input_data_width-1 downto 0);
   
   signal addr_data_o_BRAM1_FIR_s : std_logic_vector(log2c(number_samples_g+1)-1 downto 0);
   signal added_register : STD_LOGIC_VECTOR (input_data_width-1 downto 0);
   --signals between FIR and voter
   signal big_voter_i_s: STD_LOGIC_VECTOR (M*input_data_width -1 downto 0);
   signal big_voter_o_s: STD_LOGIC_VECTOR (output_data_width -1 downto 0);  
   signal data_o_FIR_voter_s : std_logic_vector(M*input_data_width -1 downto 0);
   --signals between FIR and BRAM2
   signal addr_data_o_FIR_BRAM2_s : std_logic_vector(log2c(number_samples_g+1)-1 downto 0);
   signal we_FIR_BRAM2_s : std_logic;
   --signal for top output
   signal addr_data_o_s : std_logic_vector(log2c(number_samples_g+1)-1 downto 0);
   signal ready_o_s : std_logic;
   
    attribute dont_touch :string;
    attribute dont_touch  of data_o_FIR_voter_s :signal is "true";
    
    component  BRAM
    generic(
        width_g:positive:=24;
        size_g:positive:=4000
        );
    port(
        clka : in std_logic;
        clkb : in std_logic;
        ena: in std_logic;
        enb: in std_logic;
        wea: in std_logic;
        web: in std_logic;
        addra : in std_logic_vector(log2c(size_g+1)-1 downto 0);
        addrb : in std_logic_vector(log2c(size_g+1)-1 downto 0);
        dia: in std_logic_vector(width_g-1 downto 0);
        dib: in std_logic_vector(width_g-1 downto 0);
        doa: out std_logic_vector(width_g-1 downto 0);
        dob: out std_logic_vector(width_g-1 downto 0)
        );
    end component;
    
    
    component fir_param 
    generic(fir_ord : natural :=20;
            input_data_width : natural := 16;
            output_data_width : natural := 16;
            number_samples_g:positive:=4000);
    Port ( clk : in STD_LOGIC;
           reset : in std_logic;
           start_FIR : in std_logic;
           
           we_o_fir_bram2 : out std_logic;
           we_i_coeff: in std_logic; 
           
           coef_i_FIR : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           coef_addr_i_FIR : std_logic_vector(log2c(fir_ord+1)-1 downto 0);
           
           data_i_FIR : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           addr_data_o_BRAM1_FIR : out std_logic_vector(log2c(number_samples_g+1)-1 downto 0); --netacno, ima vise
           
           data_o_FIR : out STD_LOGIC_VECTOR (output_data_width-1 downto 0);
           addr_data_o_FIR_BRAM2 : out std_logic_vector(log2c(number_samples_g+1)-1 downto 0);
           ready_o_FIR : out std_logic);
    end component;

    component big_voter 
      generic (
        M : integer := 3; -- number of modules
        N : integer := 2  -- number of bits per module
      );
      port (
        clk : in std_logic;
        big_voter_i : in std_logic_vector(M*N -1 downto 0);
        big_voter_o : out std_logic_vector(N -1 downto 0)
      );
    end component;

begin

    en_mem_s <= '1';
    zero <= '0';
    zero_width_g <= std_logic_vector(to_unsigned(0,input_data_width));
    --connecting top and BRAM1
    addr_data_i_s <= addr_data_i;
    
    --connecting top and FIR
    coef_addr_i_s <= coef_addr_i;
    
    --connecting top and BRAM2           
    addr_data_o_s <= addr_data_o;
    
    --connecting FIR and voter
    big_voter_i_s <= data_o_FIR_voter_s;
    
 mem_1: BRAM
    generic map(
                width_g => input_data_width,
                size_g => number_samples_g
                )
    port map(
            clka => clk,
            clkb => clk,
            ena => en_mem_s,
            enb => en_mem_s,
            wea => we_bram1_i,       -- portA za UPIS pocetnih odbiraka u BRAM1
            web => zero,               -- portB za CITANJE odbiraka iz BRAM1 od strane FIR
            addra => addr_data_i_s,       --adresa na koju se upisuje odbirak sa starta
            addrb => addr_data_o_BRAM1_FIR_s,  --adresa sa koje fir cita ulazni podatak
            dia => data_i,
            dib => zero_width_g,  
            doa => open,
            dob => data_i_FIR_next      --ulazni odbirci za FIR
            );
            

 reg_proc: process(clk)
    begin
        if(clk'event and clk = '1')then
            if(reset = '1')then
                data_i_FIR_reg <= (others=> '0');
            else
                data_i_FIR_reg <= data_i_FIR_next;
            end if;
         end if;
    end process;
 
  FIR_0: fir_param
        generic map(
                    fir_ord  => fir_ord ,
                    input_data_width  => input_data_width,
                    output_data_width  => output_data_width,
                    number_samples_g  => number_samples_g
                    )
        port map(
                clk => clk,
                reset => reset,
                start_FIR => start,
                
                we_o_fir_bram2 => we_FIR_BRAM2_s,
                we_i_coeff => we_i_coeff,
                coef_i_FIR => coef_i,
                coef_addr_i_FIR => coef_addr_i_s,
               
               data_i_FIR => data_i_FIR_reg,
               addr_data_o_BRAM1_FIR => addr_data_o_BRAM1_FIR_s,           
               data_o_FIR => data_o_FIR_voter_s(output_data_width-1 downto 0), --konkatenacija izlaza FIRa redom na bite
               addr_data_o_FIR_BRAM2 => addr_data_o_FIR_BRAM2_s,
               ready_o_FIR => ready_o_s
                );
 
 
 gen_FIR_other_modules: for i in 1 to M-1 generate
     FIR_others: fir_param
        generic map(
                    fir_ord  => fir_ord ,
                    input_data_width  => input_data_width,
                    output_data_width  => output_data_width,
                    number_samples_g  => number_samples_g
                    )
        port map(
                clk => clk,
                reset => reset,
                start_FIR => start,
                
                we_o_fir_bram2 => open,
                we_i_coeff => we_i_coeff,
                coef_i_FIR => coef_i,
                coef_addr_i_FIR => coef_addr_i_s,
               
               data_i_FIR => data_i_FIR_reg,
               addr_data_o_BRAM1_FIR => open,           
               data_o_FIR => data_o_FIR_voter_s(output_data_width + i*output_data_width -1 downto output_data_width*i), --konkatenacija izlaza FIRa redom na bite
               addr_data_o_FIR_BRAM2 => open,
               ready_o_FIR => open
                );
    end generate;     
            
    voter_c: big_voter
    generic map(
                M  => M,
                N  => input_data_width)
    port map(
              clk => clk,
              big_voter_i => big_voter_i_s,
              big_voter_o => big_voter_o_s); 
         
            
    mem2: BRAM
    generic map(
                width_g => input_data_width,
                size_g => number_samples_g
                )
    port map(
            clka => clk,
            clkb => clk,
            ena => en_mem_s,
            enb => en_mem_s,
            wea => we_FIR_BRAM2_s,               -- portA za UPIS u BRAM2 iz votera
            web => zero,                         -- portB za CITANJE odbiraka iz BRAM2 za izlazne podatke
            addra => addr_data_o_FIR_BRAM2_s,    --adresa na koju se upisuje, iz FIRa
            addrb => addr_data_o_s,              --adresa sa koje se cita za izlazne podatke
            dia => big_voter_o_s,
            dib => zero_width_g,  
            doa => open,
            dob => data_o                 --izlazni podaci
            );
            
 ready_o <= ready_o_s;  
          
end Behavioral;
