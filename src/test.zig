const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;
const fs = std.fs;

const KiloByte = 1024;
const MegaByte = 1024 * KiloByte;

test {
    const gpa = std.testing.allocator;
    var arena_allocator = std.heap.ArenaAllocator.init(gpa);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    var ctx = TestContext.init(arena);
    {
        const zig_exe_path = try std.process.getEnvVarOwned(arena, "ZIG_EXE");
        const zig_cc_compiler_args = [_][]const u8{ zig_exe_path, "cc" };
        const gcc_compiler_args = [_][]const u8{"gcc"};

        const common_dir_path = try fs.path.join(arena, &.{ fs.path.dirname(@src().file).?, "..", "tests", "common" });
        const zig_cc_dir_path = try fs.path.join(arena, &.{ fs.path.dirname(@src().file).?, "..", "tests", "zig_cc" });
        try ctx.addTestsFromDir(common_dir_path, &zig_cc_compiler_args);
        try ctx.addTestsFromDir(zig_cc_dir_path, &zig_cc_compiler_args);

        const gcc_dir_path = try fs.path.join(arena, &.{ fs.path.dirname(@src().file).?, "..", "tests", "gcc" });
        try ctx.addTestsFromDir(common_dir_path, &gcc_compiler_args);
        try ctx.addTestsFromDir(gcc_dir_path, &gcc_compiler_args);
    }

    try ctx.run();
}

const TestContext = struct {
    arena: std.mem.Allocator,
    tests: std.ArrayListUnmanaged(Test) = .{},
    const Self = @This();

    const TestConfig = struct {
        dwarf_version: u8,
        dwarf_bitness: u8,
        compiler_args: []const []const u8,
    };

    const Test = struct {
        name: []const u8,
        file_path: []const u8,
        expected_output: []const u8,
        config: TestConfig,
    };

    pub fn init(arena: std.mem.Allocator) Self {
        return Self{
            .arena = arena,
        };
    }

    pub fn getExpectedTestOutput(tc: *Self, src: []const u8) ![]const u8 {
        var start = std.mem.indexOf(u8, src, "//") orelse return error.EndOfFile;
        var line_it = std.mem.split(u8, src[start..], "\n");
        var result: []const u8 = "";
        while (line_it.next()) |line| {
            if (!std.mem.startsWith(u8, line, "//")) {
                return result;
            }
            result = try std.mem.concat(tc.arena, u8, &[_][]const u8{ result, line[2..], "\n" });
        }
        return result;
    }

    pub fn addTestsFromDir(tc: *Self, dir_path: []const u8, compiler_args: []const []const u8) !void {
        var dir = try std.fs.cwd().openIterableDir(dir_path, .{});
        defer dir.close();

        var it = try dir.walk(tc.arena);
        var filenames = std.ArrayList([]const u8).init(tc.arena);

        while (try it.next()) |entry| {
            if (entry.kind != .File) continue;

            const ext = std.fs.path.extension(entry.basename);
            if (std.mem.eql(u8, ext, ".c") or std.mem.eql(u8, ext, ".cpp")) {
                try filenames.append(try tc.arena.dupe(u8, entry.path));
            }
        }

        for (filenames.items) |filename| {
            const max_file_size = 10 * MegaByte;
            const src = try dir.dir.readFileAllocOptions(tc.arena, filename, max_file_size, null, 1, 0);
            const expected_output = try tc.getExpectedTestOutput(src);

            const configs = &[_]TestConfig{
                .{ .dwarf_version = 2, .dwarf_bitness = 32, .compiler_args = compiler_args },
                .{ .dwarf_version = 3, .dwarf_bitness = 32, .compiler_args = compiler_args },
                .{ .dwarf_version = 4, .dwarf_bitness = 32, .compiler_args = compiler_args },
                .{ .dwarf_version = 5, .dwarf_bitness = 32, .compiler_args = compiler_args },
                .{ .dwarf_version = 3, .dwarf_bitness = 64, .compiler_args = compiler_args },
                .{ .dwarf_version = 4, .dwarf_bitness = 64, .compiler_args = compiler_args },
                .{ .dwarf_version = 5, .dwarf_bitness = 64, .compiler_args = compiler_args },
            };
            for (configs) |config| {
                try tc.tests.append(tc.arena, Test{
                    .name = try std.fmt.allocPrint(tc.arena, "{s}_dwarf{d}_{d}bit_{s}", .{
                        fs.path.basename(compiler_args[0]),
                        config.dwarf_version,
                        config.dwarf_bitness,
                        std.fs.path.basename(filename),
                    }),
                    .file_path = try std.fs.path.join(tc.arena, &.{ dir_path, filename }),
                    .expected_output = expected_output,
                    .config = config,
                });
            }
        }
    }

    pub fn run(tc: *Self) !void {

        // Compile the exec
        {
            const zig_exe_path = try std.process.getEnvVarOwned(tc.arena, "ZIG_EXE");

            var args = std.ArrayList([]const u8).init(tc.arena);
            defer args.deinit();

            try args.append(zig_exe_path);
            try args.append("build");

            const result = try std.ChildProcess.exec(.{
                .allocator = tc.arena,
                .argv = args.items,
            });

            if (result.term.Exited != 0) {
                std.debug.print("{s}\n", .{result.stdout});
                std.debug.print("{s}\n", .{result.stderr});
            }

            try std.testing.expectEqual(result.term.Exited, 0);
        }

        var passed: u32 = 0;
        for (tc.tests.items) |t| {
            std.debug.print("Running {s}... ", .{t.name});

            var tmp = std.testing.tmpDir(.{});
            defer tmp.cleanup();
            const tmp_dir_path = try tmp.dir.realpathAlloc(tc.arena, ".");

            const output_basename = std.fs.path.basename(t.file_path);
            const output_filename = try std.mem.concat(tc.arena, u8, &[_][]const u8{
                output_basename[0 .. output_basename.len - std.fs.path.extension(output_basename).len],
                ".o",
            });
            const output_path = try std.fs.path.join(tc.arena, &.{ tmp_dir_path, output_filename });

            // Compile the source file
            {
                var args = std.ArrayList([]const u8).init(tc.arena);
                defer args.deinit();

                for (t.config.compiler_args) |arg| {
                    try args.append(arg);
                }
                try args.append(t.file_path);
                try args.append("-o");
                try args.append(output_path);
                try args.append("-c");
                try args.append(try std.fmt.allocPrint(tc.arena, "-gdwarf-{d}", .{t.config.dwarf_version}));
                try args.append(try std.fmt.allocPrint(tc.arena, "-gdwarf{d}", .{t.config.dwarf_bitness}));

                const result = try std.ChildProcess.exec(.{
                    .allocator = tc.arena,
                    .argv = args.items,
                });

                if (result.term.Exited != 0) {
                    std.debug.print("{s}\n", .{result.stdout});
                    std.debug.print("{s}\n", .{result.stderr});
                }
                try std.testing.expectEqual(result.term.Exited, 0);
            }

            // Run program
            {
                var args = std.ArrayList([]const u8).init(tc.arena);
                defer args.deinit();

                try args.append("./zig-out/bin/dis");
                try args.append(output_path);

                const result = try std.ChildProcess.exec(.{
                    .allocator = tc.arena,
                    .argv = args.items,
                });

                switch (result.term) {
                    .Exited => {
                        if (result.term.Exited != 0) {
                            std.debug.print("{s}\n", .{result.stdout});
                            std.debug.print("{s}\n", .{result.stderr});
                        }
                        try std.testing.expectEqual(result.term.Exited, 0);
                        if (!std.mem.eql(u8, t.expected_output, result.stdout)) {
                            var padding: usize = 0;
                            var lit = std.mem.split(u8, t.expected_output, "\n");
                            while (lit.next()) |line| {
                                padding = @maximum(padding, line.len);
                            }

                            std.debug.print("\n{s: >[1]} | Got\n", .{ "Expected", padding });
                            var exp_line_it = std.mem.split(u8, t.expected_output, "\n");
                            var got_line_it = std.mem.split(u8, result.stdout, "\n");
                            while (true) {
                                const exp_line_opt = exp_line_it.next();
                                const got_line_opt = got_line_it.next();

                                if (exp_line_opt == null and got_line_opt == null) {
                                    break;
                                }
                                const exp_line = if (exp_line_opt) |l| l else "";
                                const got_line = if (got_line_opt) |l| l else "";
                                if (std.mem.eql(u8, exp_line, got_line)) {
                                    std.debug.print("{s: <[2]} | {s}\n", .{ exp_line, got_line, padding });
                                } else {
                                    std.debug.print("{s: <[2]} # {s}\n", .{ exp_line, got_line, padding });
                                }
                            }

                            std.debug.print("Failed.\n", .{});
                            continue;
                        }
                    },
                    else => {
                        std.debug.print("Failed.\n", .{});
                        continue;
                    },
                }
            }

            passed += 1;
            std.debug.print("Passed.\n", .{});
        }

        std.debug.print("\nTest results: {}/{} passed\n", .{ passed, tc.tests.items.len });
    }
};
