const kernel_size = @import("build_options").kernel_size;
const vga = @import("vga.zig");
const Registers = @import("regs.zig").Registers;
const mem = @import("mem.zig");
const disk = @import("disk.zig");
pub extern fn bios_int(int_num: u8, out_regs: *Registers, in_regs: *const Registers) void;

pub const BootInfo = struct { mem_map: []mem.MemMapEntry };

pub fn halt() noreturn {
    while (true) {
        asm volatile (
            \\ cli
            \\ hlt
        );
    }
}
pub inline fn segment(x: u32) u16 {
    return @intCast((x & 0xffff0) >> 4);
}

pub inline fn offset(x: u32) u16 {
    return @intCast((x & 0x0f));
}

extern var stage2_sector_size: u32;

export fn main(boot_drive: u32) noreturn {
    vga.init(.{});

    const entryCount = mem.detectMemory();
    vga.writeln("entry count {}", .{entryCount});

    for (mem.memoryMap[0..entryCount]) |entry| {
        vga.writeln("mem map: {x} ... {x}", .{ entry.base, entry.length });
    }

    const stage2_ssize = @intFromPtr(&stage2_sector_size);
    const kernel_lba_addr: u8 = @as(u8, @truncate(stage2_ssize)) + 1;
    const kernel_sector_size: usize = (kernel_size / 512) + 1;

    const kernel_addr: u32 = 0x100000;
    read_disk(kernel_sector_size, kernel_lba_addr, boot_drive);

    var bootInfo = BootInfo{ .mem_map = mem.memoryMap[0..entryCount] };

    asm volatile (
        \\ push %%ebx
        \\ jmp *%%eax
        :
        : [kernel_addr] "{eax}" (kernel_addr),
          [bootInfo] "{ebx}" (&bootInfo),
    );

    halt();
}

// Disk Address Packet
pub const DAP = extern struct {
    size: u8,
    zero: u8 = 0,
    sectors: u16,
    buf_offset: u16,
    buf_segmment: u16,
    low_addr: u32,
    high_addr: u32,
    pub fn init(sectors: u8, buf_offset: u16, buf_segment: u16, low_addr: u32, high_addr: u32) DAP {
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

fn bios_print() void {
    const in_regs = Registers{ .eax = 0x0e61 };
    var out_regs = Registers{};
    bios_int(0x10, &out_regs, &in_regs);
}

pub const DriveParameters = packed struct {
    buffer_size: u16,
    info_flags: u16,
    cylinders: u32,
    heads: u32,
    sectors: u32,
    lba_count: u64,
    bytes_per_sector: u16,
    edd: u32,
};

fn getDriveInfo(drive: u32) DriveParameters {
    var drive_params: DriveParameters = undefined;
    drive_params.buffer_size = @sizeOf(DriveParameters);
    const in_regs = Registers{
        .eax = 0x4800,
        .edx = drive,
        .ds = segment(@intFromPtr(&drive_params)),
        .esi = offset(@intFromPtr(&drive_params)),
    };

    var out_regs = Registers{};
    bios_int(0x13, &out_regs, &in_regs);

    if (out_regs.eflags.flags.carry_flag) {
        vga.writeln("unable to get disk info", .{});
        halt();
    }

    return drive_params;
}

export fn read_disk(sectors: usize, lba_start: u32, disk_num: u32) void {
    disk.load_kernel(sectors, lba_start, disk_num);
}
