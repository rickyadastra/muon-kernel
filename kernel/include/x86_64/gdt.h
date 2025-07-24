#pragma once

#include "base/int.h"
#define GDT_ENTRIES 5

#define GDT_ACCESS_BYTE_MEMBERS(T, F) \
    F(T, PRESENT,       0b10010000) \
    F(T, USER,          0b01100000) \
    F(T, EXEC,          0b00001000) \
    F(T, RW,            0b00000010) \
    F(T, DIRTY,         0b00000001) \
    F(T, TSS_PRESENT,   0b10000000) \
    F(T, TSS,           0b00001001)
ENUMDEF(GDTAccessByte, UInt8, GDT_ACCESS_BYTE_MEMBERS, NO_METHODS)

#define GDT_FLAGS_MEMBERS(T, F) \
    F(T, B64_DATA,  0b1000) \
    F(T, B64_CODE,  0b1010) \
    F(T, B32_ANY,   0b1100) \
    F(T, TSS,       0b0000)
ENUMDEF(GDTFlag, UInt8, GDT_FLAGS_MEMBERS, NO_METHODS)

typedef union _GDTEntry_struct {
    UInt64 raw;
    struct {
        UInt16 limit_low;   // limit[0:15]
        UInt16 base_low;    // base[0:15]
        UInt8 base_mid;     // base[16:23]
        UInt8 access;
        UInt8 limit_high : 4; // limit[16:19]
        UInt8 flags : 4;
        UInt8 base_high;    // base[24:31]
    };
} GDTEntry;

typedef union _GDTRegister_struct {
    UInt64 raw;
    struct {
        UInt16 size;
        UPtr address;
    } __attribute__((packed));
} GDTRegister;

#define GDTMANAGER_ONLY_METHODS(T, S, M) \
    STATIC(T, S, M, GDTEntry, construct_entry, UPtr base, UPtr limit, UInt8 access, UInt8 flags) \
    METHOD(T, S, M, void, setup) \
    METHOD(T, S, M, void, install)

#define GDTMANAGER_METHODS(T, S, M) \
    OBJECT_METHODS(T, S, M) \
    GDTMANAGER_ONLY_METHODS(T, S, M)

CLASSDEF(GDTManager, Object, GDTMANAGER_METHODS)
    GDTEntry gdt[GDT_ENTRIES];
ENDCLASSDEF(GDTManager)
