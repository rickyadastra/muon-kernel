#include "memory_manager.h"
#include "boson/boson.h"
#include "core/bytearray.h"
#include "efi/efi.h"
#include "efi/memory.h"
#include <base/int.h>
#include "lepton/assert.h"
#include "lepton/exception/exception.h"
#include "utils/utils.h"
#include <lepton/exception/null_exception.h>
#include <exception/memory_exception.h>
#include <lepton.h>

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
    EfiStatus s = self->bootServices->AllocatePool(EFI_LOADER_DATA, size, (void**)buffer);
    
    self->_memoryMapKey = 0;
    EFI_THROW(s, MemoryManagerException, "Cannot allocate memory pool", (UPtr)0);

    return *buffer;
}

void MemoryManager_free(MemoryManager *self, UPtr buffer) {
    EfiStatus s = self->bootServices->FreePool((void*)buffer);
    
    self->_memoryMapKey = 0;
    EFI_THROW(s, MemoryManagerException, "Cannot free memory pool");
}

UPtr MemoryManager_alloc_pages(MemoryManager *self, Size size, Bool clearPages) {
    UPtr addr;
    EfiStatus s = self->bootServices->AllocatePages(ALLOCATE_ANY_PAGES, EFI_LOADER_DATA, EFI_SIZE_TO_PAGES(size), &addr);
    
    self->_memoryMapKey = 0;
    EFI_THROW(s, MemoryManagerException, "Cannot allocate memory pages", (UPtr)0);

    if (clearPages) IByteArray.set((char*)addr, size, 0);
    return addr;
}

void MemoryManager_free_pages(MemoryManager *self, UPtr addr, Size size) {
    EfiStatus s = self->bootServices->FreePages(addr, EFI_SIZE_TO_PAGES(size));
    
    self->_memoryMapKey = 0;
    EFI_THROW(s, MemoryManagerException, "Cannot free memory pages");
}

void virtual_map_helper(MemoryManager* self, PageTable pml4, UPtr paddr, UPtr vaddr, Bool huge) {
    paddr = (UInt64)paddr & ~((UInt64)0xfff);
    vaddr = (UInt64)vaddr & ~((UInt64)0xfff);

    UPtr pml4e = (vaddr >> 39) & 0x1ff;
    UPtr pdpte = (vaddr >> 30) & 0x1ff;
    UPtr pde   = (vaddr >> 21) & 0x1ff;
    UPtr pte   = (vaddr >> 12) & 0x1ff;

    PageTable thisPml4 = pml4, thisPdpt = 0, thisPd = 0, thisPt = 0;
    if (!(thisPml4[pml4e] & EFI_PAGE_PRESENT)) {
        thisPdpt = (PageTable)IMemoryManager.alloc_pages(self, EFI_PAGE_SIZE, true);
        thisPml4[pml4e] = (UInt64)thisPdpt | EFI_PAGE_PRESENT | EFI_PAGE_RW;
    } else
    thisPdpt = (UInt64*)((UInt64)thisPml4[pml4e] & ~((UInt64)0xfff));

    if (!(thisPdpt[pdpte] & EFI_PAGE_PRESENT)) {
        thisPd = (PageTable)IMemoryManager.alloc_pages(self, EFI_PAGE_SIZE, true);
        thisPdpt[pdpte] = (UInt64)thisPd | EFI_PAGE_PRESENT | EFI_PAGE_RW;
    } else
    thisPd = (UInt64*)((UInt64)thisPdpt[pdpte] & ~((UInt64)0xfff));

    if (!huge) {
        if (!(thisPd[pde] & EFI_PAGE_PRESENT)) {
            thisPt = (PageTable)IMemoryManager.alloc_pages(self, EFI_PAGE_SIZE, true);
            thisPd[pde] = (UInt64)thisPt | EFI_PAGE_PRESENT | EFI_PAGE_RW;
        } else
        thisPt = (UInt64*)((UInt64)thisPd[pde] & ~((UInt64)0xfff));

        if (!(thisPt[pte] & EFI_PAGE_PRESENT)) {
            thisPt[pte] = paddr | EFI_PAGE_PRESENT | EFI_PAGE_RW;
        }
    } else {
        thisPd[pde] = (UInt64)paddr | EFI_PAGE_PRESENT | EFI_PAGE_RW | EFI_PAGE_HUGE;
    }
}

void MemoryManager_virtual_map(MemoryManager* self, PageTable pml4, UPtr paddr, UPtr vaddr, Size pages) {
    if (pml4 == null) {
        THROW_EXCEPTION(NullException, "pml4 is null")
    }

    for (Size count = 0; count < pages; count++, paddr += EFI_PAGE_SIZE, vaddr += EFI_PAGE_SIZE) {
        virtual_map_helper(self, pml4, paddr, vaddr, false);
    }
}

void MemoryManager_virtual_map_huge(MemoryManager *self, PageTable pml4, UPtr paddr, UPtr vaddr, Size pages) {
    if (pml4 == null) {
        THROW_EXCEPTION(NullException, "pml4 is null")
    }

    for (Size count = 0; count < pages; count++, paddr += EFI_PAGE_SIZE_HUGE, vaddr += EFI_PAGE_SIZE_HUGE) {
        virtual_map_helper(self, pml4, paddr, vaddr, true);
    }
}

void MemoryManager_virtual_self_map(MemoryManager *self, PageTable pml4, UInt32 index) {
    if (pml4 == null) {
        THROW_EXCEPTION(NullException, "pml4 is null")
    }

    if (index >= PAGE_ENTRIES_COUNT) {
        THROW_EXCEPTION(MemoryManagerException, "index out of bounds")
    }

    pml4[index] = ((UInt64)pml4 & ~((UInt64)0xfff)) | EFI_PAGE_PRESENT | EFI_PAGE_RW;
}

EfiMemoryDescriptor* MemoryManager_get_memory_map(MemoryManager *self, Size* _size, Size *_descriptorSize, UINTN* key) {
        UINTN mapKey, descriptorSize, size = 0;
        UInt32 ver;
        EfiMemoryDescriptor* map = null;
        
        EfiStatus status = self->bootServices->GetMemoryMap(&size, null, &mapKey, &descriptorSize, &ver);
        if (status == EFIERR(EFI_BUFFER_TOO_SMALL)) {
            IMemoryManager.alloc(self, size + 2*descriptorSize, (UPtr*)&map);

        } else {
            THROW_EXCEPTION(MemoryManagerException, "Could not get memory map buffer")
        } 

        status = self->bootServices->GetMemoryMap(&size, map, &mapKey, &descriptorSize, &ver);
        EFI_THROW(status, MemoryManagerException, "Could not get memory map", null)
        
        self->_memoryMapKey = mapKey;
        if (_descriptorSize != null) *_descriptorSize = descriptorSize;
        if (_size != null) *_size = size;
        if (key != null) *key = mapKey;
 
        return map;
}

UINTN MemoryManager_get_memory_map_key(MemoryManager *self) {
    if (self->_memoryMapKey == 0) {
        THROW_EXCEPTION(MemoryManagerException, "Memory map key is invalid. (get_memory_map must be called again after any allocation)")
    }

    return self->_memoryMapKey;
}

void MemoryManager_process_memory_map(EfiMemoryDescriptor* memoryMap, Size descriptorSize, Size mapSize, MemoryRegion* regionsBuffer, BigSize* usable, BigSize* total, Size* entriesCount) {
    ASSERT_NONNULL(memoryMap)
    ASSERT_NONNULL(regionsBuffer)
    ASSERT_NONNULL(usable)
    ASSERT_NONNULL(total)
    ASSERT_NONNULL(entriesCount)

    MemoryRegion* regionPtr = regionsBuffer + *entriesCount;
    EfiMemoryDescriptor* d = memoryMap;

    BigSize uunusable = 0;
    BigSize* unusable = &uunusable;

    UPtr base = -1, lastBase = -1;
    Size length = 0;
    MemoryRegionType lastType = MEMORY_REGION_RESERVED;

    for (Size i=0; i<(mapSize/descriptorSize); i++) {
        if ((regionPtr - regionsBuffer) >= MEMORY_REGION_MAX_COUNT) break;

        MemoryRegionType type;
        switch (d->Type) {
            case EFI_LOADER_DATA:
                type = MEMORY_REGION_BOOTLOADER;
                *usable += d->NumberOfPages;
                break;
            case EFI_LOADER_CODE:
            case EFI_BOOT_SERVICES_CODE:
            case EFI_CONVENTIONAL_MEMORY:
            case EFI_BOOT_SERVICES_DATA:
                type = MEMORY_REGION_AVAILABLE;
                *usable += d->NumberOfPages;
                break;
            case EFI_RUNTIME_SERVICES_CODE:
            case EFI_RUNTIME_SERVICES_DATA:
                type = MEMORY_REGION_FIRMWARE;
                *unusable += d->NumberOfPages;
                break;
            case EFI_ACPI_RECLAIM_MEMORY:
            case EFI_ACPI_MEMORY_NVS:
                type = MEMORY_REGION_ACPI;
                *unusable += d->NumberOfPages;
                break;
            case EFI_MEMORY_MAPPED_IO:
            case EFI_MEMORY_MAPPED_IO_PORT_SPACE:
                type = MEMORY_REGION_MMIO;
                *unusable += d->NumberOfPages;
                break;
            case EFI_UNUSABLE_MEMORY:
            case EFI_PAL_CODE:
            case EFI_RESERVED_MEMORY_TYPE:
            default:
                type = MEMORY_REGION_RESERVED;
                *unusable += d->NumberOfPages;
                break;
        }

        if (lastType == type && base + length == d->PhysicalStart) {
            length += d->NumberOfPages * EFI_PAGE_SIZE;
        } else {
            if (base != -1) {
                (*regionPtr) = (MemoryRegion){
                    .base = base,
                    .size = length,
                    .type = lastType
                };
                regionPtr++;
            }

            lastBase = base;
            base = d->PhysicalStart;
            lastType = type;
            length = d->NumberOfPages * EFI_PAGE_SIZE;
        }

        d = (EfiMemoryDescriptor*)((UInt8*)d + descriptorSize);
    } 

    if (lastBase != base) {
        (*regionPtr) = (MemoryRegion){
            .base = base,
            .size = length,
            .type = lastType
        };
        regionPtr++;
    }
    
    *total = *usable + uunusable;
    *entriesCount = regionPtr - regionsBuffer;
}

PACKAGECLASS(MemoryManager, Object, _MEMORYMANAGER_METHODS, OBJECT_METHODS)
