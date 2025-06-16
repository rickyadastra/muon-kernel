#include "bootloader.h"
#include "efi/efi.h"
#include "exception/bootloader_exception.h"
#include "utils/utils.h"
#include <lepton/core.h>

INHERITCLASS(Bootloader, _BOOTLOADER_METHODS, OBJECT_METHODS)

void Bootloader_set_handle(Bootloader *self, EfiHandle efiHandle) {
    self->bootloaderHandle = efiHandle;
}

void Bootloader_set_efi_table(Bootloader *self, EfiSystemTable *efiTable) {
    self->bootServices = efiTable->BootServices;

    EfiStatus s;
    s = self->bootServices->HandleProtocol(self->bootloaderHandle, &(EfiGUID)EFI_LOADED_IMAGE_PROTOCOL_GUID, (void**)&self->bootloaderImage);
    EFI_THROW(s, BootloaderException, "Cannot load bootloader image data")

    s = self->bootServices->HandleProtocol(self->bootloaderImage->DeviceHandle, &(EfiGUID)EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_GUID, (void**)&self->fileSystem);
    EFI_THROW(s, BootloaderException, "Cannot load file system information")
}

PACKAGECLASS(Bootloader, Object, _BOOTLOADER_METHODS, OBJECT_METHODS)
