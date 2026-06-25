const std = @import("std");

pub const Flag = struct {
    pub const C: u8 = 1 << 0; // Carry
    pub const Z: u8 = 1 << 1; // Zero
    pub const I: u8 = 1 << 2; // Interrupt Disable
    pub const D: u8 = 1 << 3; // Decimal
    pub const B: u8 = 1 << 4; // Break
    pub const U: u8 = 1 << 5; // Unused, usually set
    pub const V: u8 = 1 << 6; // Overflow
    pub const N: u8 = 1 << 7; // Negative
};

pub const AddressingMode = enum {
    imp, // Implied
    acc, // Accumulator
    imm, // Immediate
    zp,  // Zero Page
    zpx, // Zero Page, X
    zpy, // Zero Page, Y
    rel, // Relative
    abs, // Absolute
    abx, // Absolute, X
    aby, // Absolute, Y
    ind, // Indirect
    izx, // Indexed Indirect (X)
    izy, // Indirect Indexed (Y)
};

pub const Operation = enum {
    adc,
    @"and",
    asl,
    axs,
    bcc,
    bcs,
    beq,
    bit,
    bmi,
    bne,
    bpl,
    brk,
    bvc,
    bvs,
    clc,
    cld,
    cli,
    clv,
    cmp,
    cpx,
    cpy,
    dec,
    dex,
    dey,
    eor,
    inc,
    inx,
    iny,
    jmp,
    jsr,
    lda,
    ldx,
    ldy,
    lsr,
    nop,
    ora,
    pha,
    php,
    pla,
    plp,
    rol,
    ror,
    rti,
    rts,
    sbc,
    sec,
    sed,
    sei,
    sta,
    stx,
    sty,
    tax,
    tay,
    tsx,
    txa,
    txs,
    tya,
};

pub const Addressing = struct {
    addr: u16,
    page_crossed: bool,
};

pub const Instruction = struct {
    op: Operation,
    mode: AddressingMode,
    cycles: u8,
    page_cycle: bool = false,
};

pub const InstructionTable = [256]?Instruction{
    // 0x00
    .{ .op = .brk, .mode = .imp, .cycles = 7 },
    .{ .op = .ora, .mode = .izx, .cycles = 6 },
    null,
    null,
    null,
    .{ .op = .ora, .mode = .zp, .cycles = 3 },
    .{ .op = .asl, .mode = .zp, .cycles = 5 },
    null,
    .{ .op = .php, .mode = .imp, .cycles = 3 },
    .{ .op = .ora, .mode = .imm, .cycles = 2 },
    .{ .op = .asl, .mode = .acc, .cycles = 2 },
    null,
    null,
    .{ .op = .ora, .mode = .abs, .cycles = 4 },
    .{ .op = .asl, .mode = .abs, .cycles = 6 },
    null,

    // 0x10
    .{ .op = .bpl, .mode = .rel, .cycles = 2 },
    .{ .op = .ora, .mode = .izy, .cycles = 5, .page_cycle = true },
    null,
    null,
    null,
    .{ .op = .ora, .mode = .zpx, .cycles = 4 },
    .{ .op = .asl, .mode = .zpx, .cycles = 6 },
    null,
    .{ .op = .clc, .mode = .imp, .cycles = 2 },
    .{ .op = .ora, .mode = .aby, .cycles = 4, .page_cycle = true },
    null,
    null,
    null,
    .{ .op = .ora, .mode = .abx, .cycles = 4, .page_cycle = true },
    .{ .op = .asl, .mode = .abx, .cycles = 7 },
    null,

    // 0x20
    .{ .op = .jsr, .mode = .abs, .cycles = 6 },
    .{ .op = .@"and", .mode = .izx, .cycles = 6 },
    null,
    null,
    .{ .op = .bit, .mode = .zp, .cycles = 3 },
    .{ .op = .@"and", .mode = .zp, .cycles = 3 },
    .{ .op = .rol, .mode = .zp, .cycles = 5 },
    null,
    .{ .op = .plp, .mode = .imp, .cycles = 4 },
    .{ .op = .@"and", .mode = .imm, .cycles = 2 },
    .{ .op = .rol, .mode = .acc, .cycles = 2 },
    null,
    .{ .op = .bit, .mode = .abs, .cycles = 4 },
    .{ .op = .@"and", .mode = .abs, .cycles = 4 },
    .{ .op = .rol, .mode = .abs, .cycles = 6 },
    null,

    // 0x30
    .{ .op = .bmi, .mode = .rel, .cycles = 2 },
    .{ .op = .@"and", .mode = .izy, .cycles = 5, .page_cycle = true },
    null,
    null,
    null,
    .{ .op = .@"and", .mode = .zpx, .cycles = 4 },
    .{ .op = .rol, .mode = .zpx, .cycles = 6 },
    null,
    .{ .op = .sec, .mode = .imp, .cycles = 2 },
    .{ .op = .@"and", .mode = .aby, .cycles = 4, .page_cycle = true },
    null,
    null,
    null,
    .{ .op = .@"and", .mode = .abx, .cycles = 4, .page_cycle = true },
    .{ .op = .rol, .mode = .abx, .cycles = 7 },
    null,

    // 0x40
    .{ .op = .rti, .mode = .imp, .cycles = 6 },
    .{ .op = .eor, .mode = .izx, .cycles = 6 },
    null,
    null,
    null,
    .{ .op = .eor, .mode = .zp, .cycles = 3 },
    .{ .op = .lsr, .mode = .zp, .cycles = 5 },
    null,
    .{ .op = .pha, .mode = .imp, .cycles = 3 },
    .{ .op = .eor, .mode = .imm, .cycles = 2 },
    .{ .op = .lsr, .mode = .acc, .cycles = 2 },
    null,
    .{ .op = .jmp, .mode = .abs, .cycles = 3 },
    .{ .op = .eor, .mode = .abs, .cycles = 4 },
    .{ .op = .lsr, .mode = .abs, .cycles = 6 },
    null,

    // 0x50
    .{ .op = .bvc, .mode = .rel, .cycles = 2 },
    .{ .op = .eor, .mode = .izy, .cycles = 5, .page_cycle = true },
    null,
    null,
    null,
    .{ .op = .eor, .mode = .zpx, .cycles = 4 },
    .{ .op = .lsr, .mode = .zpx, .cycles = 6 },
    null,
    .{ .op = .cli, .mode = .imp, .cycles = 2 },
    .{ .op = .eor, .mode = .aby, .cycles = 4, .page_cycle = true },
    null,
    null,
    null,
    .{ .op = .eor, .mode = .abx, .cycles = 4, .page_cycle = true },
    .{ .op = .lsr, .mode = .abx, .cycles = 7 },
    null,

    // 0x60
    .{ .op = .rts, .mode = .imp, .cycles = 6 },
    .{ .op = .adc, .mode = .izx, .cycles = 6 },
    null,
    null,
    null,
    .{ .op = .adc, .mode = .zp, .cycles = 3 },
    .{ .op = .ror, .mode = .zp, .cycles = 5 },
    null,
    .{ .op = .pla, .mode = .imp, .cycles = 4 },
    .{ .op = .adc, .mode = .imm, .cycles = 2 },
    .{ .op = .ror, .mode = .acc, .cycles = 2 },
    null,
    .{ .op = .jmp, .mode = .ind, .cycles = 5 },
    .{ .op = .adc, .mode = .abs, .cycles = 4 },
    .{ .op = .ror, .mode = .abs, .cycles = 6 },
    null,

    // 0x70
    .{ .op = .bvs, .mode = .rel, .cycles = 2 },
    .{ .op = .adc, .mode = .izy, .cycles = 5, .page_cycle = true },
    null,
    null,
    null,
    .{ .op = .adc, .mode = .zpx, .cycles = 4 },
    .{ .op = .ror, .mode = .zpx, .cycles = 6 },
    null,
    .{ .op = .sei, .mode = .imp, .cycles = 2 },
    .{ .op = .adc, .mode = .aby, .cycles = 4, .page_cycle = true },
    null,
    null,
    null,
    .{ .op = .adc, .mode = .abx, .cycles = 4, .page_cycle = true },
    .{ .op = .ror, .mode = .abx, .cycles = 7 },
    null,

    // 0x80
    null,
    .{ .op = .sta, .mode = .izx, .cycles = 6 },
    null,
    null,
    .{ .op = .sty, .mode = .zp, .cycles = 3 },
    .{ .op = .sta, .mode = .zp, .cycles = 3 },
    .{ .op = .stx, .mode = .zp, .cycles = 3 },
    null,
    .{ .op = .dey, .mode = .imp, .cycles = 2 },
    null,
    .{ .op = .txa, .mode = .imp, .cycles = 2 },
    null,
    .{ .op = .sty, .mode = .abs, .cycles = 4 },
    .{ .op = .sta, .mode = .abs, .cycles = 4 },
    .{ .op = .stx, .mode = .abs, .cycles = 4 },
    null,

    // 0x90
    .{ .op = .bcc, .mode = .rel, .cycles = 2 },
    .{ .op = .sta, .mode = .izy, .cycles = 6 },
    null,
    null,
    .{ .op = .sty, .mode = .zpx, .cycles = 4 },
    .{ .op = .sta, .mode = .zpx, .cycles = 4 },
    .{ .op = .stx, .mode = .zpy, .cycles = 4 },
    null,
    .{ .op = .tya, .mode = .imp, .cycles = 2 },
    .{ .op = .sta, .mode = .aby, .cycles = 5 },
    .{ .op = .txs, .mode = .imp, .cycles = 2 },
    null,
    null,
    .{ .op = .sta, .mode = .abx, .cycles = 5 },
    null,
    null,

    // 0xa0
    .{ .op = .ldy, .mode = .imm, .cycles = 2 },
    .{ .op = .lda, .mode = .izx, .cycles = 6 },
    .{ .op = .ldx, .mode = .imm, .cycles = 2 },
    null,
    .{ .op = .ldy, .mode = .zp, .cycles = 3 },
    .{ .op = .lda, .mode = .zp, .cycles = 3 },
    .{ .op = .ldx, .mode = .zp, .cycles = 3 },
    null,
    .{ .op = .tay, .mode = .imp, .cycles = 2 },
    .{ .op = .lda, .mode = .imm, .cycles = 2 },
    .{ .op = .tax, .mode = .imp, .cycles = 2 },
    null,
    .{ .op = .ldy, .mode = .abs, .cycles = 4 },
    .{ .op = .lda, .mode = .abs, .cycles = 4 },
    .{ .op = .ldx, .mode = .abs, .cycles = 4 },
    null,

    // 0xb0
    .{ .op = .bcs, .mode = .rel, .cycles = 2 },
    .{ .op = .lda, .mode = .izy, .cycles = 5, .page_cycle = true },
    null,
    null,
    .{ .op = .ldy, .mode = .zpx, .cycles = 4 },
    .{ .op = .lda, .mode = .zpx, .cycles = 4 },
    .{ .op = .ldx, .mode = .zpy, .cycles = 4 },
    null,
    .{ .op = .clv, .mode = .imp, .cycles = 2 },
    .{ .op = .lda, .mode = .aby, .cycles = 4, .page_cycle = true },
    .{ .op = .tsx, .mode = .imp, .cycles = 2 },
    null,
    .{ .op = .ldy, .mode = .abx, .cycles = 4, .page_cycle = true },
    .{ .op = .lda, .mode = .abx, .cycles = 4, .page_cycle = true },
    .{ .op = .ldx, .mode = .aby, .cycles = 4, .page_cycle = true },
    null,

    // 0xc0
    .{ .op = .cpy, .mode = .imm, .cycles = 2 },
    .{ .op = .cmp, .mode = .izx, .cycles = 6 },
    null,
    null,
    .{ .op = .cpy, .mode = .zp, .cycles = 3 },
    .{ .op = .cmp, .mode = .zp, .cycles = 3 },
    .{ .op = .dec, .mode = .zp, .cycles = 5 },
    null,
    .{ .op = .iny, .mode = .imp, .cycles = 2 },
    .{ .op = .cmp, .mode = .imm, .cycles = 2 },
    .{ .op = .dex, .mode = .imp, .cycles = 2 },
    .{ .op = .axs, .mode = .imm, .cycles = 2 },
    .{ .op = .cpy, .mode = .abs, .cycles = 4 },
    .{ .op = .cmp, .mode = .abs, .cycles = 4 },
    .{ .op = .dec, .mode = .abs, .cycles = 6 },
    null,

    // 0xd0
    .{ .op = .bne, .mode = .rel, .cycles = 2 },
    .{ .op = .cmp, .mode = .izy, .cycles = 5, .page_cycle = true },
    null,
    null,
    null,
    .{ .op = .cmp, .mode = .zpx, .cycles = 4 },
    .{ .op = .dec, .mode = .zpx, .cycles = 6 },
    null,
    .{ .op = .cld, .mode = .imp, .cycles = 2 },
    .{ .op = .cmp, .mode = .aby, .cycles = 4, .page_cycle = true },
    null,
    null,
    null,
    .{ .op = .cmp, .mode = .abx, .cycles = 4, .page_cycle = true },
    .{ .op = .dec, .mode = .abx, .cycles = 7 },
    null,

    // 0xe0
    .{ .op = .cpx, .mode = .imm, .cycles = 2 },
    .{ .op = .sbc, .mode = .izx, .cycles = 6 },
    null,
    null,
    .{ .op = .cpx, .mode = .zp, .cycles = 3 },
    .{ .op = .sbc, .mode = .zp, .cycles = 3 },
    .{ .op = .inc, .mode = .zp, .cycles = 5 },
    null,
    .{ .op = .inx, .mode = .imp, .cycles = 2 },
    .{ .op = .sbc, .mode = .imm, .cycles = 2 },
    .{ .op = .nop, .mode = .imp, .cycles = 2 },
    null,
    .{ .op = .cpx, .mode = .abs, .cycles = 4 },
    .{ .op = .sbc, .mode = .abs, .cycles = 4 },
    .{ .op = .inc, .mode = .abs, .cycles = 6 },
    null,

    // 0xf0
    .{ .op = .beq, .mode = .rel, .cycles = 2 },
    .{ .op = .sbc, .mode = .izy, .cycles = 5, .page_cycle = true },
    null,
    null,
    null,
    .{ .op = .sbc, .mode = .zpx, .cycles = 4 },
    .{ .op = .inc, .mode = .zpx, .cycles = 6 },
    null,
    .{ .op = .sed, .mode = .imp, .cycles = 2 },
    .{ .op = .sbc, .mode = .aby, .cycles = 4, .page_cycle = true },
    null,
    null,
    null,
    .{ .op = .sbc, .mode = .abx, .cycles = 4, .page_cycle = true },
    .{ .op = .inc, .mode = .abx, .cycles = 7 },
    null,
};

pub const Error = error{
    InvalidOpcode,
};

pub const StepResult = struct {
    cycles: u8,
};

pub const Variant = enum {
    mos6502,
    ricoh_2a03,
};

const Cpu = @This();

a: u8 = 0,
x: u8 = 0,
y: u8 = 0,

sp: u8 = 0xff,
pc: u16 = 0,

status: u8 = Flag.U | Flag.I,

cycles: u64 = 0,

variant: Variant = .mos6502,

pub fn reset(self: *Cpu, bus: anytype) void {
    self.a = 0;
    self.x = 0;
    self.y = 0;
    self.sp = 0xfd;
    self.status = Flag.U | Flag.I;
    self.pc = self.read16(bus, 0xfffc);
    self.cycles = 0;
}

pub fn step(self: *Cpu, bus: anytype) Error!StepResult {
    const initial_pc = self.pc;
    const opcode = self.fetch(bus);
    const instruction = InstructionTable[opcode] orelse {
        self.pc = initial_pc;
        return Error.InvalidOpcode;
    };

    const addressing = self.getOperandAddressing(bus, instruction.mode);

    const extra_cycles = try self.execute(bus, instruction.op, addressing.addr, instruction.mode, addressing.page_crossed);

    const total_cycles = instruction.cycles + extra_cycles + (if (instruction.page_cycle and addressing.page_crossed) @as(u8, 1) else 0);

    self.cycles += total_cycles;
    return .{ .cycles = total_cycles };
}

fn execute(self: *Cpu, bus: anytype, op: Operation, address: u16, mode: AddressingMode, page_crossed: bool) Error!u8 {
    switch (op) {
        .adc => self.adc(bus.read(address)),
        .@"and" => self.@"and"(bus.read(address)),
        .asl => try self.asl(bus, address, mode),
        .axs => self.axs(bus.read(address)),
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

fn fetch(self: *Cpu, bus: anytype) u8 {
    const value = bus.read(self.pc);
    self.pc +%= 1;
    return value;
}

fn fetch16(self: *Cpu, bus: anytype) u16 {
    const lo = self.fetch(bus);
    const hi = self.fetch(bus);
    return @as(u16, lo) | (@as(u16, hi) << 8);
}

fn read16(_: *Cpu, bus: anytype, address: u16) u16 {
    const lo = bus.read(address);
    const hi = bus.read(address +% 1);
    return @as(u16, lo) | (@as(u16, hi) << 8);
}

fn getOperandAddressing(self: *Cpu, bus: anytype, mode: AddressingMode) Addressing {
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

fn push(self: *Cpu, bus: anytype, value: u8) void {
    bus.write(0x0100 | @as(u16, self.sp), value);
    self.sp -%= 1;
}

fn pull(self: *Cpu, bus: anytype) u8 {
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

fn asl(self: *Cpu, bus: anytype, addr: u16, mode: AddressingMode) Error!void {
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

fn lsr(self: *Cpu, bus: anytype, addr: u16, mode: AddressingMode) Error!void {
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

fn rol(self: *Cpu, bus: anytype, addr: u16, mode: AddressingMode) Error!void {
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

fn ror(self: *Cpu, bus: anytype, addr: u16, mode: AddressingMode) Error!void {
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

fn inc(self: *Cpu, bus: anytype, addr: u16) Error!void {
    const val = bus.read(addr) +% 1;
    bus.write(addr, val);
    self.setZN(val);
}

fn dec(self: *Cpu, bus: anytype, addr: u16) Error!void {
    const val = bus.read(addr) -% 1;
    bus.write(addr, val);
    self.setZN(val);
}

fn adc(self: *Cpu, value: u8) void {
    const carry: u16 = if (self.getFlag(Flag.C)) 1 else 0;
    const a = self.a;
    const b = value;

    if (self.getFlag(Flag.D) and self.variant == .mos6502) {
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
    if (!self.getFlag(Flag.D) or self.variant == .ricoh_2a03) {
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

fn brk(self: *Cpu, bus: anytype) void {
    const pc = self.pc +% 1;
    self.push(bus, @as(u8, @truncate(pc >> 8)));
    self.push(bus, @as(u8, @truncate(pc)));
    self.push(bus, self.status | Flag.B);
    self.setFlag(Flag.I, true);
    self.pc = self.read16(bus, 0xfffe);
}

pub fn nmi(self: *Cpu, bus: anytype) u8 {
    self.push(bus, @as(u8, @truncate(self.pc >> 8)));
    self.push(bus, @as(u8, @truncate(self.pc)));
    self.push(bus, self.status & ~Flag.B);
    self.setFlag(Flag.I, true);
    self.pc = self.read16(bus, 0xfffa);
    self.cycles += 7;
    return 7;
}

pub fn irq(self: *Cpu, bus: anytype) u8 {
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

fn axs(self: *Cpu, value: u8) void {
    const lhs = self.a & self.x;
    self.x = lhs -% value;
    self.setFlag(Flag.C, lhs >= value);
    self.setZN(self.x);
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
