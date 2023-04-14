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
    const kernel_lba_addr: u8 = @truncate(u8, stage2_ssize) + 1;
    write("kernel lba address is {}", .{kernel_lba_addr});

    const kernel_sector_size: u8 = (kernel_size / 512) + 1;

    write("kernel sector size is {}", .{kernel_sector_size});

    pm.bootInfo.size = count;
    pm.bootInfo.mapAddr = @ptrToInt(&mem.memoryMap);

    const d = DAP.init(kernel_sector_size, 0x1000, 0, kernel_lba_addr, 0);

    read_disk(d, @truncate(u8, boot_drive));

    gdt.init();
    pm.enter_protected_mode();
    halt();
}

export fn disk_err() void {
    write("error ccurred while loading data from disk", .{});
}

// Disk Address Packet
const DAP = packed struct {
    size: u8,
    reseverd: u8 = 0,
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

fn read_disk(d: DAP, boot_drive: u8) void {
    asm volatile (
        \\ mov $0x42, %%ah
        \\ int $0x13
        \\ jc disk_err
        :
        : [dap_addr] "{si}" (&d),
          [drive] "{dl}" (boot_drive),
    );
}
