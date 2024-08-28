const std = @import("std");
const glad = @import("compiled/glad.zig");
const glfw = @import("compiled/glfw.zig");

pub fn main() !void {
    if (glfw.glfwInit() == glfw.GLFW_FALSE) return error.GLFWFailedToInitialize;
    defer glfw.glfwTerminate();
    _ = glfw.glfwSetErrorCallback(error_callback);
    glfw.glfwWindowHint(glfw.GLFW_RESIZABLE, glfw.GLFW_FALSE);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_PROFILE, glfw.GLFW_OPENGL_CORE_PROFILE);
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MINOR, 6);
    const gwindow = glfw.glfwCreateWindow(1024, 768, "GLFW With Zig", null, null) orelse return error.GLFWWindowFailedToInitialize;
    defer glfw.glfwDestroyWindow(gwindow);
    glfw.glfwMakeContextCurrent(gwindow);
    if (glad.gladLoadGLLoader(@ptrCast(&glfw.glfwGetProcAddress)) == glad.GL_FALSE) return error.GLADFailedToInitialize;
    std.debug.print("{s}\n", .{glfw.glGetString(glfw.GL_VERSION)});

    var width: c_int = undefined;
    var height: c_int = undefined;
    glfw.glfwGetFramebufferSize(gwindow, &width, &height);
    glfw.glViewport(0, 0, width, height);
    _ = glfw.glfwSetKeyCallback(gwindow, key_callback);
    const vertices = [_]f32{
        -1, -1, 0,
        1,  -1, 0,
        0,  1,  0,
    };
    var shader_program: c_uint = undefined;
    {
        var status: c_int = undefined;
        var error_msg: [512]u8 = undefined;
        var error_msg_len: c_int = undefined;
        const shader_vert: c_uint = glad.glCreateShader(glad.GL_VERTEX_SHADER);
        glad.glShaderSource(shader_vert, 1, @ptrCast(&@embedFile("shaders/shader.vert")), 0);
        defer glad.glDeleteShader(shader_vert);
        glad.glCompileShader(shader_vert);
        glad.glGetShaderiv(shader_vert, glad.GL_COMPILE_STATUS, &status);
        if (status == glad.GL_FALSE) {
            glad.glGetShaderInfoLog(shader_vert, 512, &error_msg_len, &error_msg);
            std.debug.print("Vertex Shader Compile Error => {s}\n", .{error_msg[0..@intCast(error_msg_len)]});
            return error.VertexShaderCompileError;
        }

        const shader_frag: c_uint = glad.glCreateShader(glad.GL_FRAGMENT_SHADER);
        glad.glShaderSource(shader_frag, 1, @ptrCast(&@embedFile("shaders/shader.frag")), 0);
        defer glad.glDeleteShader(shader_frag);
        glad.glCompileShader(shader_frag);
        glad.glGetShaderiv(shader_frag, glad.GL_COMPILE_STATUS, &status);
        if (status == glad.GL_FALSE) {
            glad.glGetShaderInfoLog(shader_frag, 512, &error_msg_len, &error_msg);
            std.debug.print("Fragment Shader Compile Error => {s}\n", .{error_msg[0..@intCast(error_msg_len)]});
            return error.FragmentShaderCompileError;
        }

        shader_program = glad.glCreateProgram();
        glad.glAttachShader(shader_program, shader_vert);
        glad.glAttachShader(shader_program, shader_frag);
        glad.glLinkProgram(shader_program);
        glad.glGetProgramiv(shader_program, glad.GL_LINK_STATUS, &status);
        if (status == glad.GL_FALSE) {
            glad.glGetProgramInfoLog(shader_program, 512, &error_msg_len, &error_msg);
            std.debug.print("Shader Program Link Error => {s}\n", .{error_msg[0..@intCast(error_msg_len)]});
            return error.ProgramShaderLinkError;
        }
    }
    defer glad.glDeleteProgram(shader_program);
    var vao: c_uint = undefined;
    glad.glGenVertexArrays(1, &vao);
    defer glad.glDeleteVertexArrays(1, &vao);
    glad.glBindVertexArray(vao);
    var vbo: c_uint = undefined;
    glad.glGenBuffers(1, &vbo);
    defer glad.glDeleteBuffers(1, &vbo);
    glad.glBindBuffer(glad.GL_ARRAY_BUFFER, vbo);
    glad.glBufferData(glad.GL_ARRAY_BUFFER, @intCast(@sizeOf(@TypeOf(vertices))), &vertices, glad.GL_STATIC_DRAW);
    glad.glVertexAttribPointer(0, 3, glad.GL_FLOAT, glad.GL_FALSE, @intCast(3 * @sizeOf(f32)), @ptrFromInt(0));
    glad.glEnableVertexAttribArray(0);
    glad.glBindVertexArray(0);

    while (glfw.glfwWindowShouldClose(gwindow) == glfw.GLFW_FALSE) {
        glad.glProgramUniform1f(shader_program, 1, @floatCast(glfw.glfwGetTime()));
        std.debug.print("{d}\r", .{glfw.glfwGetTime()});
        glfw.glClearColor(0, 0, 0, 1);
        glfw.glClear(glfw.GL_COLOR_BUFFER_BIT);
        glad.glUseProgram(shader_program);
        glad.glBindVertexArray(vao);
        glad.glDrawArrays(glad.GL_TRIANGLES, 0, 3);
        glfw.glfwSwapBuffers(gwindow);
        glfw.glfwPollEvents();
    }
}
fn error_callback(e: c_int, str: [*c]const u8) callconv(.C) void {
    std.debug.print("Error {}: {s}\n", .{ e, str });
}
fn key_callback(window: ?*glfw.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    if (key == glfw.GLFW_KEY_ESCAPE and action == glfw.GLFW_PRESS) glfw.glfwSetWindowShouldClose(window, glfw.GLFW_TRUE);
    std.debug.print("{} {} {} {}\n", .{ key, scancode, action, mods });
}
