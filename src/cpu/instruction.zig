const enums = @import("enums.zig");

const Instruction = @This();

op: enums.Operation,
mode: enums.AddressinMode,
cycles: u8,
page_cycle: bool = false,
