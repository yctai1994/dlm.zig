const std = @import("std");

fn hexFromInt(int: u64) u8 {
    return switch (int) {
        0...9 => @as(u8, @truncate(int)) + 48,
        10...15 => @as(u8, @truncate(int)) + 87,
        else => unreachable,
    };
}

pub fn write(buffer: []u8, val: f64) []u8 {
    inline for (
        .{ 0, 1, 2, 3, 17 },
        .{ '0', 'x', '1', '.', 'p' },
    ) |i, c| buffer[i] = c;

    var tmp: u64 = @bitCast(val);
    var ind: u8 = 16;
    while (3 < ind) : ({
        tmp >>= 4;
        ind -= 1;
    }) buffer[ind] = hexFromInt(tmp & 0xf);

    ind = 20;
    while (17 < ind) : ({
        tmp >>= 4;
        ind -= 1;
    }) buffer[ind] = hexFromInt(tmp & 0xf);

    return buffer[0..];
}

test "write" {
    var buffer: [21]u8 = undefined;

    try std.testing.expect(std.mem.eql(u8, write(&buffer, std.math.pi), "0x1.921fb54442d18p400"));
    try std.testing.expect(std.mem.eql(u8, write(&buffer, 0x1.fffffffffffffp+1023), "0x1.fffffffffffffp7fe"));
}
