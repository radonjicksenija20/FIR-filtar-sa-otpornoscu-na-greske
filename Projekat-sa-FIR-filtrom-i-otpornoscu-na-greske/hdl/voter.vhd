----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/07/2023 12:43:05 PM
-- Design Name: 
-- Module Name: voter - Behavioral
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
entity voter is
    generic (
        M : integer := 5; -- number of modules
        N : integer := 2  -- number of bits per module
    );
    Port (
        clk : in  STD_LOGIC;
        voter_i : in  STD_LOGIC_VECTOR (M-1 downto 0);
        voter_o : out  STD_LOGIC
    );
end entity voter;

architecture Behavioral of voter is
    type array_type is array (0 to M-1) of std_logic_vector(log2c(M+1)-1 downto 0);
    signal count_array : array_type;
    attribute dont_touch :string;
 attribute dont_touch  of count_array :signal is "true";
begin

    voting: process(voter_i,count_array)
    begin   
             count_array(0) <= std_logic_vector(to_unsigned(0, log2c(M+1)-1))  & voter_i(0);             
             for i in 1 to M-1 loop 
                if(voter_i(i) = '1') then   
                       count_array(i) <= std_logic_vector(unsigned(count_array(i-1)) + to_unsigned(1, log2c(M+1)));
                else
                       count_array(i) <= count_array(i-1);
                end if;
              end loop;
        
             if(count_array(M-1) > std_logic_vector(to_unsigned(M/2, log2c(M+1)))) then
                    voter_o <= '1';
              else
                    voter_o <= '0';
              end if; 
             
    end process;
    
end architecture Behavioral;
        