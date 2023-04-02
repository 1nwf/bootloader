const write = @import("print.zig").write;
const mem = @import("mem.zig");
const gdt = @import("gdt.zig");

const pm = @import("protected_mode.zig");

export fn halt() noreturn {
    while (true) {
        asm volatile (
            \\ cli
            \\ hlt
        );
    }
}

export fn main() noreturn {
    write("running stage2...", .{});

    var count = mem.detectMemory();
    var map = mem.memoryMap[0..count];

    for (map) |e| {
        write("{}", .{e});
    }
    var size: u32 = mem.availableMemory();
    write("available memory = {}mb", .{size});

    gdt.init();

    pm.enter_protected_mode();

    halt();
}
