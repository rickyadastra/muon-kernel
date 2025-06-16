#pragma once

#include <int.h>
#include <bool.h>

#define PACKED __attribute__((packed))
#define ELF_MAGIC "\177ELF"

typedef enum {
    ELF_32BIT = 1,
    ELF_64BIT = 2
} PACKED ElfMode;

typedef enum {
    ELF_LITTLE_ENDIAN = 1,
    ELF_BIG_ENDIAN = 2
} PACKED ElfEndian;

typedef enum {
    _TYPE_FORCE_16_BIT = 0xffff,
    ELF_RELOCATABLE = 1,
    ELF_EXECUTABLE = 2,
    ELF_SHARED = 3,
    ELF_CORE = 4,
} PACKED ElfType;

typedef enum {
    _ARCH_FORCE_16_BIT = 0xffff,
    ELF_NO_SPECIFIC = 0,
    ELF_SPARC = 2,
    ELF_x86 = 3,
    ELF_MIPS = 8,
    ELF_POWERPC = 0x14,
    ELF_ARM = 0x28,
    ELF_SUPERH = 0x2a,
    ELF_IA64 = 0x32,
    ELF_x86_64 = 0x3e,
    ELF_AARCH64 = 0xb7,
    ELF_RISC_V = 0xf3
} PACKED ElfArch;

typedef struct _ElfHeaderCommon_struct {
    char magic[4];
    ElfMode elf_mode;
    ElfEndian endian_type;
    UInt8 header_version;
    UInt8 os;
    UInt8 abi_version;
    UInt8 _padding[7];
} PACKED ElfCommonHeader;

typedef struct _Elf64Header_struct {
    ElfCommonHeader common;
    ElfType elf_type;
    ElfArch elf_arch;
    UInt32 elf_version;
    
    UPtr entry_point;
    UPtr program_offset;
    UPtr sections_offset;

    UInt32 flags;
    UInt16 size;

    UInt16 programs_size;
    UInt16 programs_count;

    UInt16 sections_size;
    UInt16 sections_count;

    UInt16 strings_section_index;
} PACKED Elf64Header;
