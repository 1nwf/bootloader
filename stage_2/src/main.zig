export fn entry() linksection(".entry") void {
    main();
}

const write = @import("print.zig").write;

fn halt() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}
pub fn main() noreturn {
    write("hello from zig!", .{});
    halt();
}
