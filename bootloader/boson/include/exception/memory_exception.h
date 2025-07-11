#pragma once

#include <lepton.h>
#include <exception/bootloader_exception.h>

#define _MEMORYMANAGER_EXCEPTION_METHODS(TYPE, SUPER, FUNC)

#define MEMORYMANAGER_EXCEPTION_METHODS(TYPE, SUPER, FUNC) \
    THROWABLE_METHODS(TYPE, SUPER, FUNC) \
    _MEMORYMANAGER_EXCEPTION_METHODS(TYPE, SUPER, FUNC)

CLASSDEF(MemoryManagerException, BootloaderException, MEMORYMANAGER_EXCEPTION_METHODS)

ENDCLASSDEF(MemoryManagerException)
