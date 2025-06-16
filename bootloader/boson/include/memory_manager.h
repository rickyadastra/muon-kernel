#pragma once

#include "lepton/core/class.h"
#include <lepton/core.h>
#include <efi/boot_services.h>

#define _MEMORYMANAGER_METHODS(T, S, M) \
    METHOD(T, S, M, void, set_efi_table, EfiSystemTable* efiTable) \
    METHOD(T, S, M, UPtr, alloc, Size size, UPtr* buffer) \
    METHOD(T, S, M, void, free, UPtr buffer)

#define MEMORYMANAGER_METHODS(T, S, M) \
    OBJECT_METHODS(T, S, M) \
    _MEMORYMANAGER_METHODS(T, S, M)

CLASSDEF(MemoryManager, Object, MEMORYMANAGER_METHODS)
    EfiBootServices* bootServices;
ENDCLASSDEF(MemoryManager)
