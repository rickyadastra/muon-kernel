#pragma once

#include "efi/efi.h"
#include "efi/memory.h"
#include "int.h"
#include "lepton/core/class.h"
#include "size.h"
#include <lepton/core.h>
#include <efi/boot_services.h>
#include <boson/boson.h>

#define PAGE_ENTRIES_COUNT 512

typedef UInt64* PageTable;

#define MEMORY_REGION_MAX_COUNT (EFI_PAGE_SIZE / sizeof(MemoryRegion))

#define _MEMORYMANAGER_METHODS(T, S, M) \
    METHOD(T, S, M, void, set_efi_table, EfiSystemTable* efiTable) \
    METHOD(T, S, M, UPtr, alloc, Size size, UPtr* buffer) \
    METHOD(T, S, M, UPtr, alloc_pages, Size size, Bool clearPage) \
    METHOD(T, S, M, void, free, UPtr buffer) \
    METHOD(T, S, M, void, free_pages, UPtr addr, Size size) \
    METHOD(T, S, M, void, virtual_map, PageTable pml4, UPtr paddr, UPtr vaddr, Size pages) \
    METHOD(T, S, M, void, virtual_map_huge, PageTable pml4, UPtr paddr, UPtr vaddr, Size pages) \
    METHOD(T, S, M, void, virtual_self_map, PageTable pml4, UInt32 index) \
    METHOD(T, S, M, EfiMemoryDescriptor*, get_memory_map, Size* size, Size* descriptorSize, UINTN* key) \
    METHOD(T, S, M, UINTN, get_memory_map_key) \
    STATIC(T, S, M, void, process_memory_map, EfiMemoryDescriptor* memoryMap, Size descriptorSize, Size mapSize, MemoryRegion* regionsBuffer, BigSize* total, Size* entriesCount) \

#define MEMORYMANAGER_METHODS(T, S, M) \
    OBJECT_METHODS(T, S, M) \
    _MEMORYMANAGER_METHODS(T, S, M)

CLASSDEF(MemoryManager, Object, MEMORYMANAGER_METHODS)
    EfiBootServices* bootServices;
    UINTN _memoryMapKey;
ENDCLASSDEF(MemoryManager)
