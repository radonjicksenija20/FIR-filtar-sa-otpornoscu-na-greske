----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/09/2023 04:41:54 PM
-- Design Name: 
-- Module Name: big_voter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.util_pkg.all;

entity big_voter is
  generic (
    M : integer := 3; -- number of modules
    N : integer := 2  -- number of bits per module
  );
  port (
    clk : in std_logic;
    big_voter_i : in std_logic_vector(M*N -1 downto 0);
    big_voter_o : out std_logic_vector(N -1 downto 0)
  );
end big_voter;
architecture Behavioral of big_voter is

type array_type is array (0 to N-1) of std_logic_vector(M-1 downto 0);
signal bits_array_i : array_type;

 attribute dont_touch :string;
 attribute dont_touch  of bits_array_i :signal is "true";
begin

process(big_voter_i)
begin
  
    for i in 0 to N-1 loop    
        for j in 0 to M-1 loop
             bits_array_i(i)(j) <= big_voter_i (N * j + i);      
        end loop;
    end loop;
    
end process;

voter_sections:
for i in 0 to N-1 generate
   voters: entity work.voter(behavioral)
            generic map(M => M,
                        N => N)
            port map(clk => clk,
                     voter_i => bits_array_i(i),
                     voter_o => big_voter_o(i)); 
end generate;

end Behavioral;

   ----   match_bits <= (others =>(others => '0'));
    --    match_bits_shifted <= (others =>(others => '0'));
--    for i in 0 to N-1 loop 
--       -- bits_array_i <= (others =>(others => '0'));
--      --  match_bits_shifted <= (others =>(others => '0'));   
--        for j in 0 to M-1 loop
--             bits_array_i(i)(j) <= big_voter_i (N * j + i);
--       --     match_bits(i) <= big_voter_i (N * j + i) & match_bits_shifted(i)(M-2 downto 0);
--          --  match_bits_shifted(i) <= std_logic_vector(shift_right(unsigned(match_bits(i)), 1));         
--        end loop;
--       -- bits_array_i(i) <= match_bits(i);
--    end loop;
