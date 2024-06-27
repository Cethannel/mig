const std = @import("std");

pub fn unwrap(comptime T: type, val: anyerror!T) T {
    if (val) |value| {
        return value;
    } else |err| {
        std.debug.panic("Panicked at Error: {any}", .{err});
    }
}
