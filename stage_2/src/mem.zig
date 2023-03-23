const write = @import("print.zig").write;
pub export fn mem_size() u32 {
    asm volatile (
        \\ clc
        \\ xor %%ecx, %%ecx
        \\ xor  %%edx, %%edx
        \\ mov  $0xE801, %%ax
        \\ int $0x15
        \\ jc err
    );

    return read_mem_size();
}

// ebx = memory above 16 mb in 64kb chunks
// ecx = memory between 1mb and 16mb in kb
export fn read_mem_size() u32 {
    var ecx = read_ecx();
    var ebx = read_ebx();

    var totalMemMb = ((ebx * 64) + ecx) / 1024;

    return totalMemMb;
}

fn read_ebx() u32 {
    return asm volatile (""
        : [ret] "={ebx}" (-> u32),
    );
}

fn read_ecx() u32 {
    return asm volatile (""
        : [ret] "={ecx}" (-> u32),
    );
}

export fn err() callconv(.Naked) void {
    write("error occured", .{});
    return;
}
