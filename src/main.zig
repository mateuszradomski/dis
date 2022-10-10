const std = @import("std");
const Dwarf = @import("dwarf.zig");
const elf = @import("elf.zig");

const fmt = std.fmt;
const mem = std.mem;
const time = std.time;

const KiloByte = 1024;
const MegaByte = KiloByte * 1024;

pub const Buffer = struct {
    data: []u8,
    curr_pos: u64 = 0,

    pub fn peek(self: *Buffer, amount: u32) []u8 {
        return self.data[self.curr_pos .. self.curr_pos + amount];
    }

    pub fn isSpaceLeft(self: *Buffer, amount: u32) bool {
        return self.curr_pos <= (self.data.len + amount);
    }

    pub fn consume(self: *Buffer, amount: u32) ?[]u8 {
        self.curr_pos += amount;
        if (self.curr_pos <= self.data.len) {
            return self.data[self.curr_pos - amount .. self.curr_pos];
        } else {
            return null;
        }
    }

    pub fn consumeUnchecked(self: *Buffer, amount: u32) []u8 {
        self.curr_pos += amount;
        return self.data[self.curr_pos - amount .. self.curr_pos];
    }

    pub fn advanceUntil(self: *Buffer, delim: u8) void {
        if (mem.indexOfScalar(u8, self.data[self.curr_pos..], delim)) |pos| {
            self.curr_pos += pos + 1;
        } else {
            unreachable;
        }
    }

    pub fn consumeUntil(self: *Buffer, delim: u8) ?[]u8 {
        const VT: type = comptime std.meta.Vector(16, u8);

        var k: [@sizeOf(VT)]u8 = undefined;
        const start_pos = self.curr_pos;
        while (self.data.len - self.curr_pos > @sizeOf(VT)) {
            mem.copy(u8, &k, self.data[self.curr_pos .. self.curr_pos + @sizeOf(VT)]);
            const d: VT = k;
            const zero: VT = mem.zeroes(VT);
            const mask = @bitCast(u16, d == zero);
            if (mask > 0) {
                const pos = @ctz(mask);
                const r = self.data[start_pos .. self.curr_pos + pos];
                self.curr_pos += pos + 1;
                return r;
            } else {
                self.curr_pos += @sizeOf(VT);
            }
        }

        if (mem.indexOfScalar(u8, self.data[self.curr_pos..], delim)) |pos| {
            const r = self.data[start_pos .. self.curr_pos + pos];
            self.curr_pos += pos + 1;
            return r;
        } else {
            return null;
        }
    }

    pub fn consumeType(self: *Buffer, comptime T: type) ?T {
        var opt_slice = self.consume(@sizeOf(T));
        if (opt_slice) |slice| {
            return mem.bytesToValue(T, slice[0..@sizeOf(T)]);
        } else {
            return null;
        }
    }

    pub fn consumeTypeUnchecked(self: *Buffer, comptime T: type) T {
        var slice = self.consumeUnchecked(@sizeOf(T));
        return mem.bytesToValue(T, slice[0..@sizeOf(T)]);
    }

    pub fn consumeTypeAligned(self: *Buffer, comptime T: type, alignment: u32) ?T {
        self.curr_pos += alignment - 1;
        self.curr_pos &= ~(alignment - 1);

        return self.consumeType(T);
    }

    pub fn getCurrentPos(self: Buffer) u64 {
        return self.curr_pos;
    }

    pub fn advance(self: *Buffer, amount: u64) void {
        self.curr_pos += amount;
    }

    pub fn isGood(self: Buffer) bool {
        return self.curr_pos < self.data.len;
    }
};

pub fn Range2T(comptime IdT: type, comptime LenT: type) type {
    return packed struct {
        start: IdT = 0,
        len: LenT = 0,

        const Self = @This();

        pub fn len(s: Self) LenT {
            return s.len;
        }

        pub fn contains(s: Self, id: IdT) bool {
            return s.start <= id and (s.start + s.len) > id;
        }
    };
}

pub fn Range(comptime T: type) type {
    return struct {
        start: T = 0,
        end: T = 0,

        const Self = @This();

        pub fn len(s: Self) usize {
            return @intCast(usize, s.end) - @intCast(usize, s.start);
        }

        pub fn contains(s: Self, id: T) bool {
            return s.start <= id and s.end > id;
        }
    };
}

const TypeError = Dwarf.Error || mem.Allocator.Error;

const TypeId = u32;
const Type = struct {
    name: []const u8,
    size: u32,
    dimension: u32,
    ptr_count: u8,
    struct_type: StructType = .none,
    struct_id: StructId = InvalidStructId,

    const StructType = enum(u8) {
        none,
        struct_type,
        union_type,
        class_type,
    };

    pub fn isArray(self: Type) bool {
        return self.dimension != std.math.maxInt(@TypeOf(self.dimension));
    }
};

const StructMember = struct {
    name: []const u8,
    type_id: TypeId,
    mem_loc: u32,
};

const MemberId = u32;
const MemberRange = Range(MemberId);

const StructId = u32;
const InvalidStructId = std.math.maxInt(StructId);
const StructRange = Range(StructId);

const Structure = struct {
    type_id: TypeId,
    member_range: MemberRange,
    inline_structures: StructRange = .{},
};

const Namespace = struct {
    name: []const u8,
    struct_range: StructRange,
};

pub fn Stack(comptime T: type) type {
    return struct {
        mem: []T,
        top: u16 = 0,
        const Self = @This();

        pub fn init(capacity: u16, gpa: mem.Allocator) !Self {
            return Self{
                .mem = try gpa.alloc(T, capacity),
            };
        }

        pub fn push(s: *Self, obj: T) void {
            s.mem[s.top] = obj;
            s.top += 1;
        }

        pub fn popTo(s: *Self, n: u16) void {
            s.top = n;
        }

        pub fn sliceFrom(s: *Self, n: u16) []T {
            return s.mem[n..s.top];
        }
    };
}

const Context = struct {
    const Self = @This();

    types: std.ArrayList(Type),
    type_addresses: []TypeId = &[_]TypeId{},
    structures: std.ArrayList(Structure),
    members: std.ArrayList(StructMember),
    namespaces: std.ArrayListUnmanaged(Namespace) = .{},
    dwarf: Dwarf,

    gpa: mem.Allocator,
    arena: mem.Allocator,

    member_scratch_stack: Stack(StructMember),
    structure_scratch_stack: Stack(Structure),

    pub fn init(allocator: mem.Allocator, dwarf: Dwarf) !Self {
        var c = Context{
            .types = std.ArrayList(Type).init(allocator),
            .structures = std.ArrayList(Structure).init(allocator),
            .members = std.ArrayList(StructMember).init(allocator),
            .dwarf = dwarf,
            .gpa = allocator,
            .arena = allocator,

            .member_scratch_stack = try Stack(StructMember).init(16 * 1024, allocator),
            .structure_scratch_stack = try Stack(Structure).init(4 * 1024, allocator),
        };

        return c;
    }

    pub fn addType(c: *Self, t: Type) !TypeId {
        const id = @intCast(TypeId, c.types.items.len);
        try c.types.append(t);
        return id;
    }

    pub fn addStruct(c: *Self, s: Structure) !StructId {
        const id = @intCast(StructId, c.structures.items.len);
        try c.structures.append(s);
        return id;
    }

    pub fn run(c: *Self) !void {
        {
            var timer = try std.time.Timer.start();
            var biggest_cu_size: u32 = 0;
            for (c.dwarf.cus.items) |cu| {
                biggest_cu_size = @maximum(biggest_cu_size, cu.payload_size + cu.size);
            }
            c.type_addresses = try c.gpa.alloc(TypeId, biggest_cu_size);
            mem.set(TypeId, c.type_addresses, std.math.maxInt(TypeId));

            for (c.dwarf.cus.items) |cu| {
                c.dwarf.setCu(cu);

                // TODO(radomski): Kinda stupid?
                while (c.dwarf.inCurrentCu()) {
                    try c.readChildren();
                }

                mem.set(TypeId, c.type_addresses[0 .. cu.size + cu.payload_size], std.math.maxInt(TypeId));
            }
            const ns = timer.read();
            const elapsed_s = @intToFloat(f64, ns) / time.ns_per_s;
            const throughput = @floatToInt(u64, @intToFloat(f64, c.dwarf.debug_info.data.len) / elapsed_s);
            std.debug.print("Parsing: {}[{}/s]\n", .{ std.fmt.fmtDuration(ns), std.fmt.fmtIntSizeDec(throughput) });
        }

        {
            var timer = try std.time.Timer.start();
            try c.printContainers();
            const ns = timer.read();
            std.debug.print("Printing: {}\n", .{std.fmt.fmtDuration(ns)});
        }

        std.log.debug("types {}/{}", .{ c.types.items.len, fmt.fmtIntSizeDec(c.types.items.len * @sizeOf(Type)) });
        std.log.debug("structures {}/{}", .{ c.structures.items.len, fmt.fmtIntSizeDec(c.structures.items.len * @sizeOf(Structure)) });
        std.log.debug("members {}/{}", .{ c.members.items.len, fmt.fmtIntSizeDec(c.members.items.len * @sizeOf(StructMember)) });
    }

    pub fn readChildren(c: *Context) !void {
        while (c.dwarf.readNextDie()) |die_addr| {
            const die_id = try c.dwarf.readDieIdAtAddress(die_addr) orelse break;
            const die = c.dwarf.dies.items[die_id];

            switch (die.tag) {
                .structure_type,
                .union_type,
                .class_type,
                => {
                    _ = try c.parseStructure(die_addr, die_id);
                },
                Dwarf.DW_TAG.typedef => {
                    try c.readTypedefAtAddress(die_addr);
                },
                Dwarf.DW_TAG.namespace => {
                    var namespace = try c.readNamespace(die_addr);
                    try c.readChildren();
                    namespace.struct_range.end = @intCast(u32, c.structures.items.len);
                    try c.namespaces.append(c.arena, namespace);
                },
                Dwarf.DW_TAG.compile_unit => {
                    c.dwarf.skipDieAttrs(die_id);
                },
                else => {
                    try c.dwarf.skipDieAndChildren(die_id);
                },
            }
        }
    }

    pub fn readNamespace(c: *Context, die_addr: usize) !Namespace {
        const die_id = try c.dwarf.readDieIdAtAddress(die_addr) orelse unreachable;
        const die = c.dwarf.dies.items[die_id];
        const name = blk: {
            var name: []const u8 = undefined;

            for (c.dwarf.getAttrs(die.attr_range)) |attr| {
                switch (attr.at) {
                    .name => {
                        name = try c.dwarf.readString(attr.form);
                    },
                    else => c.dwarf.skipFormData(attr.form),
                }
            }

            break :blk name;
        };

        return Namespace{
            .name = name,
            .struct_range = .{ .start = @intCast(u32, c.structures.items.len) },
        };
    }

    pub fn parseStructure(c: *Context, die_addr: usize, die_id: Dwarf.DieId) !Structure {
        const stype_id = try c.readTypeAtAddressAndNoSkip(die_addr);
        const stype = c.types.items[stype_id];
        if (stype.struct_id != std.math.maxInt(@TypeOf(stype.struct_id))) {
            try c.dwarf.skipDieAndChildren(die_id);
            return c.structures.items[stype.struct_id];
        }

        const die = c.dwarf.dies.items[die_id];
        const s = try c.parseStructureImpl(die_addr, die_id);

        const id = try c.addStruct(s);
        c.types.items[s.type_id].struct_id = id;
        c.types.items[s.type_id].struct_type = switch (die.tag) {
            .structure_type => .struct_type,
            .union_type => .union_type,
            .class_type => .class_type,
            else => unreachable,
        };

        return s;
    }

    pub fn parseStructureImpl(c: *Context, die_addr: usize, die_id: Dwarf.DieId) TypeError!Structure {
        const die = c.dwarf.dies.items[die_id];
        const stype_id = try c.readTypeAtAddressAndSkip(die_addr);

        const member_top_start = c.member_scratch_stack.top;
        defer c.member_scratch_stack.popTo(member_top_start);
        const structure_top_start = c.structure_scratch_stack.top;
        defer c.structure_scratch_stack.popTo(structure_top_start);

        if (die.has_children) {
            while (c.dwarf.readNextDie()) |child_die_addr| {
                const child_die_id = try c.dwarf.readDieIdAtAddress(child_die_addr) orelse break;
                const child_die = c.dwarf.dies.items[child_die_id];

                switch (child_die.tag) {
                    Dwarf.DW_TAG.member => {
                        var member = mem.zeroes(StructMember);
                        for (c.dwarf.getAttrs(child_die.attr_range)) |attr| {
                            switch (attr.at) {
                                .type => {
                                    const type_addr = @intCast(u32, try c.dwarf.readFormData(attr.form));
                                    c.dwarf.pushAddress();
                                    member.type_id = try c.readTypeAtAddressAndNoSkip(type_addr);
                                    c.dwarf.popAddress();
                                },
                                .data_member_location => member.mem_loc = @intCast(u32, try c.dwarf.readFormData(attr.form)),
                                .name => member.name = try c.dwarf.readString(attr.form),
                                else => c.dwarf.skipFormData(attr.form),
                            }
                        }

                        c.member_scratch_stack.push(member);
                    },
                    .structure_type => {
                        const s = try c.parseStructureImpl(child_die_addr, child_die_id);
                        c.types.items[s.type_id].struct_type = .struct_type;
                        c.structure_scratch_stack.push(s);
                    },
                    .union_type => {
                        const s = try c.parseStructureImpl(child_die_addr, child_die_id);
                        c.types.items[s.type_id].struct_type = .union_type;
                        c.structure_scratch_stack.push(s);
                    },
                    .class_type => {
                        const s = try c.parseStructureImpl(child_die_addr, child_die_id);
                        c.types.items[s.type_id].struct_type = .class_type;
                        c.structure_scratch_stack.push(s);
                    },
                    else => try c.dwarf.skipDieAndChildren(child_die_id),
                }
            }
        }

        const member_start_id = c.members.items.len;
        try c.members.appendSlice(c.member_scratch_stack.sliceFrom(member_top_start));
        const member_end_id = c.members.items.len;

        const struct_start_id = c.structures.items.len;
        for (c.structure_scratch_stack.sliceFrom(structure_top_start)) |s| {
            const id = try c.addStruct(s);
            c.types.items[s.type_id].struct_id = id;
        }
        const struct_end_id = c.structures.items.len;

        const structure = Structure{
            .type_id = stype_id,
            .member_range = MemberRange{
                .start = @intCast(MemberId, member_start_id),
                .end = @intCast(MemberId, member_end_id),
            },
            .inline_structures = StructRange{
                .start = @intCast(StructId, struct_start_id),
                .end = @intCast(StructId, struct_end_id),
            },
        };

        return structure;
    }

    pub fn readTypeAtAddressAndNoSkip(c: *Context, type_addr: usize) TypeError!TypeId {
        if (c.type_addresses[type_addr] != std.math.maxInt(TypeId)) {
            return c.type_addresses[type_addr];
        }

        return try c.readTypeAtAddressIfNotCached(type_addr);
    }

    pub fn readTypeAtAddressAndSkip(c: *Context, type_addr: usize) TypeError!TypeId {
        const die_id = try c.dwarf.readDieIdAtAddress(type_addr) orelse unreachable;
        if (c.type_addresses[type_addr] != std.math.maxInt(TypeId)) {
            c.dwarf.skipDieAttrs(die_id);
            return c.type_addresses[type_addr];
        }

        return try c.readTypeAtAddressIfNotCached(type_addr);
    }

    pub fn readTypeAtAddressIfNotCached(c: *Context, type_addr: usize) TypeError!TypeId {
        const die_id = try c.dwarf.readDieIdAtAddress(type_addr) orelse unreachable;
        const die = c.dwarf.dies.items[die_id];
        const default_name = if (die.tag == .structure_type or die.tag == .union_type or die.tag == .class_type) "" else "void";

        var name: ?[]const u8 = null;
        var size: ?u32 = if (die.tag == Dwarf.DW_TAG.pointer_type) 8 else null;
        var inner_type_id: ?u32 = null;
        for (c.dwarf.getAttrs(die.attr_range)) |attr| {
            switch (attr.at) {
                Dwarf.DW_AT.name => {
                    name = try c.dwarf.readString(attr.form);
                },
                Dwarf.DW_AT.byte_size => {
                    size = @intCast(u32, try c.dwarf.readFormData(attr.form));
                },
                Dwarf.DW_AT.type => {
                    const inner_type_address = @intCast(u32, try c.dwarf.readFormData(attr.form));
                    c.dwarf.pushAddress();
                    inner_type_id = try c.readTypeAtAddressAndNoSkip(inner_type_address);
                    c.dwarf.popAddress();
                },
                else => {
                    c.dwarf.skipFormData(attr.form);
                },
            }
        }

        var dimension: u32 = std.math.maxInt(u32);
        if (die.tag == Dwarf.DW_TAG.array_type) {
            dimension = 1;
            std.debug.assert(die.has_children);
            while (c.dwarf.readDieIfTag(Dwarf.DW_TAG.subrange_type)) |child_die| {
                for (c.dwarf.getAttrs(child_die.attr_range)) |child_attr| {
                    switch (child_attr.at) {
                        Dwarf.DW_AT.upper_bound, Dwarf.DW_AT.count => {
                            const array_dim = blk: {
                                const val = @intCast(u64, try c.dwarf.readFormData(child_attr.form));
                                if (val == std.math.maxInt(u64)) {
                                    break :blk 0;
                                } else {
                                    break :blk val;
                                }
                            };
                            dimension *= @intCast(u32, array_dim);
                        },
                        else => {
                            c.dwarf.skipFormData(child_attr.form);
                        },
                    }
                }
            }
        }

        var ptr_count: u8 = if (die.tag == Dwarf.DW_TAG.pointer_type) 1 else 0;
        if (inner_type_id) |inner_id| {
            if (name == null) {
                name = c.types.items[inner_id].name;
            }
            if (size == null) {
                size = c.types.items[inner_id].size;
            }

            ptr_count += c.types.items[inner_id].ptr_count;
        }

        const id = try c.addType(Type{
            .name = if (name) |n| n else default_name,
            .size = if (size) |s| s else 0,
            .ptr_count = ptr_count,
            .dimension = dimension,
        });
        c.type_addresses[type_addr] = id;

        return id;
    }

    pub fn readTypedefAtAddress(c: *Context, typedef_address: usize) !void {
        const die_id = try c.dwarf.readDieIdAtAddress(typedef_address) orelse unreachable;
        const die = c.dwarf.dies.items[die_id];

        var name: []const u8 = "";
        var inner_type_address_opt: ?usize = null;
        var inner_type_id: TypeId = 0;
        var s: Structure = undefined;

        for (c.dwarf.getAttrs(die.attr_range)) |attr| {
            switch (attr.at) {
                Dwarf.DW_AT.name => {
                    name = try c.dwarf.readString(attr.form);
                },
                Dwarf.DW_AT.type => {
                    inner_type_address_opt = @intCast(u32, try c.dwarf.readFormData(attr.form));
                    const inner_type_address = inner_type_address_opt.?;

                    c.dwarf.pushAddress();
                    defer c.dwarf.popAddress();

                    const inner_die_id = try c.dwarf.readDieIdAtAddress(inner_type_address) orelse unreachable;
                    const inner_die = c.dwarf.dies.items[inner_die_id];
                    if (inner_die.tag == .structure_type or inner_die.tag == .union_type or inner_die.tag == .class_type) {
                        inner_type_id = try c.readTypeAtAddressAndSkip(inner_type_address);
                        const inner_type = c.types.items[inner_type_id];
                        if (inner_type.struct_id != InvalidStructId) {
                            s = c.structures.items[inner_type.struct_id];
                        } else {
                            s = try c.parseStructure(inner_type_address, inner_die_id);
                        }
                    }
                },
                else => {
                    c.dwarf.skipFormData(attr.form);
                },
            }
        }

        if (inner_type_address_opt) |inner_type_address| {
            c.dwarf.pushAddress();
            defer c.dwarf.popAddress();

            const in_die_id = try c.dwarf.readDieIdAtAddress(inner_type_address) orelse unreachable;
            const in_die = c.dwarf.dies.items[in_die_id];
            if (in_die.tag == .structure_type or in_die.tag == .union_type or in_die.tag == .class_type) {
                const id = try c.addType(Type{
                    .name = name,
                    .size = c.types.items[inner_type_id].size,
                    .ptr_count = c.types.items[inner_type_id].ptr_count,
                    .dimension = c.types.items[inner_type_id].dimension,
                });
                c.type_addresses[typedef_address] = id;
                const container = Structure{
                    .type_id = id,
                    .member_range = s.member_range,
                    .inline_structures = s.inline_structures,
                };

                const struct_id = try c.addStruct(container);
                c.types.items[id].struct_id = struct_id;
                c.types.items[id].struct_type = switch (in_die.tag) {
                    .structure_type => .struct_type,
                    .union_type => .union_type,
                    .class_type => .class_type,
                    else => unreachable,
                };
            } else {
                return;
            }
        } else {
            return;
        }
    }

    pub fn printStructImpl(
        c: *Context,
        sid: StructId,
        s: Structure,
        stdout: anytype,
        left_pad: usize,
        mem_offset: usize,
        member_name: []const u8,
    ) !void {
        const members = c.members.items[s.member_range.start..s.member_range.end];

        var type_name_pad: usize = 0;
        var member_name_pad: usize = 0;
        for (members) |member| {
            const mtype = c.types.items[member.type_id];
            const skip = s.inline_structures.contains(mtype.struct_id);
            if (skip) {
                continue;
            }

            type_name_pad = @maximum(type_name_pad, mtype.name.len + mtype.ptr_count);
            if (mtype.isArray()) {
                member_name_pad = @maximum(member_name_pad, member.name.len + fmt.count("[{d}]", .{mtype.dimension}));
            } else {
                member_name_pad = @maximum(member_name_pad, member.name.len);
            }
        }

        const stype = c.types.items[s.type_id];
        const container_prefix = switch (stype.struct_type) {
            .struct_type => "struct",
            .union_type => "union",
            .class_type => "class",
            else => unreachable,
        };
        if (stype.name.len == 0) {
            try stdout.print("{s: >[2]} {{ // size={}\n", .{ container_prefix, stype.size, left_pad + container_prefix.len });
        } else {
            try stdout.print("{s: >[1]} ", .{ container_prefix, left_pad + container_prefix.len });
            if (c.namespaces.items.len > 0) {
                var ni = c.namespaces.items.len;
                while (ni > 0) {
                    ni -= 1;
                    const ns = c.namespaces.items[ni];
                    const in = ns.struct_range.contains(sid);

                    if (in) {
                        try stdout.print("{s}::", .{ns.name});
                    }
                }
            }
            try stdout.print("{s} {{ // size={}\n", .{ stype.name, stype.size });
        }
        for (members) |member| {
            const mtype = c.types.items[member.type_id];
            if (s.inline_structures.contains(mtype.struct_id)) {
                try c.printStructImpl(
                    mtype.struct_id,
                    c.structures.items[mtype.struct_id],
                    stdout,
                    left_pad + 2,
                    member.mem_loc + mem_offset,
                    member.name,
                );
                continue;
            }

            try stdout.print("{s: >[4]} {s:*<[5]}{s: <[6]}{s}", .{
                mtype.name,
                "",
                "",
                member.name,
                left_pad + 2 + mtype.name.len,
                mtype.ptr_count,
                type_name_pad - mtype.name.len - mtype.ptr_count,
            });
            var written = member.name.len;
            var size = mtype.size;
            if (mtype.isArray()) {
                try stdout.print("[{d}]", .{mtype.dimension});
                size *= @intCast(u32, mtype.dimension);
                written += fmt.count("[{d}]", .{mtype.dimension});
            }
            try stdout.print(";{s: <[3]} // size={}, offset={}\n", .{
                "",
                size,
                mem_offset + member.mem_loc,
                member_name_pad - written,
            });
        }
        if (member_name.len > 0) {
            try stdout.print("{s: <[2]}}} {s};\n", .{ "", member_name, left_pad });
        } else {
            try stdout.print("{s: <[1]}}};\n", .{ "", left_pad });
        }
    }

    pub fn printStruct(
        c: *Context,
        sid: StructId,
        s: Structure,
        stdout: anytype,
    ) !void {
        try c.printStructImpl(sid, s, stdout, 0, 0, "");
    }

    pub fn printContainers(c: *Context) !void {
        const stdout_file = std.io.getStdOut().writer();
        var bw = std.io.BufferedWriter(MegaByte, @TypeOf(stdout_file)){ .unbuffered_writer = stdout_file };
        const stdout = bw.writer();

        for (c.structures.items) |s, sid| {
            const stype = c.types.items[s.type_id];
            if (stype.size > 0 and stype.name.len > 0) {
                try c.printStruct(@intCast(u32, sid), s, stdout);
            }
        }

        try bw.flush();
    }
};

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    if (std.os.argv.len != 2) {
        std.log.warn("usage: {s} <exec path>", .{std.os.argv[0]});
        return;
    }

    const exec_path = mem.span(std.os.argv[1]);
    const file = try std.fs.cwd().openFile(exec_path, .{});
    defer file.close();
    const file_size = try file.getEndPos();
    var exec_bin = try arena.alloc(u8, file_size);
    const read = try file.readAll(exec_bin);
    std.debug.assert(read == file_size);
    var buffer = Buffer{ .data = exec_bin, .curr_pos = 0 };
    var sections = try elf.getSectionsDebugSections(&buffer, arena);

    var timer = try std.time.Timer.start();
    var dwarf = try Dwarf.init(
        &sections.debug_abbrev,
        sections.debug_info,
        sections.debug_str,
        sections.debug_str_offsets,
        arena,
    );
    const ns = timer.read();
    std.debug.print("Dwarf init: {}\n", .{std.fmt.fmtDuration(ns)});
    var context = try Context.init(arena, dwarf);
    try context.run();
}
