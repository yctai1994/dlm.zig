const std = @import("std");

fn hexFromInt(int: u64) u8 {
    return switch (int) {
        0...9 => @as(u8, @truncate(int)) + 48,
        10...15 => @as(u8, @truncate(int)) + 87,
        else => unreachable,
    };
}

/// This function writes a custom hexadecimal representation of a
/// 64-bit floating-point number (`val`) to a provided buffer (`buffer`).
/// The format uses hexadecimal for the significand and exponent,
/// with the exponent prefixed by 'p'.
///
/// **Input:**
///
/// - `buffer (slice)`: Needs at least 21 `u8` elements (not checked).
/// - `val (f64)`: The 64-bit floating-point number to convert.
///
/// **Output:**
///
/// (void) - Writes the converted representation directly into the buffer.
///
/// **Notes:**
///
/// - Non-standard format, not IEEE 754 compatible.
/// - Assumes sufficient buffer space (>= 21 elements).
pub fn write(buffer: []u8, val: f64) void {
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

    return;
}

test "write" {
    var buffer: [21]u8 = undefined;

    // positive numbers
    write(&buffer, std.math.pi);
    try std.testing.expect(std.mem.eql(u8, &buffer, "0x1.921fb54442d18p400"));
    write(&buffer, std.math.nan(f64));
    try std.testing.expect(std.mem.eql(u8, &buffer, "0x1.8000000000000p7ff"));
    write(&buffer, std.math.inf(f64));
    try std.testing.expect(std.mem.eql(u8, &buffer, "0x1.0000000000000p7ff"));
    write(&buffer, std.math.floatMax(f64));
    try std.testing.expect(std.mem.eql(u8, &buffer, "0x1.fffffffffffffp7fe"));
    write(&buffer, std.math.floatMin(f64));
    try std.testing.expect(std.mem.eql(u8, &buffer, "0x1.0000000000000p001"));
    write(&buffer, 0x1.5555555555555p-2); // 0.3333333333333333 ≈ 1/3
    try std.testing.expect(std.mem.eql(u8, &buffer, "0x1.5555555555555p3fd"));

    // negative numbers
    write(&buffer, -std.math.pi);
    try std.testing.expect(std.mem.eql(u8, &buffer, "0x1.921fb54442d18pc00"));
    write(&buffer, -std.math.nan(f64));
    try std.testing.expect(std.mem.eql(u8, &buffer, "0x1.8000000000000pfff"));
    write(&buffer, -std.math.inf(f64));
    try std.testing.expect(std.mem.eql(u8, &buffer, "0x1.0000000000000pfff"));
    write(&buffer, -std.math.floatMax(f64));
    try std.testing.expect(std.mem.eql(u8, &buffer, "0x1.fffffffffffffpffe"));
    write(&buffer, -std.math.floatMin(f64));
    try std.testing.expect(std.mem.eql(u8, &buffer, "0x1.0000000000000p801"));
    write(&buffer, -0x1.5555555555555p-2); // 0.3333333333333333 ≈ 1/3
    try std.testing.expect(std.mem.eql(u8, &buffer, "0x1.5555555555555pbfd"));
}
