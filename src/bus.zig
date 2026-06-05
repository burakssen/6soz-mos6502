const std = @import("std");

const Bus = @This();

ptr: *anyopaque,

read_fn: *const fn (ptr: *anyopaque, addr: u16) u8,
write_fn: *const fn (ptr: *anyopaque, addr: u16, value: u8) void,

pub fn init(ptr: anytype) Bus {
    const T = @TypeOf(ptr);

    const info = @typeInfo(T);
    if (info != .pointer)
        @compileError("Bus.init expects a pointer");

    const Child = info.pointer.child;

    const VTable = struct {
        pub fn read(p: *anyopaque, addr: u16) u8 {
            const self: T = @ptrCast(@alignCast(p));
            return Child.read(self, addr);
        }

        pub fn write(p: *anyopaque, addr: u16, value: u8) void {
            const self: T = @ptrCast(@alignCast(p));
            Child.write(self, addr, value);
        }
    };

    return .{
        .ptr = ptr,
        .read_fn = VTable.read,
        .write_fn = VTable.write,
    };
}

pub fn read(self: Bus, addr: u16) u8 {
    return self.read_fn(self.ptr, addr);
}

pub fn write(self: Bus, addr: u16, value: u8) void {
    self.write_fn(self.ptr, addr, value);
}
