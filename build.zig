const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const glfw_lib = b.addStaticLibrary(.{
        .name = "glfw_lib",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    glfw_lib.addIncludePath(b.path("dependencies/glad/include/")); //`dependencies/glad/include/` because glad.c uses #include <glad/glad.h>
    glfw_lib.addCSourceFile(.{
        .file = b.path("dependencies/glad/src/glad.c"),
        .flags = &.{"-std=c99"},
    });
    glfw_lib.addCSourceFiles(.{ //Information to compile glfw for windows is based from https://www.glfw.org/docs/latest/compile.html
        .root = b.path("dependencies/glfw-3.4/src"),
        .files = &.{
            "context.c",        "egl_context.c",   "init.c",
            "input.c",          "monitor.c",       "null_init.c",
            "null_joystick.c",  "null_monitor.c",  "null_window.c",
            "osmesa_context.c", "platform.c",      "vulkan.c",
            "wgl_context.c",    "win32_init.c",    "win32_joystick.c",
            "win32_module.c",   "win32_monitor.c", "win32_thread.c",
            "win32_time.c",     "win32_window.c",  "window.c",
        },
        .flags = &.{ "-std=c99", "-D_GLFW_WIN32" },
    });
    glfw_lib.linkSystemLibrary("gdi32"); //Some libraries may be missing and/or need to be added for Windows
    glfw_lib.linkSystemLibrary("opengl32");
    b.installArtifact(glfw_lib);

    const exe = b.addExecutable(.{
        .name = "zig_glfw",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibrary(glfw_lib);
    b.installArtifact(exe);
    exe.step.dependOn(&glfw_lib.step);

    //Copy Translate C zig header files of glad and glfw to src/
    const glfw_header = b.addTranslateC(.{
        .root_source_file = b.path("dependencies/glfw-3.4/include/GLFW/glfw3.h"),
        .target = target,
        .optimize = optimize,
    });
    const glad_header = b.addTranslateC(.{
        .root_source_file = b.path("dependencies/glad/include/glad/glad.h"),
        .target = target,
        .optimize = optimize,
    });
    const wf = b.addWriteFiles();
    wf.addCopyFileToSource(glfw_header.getOutput(), "src/compiled/glfw.zig");
    wf.addCopyFileToSource(glad_header.getOutput(), "src/compiled/glad.zig");
    exe.step.dependOn(&wf.step);
    wf.step.dependOn(&glfw_header.step);
    wf.step.dependOn(&glad_header.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
