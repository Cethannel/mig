const std = @import("std");
const lexer = @import("lexer.zig");
const token = @import("token.zig");

const PROMPT = ">> ";

pub fn create(in_t: type, out_t: type) type {
    return struct {
        pub fn start(in: in_t, out: out_t) !void {
            const writer = out.writer();
            const reader = in.reader();
            var buf: [1024]u8 = undefined;
            try writer.writeAll(PROMPT);
            while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
                var l = lexer.New(line);
                var tok = l.next_token();
                while (tok.type != token.TokenType.EOF) : (tok = l.next_token()) {
                    try std.fmt.format(writer, "Token: {{ type: {any}, literal: \"{s}\"}}\n", .{ tok.type, tok.literal });
                }
                try writer.writeAll(PROMPT);
            }
        }
    };
}
