const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const vulkan_dep = b.dependency("vulkan_headers", .{});
    const vulkan_registry = vulkan_dep.path("registry/vk.xml").getPath(b);

    const vkzig = b.dependency("vulkan_zig", .{
        .registry = vulkan_registry,
    });

    const wf = b.addWriteFiles();
    const vma_src = wf.add("vk_mem_alloc.cpp",
        \\#define VMA_IMPLEMENTATION
        \\#include "vk_mem_alloc.h"
    );

    const vma = b.addStaticLibrary(.{
        .name = "vma",
        .target = target,
        .optimize = optimize,
    });
    vma.linkLibCpp();
    vma.addIncludePath(b.path("."));
    vma.addIncludePath(vulkan_dep.path("include"));
    vma.addCSourceFile(.{ .file = vma_src });

    const vma_zig = b.addModule("vma-zig", .{
        .root_source_file = b.path("src/root.zig"),
        .imports = &.{
            .{ .name = "vulkan-zig", .module = vkzig.module("vulkan-zig") },
        },
    });
    vma_zig.addIncludePath(b.path("."));
    vma_zig.addIncludePath(vulkan_dep.path("include"));
    vma_zig.linkLibrary(vma);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
