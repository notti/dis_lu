library IEEE;
        use IEEE.STD_LOGIC_1164.ALL;
        USE ieee.math_real.ALL;
        use IEEE.NUMERIC_STD.ALL;
library std;
        use std.textio.all;
library work;
use work.all;

entity tb_rotkey is
end tb_rotkey;

architecture behav of tb_rotkey is
    signal clk : std_logic := '0';
	signal rotA          : std_logic := '0';
	signal rotB          : std_logic := '0';
	signal rotPush       : std_logic := '0';

	signal rotRightEvent : std_logic := '0';
	signal rotLeftEvent  : std_logic := '0';
	signal rotPushEvent  : std_logic := '0';

begin
    
    process
    begin
        clk <= '1', '0' after 10 ns;
        wait for 20 ns;
    end process;


    process
    begin
        wait for 1400 ns;
        rotPush <= '1';
        wait for 1400 ns;
        rotPush <= '0';
        wait for 1400 ns;
        rotA <= '1';
        wait for 1400 ns;
        rotB <= '1';
        wait for 1400 ns;
        rotA <= '0';
        wait for 1400 ns;
        rotB <= '0';
        wait for 2000 ns;
        rotB <= '1';
        wait for 1400 ns;
        rotA <= '1';
        wait for 1400 ns;
        rotB <= '0';
        wait for 1400 ns;
        rotA <= '0';
        wait for 3000 ns;
        assert false report "done" severity failure;
        wait;
    end process;

    rotkey: entity work.rotkey
    generic map(
	    CNT	=> 15 -- 1500000 = 30 ms at 50 MHz; hier 300ns
    )
    port map(
		clk        => clk,

		rotA          => rotA,
		rotB          => rotB,
		rotPush       => rotPush,

		rotRightEvent => rotRightEvent,
		rotLeftEvent  => rotLeftEvent,
		rotPushEvent  => rotPushEvent
    );

    
end behav;
