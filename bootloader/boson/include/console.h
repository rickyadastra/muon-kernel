#pragma once

#include "efi/efi.h"
#include <efi/runtime_services.h>
#include <lepton/core.h>
#include <wchar.h>
#include <bool.h>

#define _CONSOLE_METHODS(T, S, M) \
    METHOD(T, S, M, void, set_efi_table, EfiSystemTable* efiTable) \
    METHOD(T, S, M, void, set_mode_and_clear, UInt64 mode) \
    METHOD(T, S, M, void, output, WChar16* msg, Bool showTimestamp) \
    METHOD(T, S, M, void, announce, WChar16* msg) \
    METHOD(T, S, M, void, log, WChar16* msg) \
    METHOD(T, S, M, void, logf, const char* msg, ...) \
    METHOD(T, S, M, void, pause)
    
#define CONSOLE_METHODS(T, S, M) \
    OBJECT_METHODS(T, S, M) \
    _CONSOLE_METHODS(T, S, M)

CLASSDEF(Console, Object, CONSOLE_METHODS)
    EfiRuntimeServices* runtimeServices;
    EfiSimpleTextOutputProtocol* efiOut;
    EfiSimpleTextInputProtocol* efiIn;
ENDCLASSDEF(Console)
