#pragma once

#include <size.h>
#include <efi/efi.h>
#include <efi/runtime_services.h>
#include <efi/boot_services.h>

#define EFI_THROW(STATUS, TYPE, MESSAGE) \
    if (EFI_ERROR(STATUS)) { \
        TYPE e = I##TYPE.init(); \
        I##TYPE.set(&e, MESSAGE, __FILE__, __LINE__); \
        THROW(e); \
        return; \
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

EfiStatus efi_log_full(WChar16* msg, Bool showTimestamp);
EfiStatus efi_announce(WChar16* msg);
EfiStatus efi_log(WChar16* msg);
EfiStatus efi_logf(const char* s, ...);
EfiInputKey efi_pause();
EfiStatus efi_alloc(Size size, void** buffer);
EfiStatus efi_free(void* buffer);
EfiStatus efi_alloc_pages(Size size, UPtr* addr);
void efi_mem_copy(const char* from, char* to, Size size);
void efi_mem_set(char* to, Size size, char value);

void memcpy(void *dest, const void *src, Size count);

extern EfiSimpleTextOutputProtocol* efiOut;
extern EfiSimpleTextInputProtocol* efiIn;
extern EfiRuntimeServices* runtimeServices;
extern EfiBootServices* bootServices;
