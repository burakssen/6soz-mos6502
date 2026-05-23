const enums = @import("enums.zig");

const Instruction = @This();

op: enums.Operation,
mode: enums.AddressingMode,
cycles: u8,
page_cycle: bool = false,
