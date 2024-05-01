pub const @"log.Level" = enum (u2) {
    err = 0,
    warn = 1,
    info = 2,
    debug = 3,
};
pub const log_level: @"log.Level" = .info;
pub const nfdk_version: @import("std").SemanticVersion = .{
    .major = 0,
    .minor = 1,
    .patch = 0,
};
