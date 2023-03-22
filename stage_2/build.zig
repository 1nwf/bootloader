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
        .abi = Target.Abi.none,
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
    // This *creates* a RunStep in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = exe.run();

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    //zig objcopy-O binary zig-out/bin/zkernel kernel.bin
    const exe_path = b.getInstallPath(exe.install_step.?.dest_dir, exe.out_filename);
    const bin = b.addSystemCommand(&.{ "zig", "objcopy", "-O", "binary", exe_path, "kernel.bin" });
    const bin_step = b.step("bin", "create .bin");
    bin_step.dependOn(b.getInstallStep());
    bin_step.dependOn(&bin.step);

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
    run_step.dependOn(&bin.step);

    // Creates a step for unit testing.
    const exe_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe_tests.setLinkerScriptPath(.{ .path = "link.ld" });

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&bin.step);
    test_step.dependOn(&exe_tests.step);
}
