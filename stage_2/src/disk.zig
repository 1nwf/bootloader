const root = @import("root");
const std = @import("std");
const offset = root.offset;
const segment = root.segment;
const vga = @import("vga.zig");
const DAP = @import("root").DAP;
const Registers = @import("regs.zig").Registers;
pub extern fn bios_int(int_num: u8, out_regs: *Registers, in_regs: *const Registers) void;

const max_sectors = 50;
const buffer_len = max_sectors * 512;
pub fn copyMemory(src: []u8, addr: usize) void {
    var dest = createSlice(addr, buffer_len);
    @memcpy(dest, src);
}

fn copyMem(dest: []u8, src: []u8) void {
    for (0..buffer_len) |idx| {
        dest[idx] = src[idx];
    }
}

fn createSlice(addr: usize, comptime size: u32) []u8 {
    var slice: []u8 = undefined;
    slice.ptr = @intToPtr([*]u8, addr);
    slice.len = size;
    return slice;
}

pub fn read_disk(sectors: u8, lba_start: u32, buff: u16, disk_num: usize) void {
    var dap = DAP.init(sectors, offset(buff), segment(buff), lba_start, 0);
    const dap_addr = @ptrToInt(&dap);
    var in_regs = Registers{
        .eax = 0x4200,
        .esi = offset(dap_addr),
        .ds = segment(dap_addr),
        .edx = disk_num,
    };

    const out = int(0x13, &in_regs);
    if (out.eflags.flags.carry_flag) {
        vga.writeln("disk load carry set", .{});
        root.halt();
    }
}

fn int(int_num: u8, in_regs: *Registers) *Registers {
    bios_int(int_num, in_regs, in_regs);
    return in_regs;
}

pub fn load_kernel(kernel_size: usize, lba_start: u32, disk_num: u32) void {
    var start_addr: u32 = 0x100000;
    var low_mem = createSlice(0x1000, buffer_len);
    var sectors_left = kernel_size;
    while (sectors_left != 0) {
        var to_read: u8 = @min(sectors_left, max_sectors);
        const lba_offset = kernel_size - sectors_left;
        const lba = lba_start + lba_offset;

        read_disk(to_read, lba, 0x1000, disk_num);
        sectors_left -= to_read;
        copyMemory(low_mem, start_addr);

        start_addr += (@as(usize, to_read) * 512);
    }
}
