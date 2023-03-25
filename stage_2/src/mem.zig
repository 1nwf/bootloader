const write = @import("print.zig").write;
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
