export fn entry() linksection(".entry") void {
    main();
}

fn halt() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}
pub fn main() noreturn {
    printStr("hello from zig!");
    halt();
}

fn print(c: u8) void {
    asm volatile (
        \\   mov $0x0e, %%ah
        \\   mov %[char], %%al
        \\   int $0x10  
        :
        : [char] "r" (c),
    );
}

fn printStr(comptime str: []const u8) void {
    print(0xA);
    print(0xD);
    inline for (str) |c| {
        print(c);
    }
}
