const std = @import("std");

const test_targets = [_]std.zig.CrossTarget{
    .{}, // native
    .{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
    },
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addSharedLibrary(.{
        // const lib = b.addStaticLibrary(.{
        .name = "secp256k1",
        .target = target,
        .optimize = optimize,
        .version = .{ .major = 0, .minor = 4, .patch = 1 },
    });

    lib.addIncludePath(.{ .path = "include" });

    const src_files = [_][]const u8{
        "src/secp256k1.c",
    };

    lib.addCSourceFiles(
        &src_files,
        &.{},
    );

    lib.linkLibC();
    lib.installHeadersDirectory("include", "secp256k1");
    b.installArtifact(lib);
}
