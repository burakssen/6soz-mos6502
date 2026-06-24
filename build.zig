const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mos6502_mod = b.addModule("mos6502", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/root.zig"),
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
