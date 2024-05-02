const std = @import("std");
const print = std.debug.print;
const Child = std.process.Child;
const env = @import("env.zig");
const notify = @import("notify_channel.zig");
const Chameleon = @import("chameleon/src/chameleon.zig").Chameleon;

pub fn deploy() !bool {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const argv = [_][]const u8{ "fdk", "theme", "sync" };
    var child = Child.init(&argv, allocator);
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;
    try child.spawn();
    const term = try child.wait();
    if (term.Exited == 0) return true else return false;
}

pub fn setenv(args: []const []const u8) !void {
    comptime var cham = Chameleon.init(.Auto);
    if (!std.mem.eql(u8, args[2][0..11], "WEBHOOK_URL")) {
        return print(cham.red().fmt("Invalid Key, Key should be WEBHOOK_URL"), .{});
    }
    _ = std.Uri.parse(args[2][12..]) catch {
        return print(cham.red().fmt("Invalid Webhook URL"), .{});
    };
    _ = try env.setEnv(args[2][0..11], args[2][12..]);
}

pub fn getenv(_: []const []const u8, allocator: std.mem.Allocator, printURL: bool) ![:0]u8 {
    comptime var cham = Chameleon.init(.Auto);

    const key: [:0]const u8 = "WEBHOOK_URL";
    const webhookURLptr = env.getEnv(key);
    if (webhookURLptr == null) {
        std.debug.print(cham.red().fmt("Webhook URL not set!"), .{});
        std.process.exit(0);
    }

    const webhookURL = (std.mem.Allocator.dupeZ(allocator, u8, std.mem.sliceTo(webhookURLptr.?, 0)) catch unreachable);
    const parsedWebhookURL = if (std.Uri.parse(webhookURL)) |result| result else |_| {
        print(cham.red().fmt("Invalid webhook URI"), .{});
        std.process.exit(0);
    };
    if (printURL)
        print("WEBHOOK_URL={any}", .{parsedWebhookURL});
    return webhookURL;
}

pub fn upgrade() !void {
    comptime var cham = Chameleon.init(.Auto);
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const argv = [_][]const u8{ "sh", "/Users/admin/.nfdk/bin/upgrade.sh" };
    var child = Child.init(&argv, allocator);
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;
    try child.spawn();
    const term = try child.wait();
    if (term.Exited != 0) {
        std.debug.print(cham.red().fmt("Upgrade Failed\n"), .{});
    } else {
        std.debug.print(cham.green().fmt("Successfully Upgraded\n"), .{});
    }
}

pub fn getHelp() !void {
    const help =
        \\
        \\ Commands:
        \\ nfdk theme sync                                       To deploy theme and notify
        \\ nfdk get key                                          Displays the Webhook URL
        \\ nfdk set WEBHOOK_URL=<URL>(Without any quotes)        Sets the webhook URl
        \\ nfdk upgrade                                          Upgrades to latest version
        \\ nfdk help or --help                                   Displays help
        \\
    ;
    std.debug.print("{s}", .{help});
}
