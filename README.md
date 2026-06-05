# 6soz-mos6502

A MOS 6502 and Ricoh 2A03 CPU implementation in Zig. This package is used as the CPU core for the `6soz-nes` emulator.

## Features

- Complete implementation of the MOS 6502 instruction set.
- Selectable behavior variants (Generic MOS 6502, Ricoh 2A03 for NES).
- Cycle-accurate accounting reported through step results.
- Type-erased bus interface for easy integration into different system maps.

## Usage

The CPU requires a `Bus` implementation that provides `read` and `write` methods.

```zig
const mos6502 = @import("mos6502");

var cpu = mos6502.Cpu.init(.rp2a03); // Use Ricoh variant for NES
var bus = MyBus.init();

const result = try cpu.step(&bus, &interrupt_flags);
// result.cycles contains the number of cycles consumed by the instruction
```

## Build & Test

```sh
zig build
zig build test
```

