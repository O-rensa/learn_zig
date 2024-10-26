const std = @import("std");
const net = std.net;
const posix = std.posix;

pub fn main() !void {
    const addr = try net.Address.parseIp4("127.0.0.1", 4000);
    const tpe: u32 = posix.SOCK.STREAM;
    const protoc = posix.IPPROTO.TCP;

    const listener = try posix.socket(addr.any.family, tpe, protoc);
    defer posix.close(listener);

    try posix.setsockopt(listener, posix.SOL.SOCKET, posix.SO.REUSEADDR, &std.mem.toBytes((@as(c_int, 1))));
    try posix.bind(listener, &addr.any, addr.getOsSockLen());
    try posix.listen(listener, 128);

    std.debug.print("listening to port: {}", .{4000});
    while (true) {
        var client_addr: net.Address = undefined;
        var client_addr_len: posix.socklen_t = @sizeOf(net.Address);

        const scket = posix.accept(listener, &client_addr.any, &client_addr_len, 0) catch |err| {
            std.debug.print("error accept: {}\n", .{err});
            continue;
        };

        defer posix.close(scket);
        std.debug.print("{} connected\n", .{client_addr});

        write(scket, "Hello (and goodbye)") catch |err| {
            std.debug.print("error writing: {}\n", .{err});
        };
    }
}

fn write(socket: posix.socket_t, msg: []const u8) !void {
    var pos: usize = 0;
    while (pos < msg.len) {
        const written = try posix.write(socket, msg[pos..]);
        if (0 == written) {
            return error.Closed;
        }
        pos += written;
    }
}
