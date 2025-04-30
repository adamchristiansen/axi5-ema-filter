-- SPDX-License-Identifier: MIT
-- Copyright (c) 2025 Adam Christiansen

use std.env.finish;

library ieee;
use ieee.fixed_pkg.all;
use ieee.math_real.all;
use ieee.std_logic_1164.all;

entity ema_filter_tb is
end ema_filter_tb;

architecture behaviour of ema_filter_tb
is
    constant CLK_PERIOD : time := 10 ns;

    --- EMA.
    constant DATA_WIDTH: natural := 24;
    constant DATA_RADIX: natural := 10;
    constant ALPHA_WIDTH: natural := DATA_WIDTH;
    constant ALPHA_RADIX: natural := DATA_RADIX;
    signal aclk: std_logic;
    signal aresetn: std_logic;
    signal s_axis_x_tdata: std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal s_axis_x_tvalid: std_logic;
    signal m_axis_y_tdata: std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal m_axis_y_tvalid: std_logic;
    signal alpha: std_logic_vector(ALPHA_WIDTH - 1 downto 0);

    -- Get `m_axis_y_tdata` as a real number.
    impure function yreal return real is
    begin
        return to_real(to_sfixed(m_axis_y_tdata, DATA_WIDTH - DATA_RADIX - 1, - DATA_RADIX));
    end function;

    --- Assert that `x` falls in the inclusive interval `[low, high]`.
    procedure assert_interval(x: real; low: real; high: real) is
    begin
        assert low <= x and x <= high
            report "Expected value in ["
                & to_string(low)
                & ", "
                & to_string(high)
                & "]: got "
                & to_string(x)
            severity failure;
    end procedure;
begin

-- Clock.
aclk_p: process
begin
    aclk <= '1';
    wait for CLK_PERIOD / 2;
    aclk <= '0';
    wait for CLK_PERIOD / 2;
end process;

-- Drive inputs.
x_p: process
    variable x: real := 0.0;
begin
    -- This alpha has a time constant of 100 ns, which is the time for a step response to reach
    -- `1 - 1/e` (i.e. 63%).
    alpha <= to_slv(to_sfixed(0.095, ALPHA_WIDTH - ALPHA_RADIX - 1, -ALPHA_RADIX));
    -- Unit step input.
    aresetn         <= '0';
    s_axis_x_tvalid <= '0';
    s_axis_x_tdata  <= (others => '0');
    wait for 10 * CLK_PERIOD;
    aresetn         <= '1';
    s_axis_x_tvalid <= '1';
    wait for 10 * CLK_PERIOD;
    s_axis_x_tdata <= to_slv(to_sfixed(10.0, DATA_WIDTH - DATA_RADIX - 1, -DATA_RADIX));
    wait for 10 * CLK_PERIOD; -- 100 ns.
    assert_interval(yreal, 6.27, 6.37);
    wait for 10 * CLK_PERIOD; -- 100 ns.
    assert_interval(yreal, 8.59, 8.69);
    wait for 10 * CLK_PERIOD; -- 100 ns.
    assert_interval(yreal, 9.45, 9.55);
    wait for 150 * CLK_PERIOD;
    assert_interval(yreal, 9.99, 10.0);
    -- Linear input.
    aresetn         <= '0';
    s_axis_x_tvalid <= '0';
    s_axis_x_tdata  <= (others => '0');
    wait for 10 * CLK_PERIOD;
    aresetn         <= '1';
    s_axis_x_tvalid <= '1';
    wait for 10 * CLK_PERIOD;
    while x <= 10.0 loop
        s_axis_x_tdata <= to_slv(to_sfixed(x, DATA_WIDTH - DATA_RADIX - 1, -DATA_RADIX));
        wait for CLK_PERIOD;
        x := x + 1.0;
    end loop;
    assert_interval(yreal, 0.0, 5.0); -- The response is slow.
    wait for 180 * CLK_PERIOD;
    assert_interval(yreal, 9.99, 10.0);
    finish;
end process;

dut: entity work.ema_filter
generic map (
    DATA_WIDTH => DATA_WIDTH,
    DATA_RADIX => DATA_RADIX,
    ALPHA_WIDTH => ALPHA_WIDTH,
    ALPHA_RADIX => ALPHA_RADIX
)
port map (
    aclk => aclk,
    aresetn => aresetn,
    s_axis_x_tdata => s_axis_x_tdata,
    s_axis_x_tvalid => s_axis_x_tvalid,
    m_axis_y_tdata => m_axis_y_tdata,
    m_axis_y_tvalid => m_axis_y_tvalid,
    alpha => alpha
);

end behaviour;
