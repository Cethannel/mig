const std = @import("std");
const token = @import("token.zig");

pub const Program = struct {
    const statement_list = std.ArrayList(Statement);

    statements: statement_list,

    pub fn init(allocator: std.mem.Allocator) Program {
        return .{
            .statements = statement_list.init(allocator),
        };
    }

    pub fn deinit(p: *Program) void {
        p.statements.deinit();
    }

    pub fn token_literal(program: *const Program) []const u8 {
        if (program.statements.items.len > 0) {
            return program.statements.items[0].token_literal();
        }
        return "";
    }
};

const Expression = struct {};

const StatementTag = enum {
    Let,
    Dummy,
};

pub const Statement = union(StatementTag) {
    Let: struct {
        token: token.Token,
        name: Identifier,
        value: Expression,
    },
    Dummy,

    pub fn token_literal(stmt: *const Statement) []const u8 {
        switch (stmt.*) {
            .Let => |value| return value.token.literal.items,
            else => unreachable,
        }
    }
};

pub const Identifier = struct {
    token: token.Token,
    value: std.ArrayList(u8),

    pub fn token_literal(ident: *const Identifier) []const u8 {
        return ident.token.literal.items;
    }
};
