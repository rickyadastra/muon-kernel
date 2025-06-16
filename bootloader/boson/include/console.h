#pragma once

#include "efi/efi.h"
#include <efi/runtime_services.h>
#include <lepton/core.h>
#include <wchar.h>
#include <bool.h>

#define _CONSOLE_METHODS(T, S, M) \
    M(T, S, void, set_efi_table, Console* self, EfiSystemTable* efiTable) \
    M(T, S, void, set_mode_and_clear, Console* self, UInt64 mode) \
    M(T, S, void, output, Console* self, WChar16* msg, Bool showTimestamp) \
    M(T, S, void, announce, Console* self, WChar16* msg) \
    M(T, S, void, log, Console* self, WChar16* msg) \
    M(T, S, void, logf, Console* self, const char* msg, ...) \
    METHOD(T, S, M, void, pause)
    
#define CONSOLE_METHODS(T, S, M) \
    OBJECT_METHODS(T, S, M) \
    _CONSOLE_METHODS(T, S, M)

CLASSDEF(Console, Object, CONSOLE_METHODS)
    EfiRuntimeServices* runtimeServices;
    EfiSimpleTextOutputProtocol* efiOut;
    EfiSimpleTextInputProtocol* efiIn;
ENDCLASSDEF(Console)
