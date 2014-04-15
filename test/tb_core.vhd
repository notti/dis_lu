library IEEE;
        use IEEE.STD_LOGIC_1164.ALL;
        use IEEE.NUMERIC_STD.ALL;
library std;
        use std.textio.all;
library work;
use work.all;

entity tb_core is
end tb_core;

architecture behav of tb_core is
    signal clk : std_logic := '0';
    signal rst_n_i   : std_logic:='0';
    signal address   : std_logic_vector(7 downto 0);
    signal data      : std_logic_vector(7 downto 0);
    signal lcd_wr    : std_logic;
    signal lcd_out   : std_logic_vector(7 downto 0);

    signal rightInt  : std_logic := '0';
    signal leftInt   : std_logic := '0';
    signal pushInt   : std_logic := '0';
    
    signal switch_i        : std_logic_vector(3 downto 0) := (others => '0');

begin
    
    process
    begin
        clk <= '1', '0' after 10 ns;
        wait for 20 ns;
    end process;


    process
    begin
        wait for 100 ns;
        rst_n_i <= '1';
        wait for 100 ns;
        pushInt <= '1', '0' after 20 ns;
        wait for 400 ns;
        switch_i(0) <= '1';
        rightInt <= '1', '0' after 20 ns;
        wait for 400 ns;
        rightInt <= '1', '0' after 20 ns;
        wait for 400 ns;
        rightInt <= '1', '0' after 20 ns;
        wait for 400 ns;
        rightInt <= '1', '0' after 20 ns;
        wait for 400 ns;
        rightInt <= '1', '0' after 20 ns;
        wait for 400 ns;
        switch_i(0) <= '0';
        rightInt <= '1', '0' after 20 ns;
        wait for 400 ns;
        rightInt <= '1', '0' after 20 ns;
        wait for 400 ns;
        pushInt <= '1', '0' after 20 ns;
        wait for 1000 ns;
        assert false report "done" severity failure;
        wait;
    end process;

    mem_inst: entity work.memory
    port map(
        address => address,
        data => data
    );
        

    cpu_core: entity work.core
    port map(
        clk         => clk,
        rst         => rst_n_i,

        address     => address,
        data        => data,

        lcd_out     => lcd_out,
        lcd_wr      => lcd_wr,

        rightInt    => rightInt,
        leftInt     => leftInt,
        pushInt     => pushInt,

        switch      => switch_i

    );
    
end behav;
