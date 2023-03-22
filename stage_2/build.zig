const std = @import("std");
const CrossTarget = std.build.CrossTarget;
const Target = std.Target;
const Step = std.Build.Step;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    // const target = b.standardTargetOptions(.{});
    const target = .{
        .cpu_arch = .x86,
        .os_tag = Target.Os.Tag.freestanding,
        .abi = Target.Abi.code16,
        .ofmt = .elf,
        .cpu_model = .{ .explicit = &Target.x86.cpu.i386 },
    };

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    // const optimize = b.standardOptimizeOption(.{});
    const optimize = .ReleaseFast;

    const exe = b.addExecutable(.{
        .name = "stage2",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
        .linkage = .static,
    });
    // exe.strip = true;
    exe.setLinkerScriptPath(.{ .path = "link.ld" });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    exe.install();

    const exe_path = b.getInstallPath(exe.install_step.?.dest_dir, exe.out_filename);
    const create_bin = b.addSystemCommand(&.{ "zig", "objcopy", "-O", "binary", exe_path, "kernel.bin" });
    const bin_step = b.step("bin", "create .bin");
    bin_step.dependOn(b.getInstallStep());
    bin_step.dependOn(&create_bin.step);
}
