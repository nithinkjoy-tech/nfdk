const std = @import("std");
const Child = std.process.Child;
const print = std.debug.print;
const command = @import("command.zig");
const notifyChannel = @import("notify_channel.zig");
const Chameleon = @import("chameleon/src/chameleon.zig").Chameleon;

pub fn main() !void {
    comptime var cham = Chameleon.init(.Auto);
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    if (args.len == 1 or std.mem.eql(u8, args[1], "help") or std.mem.eql(u8, args[1], "--help")) return try command.getHelp();

    if (args.len == 1 or std.mem.eql(u8, args[1], "upgrade")) return try command.upgrade();

    if (args.len != 3)
        return print(cham.red().fmt("Command not found in nfdk please use fdk for following command\n"), .{});

    if (std.mem.eql(u8, args[1], "theme") and std.mem.eql(u8, args[2], "sync")) {
        const res = try command.deploy();
        if (res) {
            const webhookURL = try command.getenv(args, arena_allocator, false);
            try notifyChannel.notify(webhookURL);
        } else {
            const argv = [_][]const u8{ "sh", "/Users/admin/.nfdk/bin/deployment_fail.sh" };
            var child = Child.init(&argv, arena_allocator);
            child.stdout_behavior = .Ignore;
            child.stderr_behavior = .Ignore;
            try child.spawn();
            _ = try child.wait();
        }
    } else if (std.mem.eql(u8, args[1], "set")) {
        _ = try command.setenv(args);
    } else if (std.mem.eql(u8, args[1], "get") and std.mem.eql(u8, args[2], "key")) {
        _ = try command.getenv(args, arena_allocator, true);
    } else {
        print(cham.red().fmt("Command not found in nfdk please use fdk for following command\n"), .{});
    }
    defer std.process.argsFree(allocator, args);
}
