library ieee;
use ieee.std_logic_1164.all;

entity rotKey is
    generic(
	    CNT			: integer := 5000	-- 30 ms at 50 MHz
    );
	port(
		clk        : in  std_logic;

		rotA          : in  std_logic;
		rotB          : in  std_logic;
		rotPush       : in  std_logic;

		rotRightEvent : out std_logic;
		rotLeftEvent  : out std_logic;
		rotPushEvent  : out std_logic
	);
end entity rotKey;

architecture RTL of rotKey is

	-- Declaration of the  debounce component
	component debounce
		port(clk   : in  std_logic;
			 input    : in  std_logic;
			 output   : out std_logic;
			 riseedge : out std_logic;
			 falledge : out std_logic);
	end component debounce;

    signal rotA_d : std_logic;
    signal rotB_d : std_logic;
    signal rotA_rise : std_logic;
    signal rotA_fall : std_logic;
    signal rotB_rise : std_logic;
    signal rotB_fall : std_logic;
begin
    deb_rotA: entity work.debounce
    generic map(
        CNT => CNT)
    port map(
        clk => clk,
        input => rotA,
        output => rotA_d,
        riseedge => rotA_rise,
        falledge => rotA_fall 
    );

    deb_rotB: entity work.debounce
    generic map(
        CNT => CNT)
    port map(
        clk => clk,
        input => rotB,
        output => rotB_d,
        riseedge => rotB_rise,
        falledge => rotB_fall 
    );

    deb_rotPush: entity work.debounce
    generic map(
        CNT => CNT)
    port map(
        clk => clk,
        input => rotPush,
        output => open,
        riseedge => rotPushEvent,
        falledge => open 
    );

    rotRightEvent <= '1' when rotA_rise = '1' and rotB_d = '0' else
                     '0';

    rotLeftEvent <= '1' when rotB_rise = '1' and rotA_d = '0' else
                    '0';

end architecture RTL;
