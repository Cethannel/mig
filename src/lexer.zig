const std = @import("std");
const token = @import("token.zig");
const util = @import("util.zig");

pub const Lexer = struct {
    input: []u8,
    position: usize,
    readPosition: usize,
    ch: u8,
    allocator: std.mem.Allocator,

    fn read_char(self: *Lexer) void {
        if (self.readPosition >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.readPosition];
        }
        self.position = self.readPosition;
        self.readPosition += 1;
    }

    fn new_token(self: Lexer, tokenType: token.TokenType) token.Token {
        var literal: token.LITERAL_T = undefined;
        if (self.position < self.input.len) {
            literal = token.literal_from_str(self.input[self.position .. self.position + 1], self.allocator);
        } else {
            literal = token.literal_from_str("", self.allocator);
        }
        return token.Token{ .type = tokenType, .literal = literal };
    }

    pub fn next_token(self: *Lexer) token.Token {
        var tok = token.Token{
            .type = token.TokenType.ILLEGAL,
            .literal = undefined,
        };

        self.skip_whitespace();

        switch (self.ch) {
            '=' => if (self.peek_char() == '=') {
                const position = self.readPosition - 1;
                self.read_char();
                const literal = token.literal_from_str(self.input[position..self.readPosition], self.allocator);
                tok = .{
                    .literal = literal,
                    .type = token.TokenType.EQ,
                };
            } else {
                tok = self.new_token(.ASSIGN);
            },
            '+' => tok = self.new_token(.PLUS),
            '-' => tok = self.new_token(.MINUS),
            '!' => if (self.peek_char() == '=') {
                const position = self.readPosition - 1;
                self.read_char();
                var literal: token.LITERAL_T = undefined;
                literal = token.literal_from_str(self.input[position..self.readPosition], self.allocator);
                tok = .{
                    .literal = literal,
                    .type = token.TokenType.NOT_EQ,
                };
            } else {
                tok = self.new_token(.BANG);
            },
            '/' => tok = self.new_token(.SLASH),
            '*' => tok = self.new_token(.ASTERISK),
            '<' => tok = self.new_token(.LT),
            '>' => tok = self.new_token(.GT),
            ';' => tok = self.new_token(.SEMICOLON),
            '(' => tok = self.new_token(.LPAREN),
            ')' => tok = self.new_token(.RPAREN),
            '{' => tok = self.new_token(.LBRACE),
            '}' => tok = self.new_token(.RBRACE),
            ',' => tok = self.new_token(.COMMA),
            0 => tok = self.new_token(.EOF),

            else => {
                if (is_letter(self.ch)) {
                    tok.literal = self.read_identifier();
                    tok.type = token.lookup_ident(tok.literal);
                    return tok;
                } else if (is_digit(self.ch)) {
                    tok.type = token.TokenType.INT;
                    tok.literal = self.read_number();
                    return tok;
                } else {
                    tok = self.new_token(.ILLEGAL);
                }
            },
        }

        self.read_char();

        return tok;
    }

    fn read_identifier(self: *Lexer) token.LITERAL_T {
        const readPosition = self.readPosition - 1;
        while (is_letter(self.ch)) {
            self.read_char();
        }
        const out = util.unwrap(std.ArrayList(u8), std.ArrayList(u8).fromOwnedSlice(self.allocator, self.input[readPosition .. self.readPosition - 1]));
        return out;
    }

    fn skip_whitespace(self: *Lexer) void {
        while (is_whitespace(self.ch)) {
            self.read_char();
        }
    }

    fn read_number(self: *Lexer) token.LITERAL_T {
        const position = self.position;
        while (is_digit(self.ch)) {
            self.read_char();
        }

        var out: token.LITERAL_T = undefined;
        out = token.literal_from_str(self.input[position..self.position], self.allocator);
        return out;
    }

    fn peek_char(self: *Lexer) u8 {
        if (self.readPosition >= self.input.len) {
            return 0;
        } else {
            return self.input[self.readPosition];
        }
    }
};

fn is_digit(ch: u8) bool {
    return '0' <= ch and ch <= '9';
}

fn is_whitespace(ch: u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\n' or ch == '\r';
}

fn is_letter(ch: u8) bool {
    return 'a' <= ch and ch <= 'z' or 'A' <= ch and ch <= 'Z' or ch == '_';
}

pub fn New(input: []u8, allocator: std.mem.Allocator) Lexer {
    var l = Lexer{ .input = input, .position = 0, .readPosition = 0, .ch = 0, .allocator = allocator };

    l.read_char();

    return l;
}

test "TEstNextToken" {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\
        \\let add = fn(x, y) {
        \\  x + y;
        \\};
        \\
        \\let result = add(five, ten);
        \\!-/*5;
        \\5 < 10 > 5;
        \\
        \\if (5 < 10) {
        \\  return true;
        \\} else {
        \\  return false;
        \\}
        \\
        \\10 == 10;
        \\10 != 9;
    ;

    const tests = [_]struct {
        expected_type: token.TokenType,
        expected_literal: []const u8,
    }{
        .{ .expected_type = token.TokenType.LET, .expected_literal = "let" },
        .{ .expected_type = token.TokenType.IDENT, .expected_literal = "five" },
        .{ .expected_type = token.TokenType.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = token.TokenType.INT, .expected_literal = "5" },
        .{ .expected_type = token.TokenType.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.TokenType.LET, .expected_literal = "let" },
        .{ .expected_type = token.TokenType.IDENT, .expected_literal = "ten" },
        .{ .expected_type = token.TokenType.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = token.TokenType.INT, .expected_literal = "10" },
        .{ .expected_type = token.TokenType.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.TokenType.LET, .expected_literal = "let" },
        .{ .expected_type = token.TokenType.IDENT, .expected_literal = "add" },
        .{ .expected_type = token.TokenType.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = token.TokenType.FUNCTION, .expected_literal = "fn" },
        .{ .expected_type = token.TokenType.LPAREN, .expected_literal = "(" },
        .{ .expected_type = token.TokenType.IDENT, .expected_literal = "x" },
        .{ .expected_type = token.TokenType.COMMA, .expected_literal = "," },
        .{ .expected_type = token.TokenType.IDENT, .expected_literal = "y" },
        .{ .expected_type = token.TokenType.RPAREN, .expected_literal = ")" },
        .{ .expected_type = token.TokenType.LBRACE, .expected_literal = "{" },
        .{ .expected_type = token.TokenType.IDENT, .expected_literal = "x" },
        .{ .expected_type = token.TokenType.PLUS, .expected_literal = "+" },
        .{ .expected_type = token.TokenType.IDENT, .expected_literal = "y" },
        .{ .expected_type = token.TokenType.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.TokenType.RBRACE, .expected_literal = "}" },
        .{ .expected_type = token.TokenType.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.TokenType.LET, .expected_literal = "let" },
        .{ .expected_type = token.TokenType.IDENT, .expected_literal = "result" },
        .{ .expected_type = token.TokenType.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = token.TokenType.IDENT, .expected_literal = "add" },
        .{ .expected_type = token.TokenType.LPAREN, .expected_literal = "(" },
        .{ .expected_type = token.TokenType.IDENT, .expected_literal = "five" },
        .{ .expected_type = token.TokenType.COMMA, .expected_literal = "," },
        .{ .expected_type = token.TokenType.IDENT, .expected_literal = "ten" },
        .{ .expected_type = token.TokenType.RPAREN, .expected_literal = ")" },
        .{ .expected_type = token.TokenType.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.TokenType.BANG, .expected_literal = "!" },
        .{ .expected_type = token.TokenType.MINUS, .expected_literal = "-" },
        .{ .expected_type = token.TokenType.SLASH, .expected_literal = "/" },
        .{ .expected_type = token.TokenType.ASTERISK, .expected_literal = "*" },
        .{ .expected_type = token.TokenType.INT, .expected_literal = "5" },
        .{ .expected_type = token.TokenType.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.TokenType.INT, .expected_literal = "5" },
        .{ .expected_type = token.TokenType.LT, .expected_literal = "<" },
        .{ .expected_type = token.TokenType.INT, .expected_literal = "10" },
        .{ .expected_type = token.TokenType.GT, .expected_literal = ">" },
        .{ .expected_type = token.TokenType.INT, .expected_literal = "5" },
        .{ .expected_type = token.TokenType.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.TokenType.IF, .expected_literal = "if" },
        .{ .expected_type = token.TokenType.LPAREN, .expected_literal = "(" },
        .{ .expected_type = token.TokenType.INT, .expected_literal = "5" },
        .{ .expected_type = token.TokenType.LT, .expected_literal = "<" },
        .{ .expected_type = token.TokenType.INT, .expected_literal = "10" },
        .{ .expected_type = token.TokenType.RPAREN, .expected_literal = ")" },
        .{ .expected_type = token.TokenType.LBRACE, .expected_literal = "{" },
        .{ .expected_type = token.TokenType.RETURN, .expected_literal = "return" },
        .{ .expected_type = token.TokenType.TRUE, .expected_literal = "true" },
        .{ .expected_type = token.TokenType.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.TokenType.RBRACE, .expected_literal = "}" },
        .{ .expected_type = token.TokenType.ELSE, .expected_literal = "else" },
        .{ .expected_type = token.TokenType.LBRACE, .expected_literal = "{" },
        .{ .expected_type = token.TokenType.RETURN, .expected_literal = "return" },
        .{ .expected_type = token.TokenType.FALSE, .expected_literal = "false" },
        .{ .expected_type = token.TokenType.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.TokenType.RBRACE, .expected_literal = "}" },
        .{ .expected_type = token.TokenType.INT, .expected_literal = "10" },
        .{ .expected_type = token.TokenType.EQ, .expected_literal = "==" },
        .{ .expected_type = token.TokenType.INT, .expected_literal = "10" },
        .{ .expected_type = token.TokenType.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.TokenType.INT, .expected_literal = "10" },
        .{ .expected_type = token.TokenType.NOT_EQ, .expected_literal = "!=" },
        .{ .expected_type = token.TokenType.INT, .expected_literal = "9" },
        .{ .expected_type = token.TokenType.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.TokenType.EOF, .expected_literal = "" },
    };

    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();
    var lexer = New(@constCast(input), allocator.allocator());

    for (tests) |tt| {
        const tok = lexer.next_token();

        try std.testing.expectEqual(tt.expected_type, tok.type);
        try std.testing.expectEqualStrings(tt.expected_literal, tok.literal.items);
    }
}
