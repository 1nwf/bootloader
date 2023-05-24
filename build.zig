const std = @import("std");
const CrossTarget = std.zig.CrossTarget;
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
    var target: CrossTarget = .{
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
        .root_source_file = .{ .path = "stage_2/src/main.zig" },
        .target = target,
        .optimize = optimize,
        .linkage = .static,
    });
    exe.strip = true;
    exe.setLinkerScriptPath(.{ .path = "link.ld" });

    const options = b.addOptions();
    const kernel_size = b.option(usize, "kernel_size", "size of kernel") orelse 30;
    options.addOption(usize, "kernel_size", kernel_size);

    exe.addOptions("build_options", options);
    const nasm_sources = [_][]const u8{
        "stage_2/src/entry.asm",
        "boot_sector/boot.asm",
    };

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).

    std.build.installArtifact(b, exe);

    const nasm_out = compileNasmSource(b, &nasm_sources);
    for (nasm_out) |out| {
        exe.addObjectFileSource(.{ .path = out });
    }

    const bin = exe.addObjCopy(.{ .basename = "bootloader.bin", .format = .bin });
    const install_step = b.addInstallBinFile(bin.getOutputSource(), bin.basename);
    b.default_step.dependOn(&install_step.step);
}

fn replaceExtension(b: *std.Build, path: []const u8, new_extension: []const u8) []const u8 {
    const basename = std.fs.path.basename(path);
    const ext = std.fs.path.extension(basename);
    return b.fmt("{s}{s}", .{ basename[0 .. basename.len - ext.len], new_extension });
}

fn compileNasmSource(b: *std.Build, comptime nasm_sources: []const []const u8) [nasm_sources.len][]const u8 {
    const compile_step = b.step("nasm", "compile nasm source");

    var outputSources: [nasm_sources.len][]const u8 = undefined;
    for (nasm_sources, 0..) |src, idx| {
        const out = replaceExtension(b, src, ".o");
        const create_bin = b.addSystemCommand(&.{ "nasm", "-f", "elf32", src, "-o", out });
        outputSources[idx] = out;

        compile_step.dependOn(&create_bin.step);
    }

    b.default_step.dependOn(compile_step);
    return outputSources;
}
