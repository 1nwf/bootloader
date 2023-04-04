const write = @import("print.zig").write;
pub const Access = packed struct {
    access: u1 = 0,
    rw: u1,
    dc: u1,
    exec: u1,
    type: u1, // 0 = system segment. 1 = code or data segment
    dpl: u2, // descriptor privelage level
    present: u1,

    const Code = Access{ .present = 1, .dpl = 0, .type = 1, .exec = 1, .dc = 0, .rw = 1, .access = 0 };
    const Data = Access{ .present = 1, .dpl = 0, .type = 1, .exec = 0, .dc = 0, .rw = 1, .access = 0 };
};

const Flags = packed struct {
    reserved: u1 = 0,
    // if set, defines if the segment is a 32-bit segment. else it is a 16-bit segment
    is_32bit: u1,
    // if set, defines if the segment is a 64-bit code segment
    long_mode: u1,
    // indicates how the limit value should be interpreted. if set, the limit is in 4 Kib blocks
    granularity: u1,
};

pub const Entry = packed struct {
    limit_low: u16,
    base_low: u24,
    access: Access,
    limit_high: u4,
    flags: Flags,
    base_high: u8,

    pub fn bits(self: Entry) u64 {
        return @bitCast(u64, self);
    }

    pub fn empty() Entry {
        return @bitCast(Entry, @as(u64, 0));
    }

    fn init(base: u32, limit: u20, access: Access, flags: Flags) Entry {
        // zig fmt: off
        return Entry{
            .limit_low = @truncate(u16, limit & 0xFFFF),
            .limit_high = @truncate(u4,limit >> 16),
            .base_low = @truncate(u24, base & ~@as(u32, (0xFF << 24))),
            .base_high = @truncate(u8,base >> 24),
            .access = access,
            .flags = flags
        };
        // zig fmt: on
    }
};

pub const CodeSegment = Entry.init(0, 0xFFFFF, Access.Code, .{ .is_32bit = 1, .long_mode = 0, .granularity = 0 });

pub const DataSegment = Entry.init(0, 0xFFFFF, Access.Data, .{ .is_32bit = 1, .long_mode = 0, .granularity = 0 });

pub const GDT = [_]Entry{ Entry.empty(), CodeSegment, DataSegment };

pub const GDTR = packed struct {
    size: u16,
    base: u32,
    fn init(base: u32, size: u16) GDTR {
        return GDTR{ .base = base, .size = size };
    }

    export fn load(self: *GDTR) void {
        asm volatile (
            \\ cli
            \\ lgdt (%[addr])
            \\ sti
            :
            : [addr] "r" (self),
        );
    }
};

var gdtr = GDTR.init(0, @sizeOf(@TypeOf(GDT)) - 1);

pub fn init() void {
    gdtr.base = @ptrToInt(&GDT);
    gdtr.load();
}

export fn storedGDT() void {
    var ptr = GDTR.init(0, 0);
    asm volatile (
        \\ sgdtl %[val]
        : [val] "=m" (ptr),
    );

    var data = @intToPtr(*@TypeOf(GDT), ptr.base);
    write("GDT Entries:", .{});
    for (data) |e| {
        write("{}", .{e});
    }

    write("Loaded GDTR:  {}", .{ptr});
}