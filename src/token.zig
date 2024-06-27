const std = @import("std");
const util = @import("util.zig");

pub const TokenType = enum {
    ILLEGAL,
    EOF,
    IDENT,
    INT,
    ASSIGN, // =
    PLUS, // +
    MINUS, // -
    BANG, // !
    ASTERISK, // *
    SLASH, // /
    COMMA, // ,
    SEMICOLON, // ;
    LPAREN, // (
    RPAREN, // )
    LBRACE, // {
    RBRACE, // }

    LT, // <
    GT, // >
    EQ, // ==
    NOT_EQ, // !=

    FUNCTION, // fn
    LET, // let
    TRUE,
    FALSE,
    IF,
    ELSE,
    RETURN,
};

pub const LITERAL_LEN: usize = 128;
pub const LITERAL_T = std.ArrayList(u8);
pub const LITERAL_DEFAULT = .{0} ** LITERAL_LEN;

pub fn new_literal(allocator: std.mem.Allocator, capacity: usize) LITERAL_T {
    return util.unwrap(LITERAL_T, LITERAL_T.initCapacity(allocator, capacity));
}

pub fn literal_from_str(str: []const u8, allocator: std.mem.Allocator) LITERAL_T {
    var out = new_literal(allocator, str.len);

    util.unwrap(void, out.appendSlice(str));

    return out;
}

pub const Token = struct {
    type: TokenType,
    literal: LITERAL_T,
};

fn str_equal(a: []const u8, b: []const u8) bool {
    for (a, 0..) |value, i| {
        if (value == 0 or b[i] == 0) {
            return true;
        }
        if (value != b[i]) {
            return false;
        }
    }

    return true;
}

//const keywords = std.ComptimeStringMap(TokenType, .{
//    .{
//        "fn", TokenType.FUNCTION,
//    },
//    .{
//        "let", TokenType.LET,
//    },
//    .{
//        "true", TokenType.TRUE,
//    },
//    .{
//        "false", TokenType.FALSE,
//    },
//    .{
//        "if", TokenType.IF,
//    },
//    .{
//        "else", TokenType.ELSE,
//    },
//    .{
//        "return", TokenType.RETURN,
//    },
//});

fn strcmp(a: []const u8, b: []const u8) bool {
    for (a, 0..) |value, i| {
        if (value == 0) {
            return true;
        }
        if (i > b.len) {
            std.debug.print("Failed to compare: \"{s}\" and \"{s}\"\n", .{ a, b });
            std.debug.print("Lengths where: {} and {}\n", .{ a.len, b.len });
            return false;
        }
        if (b[i] == 0) {
            return true;
        }
        if (value != b[i]) {
            return false;
        }
    }

    return true;
}

fn get_token(literal: LITERAL_T) ?TokenType {
    const keywords = [_]struct { name: []const u8, tt: TokenType }{
        .{ .name = "fn", .tt = TokenType.FUNCTION },
        .{ .name = "let", .tt = TokenType.LET },
        .{ .name = "true", .tt = TokenType.TRUE },
        .{ .name = "false", .tt = TokenType.FALSE },
        .{ .name = "if", .tt = TokenType.IF },
        .{ .name = "else", .tt = TokenType.ELSE },
        .{ .name = "return", .tt = TokenType.RETURN },
    };

    for (keywords) |value| {
        if (strcmp(value.name, literal.items)) {
            return value.tt;
        }
    }

    return null;
}

pub fn strlen(str: []const u8) ?usize {
    for (str, 0..) |value, i| {
        if (value == 0) {
            return i - 1;
        }
    }

    return str.len;
}

pub fn lookup_ident(ident: LITERAL_T) TokenType {
    const len = strlen(ident.items);
    if (len == null) {
        std.debug.print("Bad length for: {s}\n", .{ident.items});
    }
    if (get_token(ident)) |token_type| {
        return token_type;
    }

    return TokenType.IDENT;
}
