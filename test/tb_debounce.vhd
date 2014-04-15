library IEEE;
        use IEEE.STD_LOGIC_1164.ALL;
        USE ieee.math_real.ALL;
        use IEEE.NUMERIC_STD.ALL;
library std;
        use std.textio.all;
library work;
use work.all;

entity tb_debounce is
end tb_debounce;

architecture behav of tb_debounce is
    signal clk : std_logic := '0';
    signal io_i  : std_logic := '0';
    signal io_o : std_logic := '0';
    signal noise : std_logic := '0';
    signal fixed : std_logic := '0';
    signal toggling : std_logic := '0';
    signal riseedge : std_logic := '0';
    signal falledge: std_logic := '0';

begin
    
    process
    begin
        clk <= '1', '0' after 10 ns;
        wait for 20 ns;
    end process;

    process
        VARIABLE seed1: positive := 1;
        VARIABLE seed2: positive := 1;
        VARIABLE rand: real;
        VARIABLE t_rand: time;
    begin
        noise <= not noise;
        UNIFORM(seed1, seed2, rand); 
        t_rand := (rand*100.0)*1 ns;
        wait for t_rand;
    end process;

    process
    begin
        wait for 1400 ns;
        toggling <= '1';
        wait for 600 ns;
        toggling <= '0';
        fixed <= '1';
        wait for 2000 ns;
        toggling <= '1';
        fixed <= '0';
        wait for 1000 ns;
        toggling <= '0';
        wait for 3000 ns;
        assert false report "done" severity failure;
        wait;
    end process;

    io_i <= noise when toggling = '1' else
            fixed;

    debounce : entity work.debounce
    generic map(
	    CNT	=> 15 -- 1500000 = 30 ms at 50 MHz; hier 300ns
    )
    port map(
        clk => clk,
        input => io_i,
        output => io_o,
        riseedge => riseedge,
        falledge => falledge 
    );

    
end behav;
