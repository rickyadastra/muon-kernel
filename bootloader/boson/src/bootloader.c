#include "bootloader.h"
#include "efi/file_protocol.h"
#include "file.h"
#include "int.h"
#include <lepton/exception/null_exception.h>
#include <efi/efi.h>
#include <exception/bootloader_exception.h>
#include <utils/utils.h>
#include <lepton/core.h>
#include <null.h>

INHERITCLASS(Bootloader, _BOOTLOADER_METHODS, OBJECT_METHODS)

void Bootloader_set_handle(Bootloader *self, EfiHandle efiHandle) {
    self->bootloaderHandle = efiHandle;
}

void Bootloader_set_efi_table(Bootloader *self, EfiSystemTable *efiTable) {
    if (efiTable == null) {
        THROW_EXCEPTION(NullException, "EfiSystemTable is null")
        return;
    }

    if (efiTable->BootServices == null) {
        THROW_EXCEPTION(NullException, "BootServices is null")
        return;
    }

    self->bootServices = efiTable->BootServices;

    EfiStatus s;
    s = self->bootServices->HandleProtocol(self->bootloaderHandle, &(EfiGUID)EFI_LOADED_IMAGE_PROTOCOL_GUID, (void**)&self->bootloaderImage);
    EFI_THROW(s, BootloaderException, "Cannot load bootloader image data")

    s = self->bootServices->HandleProtocol(self->bootloaderImage->DeviceHandle, &(EfiGUID)EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_GUID, (void**)&self->fileSystem);
    EFI_THROW(s, BootloaderException, "Cannot load file system information")
}

Bool Bootloader_open_volume(Bootloader *self) {
    EfiStatus s;
    
    EfiFileProtocol* fileRoot;
    s = self->fileSystem->OpenVolume(self->fileSystem, &fileRoot);
    EFI_THROW(s, BootloaderException, "Cannot open volume", false)

    self->root = IFile.init();
    IFile.from(&self->root, fileRoot);

    return true;
}

UPtr Bootloader_alloc(Bootloader *self, Size size, UPtr* buffer) {
    EfiStatus s = self->bootServices->AllocatePool(EFI_BOOT_SERVICES_DATA, size, (void**)buffer);
    EFI_THROW(s, BootloaderException, "Cannot allocate memory pool", (UPtr)0);

    return *buffer;
}

void Bootloader_free(Bootloader *self, UPtr buffer) {
    EfiStatus s = self->bootServices->FreePool((void*)buffer);
    EFI_THROW(s, BootloaderException, "Cannot free memory pool");
}

PACKAGECLASS(Bootloader, Object, _BOOTLOADER_METHODS, OBJECT_METHODS)
