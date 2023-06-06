const write = @import("print.zig").write;
const mem = @import("mem.zig");
const gdt = @import("gdt.zig");
const pm = @import("protected_mode.zig");
const kernel_size = @import("build_options").kernel_size;
const BootInfo = struct { mapAddr: u32, size: u32 };

fn halt() noreturn {
    while (true) {
        asm volatile (
            \\ cli
            \\ hlt
        );
    }
}

inline fn offset(x: u32) u16 {
    return @intCast(u16, (x & 0xf));
}

inline fn segment(x: u32) u16 {
    return @intCast(u16, (x & 0xffff0) >> 4);
}

extern var stage2_sector_size: u32;
export fn main(boot_drive: u16) noreturn {
    var count = mem.detectMemory();
    var map = mem.memoryMap[0..count];

    for (map) |e| {
        write("{}", .{e});
    }
    var size: u32 = mem.availableMemory();
    write("available memory = {}mb", .{size});

    const stage2_ssize = @ptrToInt(&stage2_sector_size);
    const kernel_lba_addr: u8 = @truncate(u8, stage2_ssize) + 1;
    const kernel_sector_size: u8 = (kernel_size / 512) + 1;

    write("stage2 size {}", .{stage2_ssize});
    write("kernel lba_addr {}", .{kernel_lba_addr});
    write("kernel sector size {}", .{kernel_sector_size});

    const kernel_addr = 0x1000;
    var d = DAP.init(kernel_sector_size, offset(kernel_addr), segment(kernel_addr), kernel_lba_addr, 0);

    pm.bootInfo.size = count;
    pm.bootInfo.mapAddr = @ptrToInt(&mem.memoryMap);

    read_disk(&d, @truncate(u8, boot_drive));

    gdt.init();
    pm.enter_protected_mode(kernel_addr);
    halt();
}

export fn disk_err() noreturn {
    write("error ccurred while loading data from disk", .{});
    halt();
}

// Disk Address Packet
const DAP = extern struct {
    size: u8,
    zero: u8 = 0,
    sectors: u16,
    buf_offset: u16,
    buf_segmment: u16,
    low_addr: u32,
    high_addr: u32,
    fn init(sectors: u8, buf_offset: u16, buf_segment: u16, low_addr: u32, high_addr: u32) DAP {
        return DAP{
            .size = @sizeOf(DAP),
            .sectors = sectors,
            .buf_offset = buf_offset,
            .buf_segmment = buf_segment,
            .low_addr = low_addr,
            .high_addr = high_addr,
        };
    }
};

fn read_disk(d: *DAP, boot_drive: u8) void {
    asm volatile (
        \\ mov $0x42, %%ah
        \\ int $0x13
        \\ jc disk_err
        :
        : [dap_addr] "{si}" (d),
          [drive] "{dl}" (boot_drive),
    );
}
