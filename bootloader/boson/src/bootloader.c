#include "bootloader.h"
#include "bool.h"
#include "efi/file_protocol.h"
#include "efi/memory.h"
#include "file.h"
#include "int.h"
#include "memory_manager.h"
#include <lepton/exception/null_exception.h>
#include <efi/efi.h>
#include <exception/bootloader_exception.h>
#include <utils/utils.h>
#include <lepton/core.h>
#include <null.h>

INHERITCLASS(Bootloader, _BOOTLOADER_METHODS, MEMORYCONSUMER_METHODS)

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
    IFile.set_memory_manager(&self->root, self->memoryManager);

    return true;
}

UPtr Bootloader_load_kernel(Bootloader *self, const WChar16 *filename) {
    IFile.open(&self->root, &self->kernel, filename, EFI_FILE_MODE_READ);
        
    UPtr fileBuf = IFile.read(&self->kernel);
    return fileBuf;
}

void vmap_in_kernel(Bootloader* self, UPtr paddr, UPtr vaddr, Size size) {
    if (self->kernelPageTable == null) {
        self->kernelPageTable = (PageTable)IMemoryManager.alloc_pages(self->memoryManager, EFI_PAGE_SIZE, true);
    }

    IMemoryManager.virtual_map(self->memoryManager, self->kernelPageTable, paddr, vaddr, EFI_SIZE_TO_PAGES(size));
}

BootloaderKernelStack Bootloader_prepare_kernel_stack(Bootloader *self, Size size) {
    UPtr base = IMemoryManager.alloc_pages(self->memoryManager, size, true);

    vmap_in_kernel(self, base, base, size);

    return (BootloaderKernelStack){
        .base = base,
        .size = size,
        .end = base + size
    };
}

PACKAGECLASS(Bootloader, MemoryConsumer, _BOOTLOADER_METHODS, MEMORYCONSUMER_METHODS)
