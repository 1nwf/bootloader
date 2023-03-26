const write = @import("print.zig").write;

const std = @import("std");
pub export fn mem_size() u32 {
    var ebx: u32 = 0;
    var ecx: u32 = 0;
    asm volatile (
        \\ clc
        \\ xor %%ecx, %%ecx
        \\ xor  %%ebx, %%ebx
        \\ mov  $0xE801, %%ax
        \\ int $0x15
        \\ jc err
        : [r1] "={ebx}" (ebx),
          [r2] "={ecx}" (ecx),
    );

    var totalMemMb = ((ebx * 64) + ecx) / 1024;
    return totalMemMb;
}

export fn err() callconv(.Naked) void {
    write("error occured", .{});
    return;
}

const MemMapEntry = extern struct {
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
    var ebx: u32 = 0;

    var next: u32 = 0;
    while (i < MAX_ENTRIES) : (i += 1) {
        var ptr = &memoryMap[i];

        asm volatile (
            \\ clc
            \\ int $0x15
            : [ret] "={ebx}" (ebx),
            : [buffer] "{di}" (ptr),
              [smap] "{edx}" (SMAP),
              [size] "{ecx}" (entry_size),
              [fn_num] "{eax}" (fn_num),
              [next] "{ebx}" (next),
        );

        // skip reserved and empty entries
        if (ptr.type == 2 or ptr.length == 0) {
            i -= 1;
        }

        next += 1;

        if (ebx == 0) {
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
        size += @truncate(usize, m.length / 1024);
    }

    return size / 1024;
}
