library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity memory is
port(
    address     : in   std_logic_vector(7 downto 0);
    data        : out  std_logic_vector(7 downto 0)
);
end entity memory;

architecture beh of memory is

    type mem_arr is array (integer range <>) of std_logic_vector(7 downto 0);
    signal mem : mem_arr(0 to (2**address'length)-1) :=
        (
         x"f8",
         x"3f",
         x"f0",
         x"ce",
         x"e4",
         x"09",
         x"a9",
         x"e0",
         x"3a",
         x"a8",
         x"e0",
         x"3a",
         x"ce",
         x"e4",
         x"12",
         x"69",
         x"e0",
         x"3a",
         x"68",
         x"e0",
         x"3a",
         x"f8",
         x"3d",
         x"a1",
         x"e2",
         x"25",
         x"f8",
         x"45",
         x"f8",
         x"72",
         x"f8",
         x"72",
         x"f8",
         x"6f",
         x"f8",
         x"72",
         x"f0",
         x"02",
         x"23",
         x"8a",
         x"e1",
         x"32",
         x"e4",
         x"2f",
         x"6b",
         x"e0",
         x"27",
         x"4a",
         x"e0",
         x"33",
         x"22",
         x"db",
         x"d3",
         x"f8",
         x"2b",
         x"da",
         x"d2",
         x"f0",
         x"f8",
         x"0c",
         x"f8",
         x"0d",
         x"d8",
         x"d0",
         x"f8",
         x"2f",
         x"d9",
         x"d1",
         x"f0",
         others => (others => '0'));
begin

    data <= mem(to_integer(unsigned(address)));

end architecture beh;
