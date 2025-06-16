#pragma once

#include "efi/boot_services.h"
#include "memory_consumer.h"
#include <file.h>
#include <efi/efi.h>
#include <efi/file_protocol.h>
#include <efi/image_protocol.h>
#include <lepton/core.h>
#include <bool.h>

#define _BOOTLOADER_METHODS(T, S, M) \
    METHOD(T, S, M, void, set_handle, EfiHandle efiHandle) \
    METHOD(T, S, M, void, set_efi_table, EfiSystemTable* efiTable) \
    METHOD(T, S, M, Bool, open_volume)
    
#define BOOTLOADER_METHODS(T, S, M) \
    MEMORYCONSUMER_METHODS(T, S, M) \
    _BOOTLOADER_METHODS(T, S, M)

CLASSDEF(Bootloader, MemoryConsumer, BOOTLOADER_METHODS)
    EfiHandle bootloaderHandle;
    EfiBootServices* bootServices;
    EfiLoadedImageProtocol* bootloaderImage;

    EfiSimpleFileSystemProtocol* fileSystem;
    File root;
ENDCLASSDEF(Bootloader)
