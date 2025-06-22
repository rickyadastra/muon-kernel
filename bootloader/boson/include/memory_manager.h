#pragma once

#include "int.h"
#include "lepton/core/class.h"
#include "size.h"
#include <lepton/core.h>
#include <efi/boot_services.h>

#define PAGE_ENTRIES_COUNT 512

typedef UInt64* PageTable;

#define _MEMORYMANAGER_METHODS(T, S, M) \
    METHOD(T, S, M, void, set_efi_table, EfiSystemTable* efiTable) \
    METHOD(T, S, M, UPtr, alloc, Size size, UPtr* buffer) \
    METHOD(T, S, M, UPtr, alloc_pages, Size size, Bool clearPage) \
    METHOD(T, S, M, void, free, UPtr buffer) \
    METHOD(T, S, M, void, free_pages, UPtr addr, Size size) \
    METHOD(T, S, M, void, virtual_map, PageTable pml4, UPtr paddr, UPtr vaddr, Size pages) \
    METHOD(T, S, M, void, virtual_map_huge, PageTable pml4, UPtr paddr, UPtr vaddr, Size pages) \

#define MEMORYMANAGER_METHODS(T, S, M) \
    OBJECT_METHODS(T, S, M) \
    _MEMORYMANAGER_METHODS(T, S, M)

CLASSDEF(MemoryManager, Object, MEMORYMANAGER_METHODS)
    EfiBootServices* bootServices;
ENDCLASSDEF(MemoryManager)
