const std = @import("std");
const print = std.debug.print;
const Child = std.process.Child;
const http = std.http;
const Chameleon = @import("chameleon/src/chameleon.zig").Chameleon;
const ArrayList = std.ArrayList;

const arrayItems = struct {
    type: []const u8,
    text: []const u8,
    weight: ?[]const u8,

    pub fn init(_type: []const u8, text: []const u8, weight: ?[]const u8) arrayItems {
        return arrayItems{
            .type = _type,
            .text = text,
            .weight = weight,
        };
    }
};

const body = struct {
    type: []const u8,
    size: ?[]const u8,
    weight: ?[]const u8,
    text: ?[]const u8,
    items: ?[3]arrayItems,

    pub fn init(_type: []const u8, size: ?[]const u8, weight: ?[]const u8, text: ?[]const u8, items: ?[3]arrayItems) body {
        return body{
            .type = _type,
            .size = size,
            .weight = weight,
            .text = text,
            .items = items,
        };
    }
};

const mentioned = struct {
    id: []const u8,
    name: []const u8,

    pub fn init(id: []const u8, name: []const u8) mentioned {
        return mentioned{
            .id = id,
            .name = name,
        };
    }
};

const entities = struct {
    type: []const u8,
    text: []const u8,
    mentioned: mentioned,

    pub fn init(_type: []const u8, text: []const u8, _mentioned: mentioned) entities {
        return entities{
            .type = _type,
            .text = text,
            .mentioned = _mentioned,
        };
    }
};

const msteams = struct {
    entities: [1]entities,
};

const content = struct {
    type: []const u8,
    body: [22]body,
    version: []const u8,
    msteams: msteams,
};

const attachments = struct {
    contentType: []const u8,
    content: content,
};

const message = struct {
    type: []const u8,
    attachments: [1]attachments,
};

pub fn createBody(allocator: std.mem.Allocator, stream: *std.ArrayList(u8)) !*std.ArrayList(u8) {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var bodyList = std.ArrayList(body).init(gpa);
    var entitiesList = std.ArrayList(entities).init(gpa);

    try bodyList.append(body.init("TextBlock", "Medium", "Bolder", "Theme Deployed", null));
    try bodyList.append(body.init("TextBlock", null, null, "<at> </at>", null));

    const heads = [_][]const u8{ "HEAD~0", "HEAD~1", "HEAD~2", "HEAD~3", "HEAD~4", "HEAD~5", "HEAD~6", "HEAD~7", "HEAD~8", "HEAD~9" };
    for (0..10) |i| {
        const argv1 = ([_][]const u8{ "git", "log", "--format='%an'", "-n", "1", heads[i] });
        const argv2 = ([_][]const u8{ "git", "log", "-n", "1", "--pretty=format:'%ad IST'", "--date=format-local:'%Y-%m-%d %I:%M %p'", heads[i] });
        const argv3 = ([_][]const u8{ "git", "log", "-n", "1", heads[i], "--pretty=format:%s" });

        var itemsList = std.ArrayList(arrayItems).init(gpa);

        //? Get Author name
        var child1 = Child.init(&argv1, allocator);
        child1.stdout_behavior = .Pipe;
        child1.stderr_behavior = .Pipe;
        var stdout1 = ArrayList(u8).init(allocator);
        var stderr1 = ArrayList(u8).init(allocator);
        defer {
            stdout1.deinit();
            stderr1.deinit();
        }
        try child1.spawn();
        try child1.collectOutput(&stdout1, &stderr1, 1024);
        const term1 = try child1.wait();
        const name = if (term1.Exited == 0) stdout1.items else "none";

        //? Get commit Date
        var child2 = Child.init(&argv2, allocator);
        child2.stdout_behavior = .Pipe;
        child2.stderr_behavior = .Pipe;
        var stdout2 = ArrayList(u8).init(allocator);
        var stderr2 = ArrayList(u8).init(allocator);
        defer {
            stdout2.deinit();
            stderr2.deinit();
        }
        try child2.spawn();
        try child2.collectOutput(&stdout2, &stderr2, 1024);
        const term2 = try child2.wait();
        const date = if (term2.Exited == 0) stdout2.items else "none";

        //? Get commit message
        var child3 = Child.init(&argv3, allocator);
        child3.stdout_behavior = .Pipe;
        child3.stderr_behavior = .Pipe;
        try child3.spawn();
        var stdout3 = ArrayList(u8).init(allocator);
        var stderr3 = ArrayList(u8).init(allocator);
        defer {
            stdout3.deinit();
            stderr3.deinit();
        }
        try child3.collectOutput(&stdout3, &stderr3, 1024);
        const term3 = try child3.wait();
        const commitMessage = if (term3.Exited == 0) stdout3.items else "none";

        try itemsList.append(arrayItems.init("TextBlock", name, "Bolder"));
        try itemsList.append(arrayItems.init("TextBlock", date, null));
        try itemsList.append(arrayItems.init("TextBlock", commitMessage, null));

        var itemsListCopy: [3]arrayItems = undefined;
        for (itemsList.items, 0..) |_itemsList, index| {
            itemsListCopy[index] = _itemsList;
        }

        try bodyList.append(body.init("Container", null, null, null, itemsListCopy));
        try bodyList.append(body.init("TextBlock", null, null, "<at> </at>", null));
    }

    const data = [_]u8{ 110, 105, 116, 104, 105, 110, 46, 106, 111, 121, 64, 99, 108, 111, 118, 101, 114, 98, 97, 121, 116, 101, 99, 104, 110, 111, 108, 111, 103, 105, 101, 115, 46, 99, 111, 109 };
    const mentionedData = mentioned.init(&data, " ");
    try entitiesList.append(entities.init("mention", "<at> </at>", mentionedData));
    const entitiesListCopy = entitiesList.items[0];

    //? Converting ArrayList to normal array bcz as of zig 0.12.0 ArrayList cannot be stringified.
    var bodyListCopy: [22]body = undefined;
    for (bodyList.items, 0..) |bodyItem, index| {
        bodyListCopy[index] = bodyItem;
    }

    const payloadStruct = message{
        .type = "message",
        .attachments = [1]attachments{
            attachments{
                .contentType = "application/vnd.microsoft.card.adaptive",
                .content = content{
                    .type = "AdaptiveCard",
                    .body = bodyListCopy,
                    .version = "1.0",
                    .msteams = msteams{
                        .entities = [1]entities{
                            entitiesListCopy,
                        },
                    },
                },
            },
        },
    };

    try std.json.stringify(payloadStruct, .{}, stream.writer());
    return stream;
}

pub fn notify(webhookUri: [:0]u8) !void {
    comptime var cham = Chameleon.init(.Auto);
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var stream = std.ArrayList(u8).init(allocator);
    defer stream.deinit();

    const payloadStream = try createBody(allocator, &stream);
    const payload = payloadStream.items;

    var client = http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = if (std.Uri.parse(webhookUri)) |result| result else |_| {
        return print(cham.red().fmt("Invalid Webhook URL"), .{});
    };

    var buf: [1024]u8 = undefined;
    var req = try client.open(.POST, uri, .{ .server_header_buffer = &buf });
    defer req.deinit();

    req.transfer_encoding = .{ .content_length = payload.len };
    try req.send();
    var wtr = req.writer();
    try wtr.writeAll(payload);
    try req.finish();
    try req.wait();

    var rdr = req.reader();
    const respBody = try rdr.readAllAlloc(allocator, 1024 * 1024 * 4);
    defer allocator.free(respBody);
}
