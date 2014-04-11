library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity top is
    port(
        clk             : in  std_logic;
        btn_north_i     : in  std_logic;

        -- LCD Interface
        lcd_db_io       : inout std_logic_vector(7 downto 0);
        lcd_rs_o        : out std_logic;
        lcd_en_o        : out std_logic;
        lcd_rw_o        : out std_logic;

        -- Rotary Knob (ROT)
        rot_center_i    : in  std_logic;
        rot_a_i         : in  std_logic;
        rot_b_i         : in  std_logic;

        -- Mechanical Switches
        switch_i        : in  std_logic_vector(3 downto 0)
);
end entity top;

architecture RTL of top is

    signal rst       : std_logic;
    signal rst_n_i   : std_logic;

    signal address   : std_logic_vector(7 downto 0);
    signal data      : std_logic_vector(7 downto 0);

    signal lcd_db    : std_logic_vector (7 downto 0);
    signal lcd_rs    : std_logic;
    signal lcd_en    : std_logic;
    signal lcd_rw    : std_logic;

    signal lcd_wr    : std_logic;
    signal lcd_out   : std_logic_vector(7 downto 0);

    signal rightInt  : std_logic;
    signal leftInt   : std_logic;
    signal pushInt   : std_logic;
begin

    deb_rst: entity work.debounce
    port map(
        clk => clk,
        input => btn_north_i,
        output => rst,
        riseedge => open,
        falledge => open 
    );

    rst_n_i <= not rst;

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

    inst_rotKey : entity work.rotKey
    port map(
        clk           => clk,
        rotA          => rot_a_i,
        rotB          => rot_b_i,
        rotPush       => rot_center_i,
        rotRightEvent => rightInt,
        rotLeftEvent  => leftInt,
        rotPushEvent  => pushInt);

    i_lcd_core : entity work.lcd_core
    port map
    (
        clk_i      => clk,
        reset_n_i  => rst_n_i,

        lcd_cs_i   => lcd_wr,
        lcd_data_i => lcd_out,

        lcd_data_o => lcd_db,
        lcd_rs_o   => lcd_rs,
        lcd_en_o   => lcd_en,
        lcd_rw_o   => lcd_rw
    );

    lcd_db_io <= lcd_db when (lcd_rw = '0') else (others => 'Z');
    lcd_rs_o  <= lcd_rs;
    lcd_en_o  <= lcd_en;
    lcd_rw_o  <= lcd_rw;

end architecture RTL;
