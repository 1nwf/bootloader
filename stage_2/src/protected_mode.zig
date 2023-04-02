pub inline fn enter_protected_mode() void {
    asm volatile (
        \\ cli
        \\ mov %%cr0, %%eax
        \\ or $0x1, %%eax
        \\ mov %%eax, %%cr0
        \\ ljmp $0x08, $init_pm
    );
}

export fn init_pm() callconv(.Naked) void {
    asm volatile (
        \\    mov $0x10, %%ax
        \\    mov %%ax, %%ds
        \\    mov %%ax, %%ss
        \\    mov %%ax, %%es
        \\    mov %%ax, %%fs
        \\    mov %%ax, %%gs
    );

    print("switched to protected mode");

    while (true) {
        asm volatile (
            \\ hlt
        );
    }
}

fn print(comptime str: []const u8) void {
    for (str, 0..) |c, idx| {
        asm volatile (
            \\ mov $0xb8000, %%eax
            \\ add %[idx],%%eax
            \\ movb %[c], (%%eax)
            :
            : [idx] "{ecx}" (idx * 2),
              [c] "{ebx}" (c),
        );
    }
}
