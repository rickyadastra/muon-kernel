#pragma once

#include <int.h>

typedef enum {
    RESULT_STATUS_PRESENT,
    RESULT_STATUS_ERROR
} ResultStatus;

#define RESULTDEF(T) \
    typedef struct { \
        T data; \
        UInt8 status; \
    } T##Result;

#define RESULT_ERROR(T) (T##Result) {.status = RESULT_STATUS_ERROR} 
#define RESULT(T, DATA) (T##Result) {.status = RESULT_STATUS_PRESENT, .data = DATA} 

#define IS_PRESENT(RESULT) (RESULT.status == RESULT_STATUS_PRESENT)
#define UNWRAP(RESULT) (typeof(RESULT.data)) RESULT.data