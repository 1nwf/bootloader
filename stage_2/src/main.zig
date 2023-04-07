const write = @import("print.zig").write;
const mem = @import("mem.zig");
const gdt = @import("gdt.zig");

const pm = @import("protected_mode.zig");

fn halt() noreturn {
    while (true) {
        asm volatile (
            \\ cli
            \\ hlt
        );
    }
}

extern var stage2_sector_size: u32;
export fn main(boot_drive: u16) noreturn {
    write("running stage2...", .{});

    var count = mem.detectMemory();
    var map = mem.memoryMap[0..count];

    for (map) |e| {
        write("{}", .{e});
    }
    var size: u32 = mem.availableMemory();
    write("available memory = {}mb", .{size});

    const stage2_ssize = @ptrToInt(&stage2_sector_size);
    write("stage2 sector size is {}", .{stage2_ssize});
    const kernel_sector_start: u8 = @truncate(u8, stage2_ssize) + 2;
    write("kernel start sector is {}", .{kernel_sector_start});

    load_kernel(@truncate(u8, boot_drive), kernel_sector_start);

    gdt.init();
    pm.enter_protected_mode();
    asm volatile (
        \\ jmp *0x1000
    );

    halt();
}

export fn load_kernel(boot_drive: u8, sector_number: u8) void {
    asm volatile (
        \\ clc
        \\ xor %%ax , %%ax
        \\
        \\ mov $40, %%al // number of sectors to read
        \\
        \\ mov $0x00, %%dh // head number
        \\ mov $0x00, %%ch // cylindar number
        \\
        \\ mov $0x02, %%ah
        \\ int $0x13
        \\
        \\ jc disk_err
        :
        : [sector] "{cl}" (sector_number),
          [addr] "{bx}" (0x1000),
          [drive] "{dl}" (boot_drive),
    );
}

export fn disk_err() void {
    write("error ccurred while loading data from disk", .{});
}
