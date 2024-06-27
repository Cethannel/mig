const std = @import("std");
const lexer = @import("lexer.zig");
const token = @import("token.zig");
const ast = @import("ast.zig");
const unwrap = @import("util.zig").unwrap;

const Parser = struct {
    const Errors = std.ArrayList(std.ArrayList(u8));

    l: lexer.Lexer,
    allocator: std.mem.Allocator,

    cur_token: token.Token,
    peek_token: token.Token,

    errors: Errors,

    pub fn deinit(p: *Parser) void {
        for (p.errors.items) |err| {
            err.deinit();
        }
        p.errors.deinit();
    }

    pub fn next_token(p: *Parser) void {
        p.cur_token = p.peek_token;
        p.peek_token = p.l.next_token();
    }

    pub fn parse_program(p: *Parser) ast.Program {
        var program = ast.Program.init(p.allocator);

        while (p.cur_token.type != token.TokenType.EOF) {
            if (p.parse_statement()) |stmt| {
                program.statements.append(stmt) catch unreachable;
            }
            p.next_token();
        }

        return program;
    }

    const ParseError = error{Unkown_Token};

    fn parse_statement(p: *Parser) ?ast.Statement {
        return switch (p.cur_token.type) {
            .LET => p.parse_let_statement(),
            else => {
                var msg = std.ArrayList(u8).init(p.allocator);
                std.fmt.format(msg.writer(), "Unkown token: {any}\n", .{p.cur_token.type}) catch unreachable;
                p.errors.append(msg) catch unreachable;
                return null;
            },
        };
    }

    fn parse_let_statement(p: *Parser) ?ast.Statement {
        var stmt = ast.Statement{
            .Let = .{
                .token = p.cur_token,
                .name = undefined,
                .value = undefined,
            },
        };

        if (!p.expect_peek(token.TokenType.IDENT)) {
            return null;
        }

        stmt.Let.name = ast.Identifier{
            .token = p.cur_token,
            .value = p.cur_token.literal,
        };

        if (!p.expect_peek(.ASSIGN)) {
            return null;
        }

        while (!p.cur_tok_is(.SEMICOLON)) {
            p.next_token();
        }

        return stmt;
    }

    fn expect_peek(p: *Parser, tok: token.TokenType) bool {
        if (tok == p.peek_token.type) {
            p.next_token();
            return true;
        } else {
            p.peek_error(tok);
            return false;
        }
    }

    fn cur_tok_is(p: *const Parser, tok: token.TokenType) bool {
        return p.cur_token.type == tok;
    }

    fn peek_error(p: *Parser, t: token.TokenType) void {
        var msg = std.ArrayList(u8).init(p.allocator);
        std.fmt.format(msg.writer(), "expected next token to be {any}, got {any} instead", .{ t, p.peek_token.type }) catch unreachable;
        p.errors.append(msg) catch unreachable;
    }
};

pub fn New(l: lexer.Lexer, allocator: std.mem.Allocator) Parser {
    var parser: Parser = undefined;
    parser.l = l;
    parser.allocator = allocator;
    parser.errors = Parser.Errors.init(allocator);

    parser.next_token();
    parser.next_token();

    return parser;
}

test "TestLetStatemets" {
    const input =
        \\let x = 5;
        \\let y = 10;
        \\let foobar = 838383;
    ;

    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();
    const l = lexer.New(@constCast(input), allocator.allocator());
    var parser = New(l, std.heap.page_allocator);
    defer parser.deinit();

    var program: ast.Program = parser.parse_program();
    defer program.deinit();
    try check_parse_errors(&parser);

    try std.testing.expectEqual(3, program.statements.items.len);

    const tests = [_]struct {
        expectedIdent: []const u8,
    }{
        .{ .expectedIdent = "x" },
        .{ .expectedIdent = "y" },
        .{ .expectedIdent = "foobar" },
    };

    for (tests, 0..) |tt, i| {
        const stmt = program.statements.items[i];
        try test_let_statement(stmt, tt.expectedIdent);
    }
}

fn test_let_statement(stmt: ast.Statement, name: []const u8) !void {
    try std.testing.expectEqualStrings("let", stmt.token_literal());

    const letstmt = switch (stmt) {
        .Let => |letstmt| letstmt,
        else => return error.NotLetStmt,
    };

    try std.testing.expectEqualStrings(name, letstmt.name.value.items);
    try std.testing.expectEqualStrings(name, letstmt.name.token_literal());
}

fn check_parse_errors(p: *const Parser) !void {
    const errors = p.errors;
    if (errors.items.len == 0) {
        return;
    }

    std.debug.print("parser has {} errors\n", .{errors.items.len});
    for (errors.items) |err| {
        std.debug.print("parser error: {s}\n", .{err.items});
    }
    @panic("Had errors");
}
