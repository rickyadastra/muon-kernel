#include "memory_manager.h"
#include "utils/utils.h"
#include <lepton/exception/null_exception.h>
#include <exception/memory_exception.h>
#include <lepton/core.h>
#include <null.h>

INHERITCLASS(MemoryManager, _MEMORYMANAGER_METHODS, OBJECT_METHODS)

void MemoryManager_set_efi_table(MemoryManager *self, EfiSystemTable *efiTable) {
    if (efiTable == null) {
        THROW_EXCEPTION(NullException, "EfiSystemTable is null")
        return;
    }

    if (efiTable->BootServices == null) {
        THROW_EXCEPTION(NullException, "BootServices is null")
        return;
    }

    self->bootServices = efiTable->BootServices;
}

UPtr MemoryManager_alloc(MemoryManager *self, Size size, UPtr *buffer) {
    EfiStatus s = self->bootServices->AllocatePool(EFI_BOOT_SERVICES_DATA, size, (void**)buffer);
    EFI_THROW(s, MemoryManagerException, "Cannot allocate memory pool", (UPtr)0);

    return *buffer;
}

void MemoryManager_free(MemoryManager *self, UPtr buffer) {
    EfiStatus s = self->bootServices->FreePool((void*)buffer);
    EFI_THROW(s, BootloaderException, "Cannot free memory pool");
}

PACKAGECLASS(MemoryManager, Object, _MEMORYMANAGER_METHODS, OBJECT_METHODS)
