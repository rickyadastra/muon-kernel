#pragma once

#include <size.h>
#include <efi/efi.h>
#include <efi/runtime_services.h>
#include <efi/boot_services.h>

#define EFI_THROW(STATUS, TYPE, MESSAGE, ...) \
    if (EFI_ERROR(STATUS)) { \
        TYPE e = I##TYPE.init(); \
        I##TYPE.set(&e, MESSAGE, __FILE__, __LINE__); \
        THROW(e); \
        return __VA_ARGS__; \
    }

#define EFI_ASSERT(EXPR) status = EXPR; \
    if (EFI_ERROR(status)) return status;

#define EFI_ASSERT_THEN(EXPR, BLOCK) status = EXPR; \
    if (EFI_ERROR(status)) { \
        BLOCK \
        return status; \
    } 

#define EFI_ASSERT_OR(EXPR) status = EXPR; \
    if (EFI_ERROR(status)) return status; \
    else 

void memcpy(void *dest, const void *src, Size count);
