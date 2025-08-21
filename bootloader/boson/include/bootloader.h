#pragma once

#include "efi/boot_services.h"
#include "lepton/core/class.h"
#include "memory_consumer.h"
#include "memory_manager.h"
#include <boson/boson.h>
#include <file.h>
#include <efi/efi.h>
#include <efi/file_protocol.h>
#include <efi/image_protocol.h>
#include <lepton.h>

#define _BOOTLOADER_METHODS(T, S, M) \
    METHOD(T, S, M, void, set_handle, EfiHandle efiHandle) \
    METHOD(T, S, M, void, set_efi_table, EfiSystemTable* efiTable) \
    METHOD(T, S, M, void, init_memory_map) \
    METHOD(T, S, M, Bool, open_volume) \
    METHOD(T, S, M, UPtr, load_kernel, const WChar16* filename) \
    METHOD(T, S, M, BootloaderKernelStack, prepare_kernel_stack, Size size) \
    METHOD(T, S, M, void, prepare_kernel_programs) \
    METHOD(T, S, M, void, exit_bootloader) \
    
#define BOOTLOADER_METHODS(T, S, M) \
    MEMORYCONSUMER_METHODS(T, S, M) \
    _BOOTLOADER_METHODS(T, S, M)

CLASSDEF(Bootloader, MemoryConsumer, BOOTLOADER_METHODS)
    EfiHandle bootloaderHandle;
    EfiBootServices* bootServices;
    EfiLoadedImageProtocol* bootloaderImage;

    EfiSimpleFileSystemProtocol* fileSystem;
    File root;

    File kernel;
    PageTable kernelPageTable;
    BootloaderKernelStack kernelStack;

    MemoryRegion* regions;
    Size regionEntries;
ENDCLASSDEF(Bootloader)
