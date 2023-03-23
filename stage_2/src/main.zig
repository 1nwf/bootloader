export fn entry() linksection(".entry") void {
    main();
}

const write = @import("print.zig").write;

const mem = @import("mem.zig");

fn halt() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}
inline fn main() noreturn {
    write("hello from zig!", .{});

    var mem_size = mem.mem_size();
    write("mem size is {}mb", .{mem_size});

    halt();
}
