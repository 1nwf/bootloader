const bootInfo = @import("main.zig").bootInfo;
pub inline fn enter_protected_mode() void {
    asm volatile (
        \\ cli
        \\ mov %%cr0, %%eax
        \\ or $0x1, %%eax
        \\ mov %%eax, %%cr0
        \\ ljmp $0x08, $init_pm
    );
}

export fn init_pm() void {
    asm volatile (
        \\ .code32
        \\ mov $0x10, %%ax
        \\ mov %%ax, %%ds
        \\ mov %%ax, %%ss
        \\ mov %%ax, %%es
        \\ mov %%ax, %%fs
        \\ mov %%ax, %%gs
        \\
        \\ mov $0x9000, %%esp
        \\ mov %%esp, %%ebp
        \\ push %%ecx
        \\ jmp *%%ebx
    );

    // jump_to_kernel();
}

pub fn print(str: []const u8) void {
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

pub const BootInfo = extern struct { mapAddr: u32, size: u32 };
// pub var bootInfo = BootInfo{ .mapAddr = 0, .size = 0 };
inline fn jump_to_kernel() void {
    asm volatile (
        \\ .code32
        \\ mov $0x9000, %%esp
        \\ mov %%esp, %%ebp
        \\ push %%edx
        \\ mov $0x1000, %%eax
        \\ jmp *%%eax
        :
        : [boot_info] "{edx}" (&bootInfo),
    );
}
