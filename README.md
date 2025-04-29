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

> **TODO**: Write this.

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
