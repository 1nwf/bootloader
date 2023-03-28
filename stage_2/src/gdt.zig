const write = @import("print.zig").write;
pub const Access = packed struct {
    access: u1,
    rw: u1,
    dc: u1,
    exec: u1,
    type: u1, // 0 = system segment. 1 = code or data segment
    dpl: u2, // descriptor privelage level
    present: u1,
    fn init() void {}
};

pub const Entry = packed struct {
    limit: u16,
    base: u24,
    access: Access,
    limit2: u4,
    flags: u4,
    base2: u8,

    pub fn bits(self: Entry) u64 {
        return @bitCast(u64, self);
    }

    pub fn empty() Entry {
        return @bitCast(Entry, @as(u64, 0));
    }
};

pub const CodeSegment = Entry{
    .limit = 0xFFFF,
    .base = 0,
    .access = .{ .present = 1, .dpl = 0, .type = 1, .exec = 1, .dc = 0, .rw = 1, .access = 0 },
    .limit2 = 0xF,
    .flags = 0b1100,
    .base2 = 0,
};

pub const DataSegment = Entry{
    .limit = 0xFFFF,
    .base = 0,
    .access = .{ .present = 1, .dpl = 0, .type = 1, .exec = 0, .dc = 0, .rw = 1, .access = 0 },
    .limit2 = 0xF,
    .flags = 0b1100,
    .base2 = 0,
};

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

// offsets in the gdt
const CODE_SEG = 0x08;
const DATA_SEG = 0x10;

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
    write("Loaded GDTR:  {}", .{ptr});
}
