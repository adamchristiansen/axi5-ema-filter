-- SPDX-License-Identifier: MIT
-- Copyright (c) 2025 Adam Christiansen

library ieee;
use ieee.fixed_float_types.all;
use ieee.fixed_pkg.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--- TODO: Docs
--- TODO: Describe output behavior when `m_axis_y_tready` is deasserted.
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
    s_axis_x_tready: out std_logic;
    s_axis_x_tvalid: in std_logic;
    -- Output signal.
    m_axis_y_tdata: out std_logic_vector(DATA_WIDTH - 1 downto 0);
    m_axis_y_tready: in std_logic;
    m_axis_y_tvalid: out std_logic;
    -- EMA coefficient.
    alpha: in std_logic_vector(ALPHA_WIDTH - 1 downto 0)
);
end ema_filter;

architecture behavioral of ema_filter
is
    --- State of the EMA finite state machine (FSM).
    ---
    --- The `prep` stages are used to load in one value to use the the first `y` value in the
    --- computation, after which, the `ema` stages cycle through on loop to produce an output every
    --- 4 clock cycles. The reason that there are 4 `prep` stages is to ensure that
    --- `s_axis_x_tready` is asserted every 4 clock cycles.
    type EmaState is (prep0, prep1, prep2, prep3, ema0, ema1, ema2, ema3);

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
    variable state: EmaState;
    variable a:  sfixed(ALPHA_WIDTH - ALPHA_RADIX - 1 downto -ALPHA_RADIX);
    variable x:  sfixed(DATA_WIDTH - DATA_RADIX - 1 downto -DATA_RADIX);
    variable d:  sfixed(DATA_WIDTH - DATA_RADIX - 1 downto -DATA_RADIX);
    variable ad: sfixed(DATA_WIDTH - DATA_RADIX - 1 downto -DATA_RADIX);
    variable y:  sfixed(DATA_WIDTH - DATA_RADIX - 1 downto -DATA_RADIX);
begin
    if rising_edge(aclk) then
        if aresetn = '0' then
            state           := prep0;
            a               := (others => '0');
            x               := (others => '0');
            d               := (others => '0');
            ad              := (others => '0');
            y               := (others => '0');
            s_axis_x_tready <= '0';
            m_axis_y_tdata  <= (others => '0');
            m_axis_y_tvalid <= '0';
        else
            case state is
            when prep0 =>
                state := prep1;
                s_axis_x_tready <= '1';
            when prep1 =>
                if s_axis_x_tvalid = '1' then
                    state           := prep2;
                    y               := to_sfixed(s_axis_x_tdata, y);
                    s_axis_x_tready <= '0';
                end if;
            when prep2 =>
                state := prep3;
            when prep3 =>
                state := ema0;
            when ema0 =>
                state := ema1;
                s_axis_x_tready <= '1';
                m_axis_y_tdata  <= (others => '0');
                m_axis_y_tvalid <= '0';
            when ema1 =>
                if s_axis_x_tvalid = '1' then
                    state           := ema2;
                    a               := to_sfixed(alpha, a);
                    x               := to_sfixed(s_axis_x_tdata, x);
                    d               := resize_consistent(x - y, d);
                    s_axis_x_tready <= '0';
                end if;
            when ema2 =>
                state := ema3;
                ad    := resize_consistent(a * d, ad);
            when ema3 =>
                state := ema0;
                y     := resize_consistent(y + ad, y);
                if m_axis_y_tready = '1' then
                    m_axis_y_tdata  <= to_slv(y);
                    m_axis_y_tvalid <= '1';
                end if;
            end case;
        end if;
    end if;
end process;

end behavioral;
