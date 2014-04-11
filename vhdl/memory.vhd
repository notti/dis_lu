library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity memory is
    port(
        address     : in std_logic_vector(7 downto 0);
        data        : out  std_logic_vector(7 downto 0)

);
end entity memory;

architecture RTL of memory is

    type mem_arr is array (integer range <>) of std_logic_vector(7 downto 0);
    signal mem : mem_arr(255 downto 0);
begin

    data <= mem(to_integer(unsigned(address)));

end architecture RTL;
