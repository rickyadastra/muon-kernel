#pragma once

#include "efi/boot_services.h"
#include <file.h>
#include <efi/efi.h>
#include <efi/file_protocol.h>
#include <efi/image_protocol.h>
#include <lepton/core.h>
#include <bool.h>

#define _BOOTLOADER_METHODS(T, S, M) \
    METHOD(T, S, M, void, set_handle, EfiHandle efiHandle) \
    METHOD(T, S, M, void, set_efi_table, EfiSystemTable* efiTable) \
    METHOD(T, S, M, Bool, open_volume) \
    METHOD(T, S, M, UPtr, alloc, Size size, UPtr* buffer) \
    METHOD(T, S, M, void, free, UPtr buffer) \
    
#define BOOTLOADER_METHODS(T, S, M) \
    OBJECT_METHODS(T, S, M) \
    _BOOTLOADER_METHODS(T, S, M)

CLASSDEF(Bootloader, Object, BOOTLOADER_METHODS)
    EfiHandle bootloaderHandle;
    EfiBootServices* bootServices;
    EfiLoadedImageProtocol* bootloaderImage;

    EfiSimpleFileSystemProtocol* fileSystem;
    File root;
ENDCLASSDEF(Bootloader)
