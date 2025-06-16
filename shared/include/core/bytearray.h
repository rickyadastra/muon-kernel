#pragma once

#include <size.h>
#include <lepton/core.h>

#define BYTE_ARRAY_METHODS(TYPE, SUPER, FUNC) \
    FUNC(TYPE, SUPER, BytePtrResult, copy, const char* from, char* to, Size from_size, Size to_size) \
    FUNC(TYPE, SUPER, BytePtrResult, copy_n, const char* from, char* to, Size from_size, Size to_size, Size n) \
    FUNC(TYPE, SUPER, SizeResult, index_of, const char* str, const char c, Size str_size) \
    FUNC(TYPE, SUPER, Size, length, const char* str) \
    FUNC(TYPE, SUPER, BytePtrResult, concat, const char* s1, const char* s2, char* out, Size buf_size) \
    FUNC(TYPE, SUPER, Int8Result, compare, const char* s1, const char* s2) \
    FUNC(TYPE, SUPER, Int8Result, compare_n, const char* s1, const char* s2, Size n)

IFACEDEF(ByteArray, BYTE_ARRAY_METHODS)
ENDIFACEDEF(ByteArray)
