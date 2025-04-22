#include "efi/time.h"
#include <efi/runtime_services.h>
#include <wchar.h>
#include <efi/efi.h>
#include <null.h>

WChar16 buffer[64];
EfiSimpleTextOutputProtocol* efiOut;
EfiRuntimeServices* runtimeServices;

EfiStatus efi_log(WChar16* msg);

EfiStatus efi_main(EfiHandle handle, EfiSystemTable* systemTable) {
    EfiStatus status;
    EfiInputKey key;

    efiOut = systemTable->ConOut;
    runtimeServices = systemTable->RuntimeServices;

    status = efiOut->ClearScreen(efiOut);
    if (EFI_ERROR(status)) return status;

    status = efi_log(L"Hello, UEFI land!");
    if (EFI_ERROR(status)) return status;

    status = systemTable->ConIn->Reset(systemTable->ConIn, false);
    if (EFI_ERROR(status)) 
        return status;
    
    while ((status = systemTable->ConIn->ReadKeyStroke(systemTable->ConIn, &key)) == EFI_NOT_READY) {}

    return status;
}

EfiStatus efi_log(WChar16* msg) {
    EfiTime time;
    EfiStatus timeStatus = runtimeServices->GetTime(&time, null);
    if (EFI_ERROR(timeStatus)) return timeStatus;

    Size offset = format_datetime(time, buffer, 64);

    EfiStatus status = efiOut->OutputString(efiOut, buffer);
    if (EFI_ERROR(status)) return status;
    status = efiOut->OutputString(efiOut, msg);
    if (EFI_ERROR(status)) return status;
    status = efiOut->OutputString(efiOut, L"\r\n");
    return status;
}
