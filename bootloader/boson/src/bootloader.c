#include "bootloader.h"
#include "core/bytearray.h"
#include "efi/file_protocol.h"
#include "efi/memory.h"
#include "elf/elf.h"
#include "elf/program.h"
#include "file.h"
#include "lepton/exception/exception.h"
#include "memory_manager.h"
#include <lepton/exception/null_exception.h>
#include <efi/efi.h>
#include <exception/bootloader_exception.h>
#include <utils/utils.h>
#include <lepton.h>

extern UInt8 trampolineStart, trampolineEnd;

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
    if (self->kernelPageTable != null) {
        THROW_EXCEPTION(BootloaderException, "Kernel has already been loaded")
    }

    IFile.open(&self->root, &self->kernel, filename, EFI_FILE_MODE_READ);
     
    self->kernelPageTable = (PageTable)IMemoryManager.alloc_pages(self->memoryManager, EFI_PAGE_SIZE, true);

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

    self->kernelStack = (BootloaderKernelStack){
        .base = base,
        .size = size,
        .end = base + size
    };

    return self->kernelStack;
}

void Bootloader_prepare_kernel_programs(Bootloader *self) {
    Elf64Header* elfHeader = (Elf64Header*)self->kernel._fileBuffer;
    if (elfHeader == null) {
        THROW_EXCEPTION(BootloaderException, "Kernel file not loaded");
    }

    Elf64ProgramHeader* programHeader = (Elf64ProgramHeader*)((UPtr)elfHeader + elfHeader->program_offset);

    for (Size i=0; i < elfHeader->programs_count; i++) {
        if (programHeader->type != SEGMENT_TYPE_LOAD) continue;

        UPtr paddr = IMemoryManager.alloc_pages(self->memoryManager, programHeader->mem_size, true);
        
        IByteArray.copy((const char*)(((char*)self->kernel._fileBuffer) + programHeader->file_offset), (char*)paddr, programHeader->file_size, programHeader->file_size);

        Size fillZero = programHeader->mem_size - programHeader->file_size;
        if (fillZero > 0) {
            IByteArray.set(((char*)paddr + programHeader->file_size), fillZero, 0);
        }
        
        IMemoryManager.virtual_map(self->memoryManager, self->kernelPageTable, paddr, programHeader->vaddr, EFI_SIZE_TO_PAGES(programHeader->mem_size));
        programHeader = (Elf64ProgramHeader*)((UPtr)programHeader + elfHeader->programs_size);
    }
}

void Bootloader_exit_bootloader(Bootloader *self) {
    UINTN key;
    IMemoryManager.get_memory_map(self->memoryManager, null, null, &key);
    
    EfiStatus s = self->bootServices->ExitBootServices(self->bootloaderHandle, key);
    EFI_THROW(s, BootloaderException, "Error exiting UEFI boot services")
}

PACKAGECLASS(Bootloader, MemoryConsumer, _BOOTLOADER_METHODS, MEMORYCONSUMER_METHODS)
