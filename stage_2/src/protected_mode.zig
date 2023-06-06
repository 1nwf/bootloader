pub inline fn enter_protected_mode(kernel_addr: u32) void {
    asm volatile (
        \\ cli
        \\ mov %%cr0, %%eax
        \\ or $0x1, %%eax
        \\ mov %%eax, %%cr0
        \\ ljmp $0x08, $init_pm
        \\
        \\ .code32
        \\ init_pm:
        \\ mov $0x10, %%ax
        \\ mov %%ax, %%ds
        \\ mov %%ax, %%ss
        \\ mov %%ax, %%es
        \\ mov %%ax, %%fs
        \\ mov %%ax, %%gs
    );

    jump_to_kernel(kernel_addr);
}

pub fn print(comptime str: []const u8) void {
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

const BootInfo = extern struct { mapAddr: u32, size: u32 };
pub var bootInfo = BootInfo{ .mapAddr = 0, .size = 0 };
export fn jump_to_kernel(kernel_addr: u32) void {
    asm volatile (
        \\ .code32
        \\ mov $0x9000, %%esp
        \\ mov %%esp, %%ebp
        \\ push %%ebx
        \\ jmp *%%eax
        :
        : [boot_info] "{ebx}" (&bootInfo),
          [kernel_addr] "{eax}" (kernel_addr),
    );
}
