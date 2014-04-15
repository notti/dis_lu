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

architecture beh of core is

    type state_type is (RESET, EXEC, FETCH_ARGUMENT, HLT);
    signal state : state_type;

    type alu_type is (MOV, ADD, SUB, SHL, SHR, NO_ALU);

    type reg_file is array (integer range <>) of std_logic_vector(7 downto 0);
    signal reg : reg_file(3 downto 0);
    signal reg_fixed : reg_file(3 downto 0);
    -- A, B, C, D, SWR

    signal PC_reg: std_logic_vector(7 downto 0);
    signal IR_reg: std_logic_vector(7 downto 0);

    signal carry : std_logic;
    signal zero  : std_logic;

    signal hex_value : std_logic_vector(3 downto 0);
    signal hex_write : std_logic;
    signal out_write : std_logic;
    signal hex_ascii : std_logic_vector(7 downto 0);
    signal lcd_char  : std_logic_vector(7 downto 0);

    signal leftInt_r : std_logic;
    signal rightInt_r : std_logic;
    signal pushInt_r : std_logic;
begin

    reg_fixed(0) <= x"00";
    reg_fixed(1) <= x"01";
    reg_fixed(2)(3 downto 0) <= switch;
    reg_fixed(2)(7 downto 4) <= (others => '0');
    reg_fixed(3) <= (others => '0');

    core_proc: process(clk)
        variable result: unsigned(8 downto 0);
        variable alu_op : alu_type;
        variable arg1 : unsigned(8 downto 0);
        variable arg2 : unsigned(8 downto 0);

        variable target : std_logic_vector(2 downto 0);
        
    begin
        alu_op := NO_ALU;
        arg1 := (others => '0');
        arg2 := (others => '0');
        target := (others => '0');
        result := (others => '0');
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
                        lcd_char <= (others => '0');
                        
                        state <= EXEC;
                    when EXEC =>
                        IR_reg <= data;
                        PC_reg <= std_logic_vector(unsigned(PC_reg) + 1);
                        if data(5 downto 3) = "111" or data(7 downto 4) = "1110" or data(7 downto 3) = "11111" then
                            state <= FETCH_ARGUMENT;
                        else
                            if data(7 downto 6) = "00" then
                                alu_op := MOV;
                            elsif data(7 downto 6) = "01" then
                                alu_op := ADD;
                            elsif data(7 downto 6) = "10" then
                                alu_op := SUB;
                            elsif data(7 downto 3) = "11000" then
                                alu_op := SHL;
                            elsif data(7 downto 3) = "11001" then
                                alu_op := SHR;
                            elsif data(7 downto 3) = "11010" then
                                -- OUTL
                                hex_write <= '1';
                                if data(2) = '0' then
                                    hex_value <= reg(to_integer(unsigned(data(1 downto 0))))(3 downto 0);
                                else
                                    hex_value <= reg_fixed(to_integer(unsigned(data(1 downto 0))))(3 downto 0);
                                end if;
                            elsif data(7 downto 3) = "11011" then
                                -- OUTH
                                hex_write <= '1';
                                if data(2) = '0' then
                                    hex_value <= reg(to_integer(unsigned(data(1 downto 0))))(7 downto 4);
                                else
                                    hex_value <= reg_fixed(to_integer(unsigned(data(1 downto 0))))(7 downto 4);
                                end if;
                            else
                                -- HLT
                                state <= HLT;
                            end if;
                        end if;
                        if data(2) = '0' then
                            arg1 := "0" & unsigned(reg(to_integer(unsigned(data(1 downto 0)))));
                        else
                            arg1 := "0" & unsigned(reg_fixed(to_integer(unsigned(data(1 downto 0)))));
                        end if;
                        if data(5) = '0' then
                            arg2 := "0" & unsigned(reg(to_integer(unsigned(data(4 downto 3)))));
                        else
                            arg2 := "0" & unsigned(reg_fixed(to_integer(unsigned(data(4 downto 3)))));
                        end if;
                        target := data(2 downto 0);
                    when FETCH_ARGUMENT =>
                        PC_reg <= std_logic_vector(unsigned(PC_reg) + 1);
                        if IR_reg(7 downto 6) = "00" then
                            alu_op := MOV;
                        elsif IR_reg(7 downto 6) = "01" then
                            alu_op := ADD;
                        elsif IR_reg(7 downto 6) = "10" then
                            alu_op := SUB;
                        elsif IR_reg(7 downto 0) = "11100001" then
                            -- JZ
                            if zero = '1' then
                                PC_reg <= data;
                            end if;
                        elsif IR_reg(7 downto 0) = "11100010" then
                            -- JNZ
                            if zero = '0' then
                                PC_reg <= data;
                            end if;
                        elsif IR_reg(7 downto 0) = "11100100" then
                            -- JC
                            if carry = '1' then
                                PC_reg <= data;
                            end if;
                        elsif IR_reg(7 downto 0) = "11101000" then
                            -- JNC
                            if carry = '0' then
                                PC_reg <= data;
                            end if;
                        elsif IR_reg(7 downto 0) = "11100000" then
                            -- JMP
                            PC_reg <= data;
                        else
                            -- OUT
                            out_write <= '1';
                            lcd_char <= data; 
                        end if;
                        state <= EXEC;
                        if IR_reg(2) = '0' then
                            arg1 := "0" & unsigned(reg(to_integer(unsigned(IR_reg(1 downto 0)))));
                        else
                            arg1 := "0" & unsigned(reg_fixed(to_integer(unsigned(IR_reg(1 downto 0)))));
                        end if;
                        arg2 := "0" & unsigned(data);
                        target := IR_reg(2 downto 0);
                    when HLT =>
                        if leftInt_r = '1' then
                            PC_reg <= x"03";
                            leftInt_r <= '0';
                            state <= EXEC;
                        elsif rightInt_r = '1' then
                            PC_reg <= x"0C";
                            rightInt_r <= '0';
                            state <= EXEC;
                        elsif pushInt_r = '1' then
                            PC_reg <= x"15";
                            pushInt_r <= '0';
                            state <= EXEC;
                        end if;
                end case;
                case alu_op is
                    when MOV =>
                        result := arg2;
                    when ADD | SUB=>
                        if alu_op = ADD then
                            result := arg1 + arg2;
                        else
                            result := arg1 - arg2;
                        end if;
                        if result = "000000000" then
                            zero <= '1';
                        else
                            zero <= '0';
                        end if;
                        carry <= result(8);
                    when SHL =>
                        result := arg1(7 downto 0) & "0";
                        if result = "000000000" then
                            zero <= '1';
                        else
                            zero <= '0';
                        end if;
                        carry <= arg1(7);
                    when SHR =>
                        result := "0" & arg1(8 downto 1);
                        if result = "000000000" then
                            zero <= '1';
                        else
                            zero <= '0';
                        end if;
                        carry <= arg1(0);
                    when others =>
                end case;
                if (not (alu_op = NO_ALU)) and target(2) = '0' then
                    reg(to_integer(unsigned(target(1 downto 0)))) <= std_logic_vector(result(7 downto 0));
                end if;
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
               lcd_char;

    address <= PC_reg;
    
end architecture beh;
