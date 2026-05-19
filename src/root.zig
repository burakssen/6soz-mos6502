const std = @import("std");

pub const Bus = @import("bus");
pub const Cpu = @import("cpu");

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
    bus.load(0x8000, &.{
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

    bus.load(0x80fc, &.{ 0xd0, 0x02 });

    var cpu = Cpu{ .pc = 0x80fc };
    const cycles_used = try cpu.step(&bus);

    try std.testing.expectEqual(@as(u16, 0x8100), cpu.pc);
    try std.testing.expectEqual(@as(u8, 4), cycles_used);
}

test "untaken branch crossing a page costs two cycles" {
    var test_bus = TestBus{};
    var bus = Bus.init(&test_bus);

    bus.load(0x80fc, &.{ 0xf0, 0x02 });

    var cpu = Cpu{ .pc = 0x80fc };
    const cycles_used = try cpu.step(&bus);

    try std.testing.expectEqual(@as(u16, 0x80fe), cpu.pc);
    try std.testing.expectEqual(@as(u8, 2), cycles_used);
}

test "decimal-disabled CPU performs binary ADC with decimal flag set" {
    var test_bus = TestBus{};
    var bus = Bus.init(&test_bus);
    bus.load(0x8000, &.{
        0xf8, // SED
        0xa9, 0x09, // LDA #$09
        0x18, // CLC
        0x69, 0x01, // ADC #$01
    });

    var cpu = Cpu{ .pc = 0x8000, .decimal_disabled = true };
    _ = try cpu.step(&bus);
    _ = try cpu.step(&bus);
    _ = try cpu.step(&bus);
    _ = try cpu.step(&bus);

    try std.testing.expectEqual(@as(u8, 0x0a), cpu.a);
}
