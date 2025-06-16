#pragma once

#include <elf/elf.h>

typedef struct _Elf64SectionHeader_struct {
    UInt32 name;
    UInt32 type;
    UInt64 flags;

    UPtr vaddr;
    UPtr file_offset;
    UInt64 file_size;
    UInt32 link;
    UInt32 info;
    UInt64 addr_align;
    UInt64 entry_size;
} PACKED Elf64SectionHeader;