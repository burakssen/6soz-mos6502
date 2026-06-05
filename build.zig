const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const bus_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/bus.zig"),
    });

    const cpu_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/cpu/cpu.zig"),
        .imports = &.{
            .{ .name = "bus", .module = bus_mod },
        },
    });

    const mos6502_mod = b.addModule("mos6502", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/root.zig"),
        .imports = &.{
            .{ .name = "bus", .module = bus_mod },
            .{ .name = "cpu", .module = cpu_mod },
        },
    });

    const test_step = b.step("test", "Run MOS 6502 tests");

    inline for (&.{mos6502_mod}) |mod| {
        const mod_test = b.addTest(.{ .root_module = mod });
        const mod_cmd = b.addRunArtifact(mod_test);
        test_step.dependOn(&mod_cmd.step);
    }

    const mos6502 = b.addLibrary(.{
        .name = "mos6502",
        .root_module = mos6502_mod,
    });

    b.installArtifact(mos6502);
}
