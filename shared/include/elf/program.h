#pragma once

#include <elf/elf.h>
#include <int.h>
#include <bool.h>

typedef enum __elf_segment_type : UInt32 {
    SEGMENT_TYPE_NULL = 0,
    SEGMENT_TYPE_LOAD = 1,
    SEGMENT_TYPE_DYNAMIC = 2,
    SEGMENT_TYPE_INTERP = 3,
    SEGMENT_TYPE_NOTE = 4
} ElfSegmentType;

typedef enum __elf_segment_flags : UInt32 {
    SEGMENT_FLAGS_EXECUTABLE = 0x1,
    SEGMENT_FLAGS_WRITABLE = 0x2,
    SEGMENT_FLAGS_READABLE = 0x4
} ElfSegmentFlags;

typedef struct _Elf64ProgramHeader_struct {
    ElfSegmentType type;
    ElfSegmentFlags flags;
    
    UPtr file_offset;
    UPtr vaddr;
    UInt64 _undefined;

    UInt64 file_size;
    UInt64 mem_size;
    UInt64 required_alignment;
} PACKED Elf64ProgramHeader;

