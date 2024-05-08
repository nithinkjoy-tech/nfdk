pub extern "C" fn getenv(name: [*:0]const u8) ?[*:0]u8;
const std = @import("std");
const Child = std.process.Child;
const Chameleon = @import("chameleon/src/chameleon.zig").Chameleon;

pub fn setEnv(name: []const u8, value: []const u8) !void {
    comptime var cham = Chameleon.init(.Auto);
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // TODO: remove hardcoded path
    const argv = [_][]const u8{ "sh", "/Users/admin/.nfdk/bin/set_env.sh", name, value };
    var child = Child.init(&argv, allocator);
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;
    try child.spawn();
    const term = try child.wait();
    if (term.Exited != 0) {
        std.debug.print(cham.red().fmt("Failed to set Webhook URL\n"), .{});
    } else {
        std.debug.print(cham.green().fmt("Webhook URL set. Please restart your terminal\n"), .{});
    }
}

pub fn getEnv(name: [*:0]const u8) ?[*:0]const u8 {
    return getenv(name);
}
