const Buffer = @import("main.zig").Buffer;

const std = @import("std");
const mem = std.mem;

const ELFIdentHeader = struct {
    eh_magic: [4]u8,
    eh_class: u8,
    eh_data: u8,
    eh_version: u8,
    eh_osabi: u8,
    eh_abi_version: u8,
    eh_pad: [7]u8,
};

pub fn ELFFileHeader(comptime T: type) type {
    return struct {
        e_type: u16,
        e_machine: u16,
        e_version: u32,
        e_entry: T,
        e_phoff: T,
        e_shoff: T,
        e_flags: u32,
        e_ehsize: u16,
        e_phentsize: u16,
        e_phnum: u16,
        e_shentsize: u16,
        e_shnum: u16,
        e_shstrndx: u16,
    };
}

pub fn ELFSectionHeader(comptime T: type) type {
    return struct {
        sh_name: u32,
        sh_type: u32,
        sh_flags: T,
        sh_addr: T,
        sh_offset: T,
        sh_size: T,
        sh_link: u32,
        sh_info: u32,
        sh_addralign: T,
        sh_entsize: T,
    };
}

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

const ELFDebugSections = struct {
    debug_abbrev: Buffer,
    debug_info: Buffer,
    debug_str: Buffer,
    debug_str_offsets: Buffer,
};

const ELF_32BIT_CLASS = 1;
const ELF_64BIT_CLASS = 2;

pub fn getSectionBuffer(
    comptime T: type,
    section_headers: []const T,
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
    const rela = mem.bytesAsSlice(ELFRelocationA, rela_buff.data);
    const symtab = mem.bytesAsSlice(ELFSymbol, symtab_buff.data);

    for (rela) |r| {
        switch (r.relocationType()) {
            ELFRelocationType.R_X86_64_64 => {
                const write_type = u64;
                const value: write_type = symtab[r.symbolIndex()].st_value +| @bitCast(write_type, r.r_addend);
                const value_bytes = mem.toBytes(value);
                mem.copy(u8, buffer.data[r.r_offset .. r.r_offset + @sizeOf(write_type)], &value_bytes);
            },
            ELFRelocationType.R_X86_64_32 => {
                const write_type = u32;
                const value: write_type = @truncate(u32, symtab[r.symbolIndex()].st_value) +| @bitCast(write_type, @intCast(i32, r.r_addend));
                const value_bytes = mem.toBytes(value);
                mem.copy(u8, buffer.data[r.r_offset .. r.r_offset + @sizeOf(write_type)], &value_bytes);
            },
            else => unreachable,
        }
    }
}

pub fn readElfGeneric(comptime T: type, buffer: *Buffer, arena: mem.Allocator) !ELFDebugSections {
    const header = buffer.consumeType(ELFFileHeader(T)) orelse unreachable;
    buffer.curr_pos = header.e_shoff;
    var section_headers = try arena.alloc(ELFSectionHeader(T), header.e_shnum);
    for (section_headers) |_, i| {
        section_headers[i] = buffer.consumeType(ELFSectionHeader(T)) orelse unreachable;
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
            if (mem.indexOfScalar(u8, sstrtab[sh.sh_name..], 0)) |pos| {
                break :blk sstrtab[sh.sh_name .. sh.sh_name + pos];
            } else {
                unreachable;
            }
        };

        if (mem.eql(u8, name, ".symtab")) {
            sh_symtabi = i;
        } else if (mem.eql(u8, name, ".debug_info")) {
            sh_debug_infoi = i;
        } else if (mem.eql(u8, name, ".rela.debug_info")) {
            sh_debug_info_relai = i;
        } else if (mem.eql(u8, name, ".debug_abbrev")) {
            sh_debug_abbrevi = i;
        } else if (mem.eql(u8, name, ".rela.debug_abbrev")) {
            sh_debug_abbrev_relai = i;
        } else if (mem.eql(u8, name, ".debug_str")) {
            sh_debug_stri = i;
        } else if (mem.eql(u8, name, ".rela.debug_str")) {
            sh_debug_str_relai = i;
        } else if (mem.eql(u8, name, ".debug_str_offsets")) {
            sh_debug_str_offsetsi = i;
        } else if (mem.eql(u8, name, ".rela.debug_str_offsets")) {
            sh_debug_str_offsets_relai = i;
        }
    }

    var symtab = getSectionBuffer(ELFSectionHeader(T), section_headers, sh_symtabi, buffer);
    var debug_abbrev = getSectionBuffer(ELFSectionHeader(T), section_headers, sh_debug_abbrevi, buffer);
    var debug_info = getSectionBuffer(ELFSectionHeader(T), section_headers, sh_debug_infoi, buffer);
    var debug_str = getSectionBuffer(ELFSectionHeader(T), section_headers, sh_debug_stri, buffer);
    var debug_str_offsets = getSectionBuffer(ELFSectionHeader(T), section_headers, sh_debug_str_offsetsi, buffer);

    if (sh_debug_info_relai) |relai| {
        var rela = getSectionBuffer(ELFSectionHeader(T), section_headers, relai, buffer);
        relocateBuffer(debug_info, &rela, &symtab);
    }
    if (sh_debug_abbrev_relai) |relai| {
        var rela = getSectionBuffer(ELFSectionHeader(T), section_headers, relai, buffer);
        relocateBuffer(debug_abbrev, &rela, &symtab);
    }
    if (sh_debug_str_relai) |relai| {
        var rela = getSectionBuffer(ELFSectionHeader(T), section_headers, relai, buffer);
        relocateBuffer(debug_str, &rela, &symtab);
    }
    if (sh_debug_str_offsets_relai) |relai| {
        var rela = getSectionBuffer(ELFSectionHeader(T), section_headers, relai, buffer);
        relocateBuffer(debug_str_offsets, &rela, &symtab);
    }

    return ELFDebugSections{
        .debug_abbrev = debug_abbrev,
        .debug_info = debug_info,
        .debug_str = debug_str,
        .debug_str_offsets = debug_str_offsets,
    };
}

pub fn readElf32(buffer: *Buffer, arena: mem.Allocator) !ELFDebugSections {
    return readElfGeneric(u32, buffer, arena);
}

pub fn readElf64(buffer: *Buffer, arena: mem.Allocator) !ELFDebugSections {
    return readElfGeneric(u64, buffer, arena);
}

pub fn getSectionsDebugSections(buffer: *Buffer, arena: mem.Allocator) !ELFDebugSections {
    const header_ident = buffer.consumeType(ELFIdentHeader) orelse unreachable;
    var sections = switch (header_ident.eh_class) {
        ELF_32BIT_CLASS => try readElf32(buffer, arena),
        ELF_64BIT_CLASS => try readElf64(buffer, arena),
        else => unreachable,
    };

    return sections;
}
