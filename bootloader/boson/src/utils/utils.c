#include "efi/efi.h"
#include "efi/memory.h"
#include "int.h"
#include <utils/utils.h>
#include <utils/string.h>
#include <wchar.h>
#include <null.h>

WChar16 buffer[256];
EfiSimpleTextOutputProtocol* efiOut;
EfiSimpleTextInputProtocol* efiIn;
EfiRuntimeServices* runtimeServices;
EfiBootServices* bootServices;

EfiInputKey efi_pause() {
    EfiInputKey key;
    while (efiIn->ReadKeyStroke(efiIn, &key) == EFI_NOT_READY) {}
    return key;
}

EfiStatus efi_log_full(WChar16* msg, Bool showTimestamp) {
    EfiStatus status;
    
    if (showTimestamp) {
        EfiTime time; 
        EfiStatus timeStatus = runtimeServices->GetTime(&time, null);
        if (EFI_ERROR(timeStatus)) return timeStatus;

        format_datetime(time, buffer, 64);

        status = efiOut->OutputString(efiOut, buffer);
        if (EFI_ERROR(status)) return status;
    }

    status = efiOut->OutputString(efiOut, msg);
    if (EFI_ERROR(status)) return status;
    status = efiOut->OutputString(efiOut, L"\r\n");
    return status;
}


EfiStatus efi_announce(WChar16* msg) {
    return efi_log_full(msg, false);
}

EfiStatus efi_log(WChar16* msg) {
    return efi_log_full(msg, true);
}

EfiStatus efi_logf(const char* s, ...) {
    if (!s) return 0;

    VAList args;
    VASTART(args, s);
    WChar16 tbuf[128];
    vstrf(s, tbuf, args);

    return efi_log_full(tbuf, true);
}

EfiStatus efi_alloc(Size size, void** buffer) {
    return bootServices->AllocatePool(EFI_BOOT_SERVICES_DATA, size, buffer);
}

EfiStatus efi_alloc_pages(Size size, UPtr* addr) {
    EfiStatus status;
    EFI_ASSERT(bootServices->AllocatePages(ALLOCATE_ANY_PAGES, EFI_LOADER_DATA, EFI_SIZE_TO_PAGES(size), addr))

    efi_mem_set((char*)*addr, size, 0);
    return status;
}

EfiStatus efi_free(void* buffer) {
    return bootServices->FreePool(buffer);
}

void efi_mem_copy(const char* from, char* to, Size size) {
    for (Size i=0; i<size; i++) {
        to[i] = from[i];
    }
}

void efi_mem_set(char* to, Size size, char value) {
    for (Size i=0; i<size; i++) {
        to[i] = value;
    }
}
