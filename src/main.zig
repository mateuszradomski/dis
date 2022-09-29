const std = @import("std");
const fmt = std.fmt;
const Dwarf = @import("dwarf.zig");

const KiloByte = 1024;
const MegaByte = KiloByte * 1024;

const ELFFileHeader = struct {
    eh_magic: [4]u8,
    eh_class: u8,
    eh_data: u8,
    eh_version: u8,
    eh_osabi: u8,
    eh_abi_version: u8,
    eh_pad: u8,

    e_type: u16,
    e_machine: u16,
    e_version: u32,
    e_entry: usize,
    e_phoff: usize,
    e_shoff: usize,
    e_flags: u32,
    e_ehsize: u16,
    e_phentsize: u16,
    e_phnum: u16,
    e_shentsize: u16,
    e_shnum: u16,
    e_shstrndx: u16,
};

const ELFSectionHeader = struct {
    sh_name: u32,
    sh_type: u32,
    sh_flags: usize,
    sh_addr: usize,
    sh_offset: usize,
    sh_size: usize,
    sh_link: u32,
    sh_info: u32,
    sh_addralign: usize,
    sh_entsize: usize,
};

const ELFRelocationType = enum(u32) {
    R_X86_64_NONE = 0,
    R_X86_64_64 = 1,
    R_X86_64_PC32 = 2,
    R_X86_64_GOT32 = 3,
    R_X86_64_PLT32 = 4,
    R_X86_64_COPY = 5,
    R_X86_64_GLOB_DAT = 6,
    R_X86_64_JUMP_SLOT = 7,
    R_X86_64_RELATIVE = 8,
    R_X86_64_GOTPCREL = 9,
    R_X86_64_32 = 10,
    R_X86_64_32S = 11,
    R_X86_64_16 = 12,
    R_X86_64_PC16 = 13,
    R_X86_64_8 = 14,
    R_X86_64_PC8 = 15,
    R_X86_64_DTPMOD64 = 16,
    R_X86_64_DTPOFF64 = 17,
    R_X86_64_TPOFF64 = 18,
    R_X86_64_TLSGD = 19,
    R_X86_64_TLSLD = 20,
    R_X86_64_DTPOFF32 = 21,
    R_X86_64_GOTTPOFF = 22,
    R_X86_64_TPOFF32 = 23,
    R_X86_64_PC64 = 24,
    R_X86_64_GOTOFF64 = 25,
    R_X86_64_GOTPC32 = 26,
    R_X86_64_GOT64 = 27,
    R_X86_64_GOTPCREL64 = 28,
    R_X86_64_GOTPC64 = 29,
    R_X86_64_GOTPLT64 = 30,
    R_X86_64_PLTOFF64 = 31,
    R_X86_64_SIZE32 = 32,
    R_X86_64_SIZE64 = 33,
    R_X86_64_GOTPC32_TLSDESC = 34,
    R_X86_64_TLSDESC_CALL = 35,
    R_X86_64_TLSDESC = 36,
    R_X86_64_IRELATIVE = 37,
    R_X86_64_RELATIVE64 = 38,
    R_X86_64_GOTPCRELX = 41,
    R_X86_64_REX_GOTPCRELX = 42,
    R_X86_64_NUM = 43,
};

const ELFSymbol = struct {
    st_name: u32,
    st_info: u8,
    st_other: u8,
    st_shndx: u16,
    st_value: u64,
    st_size: u64,
};

const ELFRelocation = struct {
    r_offset: usize,
    r_info: u64,
};

const ELFRelocationA = struct {
    r_offset: usize,
    r_info: u64,
    r_addend: i64,
    const Self = @This();

    pub fn symbolIndex(s: Self) u64 {
        return s.r_info >> 32;
    }

    pub fn relocationType(s: Self) ELFRelocationType {
        return @intToEnum(ELFRelocationType, @truncate(u32, s.r_info));
    }
};

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

    pub fn consumeUntil(self: *Buffer, delim: u8) ?[]u8 {
        if (std.mem.indexOfScalar(u8, self.data[self.curr_pos..], delim)) |pos| {
            const r = self.data[self.curr_pos .. self.curr_pos + pos];
            self.curr_pos += pos + 1;
            return r;
        } else {
            return null;
        }
    }

    pub fn consumeType(self: *Buffer, comptime T: type) ?T {
        var opt_slice = self.consume(@sizeOf(T));
        if (opt_slice) |slice| {
            return std.mem.bytesToValue(T, slice[0..@sizeOf(T)]);
        } else {
            return null;
        }
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

pub fn Range(comptime T: type) type {
    return struct {
        start: T = std.math.maxInt(T),
        end: T = std.math.maxInt(T),

        const Self = @This();

        pub fn len(s: Self) usize {
            return @intCast(usize, s.end) - @intCast(usize, s.start);
        }

        pub fn contains(s: Self, id: T) bool {
            return s.start <= id and s.end > id;
        }
    };
}

const TypeId = u32;
const Type = struct {
    name: []const u8,
    size: u32,
    dimension: u32,
    ptr_count: u8,

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
const StructRange = Range(StructId);

const Structure = struct {
    type_id: TypeId,
    member_range: MemberRange,
    inline_structures: StructRange = .{},
    inline_unions: StructRange = .{},
};

const ContainerType = enum(u8) {
    Struct,
    Union,
    Class,

    const Self = @This();

    pub fn getPrefix(self: Self) []const u8 {
        return switch (self) {
            .Struct => "struct",
            .Union => "union",
            .Class => "class",
        };
    }
};

const Context = struct {
    const Self = @This();

    types: std.ArrayList(Type),
    type_addresses: std.AutoHashMap(usize, TypeId),
    structures: std.ArrayList(Structure),
    structure_types: std.AutoHashMap(TypeId, StructId),
    unions: std.ArrayList(Structure),
    union_types: std.AutoHashMap(TypeId, StructId),
    classes: std.ArrayList(Structure),
    class_types: std.AutoHashMap(TypeId, StructId),
    members: std.ArrayList(StructMember),
    dwarf: Dwarf,

    gpa: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, dwarf: Dwarf) !Self {
        var c = Context{
            .types = std.ArrayList(Type).init(allocator),
            .type_addresses = std.AutoHashMap(usize, u32).init(allocator),
            .structures = std.ArrayList(Structure).init(allocator),
            .structure_types = std.AutoHashMap(TypeId, StructId).init(allocator),
            .unions = std.ArrayList(Structure).init(allocator),
            .union_types = std.AutoHashMap(TypeId, StructId).init(allocator),
            .classes = std.ArrayList(Structure).init(allocator),
            .class_types = std.AutoHashMap(TypeId, StructId).init(allocator),
            .members = std.ArrayList(StructMember).init(allocator),
            .dwarf = dwarf,
            .gpa = allocator,
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

    pub fn addUnion(c: *Self, s: Structure) !StructId {
        const id = @intCast(StructId, c.unions.items.len);
        try c.unions.append(s);
        return id;
    }

    pub fn addClass(c: *Self, s: Structure) !StructId {
        const id = @intCast(StructId, c.classes.items.len);
        try c.classes.append(s);
        return id;
    }

    pub fn run(c: *Self) !void {
        {
            var timer = try std.time.Timer.start();
            for (c.dwarf.cus.items) |cu| {
                c.dwarf.setCu(cu);
                while (c.dwarf.readNextDie()) |die_addr| {
                    const die_opt = try c.dwarf.readDieAtAddress(die_addr);

                    if (die_opt == null) {
                        continue;
                    }
                    const die = die_opt.?;

                    switch (die.tag) {
                        Dwarf.DW_TAG.structure_type => {
                            const s = try c.parseStructure(die_addr);
                            const id = try c.addStruct(s);
                            try c.structure_types.put(s.type_id, id);
                        },
                        Dwarf.DW_TAG.union_type => {
                            const s = try c.parseStructure(die_addr);
                            const id = try c.addUnion(s);
                            try c.union_types.put(s.type_id, id);
                        },
                        Dwarf.DW_TAG.class_type => {
                            const s = try c.parseStructure(die_addr);
                            const id = try c.addClass(s);
                            try c.class_types.put(s.type_id, id);
                        },
                        Dwarf.DW_TAG.typedef => {
                            try c.readTypedefAtAddress(die_addr);
                        },
                        Dwarf.DW_TAG.compile_unit => {
                            c.dwarf.skipDieAttrs(die);
                        },
                        else => {
                            try c.dwarf.skipDieAndChildren(die);
                        },
                    }
                }
            }
            const ns = timer.read();
            std.debug.print("Parsing: {}\n", .{std.fmt.fmtDuration(ns)});
        }

        {
            var timer = try std.time.Timer.start();
            try c.printStructures();
            try c.printUnions();
            try c.printClasses();
            const ns = timer.read();
            std.debug.print("Printing: {}\n", .{std.fmt.fmtDuration(ns)});
        }

        std.log.debug("types {}/{}", .{ c.types.items.len, fmt.fmtIntSizeDec(c.types.items.len * @sizeOf(Type)) });
        std.log.debug("structures {}/{}", .{ c.structures.items.len, fmt.fmtIntSizeDec(c.structures.items.len * @sizeOf(Structure)) });
        std.log.debug("unions {}/{}", .{ c.unions.items.len, fmt.fmtIntSizeDec(c.unions.items.len * @sizeOf(Structure)) });
        std.log.debug("classes {}/{}", .{ c.classes.items.len, fmt.fmtIntSizeDec(c.classes.items.len * @sizeOf(Structure)) });
        std.log.debug("members {}/{}", .{ c.members.items.len, fmt.fmtIntSizeDec(c.members.items.len * @sizeOf(StructMember)) });
    }

    pub fn parseStructure(c: *Context, die_addr: usize) !Structure {
        var structure = std.mem.zeroes(Structure);
        structure.type_id = try c.readTypeAtAddress(die_addr);

        var arena_instance = std.heap.ArenaAllocator.init(c.gpa);
        defer arena_instance.deinit();
        const arena = arena_instance.allocator();

        var member_stack = std.ArrayList(StructMember).init(arena);
        defer member_stack.deinit();
        var structure_stack = std.ArrayList(Structure).init(arena);
        defer structure_stack.deinit();
        var union_stack = std.ArrayList(Structure).init(arena);
        defer union_stack.deinit();

        while (c.dwarf.readNextDie()) |child_die_addr| {
            const die_opt = try c.dwarf.readDieAtAddress(child_die_addr);

            if (die_opt == null) {
                break;
            }
            const die = die_opt.?;
            if (die.tag == Dwarf.DW_TAG.padding) {
                break;
            }

            switch (die.tag) {
                Dwarf.DW_TAG.member => {
                    var member = std.mem.zeroes(StructMember);
                    for (c.dwarf.getAttrs(die.attr_range)) |attr| {
                        switch (attr.at) {
                            Dwarf.DW_AT.data_member_location => {
                                member.mem_loc = @intCast(u32, try c.dwarf.readFormData(attr.form));
                            },
                            Dwarf.DW_AT.type => {
                                const type_addr = @intCast(u32, try c.dwarf.readFormData(attr.form));
                                c.dwarf.pushAddress();
                                member.type_id = try c.readTypeAtAddress(type_addr);
                                c.dwarf.popAddress();
                            },
                            Dwarf.DW_AT.name => {
                                member.name = try c.dwarf.readString(attr.form);
                            },
                            else => {
                                c.dwarf.skipFormData(attr.form);
                            },
                        }
                    }

                    try member_stack.append(member);
                },
                Dwarf.DW_TAG.structure_type => {
                    try structure_stack.append(try c.parseStructure(child_die_addr));
                },
                Dwarf.DW_TAG.union_type => {
                    try union_stack.append(try c.parseStructure(child_die_addr));
                },
                else => {
                    try c.dwarf.skipDieAndChildren(die);
                },
            }
        }

        const member_start_id = c.members.items.len;
        try c.members.appendSlice(member_stack.toOwnedSlice());
        const member_end_id = c.members.items.len;

        const struct_start_id = c.structures.items.len;
        for (structure_stack.toOwnedSlice()) |s| {
            const id = try c.addStruct(s);
            try c.structure_types.put(s.type_id, id);
        }
        const struct_end_id = c.structures.items.len;

        const union_start_id = c.unions.items.len;
        for (union_stack.toOwnedSlice()) |s| {
            const id = try c.addUnion(s);
            try c.union_types.put(s.type_id, id);
        }
        const union_end_id = c.unions.items.len;

        structure.member_range = MemberRange{
            .start = @intCast(MemberId, member_start_id),
            .end = @intCast(MemberId, member_end_id),
        };
        structure.inline_structures = StructRange{
            .start = @intCast(StructId, struct_start_id),
            .end = @intCast(StructId, struct_end_id),
        };
        structure.inline_unions = StructRange{
            .start = @intCast(StructId, union_start_id),
            .end = @intCast(StructId, union_end_id),
        };
        return structure;
    }

    pub fn readStructureMembers(c: *Context) !MemberRange {
        var arena_instance = std.heap.ArenaAllocator.init(c.gpa);
        defer arena_instance.deinit();
        const arena = arena_instance.allocator();
        var member_stack = std.ArrayList(StructMember).init(arena);
        defer member_stack.deinit();

        while (c.dwarf.readNextDie()) |die_addr| {
            const die_opt = try c.dwarf.readDieAtAddress(die_addr);

            if (die_opt == null) {
                break;
            }
            const die = die_opt.?;
            if (die.tag == Dwarf.DW_TAG.padding) {
                break;
            }

            switch (die.tag) {
                Dwarf.DW_TAG.member => {
                    var member = std.mem.zeroes(StructMember);
                    for (c.dwarf.getAttrs(die.attr_range)) |attr| {
                        switch (attr.at) {
                            Dwarf.DW_AT.data_member_location => {
                                member.mem_loc = @intCast(u32, try c.dwarf.readFormData(attr.form));
                            },
                            Dwarf.DW_AT.type => {
                                const type_addr = @intCast(u32, try c.dwarf.readFormData(attr.form));
                                c.dwarf.pushAddress();
                                member.type_id = try c.readTypeAtAddress(type_addr);
                                c.dwarf.popAddress();
                            },
                            Dwarf.DW_AT.name => {
                                member.name = try c.dwarf.readString(attr.form);
                            },
                            else => {
                                c.dwarf.skipFormData(attr.form);
                            },
                        }
                    }

                    try member_stack.append(member);
                },
                else => {
                    try c.dwarf.skipDieAndChildren(die);
                },
            }
        }

        const start_index = c.members.items.len;
        try c.members.appendSlice(member_stack.toOwnedSlice());
        const end_index = c.members.items.len;

        return MemberRange{ .start = @intCast(MemberId, start_index), .end = @intCast(MemberId, end_index) };
    }

    pub fn readTypeAtAddress(c: *Context, type_addr: usize) !TypeId {
        const global_type_addr = c.dwarf.toGlobalAddr(type_addr);
        const die_opt = try c.dwarf.readDieAtAddress(type_addr);
        const die = die_opt.?;

        if (c.type_addresses.get(global_type_addr)) |id| {
            // TODO(radomski): When the type is already cached we do not
            // read over the attrs, and that causes the upper function to
            // fail. We somehow need to skip the attrs if we already read
            // that type.
            c.dwarf.skipDieAttrs(die);
            return id;
        }

        const default_name = if (die.tag == Dwarf.DW_TAG.structure_type or die.tag == Dwarf.DW_TAG.union_type) "" else "void";

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
                    inner_type_id = try c.readTypeAtAddress(inner_type_address);
                    c.dwarf.popAddress();
                },
                else => {
                    c.dwarf.skipFormData(attr.form);
                },
            }
        }

        var dimension: u32 = 1;
        var is_array = false;
        if (die.tag == Dwarf.DW_TAG.array_type) {
            std.debug.assert(die.has_children);
            is_array = true;
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

            // TODO(radomski): check if needed
            // dimension *= c.types.items[inner_id].dimension;
            ptr_count += c.types.items[inner_id].ptr_count;
        }

        const id = try c.addType(Type{
            .name = if (name) |n| n else default_name,
            .size = if (size) |s| s else 0,
            .ptr_count = ptr_count,
            .dimension = if (is_array) dimension else std.math.maxInt(@TypeOf(dimension)),
        });
        try c.type_addresses.put(global_type_addr, id);

        return id;
    }

    pub fn readTypedefAtAddress(c: *Context, typedef_address: usize) !void {
        const die_opt = try c.dwarf.readDieAtAddress(typedef_address);
        const die = die_opt.?;

        var name: []const u8 = "";
        var inner_type_address_opt: ?usize = null;
        var inner_type_id: TypeId = 0;
        var member_range: MemberRange = undefined;

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

                    const inner_die_opt = try c.dwarf.readDieAtAddress(inner_type_address);
                    const inner_die = inner_die_opt.?;
                    if (inner_die.tag == Dwarf.DW_TAG.structure_type or inner_die.tag == Dwarf.DW_TAG.union_type) {
                        inner_type_id = try c.readTypeAtAddress(inner_type_address);
                        member_range = try c.readStructureMembers();
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

            const in_die_opt = try c.dwarf.readDieAtAddress(inner_type_address);
            const in_die = in_die_opt.?;
            if (in_die.tag == Dwarf.DW_TAG.structure_type or in_die.tag == Dwarf.DW_TAG.union_type) {
                const id = try c.addType(Type{
                    .name = name,
                    .size = c.types.items[inner_type_id].size,
                    .ptr_count = c.types.items[inner_type_id].ptr_count,
                    .dimension = c.types.items[inner_type_id].dimension,
                });
                try c.type_addresses.put(c.dwarf.toGlobalAddr(typedef_address), id);
                const container = Structure{ .type_id = id, .member_range = member_range };
                switch (in_die.tag) {
                    Dwarf.DW_TAG.structure_type => {
                        try c.structures.append(container);
                    },
                    Dwarf.DW_TAG.union_type => {
                        try c.unions.append(container);
                    },
                    else => unreachable,
                }
            } else {
                return;
            }
        } else {
            return;
        }
    }

    pub fn printStructImpl(
        c: *Context,
        s: Structure,
        stdout: anytype,
        container_type: ContainerType,
        left_pad: usize,
        mem_offset: usize,
    ) !void {
        const members = c.members.items[s.member_range.start..s.member_range.end];

        var type_name_pad: usize = 0;
        var member_name_pad: usize = 0;
        for (members) |member| {
            const mtype = c.types.items[member.type_id];
            type_name_pad = @maximum(type_name_pad, mtype.name.len + mtype.ptr_count);
            if (mtype.isArray()) {
                member_name_pad = @maximum(member_name_pad, member.name.len + fmt.count("[{d}]", .{mtype.dimension}));
            } else {
                member_name_pad = @maximum(member_name_pad, member.name.len);
            }
        }

        const stype = c.types.items[s.type_id];
        const container_prefix = container_type.getPrefix();
        if (stype.name.len == 0) {
            try stdout.print("{s: >[2]} {{ // size={}\n", .{ container_prefix, stype.size, left_pad + container_prefix.len });
        } else {
            try stdout.print("{s: >[3]} {s} {{ // size={}\n", .{ container_prefix, stype.name, stype.size, left_pad + container_prefix.len });
        }
        for (members) |member| {
            const mtype = c.types.items[member.type_id];

            if (c.structure_types.get(member.type_id)) |struct_id| {
                if (s.inline_structures.contains(struct_id)) {
                    try c.printStructImpl(
                        c.structures.items[struct_id],
                        stdout,
                        .Struct,
                        left_pad + 2,
                        member.mem_loc + mem_offset,
                    );
                    continue;
                }
            }
            if (c.union_types.get(member.type_id)) |union_id| {
                if (s.inline_unions.contains(union_id)) {
                    try c.printStructImpl(
                        c.unions.items[union_id],
                        stdout,
                        .Union,
                        left_pad + 2,
                        member.mem_loc + mem_offset,
                    );
                    continue;
                }
            }

            var size = mtype.size;

            try stdout.print("{s: >[1]} ", .{ mtype.name, left_pad + 2 + mtype.name.len });
            try stdout.print("{s:*<[2]}{s: <[3]}", .{ "", "", mtype.ptr_count, type_name_pad - mtype.name.len - mtype.ptr_count });
            try stdout.print("{s}", .{member.name});
            var written = member.name.len;
            if (mtype.isArray()) {
                try stdout.print("[{d}]", .{mtype.dimension});
                size *= @intCast(u32, mtype.dimension);
                written += fmt.count("[{d}]", .{mtype.dimension});
            }
            try stdout.print(";{s: <[1]}", .{ "", member_name_pad - written });
            try stdout.print(" // size={}, offset={}\n", .{ size, mem_offset + member.mem_loc });
        }
        try stdout.print("{s: <[1]}}};\n", .{ "", left_pad });
    }

    pub fn printStruct(
        c: *Context,
        s: Structure,
        stdout: anytype,
        container_type: ContainerType,
    ) !void {
        try c.printStructImpl(s, stdout, container_type, 0, 0);
    }

    pub fn printImpl(c: *Context, structures: []Structure, container_type: ContainerType) !void {
        const stdout_file = std.io.getStdOut().writer();
        var bw = std.io.BufferedWriter(MegaByte, @TypeOf(stdout_file)){ .unbuffered_writer = stdout_file };
        const stdout = bw.writer();

        for (structures) |s| {
            const stype = c.types.items[s.type_id];
            if (stype.size > 0 and stype.name.len > 0) {
                try c.printStruct(s, stdout, container_type);
            }
        }

        try bw.flush();
    }

    pub fn printStructures(c: *Context) !void {
        try c.printImpl(c.structures.items, .Struct);
    }

    pub fn printUnions(c: *Context) !void {
        try c.printImpl(c.unions.items, .Union);
    }

    pub fn printClasses(c: *Context) !void {
        try c.printImpl(c.classes.items, .Class);
    }
};

pub fn getSectionBuffer(
    section_headers: []const ELFSectionHeader,
    sh_bufferi_opt: ?usize,
    file_buffer: *Buffer,
) Buffer {
    if (sh_bufferi_opt) |sh_bufferi| {
        const sh_buffer = section_headers[sh_bufferi];
        file_buffer.curr_pos = sh_buffer.sh_offset;
        var sbuffer = file_buffer.consume(@intCast(u32, sh_buffer.sh_size)) orelse unreachable;
        var buffer = Buffer{ .data = sbuffer, .curr_pos = 0 };
        return buffer;
    } else {
        return Buffer{ .data = &[_]u8{} };
    }
}

pub fn relocateBuffer(buffer: Buffer, rela_buff: *Buffer, symtab_buff: *Buffer) void {
    const rela = std.mem.bytesAsSlice(ELFRelocationA, rela_buff.data);
    const symtab = std.mem.bytesAsSlice(ELFSymbol, symtab_buff.data);

    for (rela) |r| {
        switch (r.relocationType()) {
            ELFRelocationType.R_X86_64_64 => {
                const write_type = u64;
                const value: write_type = symtab[r.symbolIndex()].st_value +| @bitCast(write_type, r.r_addend);
                const value_bytes = std.mem.toBytes(value);
                std.mem.copy(u8, buffer.data[r.r_offset .. r.r_offset + @sizeOf(write_type)], &value_bytes);
            },
            ELFRelocationType.R_X86_64_32 => {
                const write_type = u32;
                const value: write_type = @truncate(u32, symtab[r.symbolIndex()].st_value) +| @bitCast(write_type, @intCast(i32, r.r_addend));
                const value_bytes = std.mem.toBytes(value);
                std.mem.copy(u8, buffer.data[r.r_offset .. r.r_offset + @sizeOf(write_type)], &value_bytes);
            },
            else => unreachable,
        }
    }
}

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    if (std.os.argv.len != 2) {
        std.log.warn("usage: {s} <exec path>", .{std.os.argv[0]});
        return;
    }

    const exec_path = std.mem.span(std.os.argv[1]);
    const file = try std.fs.cwd().openFile(exec_path, .{});
    defer file.close();
    const file_size = try file.getEndPos();
    const exec_bin = try file.readToEndAlloc(arena, file_size);
    var buffer = Buffer{ .data = exec_bin, .curr_pos = 0 };

    const header = buffer.consumeType(ELFFileHeader) orelse unreachable;
    buffer.curr_pos = header.e_shoff;
    var section_headers = try arena.alloc(ELFSectionHeader, header.e_shnum);
    for (section_headers) |_, i| {
        section_headers[i] = buffer.consumeType(ELFSectionHeader) orelse unreachable;
    }

    const shstrtab = section_headers[header.e_shstrndx];
    buffer.curr_pos = shstrtab.sh_offset;
    var sstrtab = buffer.consume(@intCast(u32, shstrtab.sh_size)) orelse unreachable;

    var sh_debug_infoi: ?usize = null;
    var sh_debug_info_relai: ?usize = null;
    var sh_debug_abbrevi: ?usize = null;
    var sh_debug_abbrev_relai: ?usize = null;
    var sh_debug_stri: ?usize = null;
    var sh_debug_str_relai: ?usize = null;
    var sh_debug_str_offsetsi: ?usize = null;
    var sh_debug_str_offsets_relai: ?usize = null;
    var sh_symtabi: ?usize = null;
    for (section_headers) |sh, i| {
        const name = blk: {
            if (std.mem.indexOfScalar(u8, sstrtab[sh.sh_name..], 0)) |pos| {
                break :blk sstrtab[sh.sh_name .. sh.sh_name + pos];
            } else {
                unreachable;
            }
        };

        if (std.mem.eql(u8, name, ".symtab")) {
            sh_symtabi = i;
        } else if (std.mem.eql(u8, name, ".debug_info")) {
            sh_debug_infoi = i;
        } else if (std.mem.eql(u8, name, ".rela.debug_info")) {
            sh_debug_info_relai = i;
        } else if (std.mem.eql(u8, name, ".debug_abbrev")) {
            sh_debug_abbrevi = i;
        } else if (std.mem.eql(u8, name, ".rela.debug_abbrev")) {
            sh_debug_abbrev_relai = i;
        } else if (std.mem.eql(u8, name, ".debug_str")) {
            sh_debug_stri = i;
        } else if (std.mem.eql(u8, name, ".rela.debug_str")) {
            sh_debug_str_relai = i;
        } else if (std.mem.eql(u8, name, ".debug_str_offsets")) {
            sh_debug_str_offsetsi = i;
        } else if (std.mem.eql(u8, name, ".rela.debug_str_offsets")) {
            sh_debug_str_offsets_relai = i;
        }
    }

    var symtab = getSectionBuffer(section_headers, sh_symtabi, &buffer);
    var debug_abbrev = getSectionBuffer(section_headers, sh_debug_abbrevi, &buffer);
    var debug_info = getSectionBuffer(section_headers, sh_debug_infoi, &buffer);
    var debug_str = getSectionBuffer(section_headers, sh_debug_stri, &buffer);
    var debug_str_offsets = getSectionBuffer(section_headers, sh_debug_str_offsetsi, &buffer);

    if (sh_debug_info_relai) |relai| {
        var rela = getSectionBuffer(section_headers, relai, &buffer);
        relocateBuffer(debug_info, &rela, &symtab);
    }
    if (sh_debug_abbrev_relai) |relai| {
        var rela = getSectionBuffer(section_headers, relai, &buffer);
        relocateBuffer(debug_abbrev, &rela, &symtab);
    }
    if (sh_debug_str_relai) |relai| {
        var rela = getSectionBuffer(section_headers, relai, &buffer);
        relocateBuffer(debug_str, &rela, &symtab);
    }
    if (sh_debug_str_offsets_relai) |relai| {
        var rela = getSectionBuffer(section_headers, relai, &buffer);
        relocateBuffer(debug_str_offsets, &rela, &symtab);
    }

    var timer = try std.time.Timer.start();
    var dwarf = try Dwarf.init(&debug_abbrev, debug_info, debug_str, debug_str_offsets, arena);
    const ns = timer.read();
    std.debug.print("Dwarf init: {}\n", .{std.fmt.fmtDuration(ns)});
    var context = try Context.init(arena, dwarf);
    try context.run();
}
