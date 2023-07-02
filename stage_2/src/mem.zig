const bios_int = @import("root").bios_int;
const Registers = @import("regs.zig").Registers;

const std = @import("std");
fn mem_size() u32 {
    const in_regs = Registers{ .eax = 0xE801 };
    var out_regs = Registers{};
    bios_int(0x15, &out_regs, &in_regs);

    var totalMemMb = ((out_regs.ebx * 64) + out_regs.ecx) / 1024;
    return totalMemMb;
}

pub const MemMapEntry = extern struct {
    base: u64,
    length: u64,
    type: u32,
    acpi: u32,
};

// http://www.brokenthorn.com/Resources/OSDev17.html
// https://wiki.osdev.org/Detecting_Memory_(x86)#Getting_an_E820_Memory_Map

// Input
// EAX = 0x0000E820
// EBX = continuation value or 0 to start at beginning of map
// ECX = size of buffer for result (Must be >= 20 bytes)
// EDX = 0x534D4150h ('SMAP')
// ES:DI = Buffer for result

// Return
// CF = clear if successful
// EAX = 0x534D4150h ('SMAP')
// EBX = offset of next entry to copy from or 0 if done
// ECX = actual length returned in bytes
// ES:DI = buffer filled
// If error, AH containes error code

const MAX_ENTRIES = 20;
pub var memoryMap = std.mem.zeroes([MAX_ENTRIES]MemMapEntry);
var mapEntries: ?u32 = null;
pub fn detectMemory() u32 {
    const SMAP: u32 = 0x534D4150;
    const entry_size: u16 = @sizeOf(MemMapEntry);
    const fn_num: u32 = 0xe820;

    var i: u32 = 0;

    var next: u32 = 0;
    while (i < MAX_ENTRIES) : (i += 1) {
        var ptr = &memoryMap[i];

        const in_regs = Registers{ .edi = @intFromPtr(ptr), .edx = SMAP, .ecx = entry_size, .eax = fn_num, .ebx = next };
        var out_regs = Registers{};
        bios_int(0x15, &out_regs, &in_regs);

        // skip reserved and empty entries
        if (ptr.type == 2 or ptr.length == 0) {
            i -= 1;
        }

        next += 1;

        if (out_regs.ebx == 0) {
            i += 1;
            break;
        }
    }

    mapEntries = i;
    return i;
}

pub fn availableMemory() u32 {
    var count: u32 = 0;
    if (mapEntries) |n| {
        count = n;
    } else {
        count = detectMemory();
    }
    var regions = memoryMap[0..count];
    var size: u32 = 0;

    for (regions) |m| {
        size += @truncate(m.length / 1024);
    }

    return size / 1024;
}
