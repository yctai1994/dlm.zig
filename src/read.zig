const std = @import("std");

fn intFromHex(hex: u8) u8 {
    return switch (hex) {
        '0'...'9' => hex - 48,
        'a'...'f' => hex - 87,
        else => unreachable,
    };
}

const ReadError = error{InvalidCharacter};

/// This function parses a string (src) in a custom hexadecimal format (similar to scientific
/// notation with hex exponents) and converts it into a 64-bit floating-point number.
///
/// **Input:**
///
/// - `src`: A constant slice (`[]const u8`) containing the string representation in the
///          custom format.
///
/// **Output:**
///
/// - `ReadError`: The function returns an error (ReadError) if the input string is invalid
///                (contains unexpected characters).
/// - `f64`: On successful parsing, the converted 64-bit floating-point number is returned.
///
/// **Notes:**
///
/// - This function assumes the input string adheres to the specific custom format
///   and performs minimal validation.
/// - Error handling is limited to checking for the presence of the expected prefix
///   and returning an error for any deviation.
pub fn read(src: []const u8) ReadError!f64 {
    inline for (
        .{ 0, 1, 2, 3, 17 },
        .{ '0', 'x', '1', '.', 'p' },
    ) |i, c| if (src[i] != c) return ReadError.InvalidCharacter;

    var val: u64 = 0x0;
    val |= intFromHex(src[18]);

    for (19..21) |ind| {
        val <<= 4;
        val |= intFromHex(src[ind]);
    }

    for (4..17) |ind| {
        val <<= 4;
        val |= intFromHex(src[ind]);
    }

    return @bitCast(val);
}

test "read" {
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

    for (val_list, str_list) |val, str| {
        if (read(str)) |tmp| {
            std.testing.expectEqual(
                @as(u64, @bitCast(tmp)),
                @as(u64, @bitCast(val)),
            ) catch |err| {
                std.debug.print(
                    "{any} at {x} vs. {s}, got {x}\n",
                    .{ err, val, str, tmp },
                );
            };
        } else |err| {
            if (err == ReadError.InvalidCharacter) continue else unreachable;
        }
    }
}
