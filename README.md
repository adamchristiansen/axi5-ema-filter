# AXI5-Stream EMA Filter

An [AXI4/5-Stream][axi5] [exponential moving average (EMA) filter][ema]
implemented in VHDL-2008.

## How to use

Simply drop [`ema_filter.vhd`](./ema_filter.vhd) into your project and
instantiate the EMA filter component.

```vhdl
my_ema_filter: work.ema_filter
generic map (
    DATA_WIDTH => ...,  -- natural (default: 16).
    DATA_RADIX => ...,  -- natural (default: 0).
    ALPHA_WIDTH => ..., -- natural (default: `DATA_WIDTH`).
    ALPHA_RADIX => ...  -- natural (default: `DATA_RADIX`).
);
port (
    -- Interface global signals.
    aclk => ...,
    aresetn => ...,
    -- Input (AXI4/5-Stream).
    s_axis_e_tdata => ...,
    s_axis_e_tvalid => ...,
    -- Filtered output (AXI4/5-Stream).
    m_axis_u_tdata => ...,
    m_axis_u_tvalid => ...,
    -- EMA coefficient.
    alpha => ...
);
```

## Documentation

> [!TIP]
> This information can also be found in [`ema_filter.vhd`](./ema_filter.vhd).

An exponential moving average (EMA) filter.

An EMA filter produces an output, `y`, from an input `x`, using the equation:

```
y[t] = α*x[t] - (1 - α)*y[t-1]
     = y[t-1] + α*(x[t] - y[t-1])
```

where `0 ≤ α ≤ 1` is the smoothing factor. This implementation uses the second form of the
equation above, which has one fewer multiplication.

The EMA filter clocks one data point in every 4 `aclk` cycles and clocks one out every 4 `aclk`
cycles. If `m_axis_y_tready` is not asserted when the output is ready, that point is lost as no
buffering is provided on the output.

### Generics

- `DATA_WIDTH`: Width in bits of the input and output AXI4/5-Streams.
- `DATA_RADIX`: Radix position in bits of the fixed-point input and output AXI4/5-Streams.
- `ALPHA_WIDTH`: Width in bits of the input `alpha` coefficient.
- `ALPHA_RADIX`: Radix position in bits of the input `alpha` coefficient.

### Ports

- `aclk`: Global AXI4/5-Stream clock.
- `aresetn`: Global active-low AXI4/5-Stream reset.
- `s_axis_x_*`: AXI4/5-Stream for the input signal as a signed fixed-point integer.
- `m_axis_y_*`: AXI4/5-Stream for the filtered output signal as a signed fixed-point integer.
- `alpha`: The smoothing factor, `α`, as a fixed-point integer.

## Testing

The [`Makefile`](./Makefile) has the following recipes:

- `make`: Alias for `make build`.
- `make build`: Analyze and elaborate the source and test files.
- `make test`: Run the testbench.
- `make wave`: Display testbench waveforms.
- `make clean`: Remove all build artifacts.

## Requirements

- [GHDL][ghdl] is used for building and testing.
- [GTKWave][gtkwave] is used for viewing waveforms.

## License

This project is distributed under the terms of the MIT License. The license text can be found in
the [`LICENSE`](./LICENSE) file of this repository.

[axi5]: https://developer.arm.com/documentation/ihi0022/latest
[ema]: https://en.wikipedia.org/wiki/Exponential_smoothing
[ghdl]: https://ghdl.github.io/ghdl/
[gtkwave]: https://gtkwave.sourceforge.net/
