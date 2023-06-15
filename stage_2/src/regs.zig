const Flags = packed struct {
    carry_flag: bool = false,
    reserved: u1 = 1,
    parity_flag: bool = false,
    reserved1: u1 = 0,
    adjust_flag: bool = false,
    reserved2: u1 = 0,
    zero_flag: bool = false,
    sign_flag: bool = false,
    trap_flag: bool = false,
    interrupt_enabled_flag: bool = false,
    direction_flag: bool = false,
    overflow_flag: bool = false,
    io_privilege_level: u2 = 0,
    nested_task_flag: bool = false,
    mode_flag: bool = false,
};

const ExtendedFlags = packed struct {
    resume_flag: bool = false,
    virtual_8086_mode: bool = false,
    alignment_smap_check: bool = false,
    virtual_interrupt_flag: bool = false,
    virtual_interrupt_pending: bool = false,
    cpuid: bool = false,
    reserved: u8 = 0,
    aes_key_schedule: bool = false,
    reserved1: bool = false,
};
const EFlags = packed struct {
    flags: Flags = .{},
    extended: ExtendedFlags = .{},
};
pub const Registers = extern struct {
    gs: u16 = 0,
    fs: u16 = 0,
    es: u16 = 0,
    ds: u16 = 0,
    eflags: EFlags = .{},
    ebp: u32 = 0,
    edi: u32 = 0,
    esi: u32 = 0,
    edx: u32 = 0,
    ecx: u32 = 0,
    ebx: u32 = 0,
    eax: u32 = 0,
};
