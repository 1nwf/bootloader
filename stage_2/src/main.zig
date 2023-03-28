export fn entry() linksection(".entry") void {
    main();
}

const write = @import("print.zig").write;
const mem = @import("mem.zig");
const gdt = @import("gdt.zig");

fn halt() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

inline fn main() noreturn {
    write("(stage 2) hello from zig!", .{});

    gdt.init();
    var count = mem.detectMemory();
    var map = mem.memoryMap[0..count];

    for (map) |e| {
        write("{}", .{e});
    }
    var size: u32 = mem.availableMemory();
    write("available memory = {}mb", .{size});

    halt();
}
