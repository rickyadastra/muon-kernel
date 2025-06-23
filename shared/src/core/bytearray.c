#include "lepton/result.h"
#include <core/bytearray.h>

DECLAREMETHODS(ByteArray, ROOT, BYTE_ARRAY_METHODS)

BytePtrResult ByteArray_set(char *to, Size size, char value) {
    if (!to || size < 0) return RESULT_ERROR(BytePtr);
    if (size == 0) return RESULT(BytePtr, to);
    
    for (Size i=0; i<size; i++) {
        to[i] = value;
    }

    return RESULT(BytePtr, to);
}

BytePtrResult ByteArray_copy(const char* from, char* to, Size from_size, Size to_size) {
    return ByteArray_copy_n(from, to, from_size, to_size, (Size)-1);
}

BytePtrResult ByteArray_copy_n(const char* from, char* to, Size from_size, Size to_size, Size n) {
    if (!from || !to || to_size == 0) return RESULT_ERROR(BytePtr);
    if (n == 0) return RESULT(BytePtr, to);
    
    for (Size i=0; i<to_size && i<from_size; i++) {
        to[i] = from[i];
    }
    
    return RESULT(BytePtr, to);
}

SizeResult ByteArray_index_of(const char* str, const char c, Size str_size) {
    if (!str) return RESULT_ERROR(Size);

    const char* strPtr = str;
    Size i = 0;
    
    while (*strPtr != c) { 
        strPtr++;
        i++;
        if (i > str_size) return RESULT_ERROR(Size);
    }

    return RESULT(Size, (Size)(strPtr - str));
}

Size ByteArray_length(const char* str) {
    SizeResult res = ByteArray_index_of(str, 0, (Size)-1);
    if (UNWRAP(res)) return res.data;
    else return 0;
}

BytePtrResult ByteArray_concat(const char* s1, const char* s2, char* buf, Size buf_size) {
    return RESULT_ERROR(BytePtr);
}

Int8Result ByteArray_compare(const char *s1, const char *s2) {
    return ByteArray_compare_n(s1, s2, (Size)-1);
}

Int8Result ByteArray_compare_n(const char *s1, const char *s2, Size n) {
    if (!s1 || !s2) return RESULT_ERROR(Int8);
    if (n == 0) return RESULT(Int8, 0);

    while (n && *s1 && (*s1 == *s2)) {
        ++s1; ++s2;
        --n;
    }

    if (n == 0) return RESULT(Int8, 0);
    else return RESULT(Int8, *s1 - *s2);
}

PACKAGEIFACE(ByteArray, BYTE_ARRAY_METHODS)
