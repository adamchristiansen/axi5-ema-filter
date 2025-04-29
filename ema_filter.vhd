-- SPDX-License-Identifier: MIT
-- Copyright (c) 2025 Adam Christiansen

library ieee;
use ieee.fixed_float_types.all;
use ieee.fixed_pkg.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--- TODO: Docs
entity ema_filter is
generic (
    DATA_WIDTH: natural := 16;
    DATA_RADIX: natural := 0;
    ALPHA_WIDTH: natural := DATA_WIDTH;
    ALPHA_RADIX: natural := DATA_WIDTH - 2
);
port (
    aclk: in std_logic;
    aresetn: in std_logic;
    -- Input signal.
    s_axis_x_tdata: in std_logic_vector(DATA_WIDTH - 1 downto 0);
    s_axis_x_tvalid: in std_logic;
    -- Output signal.
    m_axis_y_tdata: out std_logic_vector(DATA_WIDTH - 1 downto 0);
    m_axis_y_tvalid: out std_logic;
    -- EMA coefficient.
    alpha: in std_logic_vector(ALPHA_WIDTH - 1 downto 0)
);
end ema_filter;

architecture behavioral of ema_filter
is
    --- A helper function that resizes `arg` to match `size_res` with consistent rounding and
    --- overflow semantics.
    ---
    --- All arithmetic operations in the EMA filter should saturate. This function simply wraps
    --- `ieee.fixed_pkg.resize` for `sfixed` to ensure consistent behavior for all resizes.
    ---
    --- # Arguments
    ---
    --- - `arg`: The `sfixed` to resize.
    --- - `size_res`: The new size is equal to the size of this value.
    function resize_consistent(
        arg: sfixed;
        constant size_res: sfixed
    ) return sfixed is
    begin
        return resize(
            arg,
            left_index => size_res'high,
            right_index => size_res'low,
            overflow_style => fixed_saturate,
            round_style => fixed_truncate);
    end function;
begin

-- Assert that generics are valid.
assert DATA_WIDTH mod 8 = 0
    report "DATA_WIDTH must be a multiple of 8"
    severity failure;
assert DATA_RADIX <= DATA_WIDTH
    report "DATA_RADIX must be less than or equal to DATA_WIDTH"
    severity failure;
assert ALPHA_WIDTH > 0
    report "ALPHA_WIDTH must be greater than 0"
    severity failure;
assert ALPHA_RADIX <= ALPHA_WIDTH
    report "ALPHA_RADIX must be less than or equal to ALPHA_WIDTH"
    severity failure;

ema_p: process (aclk)
    variable a:  sfixed(ALPHA_WIDTH - ALPHA_RADIX - 1 downto -ALPHA_RADIX) := (others => '0');
    variable b:  sfixed(a'high downto a'low) := (others => '0'); -- `1 - a`.
    variable x:  sfixed(DATA_WIDTH - DATA_RADIX - 1 downto -DATA_RADIX) := (others => '0');
    variable ax: sfixed(DATA_WIDTH - DATA_RADIX - 1 downto -DATA_RADIX) := (others => '0');
    variable by: sfixed(DATA_WIDTH - DATA_RADIX - 1 downto -DATA_RADIX) := (others => '0');
    variable y:  sfixed(DATA_WIDTH - DATA_RADIX - 1 downto -DATA_RADIX) := (others => '0');
begin
    if rising_edge(aclk) then
        if aresetn = '0' then
            m_axis_y_tvalid <= '0';
            m_axis_y_tdata  <= (others => '0');
            a  := (others => '0');
            b  := (others => '0');
            x  := (others => '0');
            ax := (others => '0');
            by := (others => '0');
            y  := (others => '0');
        else
            if s_axis_x_tvalid = '1' then
                a  := to_sfixed(alpha, a);
                b  := resize_consistent(to_sfixed(1.0, a) - a, b);
                x  := to_sfixed(s_axis_x_tdata, x);
                ax := resize_consistent(a * x, ax);
                by := resize_consistent(b * y, by);
                y  := resize_consistent(ax + by, y);
                m_axis_y_tvalid <= '1';
                m_axis_y_tdata  <= to_slv(y);
            else
                m_axis_y_tvalid <= '0';
                m_axis_y_tdata  <= (others => '0');
            end if;
        end if;
    end if;
end process;

end behavioral;
