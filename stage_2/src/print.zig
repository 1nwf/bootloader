const std = @import("std");
const Writer = std.io.Writer;
const format = std.fmt.format;

fn print(c: u8) void {
    asm volatile (
        \\   mov $0x0e, %%ah
        \\   int $0x10  
        :
        : [c] "{al}" (c),
    );
}

fn printStr(str: []const u8) void {
    for (str) |c| {
        print(c);
    }
}
const SWriter = Writer(void, error{}, writefn);
const writer = @as(SWriter, .{ .context = {} });
fn writefn(ctx: void, str: []const u8) error{}!usize {
    _ = ctx;
    printStr(str);
    return str.len;
}

pub fn write(comptime data: []const u8, args: anytype) void {
    print(0xA);
    print(0xD);
    format(writer, data, args) catch {};
}
