#pragma once

#include <lepton/core.h>
#include <exception/bootloader_exception.h>

#define _CONSOLE_EXCEPTION_METHODS(TYPE, SUPER, FUNC)

#define CONSOLE_EXCEPTION_METHODS(TYPE, SUPER, FUNC) \
    THROWABLE_METHODS(TYPE, SUPER, FUNC) \
    _CONSOLE_EXCEPTION_METHODS(TYPE, SUPER, FUNC)

CLASSDEF(ConsoleException, BootloaderException, CONSOLE_EXCEPTION_METHODS)

ENDCLASSDEF(ConsoleException)
