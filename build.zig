const std = @import("std");
const Pkg = std.build.Pkg;

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("dis", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();
    exe.single_threaded = true;

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const trun_cmd = std.build.RunStep.create(b, "dis");
    if (b.args) |args| {
        trun_cmd.addArgs(args);
    }
    const trun_step = b.step("trun", "Run the app");
    trun_step.dependOn(&trun_cmd.step);
}
