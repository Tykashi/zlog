const std = @import("std");

pub const LogLevel = enum {
    info,
    warn,
    @"error",
};

pub const Logger = struct {
    arena: std.heap.ArenaAllocator,
    scope: []const u8,
    show_timestamp: bool,

    pub fn init(allocator: std.mem.Allocator, scope: []const u8, show_timestamp: bool) Logger {
        return Logger{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .scope = scope,
            .show_timestamp = show_timestamp,
        };
    }

    pub fn child(self: *Logger, scope: []const u8) Logger {
        const new_scope = try std.fmt.allocPrint(self.arena, "{s}.{s}", .{ self.scope, scope });

        return Logger{
            .arena = self.arena,
            .scope = new_scope,
            .show_timestamp = self.show_timestamp,
        };
    }

    fn level_color(level: LogLevel) []const u8 {
        return switch (level) {
            .info => "\x1b[32m", // green
            .warn => "\x1b[33m", // yellow
            .@"error" => "\x1b[31m", // red
        };
    }

    fn level_label(level: LogLevel) []const u8 {
        return switch (level) {
            .info => "INFO",
            .warn => "WARN",
            .@"error" => "ERROR",
        };
    }

    pub fn log(self: Logger, level: LogLevel, comptime fmt: []const u8, args: anytype) void {
        const out = std.io.getStdOut().writer();
        const color = level_color(level);
        const label = level_label(level);
        const reset = "\x1b[0m";

        if (self.show_timestamp) {
            var timestamp_buf: [64]u8 = undefined;
            const now = std.time.timestamp();
            const formatted = std.fmt.bufPrint(&timestamp_buf, "[{}]", .{now}) catch "[time_err]";
            out.print("{s} ", .{formatted}) catch return;
        }

        out.print("{s}[{s}]{s} {s}: ", .{ color, label, reset, self.scope }) catch return;
        out.print(fmt ++ "\n", args) catch return;
    }

    pub fn print_section_header(self: Logger, header: []const u8, fields: []const struct { label: []const u8, value: []const u8 }) void {
        _ = self;
        const out = std.io.getStdOut().writer();
        out.print("\x1b[36m[{s}] --------------------------------------------------\x1b[0m\n", .{header}) catch return;
        for (fields) |field| {
            out.print("{s:<14}: {s}\n", .{ field.label, field.value }) catch return;
        }
        out.print("-------------------------------------------------------------\n\n", .{}) catch return;
    }
};
