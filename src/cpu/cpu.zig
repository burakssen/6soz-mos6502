const std = @import("std");

const Bus = @import("bus");

const Flag = @import("flag.zig");
const Instruction = @import("instruction.zig");
const Addressing = @import("addressing.zig");

const enums = @import("enums.zig");
const AddressingMode = enums.AddressinMode;
const Operation = enums.Operation;

const table = @import("table.zig");
const InstructionTable = table.InstructionTable;

pub const CpuError = error{
    InvalidOpCode,
};

const Cpu = @This();

a: u8 = 0,
x: u8 = 0,
y: u8 = 0,

sp: u8 = 0xff,
pc: u16 = 0,

status: u8 = Flag.U | Flag.I,

cycles: u64 = 0,
stopped: bool = false,

decimal_disabled: bool = false,

pub fn reset(self: *Cpu, bus: *Bus) void {
    self.a = 0;
    self.x = 0;
    self.y = 0;
    self.sp = 0xfd;
    self.status = Flag.U | Flag.I;
    self.pc = self.read16(bus, 0xfffc);
    self.cycles = 0;
    self.stopped = false;
}

pub fn step(self: *Cpu, bus: *Bus) CpuError!u8 {
    if (self.stopped) return 0;

    const opcode = self.fetch(bus);
    const instruction = InstructionTable[opcode] orelse return CpuError.InvalidOpCode;

    const addressing = self.getOperandAddressing(bus, instruction.mode);

    const extra_cycles = try self.execute(bus, instruction.op, addressing.addr, instruction.mode, addressing.page_crossed);

    const total_cycles = instruction.cycles + extra_cycles + (if (instruction.page_cycle and addressing.page_crossed) @as(u8, 1) else 0);

    self.cycles += total_cycles;
    return total_cycles;
}

fn execute(self: *Cpu, bus: *Bus, op: Operation, address: u16, mode: AddressingMode, page_crossed: bool) CpuError!u8 {
    switch (op) {
        .adc => self.adc(bus.read(address)),
        .@"and" => self.@"and"(bus.read(address)),
        .asl => try self.asl(bus, address, mode),
        .bcc => return self.branch(page_crossed, !self.getFlag(Flag.C), address),
        .bcs => return self.branch(page_crossed, self.getFlag(Flag.C), address),
        .beq => return self.branch(page_crossed, self.getFlag(Flag.Z), address),
        .bit => self.bit(bus.read(address)),
        .bmi => return self.branch(page_crossed, self.getFlag(Flag.N), address),
        .bne => return self.branch(page_crossed, !self.getFlag(Flag.Z), address),
        .bpl => return self.branch(page_crossed, !self.getFlag(Flag.N), address),
        .brk => self.brk(bus),
        .bvc => return self.branch(page_crossed, !self.getFlag(Flag.V), address),
        .bvs => return self.branch(page_crossed, self.getFlag(Flag.V), address),
        .clc => self.setFlag(Flag.C, false),
        .cld => self.setFlag(Flag.D, false),
        .cli => self.setFlag(Flag.I, false),
        .clv => self.setFlag(Flag.V, false),
        .cmp => self.cmp(self.a, bus.read(address)),
        .cpx => self.cmp(self.x, bus.read(address)),
        .cpy => self.cmp(self.y, bus.read(address)),
        .dec => try self.dec(bus, address),
        .dex => {
            self.x -%= 1;
            self.setZN(self.x);
        },
        .dey => {
            self.y -%= 1;
            self.setZN(self.y);
        },
        .eor => self.eor(bus.read(address)),
        .inc => try self.inc(bus, address),
        .inx => {
            self.x +%= 1;
            self.setZN(self.x);
        },
        .iny => {
            self.y +%= 1;
            self.setZN(self.y);
        },
        .jmp => self.pc = address,
        .jsr => {
            const ret = self.pc -% 1;
            self.push(bus, @as(u8, @truncate(ret >> 8)));
            self.push(bus, @as(u8, @truncate(ret)));
            self.pc = address;
        },
        .lda => self.lda(bus.read(address)),
        .ldx => self.ldx(bus.read(address)),
        .ldy => self.ldy(bus.read(address)),
        .lsr => try self.lsr(bus, address, mode),
        .nop => {},
        .ora => self.ora(bus.read(address)),
        .pha => self.push(bus, self.a),
        .php => self.push(bus, self.status | Flag.B),
        .pla => {
            self.a = self.pull(bus);
            self.setZN(self.a);
        },
        .plp => self.status = (self.pull(bus) & ~Flag.B) | Flag.U,
        .rol => try self.rol(bus, address, mode),
        .ror => try self.ror(bus, address, mode),
        .rti => {
            self.status = (self.pull(bus) & ~Flag.B) | Flag.U;
            const lo = self.pull(bus);
            const hi = self.pull(bus);
            self.pc = (@as(u16, hi) << 8) | @as(u16, lo);
        },
        .rts => {
            const lo = self.pull(bus);
            const hi = self.pull(bus);
            self.pc = ((@as(u16, hi) << 8) | @as(u16, lo)) +% 1;
        },
        .sbc => self.sbc(bus.read(address)),
        .sec => self.setFlag(Flag.C, true),
        .sed => self.setFlag(Flag.D, true),
        .sei => self.setFlag(Flag.I, true),
        .sta => bus.write(address, self.a),
        .stx => bus.write(address, self.x),
        .sty => bus.write(address, self.y),
        .tax => {
            self.x = self.a;
            self.setZN(self.x);
        },
        .tay => {
            self.y = self.a;
            self.setZN(self.y);
        },
        .tsx => {
            self.x = self.sp;
            self.setZN(self.x);
        },
        .txa => {
            self.a = self.x;
            self.setZN(self.a);
        },
        .txs => self.sp = self.x,
        .tya => {
            self.a = self.y;
            self.setZN(self.a);
        },
    }
    return 0;
}

fn fetch(self: *Cpu, bus: *Bus) u8 {
    const value = bus.read(self.pc);
    self.pc +%= 1;
    return value;
}

fn fetch16(self: *Cpu, bus: *Bus) u16 {
    const lo = self.fetch(bus);
    const hi = self.fetch(bus);
    return @as(u16, lo) | (@as(u16, hi) << 8);
}

fn read16(_: *Cpu, bus: *Bus, address: u16) u16 {
    const lo = bus.read(address);
    const hi = bus.read(address +% 1);
    return @as(u16, lo) | (@as(u16, hi) << 8);
}

fn getOperandAddressing(self: *Cpu, bus: *Bus, mode: AddressingMode) Addressing {
    return switch (mode) {
        .imp, .acc => .{ .addr = 0, .page_crossed = false },
        .imm => blk: {
            const addr = self.pc;
            self.pc +%= 1;
            break :blk .{ .addr = addr, .page_crossed = false };
        },
        .zp => .{ .addr = @as(u16, self.fetch(bus)), .page_crossed = false },
        .zpx => .{ .addr = @as(u16, self.fetch(bus) +% self.x), .page_crossed = false },
        .zpy => .{ .addr = @as(u16, self.fetch(bus) +% self.y), .page_crossed = false },
        .rel => blk: {
            const offset = self.fetch(bus);
            const base = self.pc;
            const addr = if (offset < 0x80) base +% @as(u16, offset) else base -% (@as(u16, 0x100) - offset);
            break :blk .{ .addr = addr, .page_crossed = (addr & 0xff00) != (base & 0xff00) };
        },
        .abs => .{ .addr = self.fetch16(bus), .page_crossed = false },
        .abx => blk: {
            const base = self.fetch16(bus);
            const addr = base +% self.x;
            break :blk .{ .addr = addr, .page_crossed = (addr & 0xff00) != (base & 0xff00) };
        },
        .aby => blk: {
            const base = self.fetch16(bus);
            const addr = base +% self.y;
            break :blk .{ .addr = addr, .page_crossed = (addr & 0xff00) != (base & 0xff00) };
        },
        .ind => blk: {
            const ptr = self.fetch16(bus);
            const lo = bus.read(ptr);
            // 6502 bug: JMP ($xxFF) reads high byte from $xx00
            const hi_ptr = (ptr & 0xff00) | ((ptr +% 1) & 0x00ff);
            const hi = bus.read(hi_ptr);
            break :blk .{ .addr = @as(u16, lo) | (@as(u16, hi) << 8), .page_crossed = false };
        },
        .izx => blk: {
            const ptr = self.fetch(bus) +% self.x;
            const lo = bus.read(@as(u16, ptr));
            const hi = bus.read(@as(u16, ptr +% 1));
            break :blk .{ .addr = @as(u16, lo) | (@as(u16, hi) << 8), .page_crossed = false };
        },
        .izy => blk: {
            const ptr = self.fetch(bus);
            const lo = bus.read(@as(u16, ptr));
            const hi = bus.read(@as(u16, ptr +% 1));
            const base = @as(u16, lo) | (@as(u16, hi) << 8);
            const addr = base +% self.y;
            break :blk .{ .addr = addr, .page_crossed = (addr & 0xff00) != (base & 0xff00) };
        },
    };
}

fn push(self: *Cpu, bus: *Bus, value: u8) void {
    bus.write(0x0100 | @as(u16, self.sp), value);
    self.sp -%= 1;
}

fn pull(self: *Cpu, bus: *const Bus) u8 {
    self.sp +%= 1;
    return bus.read(0x0100 | @as(u16, self.sp));
}

fn lda(self: *Cpu, value: u8) void {
    self.a = value;
    self.setZN(self.a);
}

fn ldx(self: *Cpu, value: u8) void {
    self.x = value;
    self.setZN(self.x);
}

fn ldy(self: *Cpu, value: u8) void {
    self.y = value;
    self.setZN(self.y);
}

fn @"and"(self: *Cpu, value: u8) void {
    self.a &= value;
    self.setZN(self.a);
}

fn ora(self: *Cpu, value: u8) void {
    self.a |= value;
    self.setZN(self.a);
}

fn eor(self: *Cpu, value: u8) void {
    self.a ^= value;
    self.setZN(self.a);
}

fn bit(self: *Cpu, value: u8) void {
    self.setFlag(Flag.Z, (self.a & value) == 0);
    self.setFlag(Flag.V, (value & 0x40) != 0);
    self.setFlag(Flag.N, (value & 0x80) != 0);
}

fn branch(self: *Cpu, page_crossed: bool, condition: bool, addr: u16) u8 {
    if (!condition) return 0;

    self.pc = addr;

    return 1 + @as(u8, @intFromBool(page_crossed));
}

fn asl(self: *Cpu, bus: *Bus, addr: u16, mode: AddressingMode) CpuError!void {
    var val = if (mode == .acc) self.a else bus.read(addr);
    self.setFlag(Flag.C, (val & 0x80) != 0);
    val <<= 1;
    self.setZN(val);
    if (mode == .acc) {
        self.a = val;
    } else {
        bus.write(addr, val);
    }
}

fn lsr(self: *Cpu, bus: *Bus, addr: u16, mode: AddressingMode) CpuError!void {
    var val = if (mode == .acc) self.a else bus.read(addr);
    self.setFlag(Flag.C, (val & 0x01) != 0);
    val >>= 1;
    self.setZN(val);
    if (mode == .acc) {
        self.a = val;
    } else {
        bus.write(addr, val);
    }
}

fn rol(self: *Cpu, bus: *Bus, addr: u16, mode: AddressingMode) CpuError!void {
    var val = if (mode == .acc) self.a else bus.read(addr);
    const old_c = if (self.getFlag(Flag.C)) @as(u8, 1) else @as(u8, 0);
    self.setFlag(Flag.C, (val & 0x80) != 0);
    val = (val << 1) | old_c;
    self.setZN(val);
    if (mode == .acc) {
        self.a = val;
    } else {
        bus.write(addr, val);
    }
}

fn ror(self: *Cpu, bus: *Bus, addr: u16, mode: AddressingMode) CpuError!void {
    var val = if (mode == .acc) self.a else bus.read(addr);
    const old_c = if (self.getFlag(Flag.C)) @as(u8, 0x80) else @as(u8, 0);
    self.setFlag(Flag.C, (val & 0x01) != 0);
    val = (val >> 1) | old_c;
    self.setZN(val);
    if (mode == .acc) {
        self.a = val;
    } else {
        bus.write(addr, val);
    }
}

fn inc(self: *Cpu, bus: *Bus, addr: u16) CpuError!void {
    const val = bus.read(addr) +% 1;
    bus.write(addr, val);
    self.setZN(val);
}

fn dec(self: *Cpu, bus: anytype, addr: u16) CpuError!void {
    const val = bus.read(addr) -% 1;
    bus.write(addr, val);
    self.setZN(val);
}

fn adc(self: *Cpu, value: u8) void {
    const carry: u16 = if (self.getFlag(Flag.C)) 1 else 0;
    const a = self.a;
    const b = value;

    if (self.getFlag(Flag.D) and !self.decimal_disabled) {
        var low = (a & 0x0f) + (b & 0x0f) + carry;
        if (low > 0x09) low += 0x06;
        var high = (a >> 4) + (b >> 4) + (if (low > 0x0f) @as(u16, 1) else 0);

        const result_bin = @as(u16, a) +% @as(u16, b) +% carry;
        self.setFlag(Flag.Z, @as(u8, @truncate(result_bin)) == 0);
        self.setFlag(Flag.N, (result_bin & 0x80) != 0);
        self.setFlag(Flag.V, ((~(a ^ b) & (a ^ @as(u8, @truncate(result_bin))) & 0x80) != 0));

        if (high > 0x09) high += 0x06;
        self.setFlag(Flag.C, high > 0x0f);
        self.a = @as(u8, @truncate((high << 4) | (low & 0x0f)));
    } else {
        const sum = @as(u16, a) + @as(u16, b) + carry;
        const result = @as(u8, @truncate(sum));
        self.setFlag(Flag.C, sum > 0xff);
        self.setFlag(Flag.V, ((~(a ^ b) & (a ^ result) & 0x80) != 0));
        self.a = result;
        self.setZN(self.a);
    }
}

fn sbc(self: *Cpu, value: u8) void {
    if (!self.getFlag(Flag.D) or self.decimal_disabled) {
        self.adc(value ^ 0xff);
    } else {
        const a = self.a;
        const b = value;
        const carry: u16 = if (self.getFlag(Flag.C)) 1 else 0;

        var low = @as(i16, @intCast(a & 0x0f)) - @as(i16, @intCast(b & 0x0f)) - @as(i16, @intCast(1 - carry));
        if (low < 0) low -= 0x06;
        var high = @as(i16, @intCast(a >> 4)) - @as(i16, @intCast(b >> 4)) - (if (low < 0) @as(i16, 1) else 0);

        const result_bin = @as(u16, a) -% @as(u16, b) -% (1 - carry);
        self.setZN(@as(u8, @truncate(result_bin)));
        self.setFlag(Flag.C, result_bin < 0x100);
        self.setFlag(Flag.V, (((a ^ b) & (a ^ @as(u8, @truncate(result_bin))) & 0x80) != 0));

        if (high < 0) high -= 0x06;
        const res = (@as(u16, @bitCast(high)) << 4) | (@as(u16, @bitCast(low)) & 0x0f);
        self.a = @as(u8, @truncate(res));
    }
}

fn brk(self: *Cpu, bus: *Bus) void {
    const pc = self.pc +% 1;
    self.push(bus, @as(u8, @truncate(pc >> 8)));
    self.push(bus, @as(u8, @truncate(pc)));
    self.push(bus, self.status | Flag.B);
    self.setFlag(Flag.I, true);
    self.pc = self.read16(bus, 0xfffe);
}

pub fn nmi(self: *Cpu, bus: *Bus) u8 {
    self.push(bus, @as(u8, @truncate(self.pc >> 8)));
    self.push(bus, @as(u8, @truncate(self.pc)));
    self.push(bus, self.status & ~Flag.B);
    self.setFlag(Flag.I, true);
    self.pc = self.read16(bus, 0xfffa);
    self.cycles += 7;
    return 7;
}

pub fn irq(self: *Cpu, bus: *Bus) u8 {
    if (self.getFlag(Flag.I)) return 0;
    self.push(bus, @as(u8, @truncate(self.pc >> 8)));
    self.push(bus, @as(u8, @truncate(self.pc)));
    self.push(bus, self.status & ~Flag.B);
    self.setFlag(Flag.I, true);
    self.pc = self.read16(bus, 0xfffe);
    self.cycles += 7;
    return 7;
}

fn cmp(self: *Cpu, lhs: u8, rhs: u8) void {
    const result = lhs -% rhs;
    self.setFlag(Flag.C, lhs >= rhs);
    self.setZN(result);
}

fn setZN(self: *Cpu, value: u8) void {
    self.setFlag(Flag.Z, value == 0);
    self.setFlag(Flag.N, (value & 0x80) != 0);
}

fn getFlag(self: *const Cpu, flag: u8) bool {
    return (self.status & flag) != 0;
}

fn setFlag(self: *Cpu, flag: u8, value: bool) void {
    if (value) {
        self.status |= flag;
    } else {
        self.status &= ~flag;
    }

    self.status |= Flag.U;
}
