library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity core is
	port(
		clk         : in  std_logic;
        rst         : in  std_logic;

        address     : out std_logic_vector(7 downto 0);
        data        : in  std_logic_vector(7 downto 0);
        
        lcd_out     : out std_logic_vector(7 downto 0);
        lcd_wr      : out std_logic;

        rightInt    : in  std_logic;
        leftInt     : in  std_logic;
        pushInt     : in  std_logic;
        switch      : in  std_logic_vector(3 downto 0)

	);
end entity core;

architecture RTL of core is

    type state_type is (RESET, EXEC, FETCH_ARGUMENT, HLT);
    signal state : state_type;

    type reg_file is array (integer range <>) of std_logic_vector(7 downto 0);
    signal reg : reg_file(4 downto 0);
    -- A, B, C, D, SWR

    alias reg1 : std_logic_vector(2 downto 0) is data(5 downto 3);
    alias reg2 : std_logic_vector(2 downto 0) is data(2 downto 0);

    signal PC_reg: std_logic_vector(7 downto 0);
    signal IR_reg: std_logic_vector(7 downto 0);
    alias reg1_ir : std_logic_vector(2 downto 0) is IR_reg(2 downto 0);

    signal carry : std_logic;
    signal zero  : std_logic;

    signal hex_value : std_logic_vector(3 downto 0);
    signal hex_write : std_logic;
    signal out_write : std_logic;
    signal hex_ascii : std_logic_vector(7 downto 0);

    signal leftInt_r : std_logic;
    signal rightInt_r : std_logic;
    signal pushInt_r : std_logic;
begin

    reg(4)(3 downto 0) <= switch;
    reg(4)(7 downto 4) <= (others => '0');

    core_proc: process(clk)
        variable result: unsigned(8 downto 0);
        variable shift_result : std_logic_vector(7 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '0' then
                state <= RESET;
                leftInt_r <= '0';
                rightInt_r <= '0';
                pushInt_r <= '0';
            else
                if leftInt = '1' then
                    leftInt_r <= '1';
                end if;
                if rightInt = '1' then
                    rightInt_r <= '1';
                end if;
                if pushInt = '1' then
                    pushInt_r <= '1';
                end if;
                hex_write <= '0';
                out_write <= '0';
                case state is
                    when RESET =>
                        reg(0) <= (others => '0');
                        reg(1) <= (others => '0');
                        reg(2) <= (others => '0');
                        reg(3) <= (others => '0');
                        PC_reg <= (others => '0');
                        IR_reg <= (others => '0');
                        carry <= '0';
                        zero <= '0';
                        hex_value <= (others => '0');
                        
                        state <= EXEC;
                    when EXEC =>
                        IR_reg <= data;
                        PC_reg <= std_logic_vector(unsigned(PC_reg) + 1);
                        if reg1 = "111" then
                            state <= FETCH_ARGUMENT;
                        else
                            if 
                            case data(7 downto 6) is
                                when "00" =>
                                    -- MOV reg1, reg2
                                    reg(to_integer(unsigned(reg1))) <= reg(to_integer(unsigned(reg2)));
                                when "01" =>
                                    -- ADD reg1, reg2
                                    result := resize(unsigned(reg(to_integer(unsigned(reg1)))),9) + resize(unsigned(reg(to_integer(unsigned(reg2)))),9);
                                    reg(to_integer(unsigned(reg1))) <= std_logic_vector(result(7 downto 0));
                                    carry <= result(8);
                                    if result = "000000000" then
                                        zero <= '1';
                                    else
                                        zero <= '0';
                                    end if;
                                when "10" =>
                                    -- SUB reg1, reg2
                                    result := resize(unsigned(reg(to_integer(unsigned(reg1)))),9) - resize(unsigned(reg(to_integer(unsigned(reg2)))),9);
                                    reg(to_integer(unsigned(reg1))) <= std_logic_vector(result(7 downto 0));
                                    carry <= result(8);
                                    if result = "000000000" then
                                        zero <= '1';
                                    else
                                        zero <= '0';
                                    end if;
                                when others =>
                                    if data(5 downto 4) = "00" then
                                        if data(3) = '0' then
                                            -- SHL
                                            carry <= reg(to_integer(unsigned(reg1)))(7);
                                            shift_result := reg(to_integer(unsigned(reg1)))(6 downto 0) & "0";
                                            reg(to_integer(unsigned(reg1))) <= shift_result;
                                            if shift_result = "00000000" then
                                                zero <= '1';
                                            else
                                                zero <= '0';
                                            end if;
                                        else
                                            -- SHR
                                            carry <= reg(to_integer(unsigned(reg1)))(0);
                                            shift_result := "0" & reg(to_integer(unsigned(reg1)))(7 downto 1);
                                            reg(to_integer(unsigned(reg1))) <= shift_result;
                                            if shift_result = "00000000" then
                                                zero <= '1';
                                            else
                                                zero <= '0';
                                            end if;
                                        end if;
                                    elsif data(5 downto 4) = "01" then
                                        if data(3) = '0' then
                                            -- OUTL
                                            hex_write <= '1';
                                            hex_value <= reg(to_integer(unsigned(reg1)))(3 downto 0);
                                        else
                                            -- OUTH
                                            hex_write <= '1';
                                            hex_value <= reg(to_integer(unsigned(reg1)))(7 downto 4);
                                        end if;
                                    else
                                        -- HLT
                                        state <= HLT;
                                    end if;
                            end case;
                        end if;
                    when FETCH_ARGUMENT =>
                        PC_reg <= std_logic_vector(unsigned(PC_reg) + 1);
                        case IR_reg(7 downto 6) is
                            when "00" =>
                                -- MOV reg1, Const
                                reg(to_integer(unsigned(reg1_ir))) <= data;
                            when "01" =>
                                -- ADD reg1, const
                                result := resize(unsigned(reg(to_integer(unsigned(reg1_ir)))),9) + resize(unsigned(data),9);
                                reg(to_integer(unsigned(reg1_ir))) <= std_logic_vector(result(7 downto 0));
                                carry <= result(8);
                                if result = "000000000" then
                                    zero <= '1';
                                else
                                    zero <= '0';
                                end if;
                            when "10" =>
                                -- SUB reg1, const
                                result := resize(unsigned(reg(to_integer(unsigned(reg1_ir)))),9) - resize(unsigned(data),9);
                                reg(to_integer(unsigned(reg1_ir))) <= std_logic_vector(result(7 downto 0));
                                carry <= result(8);
                                if result = "000000000" then
                                    zero <= '1';
                                else
                                    zero <= '0';
                                end if;
                            when others =>
                                if IR_reg(5 downto 4) = "10" then
                                    if IR_reg(0) = '1' then
                                        -- JZ
                                        if zero = '1' then
                                            PC_reg <= data;
                                        end if;
                                    elsif IR_reg(1) = '1' then
                                        -- JNZ
                                        if zero = '0' then
                                            PC_reg <= data;
                                        end if;
                                    elsif IR_reg(2) = '1' then
                                        -- JC
                                        if carry = '1' then
                                            PC_reg <= data;
                                        end if;
                                    elsif IR_reg(3) = '1' then
                                        -- JNC
                                        if carry = '0' then
                                            PC_reg <= data;
                                        end if;
                                    else
                                        -- JMP
                                        PC_reg <= data;
                                    end if;
                                else
                                    -- OUT
                                    out_write <= '1';
                                end if;
                        end case;
                        state <= EXEC;
                    when HLT =>
                        if leftInt_r = '1' then
                            PC_reg <= x"08";
                            leftInt_r <= '0';
                        elsif rightInt_r = '1' then
                            PC_reg <= x"10";
                            rightInt_r <= '0';
                        elsif pushInt_r = '1' then
                            PC_reg <= x"18";
                            pushInt_r <= '0';
                        end if;
                end case;
            end if;
        end if;
    end process;


    hex_ascii <= x"30" when hex_value = x"0" else
                 x"31" when hex_value = x"1" else
                 x"32" when hex_value = x"2" else
                 x"33" when hex_value = x"3" else
                 x"34" when hex_value = x"4" else
                 x"35" when hex_value = x"5" else
                 x"36" when hex_value = x"6" else
                 x"37" when hex_value = x"7" else
                 x"38" when hex_value = x"8" else
                 x"39" when hex_value = x"9" else
                 x"41" when hex_value = x"A" else
                 x"42" when hex_value = x"B" else
                 x"43" when hex_value = x"C" else
                 x"44" when hex_value = x"D" else
                 x"45" when hex_value = x"E" else
                 x"46";
    
    lcd_wr <= hex_write or out_write;
    lcd_out <= hex_ascii when hex_write = '1' else
               data;

    address <= PC_reg;
    
end architecture RTL;
