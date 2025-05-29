/// Build a program that takes a messages from client (producers), saves to the file, and sends them back when requested (consumers)
const std = @import("std");
const net = std.net;
const config = @import("config.zig");

// Handles the tcp connection 
fn handleConnection(file: std.fs.File, conn: net.Server.Connection) !void {
    defer conn.stream.close();

    // declare a variable buffer chunk of 4KB
    var buffer: [config.MAX_BUFFER_SIZE]u8 = undefined;

    // read the number of bytes from the stream 
    const bytes_read = try conn.stream.read(&buffer);
    if (bytes_read == 0) {
        std.debug.print("Client disconnected\n", .{});
    }

    const message = buffer[0..bytes_read];
    std.debug.print("Received: {s}", .{message});

    // Write to file
    _ = try file.writeAll(message);

    // send the conformation message to the client
    const resp: []const u8 = "Received from client";
    _ = try conn.stream.write(resp);
    std.debug.print("Sent: {s}\n", .{resp});
}

fn config_server() !net.Server {
    const address = try net.Address.parseIp4(config.ip_address, config.port);
    return try address.listen( .{ .reuse_address = true } );
}

pub fn main() !void {
    // parse the IPv4 and port number
    var server = try config_server();
    defer server.deinit();

    std.debug.print("Starting the Server listening on {}\n", .{server.listen_address});

    const file = try std.fs.cwd().createFile(config.file_name, .{
        .read = true,
        .truncate = false,
    });
    defer file.close();

    while (true) {
        // accept the connections
        std.debug.print("Ready to accept new connection\n", .{});
        const conn = try server.accept();
        std.debug.print("Client connected from: {}\n", .{conn.address});

        handleConnection(file, conn) catch |err| {
            std.debug.print("Connection error: {}\n", .{err});
        };
    }
}
