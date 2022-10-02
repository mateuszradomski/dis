const Buffer = @import("main.zig").Buffer;
const Range = @import("main.zig").Range;
const Range2T = @import("main.zig").Range2T;
const std = @import("std");

pub const DW_TAG = enum(u16) {
    padding = 0x00,
    array_type = 0x01,
    class_type = 0x02,
    entry_point = 0x03,
    enumeration_type = 0x04,
    formal_parameter = 0x05,
    imported_declaration = 0x08,
    label = 0x0a,
    lexical_block = 0x0b,
    member = 0x0d,
    pointer_type = 0x0f,
    reference_type = 0x10,
    compile_unit = 0x11,
    string_type = 0x12,
    structure_type = 0x13,
    subroutine_type = 0x15,
    typedef = 0x16,
    union_type = 0x17,
    unspecified_parameters = 0x18,
    variant = 0x19,
    common_block = 0x1a,
    common_inclusion = 0x1b,
    inheritance = 0x1c,
    inlined_subroutine = 0x1d,
    module = 0x1e,
    ptr_to_member_type = 0x1f,
    set_type = 0x20,
    subrange_type = 0x21,
    with_stmt = 0x22,
    access_declaration = 0x23,
    base_type = 0x24,
    catch_block = 0x25,
    const_type = 0x26,
    constant = 0x27,
    enumerator = 0x28,
    file_type = 0x29,
    friend = 0x2a,
    namelist = 0x2b,
    namelist_item = 0x2c,
    packed_type = 0x2d,
    subprogram = 0x2e,
    template_type_param = 0x2f,
    template_value_param = 0x30,
    thrown_type = 0x31,
    try_block = 0x32,
    variant_part = 0x33,
    variable = 0x34,
    volatile_type = 0x35,
    dwarf_procedure = 0x36,
    restrict_type = 0x37,
    interface_type = 0x38,
    namespace = 0x39,
    imported_module = 0x3a,
    unspecified_type = 0x3b,
    partial_unit = 0x3c,
    imported_unit = 0x3d,
    mutable_type = 0x3e,
    condition = 0x3f,
    shared_type = 0x40,
    type_unit = 0x41,
    rvalue_reference_type = 0x42,
    template_alias = 0x43,
    coarray_type = 0x44,
    generic_subrange = 0x45,
    dynamic_type = 0x46,
    atomic_type = 0x47,
    call_site = 0x48,
    call_site_parameter = 0x49,
    skeleton_unit = 0x4a,
    immutable_type = 0x4b,
    format_label = 0x4101,
    function_template = 0x4102,
    class_template = 0x4103,
    GNU_BINCL = 0x4104,
    GNU_EINCL = 0x4105,
    GNU_template_template_param = 0x4106,
    GNU_template_parameter_pack = 0x4107,
    GNU_formal_parameter_pack = 0x4108,
    GNU_call_site = 0x4109,
    GNU_call_site_parameter = 0x410a,
};

pub const DW_AT = enum(u8) {
    null = 0x00,
    sibling = 0x01,
    location = 0x02,
    name = 0x03,
    ordering = 0x09,
    subscr_data = 0x0a,
    byte_size = 0x0b,
    bit_offset = 0x0c,
    bit_size = 0x0d,
    element_list = 0x0f,
    stmt_list = 0x10,
    low_pc = 0x11,
    high_pc = 0x12,
    language = 0x13,
    member = 0x14,
    discr = 0x15,
    discr_value = 0x16,
    visibility = 0x17,
    import = 0x18,
    string_length = 0x19,
    common_reference = 0x1a,
    comp_dir = 0x1b,
    const_value = 0x1c,
    containing_type = 0x1d,
    default_value = 0x1e,
    inline_ = 0x20,
    is_optional = 0x21,
    lower_bound = 0x22,
    producer = 0x25,
    prototyped = 0x27,
    return_addr = 0x2a,
    start_scope = 0x2c,
    stride_size = 0x2e,
    upper_bound = 0x2f,
    abstract_origin = 0x31,
    accessibility = 0x32,
    address_class = 0x33,
    artificial = 0x34,
    base_types = 0x35,
    calling_convention = 0x36,
    count = 0x37,
    data_member_location = 0x38,
    decl_column = 0x39,
    decl_file = 0x3a,
    decl_line = 0x3b,
    declaration = 0x3c,
    discr_list = 0x3d,
    encoding = 0x3e,
    external = 0x3f,
    frame_base = 0x40,
    friend = 0x41,
    identifier_case = 0x42,
    macro_info = 0x43,
    namelist_items = 0x44,
    priority = 0x45,
    segment = 0x46,
    specification = 0x47,
    static_link = 0x48,
    type = 0x49,
    use_location = 0x4a,
    variable_parameter = 0x4b,
    virtuality = 0x4c,
    vtable_elem_location = 0x4d,
    allocated = 0x4e,
    associated = 0x4f,
    data_location = 0x50,
    byte_stride = 0x51,
    entry_pc = 0x52,
    use_UTF8 = 0x53,
    extension = 0x54,
    ranges = 0x55,
    trampoline = 0x56,
    call_column = 0x57,
    call_file = 0x58,
    call_line = 0x59,
    description = 0x5a,
    binary_scale = 0x5b,
    decimal_scale = 0x5c,
    small = 0x5d,
    decimal_sign = 0x5e,
    digit_count = 0x5f,
    picture_string = 0x60,
    mutable = 0x61,
    threads_scaled = 0x62,
    explicit = 0x63,
    object_pointer = 0x64,
    endianity = 0x65,
    elemental = 0x66,
    pure = 0x67,
    recursive = 0x68,
    signature = 0x69,
    main_subprogram = 0x6a,
    data_bit_offset = 0x6b,
    const_expr = 0x6c,
    enum_class = 0x6d,
    linkage_name = 0x6e,
    string_length_bit_size = 0x6f,
    string_length_byte_size = 0x70,
    rank = 0x71,
    str_offsets_base = 0x72,
    addr_base = 0x73,
    rnglists_base = 0x74,
    dwo_id = 0x75,
    dwo_name = 0x76,
    reference = 0x77,
    rvalue_reference = 0x78,
    macros = 0x79,
    call_all_calls = 0x7a,
    call_all_source_calls = 0x7b,
    call_all_tail_calls = 0x7c,
    call_return_pc = 0x7d,
    call_value = 0x7e,
    call_origin = 0x7f,
    call_parameter = 0x80,
    call_pc = 0x81,
    call_tail_call = 0x82,
    call_target = 0x83,
    call_target_clobbered = 0x84,
    call_data_location = 0x85,
    call_data_value = 0x86,
    noreturn = 0x87,
    alignment = 0x88,
    export_symbols = 0x89,
    deleted = 0x8a,
    defaulted = 0x8b,
    loclists_base = 0x8c,
    custom_non_spec = 0xff,
};

pub const DW_FORM = enum(u8) {
    null = 0x00,
    addr = 0x01,
    block2 = 0x03,
    block4 = 0x04,
    data2 = 0x05,
    data4 = 0x06,
    data8 = 0x07,
    string = 0x08,
    block = 0x09,
    block1 = 0x0a,
    data1 = 0x0b,
    flag = 0x0c,
    sdata = 0x0d,
    strp = 0x0e,
    udata = 0x0f,
    ref_addr = 0x10,
    ref1 = 0x11,
    ref2 = 0x12,
    ref4 = 0x13,
    ref8 = 0x14,
    ref_udata = 0x15,
    indirect = 0x16,
    sec_offset = 0x17,
    exprloc = 0x18,
    flag_present = 0x19,
    strx = 0x1a,
    addrx = 0x1b,
    ref_sup4 = 0x1c,
    strp_sup = 0x1d,
    data16 = 0x1e,
    line_strp = 0x1f,
    ref_sig8 = 0x20,
    implicit_const = 0x21,
    loclistx = 0x22,
    rnglistx = 0x23,
    ref_sup8 = 0x24,
    strx1 = 0x25,
    strx2 = 0x26,
    strx3 = 0x27,
    strx4 = 0x28,
    addrx1 = 0x29,
    addrx2 = 0x2a,
    addrx3 = 0x2b,
    addrx4 = 0x2c,
};

const AttrId = u24;
const AttrRangeLen = u8;
const AttrRange = Range2T(AttrId, AttrRangeLen);

const DwarfAttr = struct {
    at: DW_AT,
    form: DW_FORM,
};

const AttrSkipId = u24;
const AttrSkipRangeLen = u8;
const AttrSkipRange = Range2T(AttrSkipId, AttrSkipRangeLen);
const DwarfAttrSkip = struct {
    tag: Tag,
    n: u8 = 0,

    const Tag = enum(u8) {
        skip_n,
        skip_uleb,
        skip_c_string,
        read_u8_len_and_skip,
        read_u16_len_and_skip,
        read_u32_len_and_skip,
        read_uleb_len_and_skip,
    };
};

const DieId = u32;
const DieRange = Range(DieId);
const DwarfDie = struct {
    has_children: bool,
    sibling_attr_index: u8,
    tag: DW_TAG,
    code: u32,
    attr_range: AttrRange,
    attr_skip_range: AttrSkipRange,
};

const DwarfCompilationUnitHeader = struct {
    unit_length: usize,
    version: u16,
    debug_abbrev_offset: usize,
    address_size: u8,
};

const DwarfCompilationUnit = struct {
    header: DwarfCompilationUnitHeader,
    offset: usize,
    header_size: u8,
    dwarf_address_size: u8,
    die_range: DieRange,
};

const DwarfError = error{
    EndOfBuffer,
};

const Self = @This();

attrs: std.ArrayList(DwarfAttr),
attr_skips: std.ArrayList(DwarfAttrSkip),
dies: std.ArrayList(DwarfDie),
cus: std.ArrayList(DwarfCompilationUnit),
current_cu: DwarfCompilationUnit,

debug_info: Buffer,
debug_str: Buffer,
debug_str_offsets: Buffer,

debug_info_address_stack: [8]usize,
debug_info_address_stack_top: u32,

pub fn init(debug_abbrev: *Buffer, debug_info: Buffer, debug_str: Buffer, debug_str_offsets: Buffer, allocator: std.mem.Allocator) !Self {
    var d = Self{
        .dies = std.ArrayList(DwarfDie).init(allocator),
        .attrs = std.ArrayList(DwarfAttr).init(allocator),
        .attr_skips = std.ArrayList(DwarfAttrSkip).init(allocator),
        .cus = std.ArrayList(DwarfCompilationUnit).init(allocator),
        .current_cu = undefined,

        .debug_info = debug_info,
        .debug_str = debug_str,
        .debug_str_offsets = debug_str_offsets,

        .debug_info_address_stack = undefined,
        .debug_info_address_stack_top = 0,
    };

    d.pushAddress();
    while (d.debug_info.isGood()) {
        const start_pos = d.debug_info.curr_pos;

        var bitness: u8 = 32;
        const unit_length = blk: {
            const ul32 = d.debug_info.consumeType(u32) orelse return DwarfError.EndOfBuffer;
            if (ul32 == std.math.maxInt(u32)) {
                bitness = 64;
                break :blk d.debug_info.consumeType(u64) orelse return DwarfError.EndOfBuffer;
            } else {
                break :blk ul32;
            }
        };
        const unit_length_size = @intCast(u8, d.debug_info.curr_pos - start_pos);

        const version = d.debug_info.consumeType(u16) orelse return DwarfError.EndOfBuffer;
        const debug_abbrev_offset = blk: {
            if (bitness == 32) {
                break :blk d.debug_info.consumeType(u32) orelse return DwarfError.EndOfBuffer;
            } else if (bitness == 64) {
                break :blk d.debug_info.consumeType(u64) orelse return DwarfError.EndOfBuffer;
            } else {
                unreachable;
            }
        };
        const address_size = d.debug_info.consumeType(u8) orelse return DwarfError.EndOfBuffer;
        const header_size = @intCast(u8, d.debug_info.curr_pos - start_pos);

        const cu_header = DwarfCompilationUnitHeader{
            .unit_length = unit_length,
            .version = version,
            .debug_abbrev_offset = debug_abbrev_offset,
            .address_size = address_size,
        };

        const cu_offset = d.debug_info.curr_pos;
        try d.cus.append(DwarfCompilationUnit{
            .header = cu_header,
            .offset = cu_offset,
            .header_size = header_size,
            .dwarf_address_size = @divExact(bitness, 8),
            .die_range = undefined,
        });

        d.debug_info.curr_pos += cu_header.unit_length - (header_size - unit_length_size);
    }
    d.popAddress();
    d.debug_info.advance(@sizeOf(DwarfCompilationUnitHeader));

    var cu_index: usize = 0;
    var die_start: usize = 0;
    while (debug_abbrev.isGood()) {
        if (cu_index + 1 < d.cus.items.len and d.cus.items[cu_index + 1].header.debug_abbrev_offset <= debug_abbrev.curr_pos) {
            d.cus.items[cu_index].die_range = .{ .start = @intCast(DieId, die_start), .end = @intCast(DieId, d.dies.items.len) };
            die_start = d.dies.items.len;
            cu_index += 1;
        }

        const code = readULEB128(debug_abbrev);
        if (code == 0) {
            continue;
        }
        const tag = @intToEnum(DW_TAG, readULEB128(debug_abbrev));
        const children = debug_abbrev.consumeTypeUnchecked(u8);

        const start_attr = d.attrs.items.len;
        var sibling_attr_index: u8 = std.math.maxInt(u8);
        var i: u8 = 0;
        while (debug_abbrev.isGood()) : (i += 1) {
            const atv = blk: {
                const uleb = readULEB128(debug_abbrev);
                if (uleb > std.math.maxInt(u8)) {
                    break :blk std.math.maxInt(u8);
                } else {
                    break :blk uleb;
                }
            };

            const at = @intToEnum(DW_AT, atv);
            // NOTE(radomski): uleb, but always just one byte
            const val = @intToEnum(DW_FORM, debug_abbrev.consumeType(u8) orelse return DwarfError.EndOfBuffer);
            if (at == DW_AT.null) {
                break;
            }
            if (at == DW_AT.sibling) {
                sibling_attr_index = i;
            }
            try d.attrs.append(DwarfAttr{ .at = at, .form = val });
        }
        const end_attr = d.attrs.items.len;

        const start_attr_skip = d.attr_skips.items.len;
        const cu = d.cus.items[cu_index];
        try d.generateAttrSkips(d.attrs.items[start_attr..end_attr], cu.header.address_size, cu.dwarf_address_size);
        const end_attr_skip = d.attr_skips.items.len;

        try d.dies.append(DwarfDie{
            .code = @intCast(u32, code),
            .tag = tag,
            .attr_range = .{ .start = @intCast(AttrId, start_attr), .len = @intCast(AttrRangeLen, end_attr - start_attr) },
            .attr_skip_range = .{ .start = @intCast(AttrSkipId, start_attr_skip), .len = @intCast(AttrSkipRangeLen, end_attr_skip - start_attr_skip) },
            .sibling_attr_index = sibling_attr_index,
            .has_children = children == 1,
        });
    }
    d.cus.items[cu_index].die_range = .{ .start = @intCast(DieId, die_start), .end = @intCast(DieId, d.dies.items.len) };

    return d;
}

pub fn generateAttrSkips(self: *Self, attrs: []DwarfAttr, machine_address_size: u8, dwarf_address_size: u8) !void {
    const SkipHelper = struct {
        last_skip: ?u16 = null,
        output: *std.ArrayList(DwarfAttrSkip),

        pub fn skipN(h: *@This(), n: u8) void {
            if (h.last_skip == null) {
                h.last_skip = n;
            } else {
                const last_skip_val = h.last_skip.?;
                if (last_skip_val + n > 255) {
                    unreachable;
                } else {
                    h.last_skip.? += n;
                }
            }
        }

        pub fn skipWithTag(h: *@This(), tag: DwarfAttrSkip.Tag) !void {
            if (h.last_skip) |n| {
                try h.output.append(DwarfAttrSkip{ .tag = .skip_n, .n = @intCast(u8, n) });
                h.last_skip = null;
            }
            try h.output.append(DwarfAttrSkip{ .tag = tag });
        }

        pub fn skipULEB(h: *@This()) !void {
            try h.skipWithTag(.skip_uleb);
        }

        pub fn skipCString(h: *@This()) !void {
            try h.skipWithTag(.skip_c_string);
        }

        pub fn readU8LenAndSkip(h: *@This()) !void {
            try h.skipWithTag(.read_u8_len_and_skip);
        }

        pub fn readU16LenAndSkip(h: *@This()) !void {
            try h.skipWithTag(.read_u16_len_and_skip);
        }

        pub fn readU32LenAndSkip(h: *@This()) !void {
            try h.skipWithTag(.read_u32_len_and_skip);
        }

        pub fn readULEBLenAndSkip(h: *@This()) !void {
            try h.skipWithTag(.read_uleb_len_and_skip);
        }

        pub fn finish(h: *@This()) !void {
            if (h.last_skip) |n| {
                try h.output.append(DwarfAttrSkip{ .tag = .skip_n, .n = @intCast(u8, n) });
            }
        }
    };

    var helper = SkipHelper{ .output = &self.attr_skips };

    for (attrs) |attr| {
        switch (attr.form) {
            DW_FORM.null => unreachable,
            DW_FORM.addr => {
                if (machine_address_size == @sizeOf(u64) or machine_address_size == @sizeOf(u32)) {
                    helper.skipN(machine_address_size);
                } else {
                    unreachable;
                }
            },
            DW_FORM.block2 => try helper.readU16LenAndSkip(),
            DW_FORM.block4 => unreachable,
            DW_FORM.data2 => helper.skipN(@sizeOf(u16)),
            DW_FORM.data4 => helper.skipN(@sizeOf(u32)),
            DW_FORM.data8 => helper.skipN(@sizeOf(u64)),
            DW_FORM.string => try helper.skipCString(),
            DW_FORM.block => unreachable,
            DW_FORM.block1 => try helper.readU8LenAndSkip(),
            DW_FORM.data1 => helper.skipN(@sizeOf(u8)),
            DW_FORM.flag => helper.skipN(1),
            DW_FORM.sdata => try helper.skipULEB(),
            DW_FORM.strp => helper.skipN(dwarf_address_size),
            DW_FORM.udata => try helper.skipULEB(),
            DW_FORM.ref_addr => unreachable,
            DW_FORM.ref1 => helper.skipN(@sizeOf(u8)),
            DW_FORM.ref2 => helper.skipN(@sizeOf(u16)),
            DW_FORM.ref4 => helper.skipN(@sizeOf(u32)),
            DW_FORM.ref8 => helper.skipN(@sizeOf(u64)),
            DW_FORM.ref_udata => unreachable,
            DW_FORM.indirect => unreachable,
            DW_FORM.sec_offset => helper.skipN(dwarf_address_size),
            DW_FORM.exprloc => try helper.readULEBLenAndSkip(),
            DW_FORM.flag_present => {},
            DW_FORM.strx => unreachable,
            DW_FORM.addrx => try helper.skipULEB(),
            DW_FORM.ref_sup4 => unreachable,
            DW_FORM.strp_sup => unreachable,
            DW_FORM.data16 => unreachable,
            DW_FORM.line_strp => unreachable,
            DW_FORM.ref_sig8 => unreachable,
            DW_FORM.implicit_const => unreachable,
            DW_FORM.loclistx => unreachable,
            DW_FORM.rnglistx => unreachable,
            DW_FORM.ref_sup8 => unreachable,
            DW_FORM.strx1 => helper.skipN(1),
            DW_FORM.strx2 => unreachable,
            DW_FORM.strx3 => unreachable,
            DW_FORM.strx4 => unreachable,
            DW_FORM.addrx1 => unreachable,
            DW_FORM.addrx2 => unreachable,
            DW_FORM.addrx3 => unreachable,
            DW_FORM.addrx4 => unreachable,
        }
    }

    try helper.finish();
}

pub fn setCu(self: *Self, cu: DwarfCompilationUnit) void {
    self.current_cu = cu;
    self.debug_info.curr_pos = cu.offset;
}

pub fn inCurrentCu(self: *Self) bool {
    return self.debug_info.curr_pos < (self.current_cu.offset + self.current_cu.header.unit_length - 7);
}

pub fn getAttrs(self: *Self, range: AttrRange) []DwarfAttr {
    return self.attrs.items[range.start .. range.start + range.len];
}

pub fn getAttrSkips(self: *Self, range: AttrSkipRange) []DwarfAttrSkip {
    return self.attr_skips.items[range.start .. range.start + range.len];
}

pub fn getDies(self: *Self, range: DieRange) []DwarfDie {
    return self.dies.items[range.start..range.end];
}

pub fn toGlobalAddr(self: *Self, local_addr: usize) usize {
    return local_addr + self.current_cu.offset - self.current_cu.header_size;
}

pub fn skipFormData(self: *Self, form: DW_FORM) void {
    switch (form) {
        DW_FORM.null => unreachable,
        DW_FORM.addr => {
            // todo
            const memory_word = self.current_cu.header.address_size;
            if (memory_word == @sizeOf(u64) or memory_word == @sizeOf(u32)) {
                self.debug_info.advance(memory_word);
            } else {
                unreachable;
            }
        },
        DW_FORM.block2 => {
            const len = self.debug_info.consumeType(u16) orelse unreachable;
            self.debug_info.advance(@intCast(u32, len));
        },
        DW_FORM.block4 => unreachable,
        DW_FORM.data2 => {
            self.debug_info.advance(@sizeOf(u16));
        },
        DW_FORM.data4 => {
            self.debug_info.advance(@sizeOf(u32));
        },
        DW_FORM.data8 => {
            self.debug_info.advance(@sizeOf(u64));
        },
        DW_FORM.string => {
            self.debug_info.advanceUntil(0);
        },
        DW_FORM.block => unreachable,
        DW_FORM.block1 => {
            const len = self.debug_info.consumeType(u8) orelse unreachable;
            _ = self.debug_info.advance(@intCast(u32, len));
        },
        DW_FORM.data1 => {
            self.debug_info.advance(@sizeOf(u8));
        },
        DW_FORM.flag => {
            _ = self.debug_info.advance(1);
        },
        DW_FORM.sdata => {
            _ = readULEB128(&self.debug_info);
        },
        DW_FORM.strp => {
            self.debug_info.advance(self.current_cu.dwarf_address_size);
        },
        DW_FORM.udata => {
            _ = readULEB128(&self.debug_info);
        },
        DW_FORM.ref_addr => unreachable,
        DW_FORM.ref1 => {
            self.debug_info.advance(@sizeOf(u8));
        },
        DW_FORM.ref2 => {
            self.debug_info.advance(@sizeOf(u16));
        },
        DW_FORM.ref4 => {
            self.debug_info.advance(@sizeOf(u32));
        },
        DW_FORM.ref8 => {
            self.debug_info.advance(@sizeOf(u64));
        },
        DW_FORM.ref_udata => unreachable,
        DW_FORM.indirect => unreachable,
        DW_FORM.sec_offset => {
            self.debug_info.advance(self.current_cu.dwarf_address_size);
        },
        DW_FORM.exprloc => {
            const len = readULEB128(&self.debug_info);
            self.debug_info.advance(@intCast(u32, len));
        },
        DW_FORM.flag_present => {},
        DW_FORM.strx => unreachable,
        DW_FORM.addrx => {
            _ = readULEB128(&self.debug_info);
        },
        DW_FORM.ref_sup4 => unreachable,
        DW_FORM.strp_sup => unreachable,
        DW_FORM.data16 => unreachable,
        DW_FORM.line_strp => unreachable,
        DW_FORM.ref_sig8 => unreachable,
        DW_FORM.implicit_const => unreachable,
        DW_FORM.loclistx => unreachable,
        DW_FORM.rnglistx => unreachable,
        DW_FORM.ref_sup8 => unreachable,
        DW_FORM.strx1 => {
            self.debug_info.advance(1);
        },
        DW_FORM.strx2 => unreachable,
        DW_FORM.strx3 => unreachable,
        DW_FORM.strx4 => unreachable,
        DW_FORM.addrx1 => unreachable,
        DW_FORM.addrx2 => unreachable,
        DW_FORM.addrx3 => unreachable,
        DW_FORM.addrx4 => unreachable,
    }
}

pub fn readFormData(self: *Self, form: DW_FORM) !usize {
    switch (form) {
        DW_FORM.null => unreachable,
        DW_FORM.addr => {
            // todo
            if (self.current_cu.header.address_size == @sizeOf(u64)) {
                return @intCast(usize, (self.debug_info.consumeType(u64) orelse return DwarfError.EndOfBuffer));
            } else if (self.current_cu.header.address_size == @sizeOf(u32)) {
                return @intCast(usize, (self.debug_info.consumeType(u32) orelse return DwarfError.EndOfBuffer));
            } else {
                unreachable;
            }
        },
        DW_FORM.block2 => {
            const len = self.debug_info.consumeType(u16) orelse return DwarfError.EndOfBuffer;
            _ = self.debug_info.advance(@intCast(u32, len));
        },
        DW_FORM.block4 => unreachable,
        DW_FORM.data2 => {
            return @intCast(usize, (self.debug_info.consumeType(u16) orelse return DwarfError.EndOfBuffer));
        },
        DW_FORM.data4 => {
            return @intCast(usize, (self.debug_info.consumeType(u32) orelse return DwarfError.EndOfBuffer));
        },
        DW_FORM.data8 => {
            return @intCast(usize, (self.debug_info.consumeType(u64) orelse return DwarfError.EndOfBuffer));
        },
        DW_FORM.string => unreachable,
        DW_FORM.block => unreachable,
        DW_FORM.block1 => {
            const len = self.debug_info.consumeType(u8) orelse return DwarfError.EndOfBuffer;
            var slice_data = self.debug_info.consume(@intCast(u32, len)) orelse return DwarfError.EndOfBuffer;

            var data = Buffer{ .data = slice_data };
            const op = data.consumeType(u8) orelse return DwarfError.EndOfBuffer;
            if (op == 0x23) {
                const uleb = readULEB128(&data);
                std.debug.assert(data.curr_pos == data.data.len);
                return uleb;
            } else {
                unreachable;
            }
        },
        DW_FORM.data1 => {
            return @intCast(usize, (self.debug_info.consumeType(u8) orelse return DwarfError.EndOfBuffer));
        },
        DW_FORM.flag => unreachable,
        DW_FORM.sdata => {
            return readULEB128(&self.debug_info);
        },
        DW_FORM.strp => {
            if (self.current_cu.dwarf_address_size == @sizeOf(u64)) {
                return @intCast(usize, (self.debug_info.consumeType(u64) orelse return DwarfError.EndOfBuffer));
            } else if (self.current_cu.dwarf_address_size == @sizeOf(u32)) {
                return @intCast(usize, (self.debug_info.consumeType(u32) orelse return DwarfError.EndOfBuffer));
            } else {
                unreachable;
            }
        },
        DW_FORM.udata => {
            return readULEB128(&self.debug_info);
        },
        DW_FORM.ref_addr => unreachable,
        DW_FORM.ref1 => {
            return @intCast(usize, (self.debug_info.consumeType(u8) orelse return DwarfError.EndOfBuffer));
        },
        DW_FORM.ref2 => {
            return @intCast(usize, (self.debug_info.consumeType(u16) orelse return DwarfError.EndOfBuffer));
        },
        DW_FORM.ref4 => {
            return @intCast(usize, (self.debug_info.consumeType(u32) orelse return DwarfError.EndOfBuffer));
        },
        DW_FORM.ref8 => {
            return @intCast(usize, (self.debug_info.consumeType(u64) orelse return DwarfError.EndOfBuffer));
        },
        DW_FORM.ref_udata => unreachable,
        DW_FORM.indirect => unreachable,
        DW_FORM.sec_offset => unreachable,
        DW_FORM.exprloc => {
            const len = readULEB128(&self.debug_info);
            _ = self.debug_info.advance(@intCast(u32, len));
        },
        DW_FORM.flag_present => {},
        DW_FORM.strx => unreachable,
        DW_FORM.addrx => unreachable,
        DW_FORM.ref_sup4 => unreachable,
        DW_FORM.strp_sup => unreachable,
        DW_FORM.data16 => unreachable,
        DW_FORM.line_strp => unreachable,
        DW_FORM.ref_sig8 => unreachable,
        DW_FORM.implicit_const => unreachable,
        DW_FORM.loclistx => unreachable,
        DW_FORM.rnglistx => unreachable,
        DW_FORM.ref_sup8 => unreachable,
        DW_FORM.strx1 => {
            return @intCast(usize, (self.debug_info.consumeType(u8) orelse return DwarfError.EndOfBuffer));
        },
        DW_FORM.strx2 => unreachable,
        DW_FORM.strx3 => unreachable,
        DW_FORM.strx4 => unreachable,
        DW_FORM.addrx1 => unreachable,
        DW_FORM.addrx2 => unreachable,
        DW_FORM.addrx3 => unreachable,
        DW_FORM.addrx4 => unreachable,
    }
    return 0;
}

pub fn readString(self: *Self, form: DW_FORM) ![]const u8 {
    if (form == DW_FORM.strp) {
        const name_addr = try self.readFormData(form);
        return self.readOffsetString(name_addr);
    } else if (form == DW_FORM.string) {
        return self.readFormString();
    } else {
        const offset_index = try self.readFormData(form);
        return self.readOffsetIndexedString(offset_index);
    }
}

pub fn readFormString(self: *Self) ![]const u8 {
    return self.debug_info.consumeUntil(0) orelse return DwarfError.EndOfBuffer;
}

pub fn readOffsetString(self: *Self, addr: usize) ![]const u8 {
    self.debug_str.curr_pos = addr;
    return self.debug_str.consumeUntil(0) orelse return DwarfError.EndOfBuffer;
}

pub fn readOffsetIndexedString(self: *Self, index: usize) ![]const u8 {
    const header_size = self.current_cu.dwarf_address_size * 2;
    self.debug_str_offsets.curr_pos = index * self.current_cu.dwarf_address_size + header_size;

    const address = blk: {
        if (self.current_cu.dwarf_address_size == @sizeOf(u64)) {
            break :blk @intCast(usize, (self.debug_str_offsets.consumeType(u64) orelse return DwarfError.EndOfBuffer));
        } else if (self.current_cu.dwarf_address_size == @sizeOf(u32)) {
            break :blk @intCast(usize, (self.debug_str_offsets.consumeType(u32) orelse return DwarfError.EndOfBuffer));
        } else {
            unreachable;
        }
    };

    const name = try self.readOffsetString(address);
    return name;
}

pub fn readDieAtAddress(self: *Self, addr: usize) !?DwarfDie {
    self.debug_info.curr_pos = addr + self.current_cu.offset - self.current_cu.header_size;

    while (self.debug_info.isGood()) {
        const code = readULEB128(&self.debug_info);
        if (code == 0) {
            return null;
        }
        return self.getDies(self.current_cu.die_range)[code - 1];
    }

    return DwarfError.EndOfBuffer;
}

pub fn skipDieAndChildren(self: *Self, die: DwarfDie) !void {
    if (die.sibling_attr_index != std.math.maxInt(@TypeOf(die.sibling_attr_index))) {
        var i: u8 = 0;
        const attrs = self.getAttrs(die.attr_range);
        while (i < die.sibling_attr_index) : (i += 1) {
            self.skipFormData(attrs[i].form);
        }
        const attr = attrs[die.sibling_attr_index];
        const address = @intCast(u32, try self.readFormData(attr.form));
        const global_address = self.toGlobalAddr(address);
        self.debug_info.curr_pos = global_address;
    } else {
        self.skipDieAttrs(die);
        if (die.has_children == true) {
            while (self.readNextDie()) |addr| {
                const inner_die = try self.readDieAtAddress(addr) orelse break;
                try self.skipDieAndChildren(inner_die);
            }
        }
    }
}

pub fn readDieIfTag(self: *Self, tag: DW_TAG) ?DwarfDie {
    const orig_pos = self.debug_info.curr_pos;
    while (self.debug_info.isGood()) {
        const code = readULEB128(&self.debug_info);
        if (code == 0) {
            continue;
        }
        const die = self.getDies(self.current_cu.die_range)[code - 1];
        if (die.tag == tag) {
            return die;
        } else {
            break;
        }
    }

    self.debug_info.curr_pos = orig_pos;
    return null;
}

pub fn readNextDie(self: *Self) ?usize {
    while (self.debug_info.isGood() and self.inCurrentCu()) {
        const addr = self.debug_info.curr_pos - self.current_cu.offset + self.current_cu.header_size;
        return addr;
    }

    return null;
}

pub fn skipDieAttrs(self: *Self, die: DwarfDie) void {
    for (self.getAttrSkips(die.attr_skip_range)) |skip| {
        switch (skip.tag) {
            .skip_n => self.debug_info.advance(skip.n),
            .skip_uleb => {
                _ = readULEB128(&self.debug_info);
            },
            .skip_c_string => self.debug_info.advanceUntil(0),
            .read_u8_len_and_skip => {
                const len = self.debug_info.consumeTypeUnchecked(u8);
                _ = self.debug_info.advance(@intCast(u32, len));
            },
            .read_u16_len_and_skip => {
                const len = self.debug_info.consumeTypeUnchecked(u16);
                _ = self.debug_info.advance(@intCast(u32, len));
            },
            .read_u32_len_and_skip => {
                const len = self.debug_info.consumeTypeUnchecked(u32);
                _ = self.debug_info.advance(len);
            },
            .read_uleb_len_and_skip => {
                const len = readULEB128(&self.debug_info);
                _ = self.debug_info.advance(len);
            },
        }
    }
}

pub fn pushAddress(self: *Self) void {
    if (self.debug_info_address_stack_top >= self.debug_info_address_stack.len) {
        unreachable;
    }

    self.debug_info_address_stack[self.debug_info_address_stack_top] = self.debug_info.curr_pos;
    self.debug_info_address_stack_top += 1;
}

pub fn popAddress(self: *Self) void {
    if (self.debug_info_address_stack_top <= 0) {
        unreachable;
    }

    self.debug_info_address_stack_top -= 1;
    self.debug_info.curr_pos = self.debug_info_address_stack[self.debug_info_address_stack_top];
}

pub fn readULEB128(b: *Buffer) usize {
    var result: usize = 0;

    result = b.consumeTypeUnchecked(u8);
    if ((result & 0x80) == 0) {
        return result;
    }
    result = @intCast(usize, result & 0x7f);

    var i: usize = 1;
    while (true) {
        const byte = b.consumeTypeUnchecked(u8);

        result = result | (@intCast(usize, byte & 0x7f) << @intCast(u6, i * 7));
        if ((byte & 0x80) == 0) {
            break;
        }

        i += 1;
    }

    return result;
}
