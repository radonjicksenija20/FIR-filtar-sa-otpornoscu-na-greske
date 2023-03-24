library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

entity mac is
    generic (input_data_width : natural :=24);
    Port ( clk : in std_logic;
           u_i : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           b_i : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           sec_i : in STD_LOGIC_VECTOR (2*input_data_width-1 downto 0);
           sec_o : out STD_LOGIC_VECTOR (2*input_data_width-1 downto 0));
end mac;

architecture Behavioral of mac is
    signal reg_u_next, reg_u_reg : STD_LOGIC_VECTOR (input_data_width-1 downto 0):=(others=>'0');
    signal reg_b_next, reg_b_reg : STD_LOGIC_VECTOR (input_data_width-1 downto 0):=(others=>'0');
    
    signal reg_a_next, reg_a_reg : STD_LOGIC_VECTOR (2*input_data_width-1 downto 0):=(others=>'0');
    signal reg_m_next, reg_m_reg : STD_LOGIC_VECTOR (2*input_data_width-1 downto 0):=(others=>'0');
    
    -- Atributes that need to be defined so Vivado synthesizer maps appropriate
    -- code to DSP cells
    attribute use_dsp : string;
    attribute use_dsp of Behavioral : architecture is "yes";
    
begin

    process(clk)
    begin
        if (clk'event and clk = '1')then
        
            reg_u_reg <= reg_u_next;
            reg_b_reg <= reg_b_next;
            reg_m_reg <= reg_m_next;
            reg_a_reg <= reg_a_next;
            
        end if;
    end process;
    
    reg_u_next <= u_i;
    reg_b_next <= b_i;
    
    reg_m_next <= std_logic_vector(signed(reg_u_reg) * signed(reg_b_reg));

    reg_a_next <= std_logic_vector(signed(sec_i) + signed(reg_m_reg));
    
    sec_o <= reg_a_reg;
    
end Behavioral;