const std = @import("std");
const mem = std.mem;

const test_targets = [_]std.zig.CrossTarget{
    .{}, // native
    .{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
    },
};

pub fn build(b: *std.Build) void {
    const MAJOR = 0;
    const MINOR = 4;
    const PATCH = 1;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // build shared library
    const buildSharedLib = b.option([]const u8, "buildsharedlib", "BUILD_SHARED_LIB") orelse "OFF";
    // Schnorr signatures
    const schnorrSigMod = b.option(bool, "schnorrsig", "SECP256K1_ENABLE_MODULE_SCHNORRSIG") orelse false;

    const schnorrsig_c_flags: []const []const u8 = if (schnorrSigMod)
        &[_][]const u8{"-DSECP256K1_ENABLE_MODULE_SCHNORRSIG=ON"}
    else
        &[_][]const u8{};

    const secp256k1_c_flags = schnorrsig_c_flags;

    const lib = blk: {
        if (mem.eql(u8, buildSharedLib, "ON")) {
            const a = b.addSharedLibrary(.{
                .name = "secp256k1",
                .target = target,
                .optimize = optimize,
                .version = .{ .major = MAJOR, .minor = MINOR, .patch = PATCH },
            });
            break :blk a;
        } else {
            const a = b.addStaticLibrary(.{
                .name = "secp256k1",
                .target = target,
                .optimize = optimize,
                .version = .{ .major = MAJOR, .minor = MINOR, .patch = PATCH },
            });
            break :blk a;
        }
    };

    lib.addIncludePath(.{ .path = "include" });
    lib.addIncludePath(.{ .path = "src/modules" });

    const src_files = [_][]const u8{
        "src/secp256k1.c",
    };

    lib.addCSourceFiles(
        &src_files,
        secp256k1_c_flags,
    );

    lib.linkLibC();
    lib.installHeadersDirectory("include", "secp256k1");
    b.installArtifact(lib);
}
