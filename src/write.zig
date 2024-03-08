const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const mask_mantissa: u64 = 0b0_00000000000_1111111111111111111111111111111111111111111111111111;

fn charFromInt(int: u64) u8 {
    return switch (int) {
        0...9 => @as(u8, @truncate(int)) + 48,
        10...15 => @as(u8, @truncate(int)) + 87,
        else => unreachable,
    };
}

pub fn write(buffer: []u8, val: f64) void {
    var tmp: u64 = @bitCast(val);
    buffer[0] = if (tmp >> 63 == 0) '+' else '-';
    inline for (.{ '0', 'x', '1', '.' }, 1..) |c, i| buffer[i] = c;

    tmp &= mask_mantissa;

    var ind: u8 = 17;
    while (4 < ind) : ({
        tmp >>= 4;
        ind -= 1;
    }) buffer[ind] = charFromInt(tmp & 0xF);

    buffer[18] = 'p';
    return;
}

test "write" {
    var buffer: [19]u8 = undefined;

    write(&buffer, 0x1.921fb54442d18p-1);
    try testing.expect(mem.eql(u8, &buffer, "+0x1.921fb54442d18p"));
    write(&buffer, -0x1.921fb54442d18p-1);
    try testing.expect(mem.eql(u8, &buffer, "-0x1.921fb54442d18p"));
}
