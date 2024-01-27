const std = @import("std");
const mem = std.mem;

pub fn build(b: *std.Build) !void {
    const LIB_NAME = "secp256k1";
    const MAJOR = 0;
    const MINOR = 4;
    const PATCH = 1;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // build shared library
    const buildSharedLib = b.option([]const u8, "buildsharedlib", "BUILD_SHARED_LIB") orelse "OFF";
    // Schnorr signatures
    const schnorrSigMod = b.option(bool, "schnorrsig", "SECP256K1_ENABLE_MODULE_SCHNORRSIG") orelse false;
    const ecdhMod = b.option([]const u8, "ecdhmod", "SECP256K1_ENABLE_MODULE_ECDH") orelse "OFF";

    // const schnorrsig_c_flags: []const []const u8 = if (schnorrSigMod)
    //     &[_][]const u8{"-DSECP256K1_ENABLE_MODULE_SCHNORRSIG=ON"}
    // else
    //     &[_][]const u8{};
    const schnorrsig_c_flag = blk: {
        if (schnorrSigMod) {
            break :blk "-DSECP256K1_ENABLE_MODULE_SCHNORRSIG=ON";
        }
        break :blk "";
    };

    std.debug.print("schnorrsig_c_flag: {s}\n", .{schnorrsig_c_flag});

    // const ecdhmod_c_flags: []const []const u8 = if (mem.eql(u8, ecdhMod, "ON"))
    //     &[_][]const u8{"-DSECP256K1_ENABLE_MODULE_ECDH=ON"}
    // else
    //     &[_][]const u8{};
    const ecdhmod_c_flag: []const []const u8 = blk: {
        if (mem.eql(u8, ecdhMod, "ON")) {
            const flag: []const []const u8 = &[_][]const u8{"-DSECP256K1_ENABLE_MODULE_ECDH=ON"};
            break :blk flag;
        }
        break :blk &[_][]const u8{};
    };

    std.debug.print("ecdmod: {s}\n", .{ecdhmod_c_flag});

    const secp256k1_c_flags = ecdhmod_c_flag;
    // const secp256k1_c_flags = schnorrsig_c_flags;

    const lib = blk: {
        if (mem.eql(u8, buildSharedLib, "ON")) {
            const a = b.addSharedLibrary(.{
                .name = LIB_NAME,
                .target = target,
                .optimize = optimize,
                .version = .{ .major = MAJOR, .minor = MINOR, .patch = PATCH },
            });
            break :blk a;
        } else {
            const a = b.addStaticLibrary(.{
                .name = LIB_NAME,
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

    lib.addCSourceFiles(.{
        .files = &src_files,
        .flags = secp256k1_c_flags,
    });

    lib.linkLibC();
    lib.installHeadersDirectory("include", "secp256k1");
    b.installArtifact(lib);

    // build the pre-computed library first
    const secp256k1_precomputed = b.addStaticLibrary(.{
        .name = "secp256k1_precomputed",
        .target = target,
        .optimize = optimize,
        .version = .{ .major = MAJOR, .minor = MINOR, .patch = PATCH },
    });

    const secp256k1_sources = [_][]const u8{
        "src/precomputed_ecmult.c",
        "src/precomputed_ecmult_gen.c",
    };

    const secp256k1_precomputed_c_flags = &[_][]const u8{""};

    secp256k1_precomputed.addCSourceFiles(.{
        .files = &secp256k1_sources,
        .flags = secp256k1_precomputed_c_flags,
    });

    b.installArtifact(secp256k1_precomputed);

    // built test exe's
    const tests_exe = b.addExecutable(.{
        .name = "tests_c",
        .root_source_file = null,
        .target = target,
        .optimize = optimize,
    });
    tests_exe.addCSourceFile(.{
        .file = .{ .path = "src/tests.c" },
        .flags = &.{},
    });

    tests_exe.addIncludePath(.{ .path = "include" });
    tests_exe.addIncludePath(.{ .path = "contrib" });
    tests_exe.linkLibC();
    tests_exe.linkLibrary(secp256k1_precomputed);

    b.installArtifact(tests_exe);

    const ecdsa_example = b.addExecutable(.{
        .name = "ecdsa",
        .root_source_file = null,
        .target = target,
        .optimize = optimize,
    });
    ecdsa_example.addCSourceFile(.{
        .file = .{ .path = "examples/ecdsa.c" },
        .flags = &.{},
    });
    ecdsa_example.addIncludePath(.{ .path = "include" });
    ecdsa_example.linkLibC();
    ecdsa_example.linkLibrary(lib);
    ecdsa_example.linkLibrary(secp256k1_precomputed);

    b.installArtifact(ecdsa_example);
}
