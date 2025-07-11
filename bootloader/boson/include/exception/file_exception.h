#pragma once

#include <lepton.h>
#include <exception/bootloader_exception.h>

#define _FILE_EXCEPTION_METHODS(TYPE, SUPER, FUNC)

#define FILE_EXCEPTION_METHODS(TYPE, SUPER, FUNC) \
    THROWABLE_METHODS(TYPE, SUPER, FUNC) \
    _FILE_EXCEPTION_METHODS(TYPE, SUPER, FUNC)

CLASSDEF(FileException, BootloaderException, FILE_EXCEPTION_METHODS)

ENDCLASSDEF(FileException)
