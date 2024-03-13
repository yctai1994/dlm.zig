const std = @import("std");

fn hexFromInt(int: u64) u8 {
    return switch (int) {
        0...9 => @as(u8, @truncate(int)) + 48,
        10...15 => @as(u8, @truncate(int)) + 87,
        else => unreachable,
    };
}

/// This function **writes** a custom hexadecimal representation of a 64-bit floating-
/// point number (`val`) to a provided buffer (`des`). The format uses hexadecimal for
/// the significand and exponent, with the exponent prefixed by 'p'.
///
/// **Input:**
///
/// - `des (slice)`: Needs at least 21 `u8` elements (not checked).
/// - `val (f64)`: The 64-bit floating-point number to convert.
///
/// **Output:**
///
/// `void`: Writes the converted representation directly into the buffer.
///
/// **Notes:**
///
/// - Non-standard format, not IEEE 754 compatible.
/// - Assumes sufficient buffer space (>= 21 elements).
pub fn write(des: []u8, val: f64) void {
    inline for (
        .{ 0, 1, 2, 3, 17 },
        .{ '0', 'x', '1', '.', 'p' },
    ) |i, c| des[i] = c;

    var tmp: u64 = @bitCast(val);
    var ind: u8 = 16;
    while (3 < ind) : ({
        tmp >>= 4;
        ind -= 1;
    }) des[ind] = hexFromInt(tmp & 0xf);

    ind = 20;
    while (18 < ind) : ({
        tmp >>= 4;
        ind -= 1;
    }) des[ind] = hexFromInt(tmp & 0xf);
    des[18] = hexFromInt(tmp & 0xf);

    return;
}

test "write" {
    const val_list = [_]f64{
        // positive numbers
        std.math.pi,
        std.math.nan(f64),
        std.math.inf(f64),
        std.math.floatMax(f64),
        std.math.floatMin(f64),
        std.math.floatTrueMin(f64),
        0x1.5555555555555p-2, // 0.3333333333333333 ≈ 1/3
        // negative numbers
        -std.math.pi,
        -std.math.nan(f64),
        -std.math.inf(f64),
        -std.math.floatMax(f64),
        -std.math.floatMin(f64),
        -std.math.floatTrueMin(f64),
        -0x1.5555555555555p-2, // 0.3333333333333333 ≈ 1/3
    };

    const str_list = [_][]const u8{
        // positive numbers
        "0x1.921fb54442d18p400",
        "0x1.8000000000000p7ff",
        "0x1.0000000000000p7ff",
        "0x1.fffffffffffffp7fe",
        "0x1.0000000000000p001",
        "0x1.0000000000001p000",
        "0x1.5555555555555p3fd",
        // negative numbers
        "0x1.921fb54442d18pc00",
        "0x1.8000000000000pfff",
        "0x1.0000000000000pfff",
        "0x1.fffffffffffffpffe",
        "0x1.0000000000000p801",
        "0x1.0000000000001p800",
        "0x1.5555555555555pbfd",
    };

    var buffer: [21]u8 = undefined;

    for (val_list, str_list) |val, str| {
        write(&buffer, val);
        std.testing.expect(std.mem.eql(u8, &buffer, str)) catch |err| {
            std.debug.print(
                "{any} at {x} vs. {s}, got {s}\n",
                .{ err, val, str, buffer },
            );
        };
    }
}
