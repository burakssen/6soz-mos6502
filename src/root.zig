const std = @import("std");

pub const Bus = @import("bus");
pub const Cpu = @import("cpu");
pub const Variant = Cpu.Variant;

const Flag = struct {
    const C: u8 = 1 << 0;
    const B: u8 = 1 << 4;
    const U: u8 = 1 << 5;
};

const TestBus = struct {
    mem: [65536]u8 = [_]u8{0} ** 65536,

    pub fn read(self: *const @This(), addr: u16) u8 {
        return self.mem[@as(usize, addr)];
    }

    pub fn write(self: *@This(), addr: u16, value: u8) void {
        self.mem[@as(usize, addr)] = value;
    }

    pub fn load(self: *@This(), start: u16, bytes: []const u8) void {
        for (bytes, 0..) |b, i| {
            self.write(start +% @as(u16, @intCast(i)), b);
        }
    }
};

test "small 6502 program" {
    var test_bus = TestBus{};
    var bus = Bus.init(&test_bus);

    // Program at $8000:
    //
    // LDA #$40
    // CLC
    // ADC #$02
    // STA $10
    // BRK
    test_bus.load(0x8000, &.{
        0xa9, 0x40,
        0x18, 0x69,
        0x02, 0x85,
        0x10, 0x00,
    });

    // Reset vector = $8000
    bus.write(0xfffc, 0x00);
    bus.write(0xfffd, 0x80);

    // IRQ/BRK vector = $9000
    bus.write(0xfffe, 0x00);
    bus.write(0xffff, 0x90);

    var cpu = Cpu{};
    cpu.reset(&bus);

    while (cpu.pc != 0x9000) {
        _ = try cpu.step(&bus);
    }

    try std.testing.expectEqual(@as(u8, 0x42), bus.read(0x0010));
}

test "taken branch crossing a page costs four cycles" {
    var test_bus = TestBus{};
    var bus = Bus.init(&test_bus);

    test_bus.load(0x80fc, &.{ 0xd0, 0x02 });

    var cpu = Cpu{ .pc = 0x80fc };
    const result = try cpu.step(&bus);

    try std.testing.expectEqual(@as(u16, 0x8100), cpu.pc);
    try std.testing.expectEqual(@as(u8, 4), result.cycles);
}

test "untaken branch crossing a page costs two cycles" {
    var test_bus = TestBus{};
    var bus = Bus.init(&test_bus);

    test_bus.load(0x80fc, &.{ 0xf0, 0x02 });

    var cpu = Cpu{ .pc = 0x80fc };
    const result = try cpu.step(&bus);

    try std.testing.expectEqual(@as(u16, 0x80fe), cpu.pc);
    try std.testing.expectEqual(@as(u8, 2), result.cycles);
}

test "Ricoh 2A03 performs binary ADC with decimal flag set" {
    var test_bus = TestBus{};
    var bus = Bus.init(&test_bus);
    test_bus.load(0x8000, &.{
        0xf8, // SED
        0xa9, 0x09, // LDA #$09
        0x18, // CLC
        0x69, 0x01, // ADC #$01
    });

    var cpu = Cpu{ .pc = 0x8000, .variant = .ricoh_2a03 };
    _ = try cpu.step(&bus);
    _ = try cpu.step(&bus);
    _ = try cpu.step(&bus);
    _ = try cpu.step(&bus);

    try std.testing.expectEqual(@as(u8, 0x0a), cpu.a);
}

test "MOS 6502 performs BCD ADC by default" {
    var test_bus = TestBus{};
    var bus = Bus.init(&test_bus);
    test_bus.load(0x8000, &.{
        0xf8, // SED
        0xa9, 0x09, // LDA #$09
        0x18, // CLC
        0x69, 0x01, // ADC #$01
    });

    var cpu = Cpu{ .pc = 0x8000 };
    _ = try cpu.step(&bus);
    _ = try cpu.step(&bus);
    _ = try cpu.step(&bus);
    _ = try cpu.step(&bus);

    try std.testing.expectEqual(@as(u8, 0x10), cpu.a);
}

test "reset uses NES stack pointer state" {
    var test_bus = TestBus{};
    var bus = Bus.init(&test_bus);

    bus.write(0xfffc, 0x34);
    bus.write(0xfffd, 0x12);

    var cpu = Cpu{};
    cpu.reset(&bus);

    try std.testing.expectEqual(@as(u8, 0xfd), cpu.sp);
    try std.testing.expectEqual(@as(u16, 0x1234), cpu.pc);
}

test "jsr pushes return address and rts resumes after call" {
    var test_bus = TestBus{};
    var bus = Bus.init(&test_bus);

    test_bus.load(0x8000, &.{ 0x20, 0x00, 0x90 });
    test_bus.load(0x9000, &.{0x60});

    var cpu = Cpu{ .pc = 0x8000 };
    _ = try cpu.step(&bus);

    try std.testing.expectEqual(@as(u16, 0x9000), cpu.pc);
    try std.testing.expectEqual(@as(u8, 0xfd), cpu.sp);
    try std.testing.expectEqual(@as(u8, 0x80), bus.read(0x01ff));
    try std.testing.expectEqual(@as(u8, 0x02), bus.read(0x01fe));

    _ = try cpu.step(&bus);

    try std.testing.expectEqual(@as(u16, 0x8003), cpu.pc);
    try std.testing.expectEqual(@as(u8, 0xff), cpu.sp);
}

test "php and plp preserve unused bit and clear break bit in status" {
    var test_bus = TestBus{};
    var bus = Bus.init(&test_bus);

    test_bus.load(0x8000, &.{ 0x08, 0x28 });

    var cpu = Cpu{ .pc = 0x8000, .status = Flag.U | Flag.C };
    _ = try cpu.step(&bus);

    try std.testing.expectEqual(@as(u8, 0xfe), cpu.sp);
    try std.testing.expectEqual(@as(u8, Flag.U | Flag.B | Flag.C), bus.read(0x01ff));

    cpu.status = 0;
    _ = try cpu.step(&bus);

    try std.testing.expectEqual(@as(u8, Flag.U | Flag.C), cpu.status);
    try std.testing.expectEqual(@as(u8, 0xff), cpu.sp);
}

test "jmp indirect emulates 6502 page-wrap bug" {
    var test_bus = TestBus{};
    var bus = Bus.init(&test_bus);

    test_bus.load(0x8000, &.{ 0x6c, 0xff, 0x12 });
    bus.write(0x12ff, 0x34);
    bus.write(0x1200, 0x80);
    bus.write(0x1300, 0x90);

    var cpu = Cpu{ .pc = 0x8000 };
    _ = try cpu.step(&bus);

    try std.testing.expectEqual(@as(u16, 0x8034), cpu.pc);
}

test "absolute indexed load crossing a page costs an extra cycle" {
    var test_bus = TestBus{};
    var bus = Bus.init(&test_bus);

    test_bus.load(0x8000, &.{ 0xbd, 0xff, 0x20 });
    bus.write(0x2100, 0x7f);

    var cpu = Cpu{ .pc = 0x8000, .x = 1 };
    const result = try cpu.step(&bus);

    try std.testing.expectEqual(@as(u8, 0x7f), cpu.a);
    try std.testing.expectEqual(@as(u8, 5), result.cycles);
}

test "invalid opcode does not mutate pc or cycles" {
    var test_bus = TestBus{};
    var bus = Bus.init(&test_bus);

    bus.write(0x8000, 0x02);

    var cpu = Cpu{ .pc = 0x8000, .cycles = 10 };
    try std.testing.expectError(Cpu.Error.InvalidOpcode, cpu.step(&bus));

    try std.testing.expectEqual(@as(u16, 0x8000), cpu.pc);
    try std.testing.expectEqual(@as(u64, 10), cpu.cycles);
}
