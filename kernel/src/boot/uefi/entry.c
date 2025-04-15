#include <boot/efi/efi.h>

EfiStatus efi_main(EfiHandle handle, EfiSystemTable* systemTable) {
    volatile int dummy = 0;
    EfiStatus status;
    EfiInputKey key;

    status = systemTable->ConOut->OutputString(systemTable->ConOut, L"Hello world\r\n");
    if (EFI_ERROR(status)) 
        return status;

    status = systemTable->ConIn->Reset(systemTable->ConIn, false);
    if (EFI_ERROR(status)) 
        return status;
    
    while ((status = systemTable->ConIn->ReadKeyStroke(systemTable->ConIn, &key)) == EFI_NOT_READY) {}

    return status;
}
