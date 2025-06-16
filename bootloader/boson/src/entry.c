#include "lepton/result.h"
#include <lepton/core.h>
#include <int.h>
#include <bool.h>
#include <null.h>
#include <wchar.h>
#include <efi/efi.h>
#include <efi/file_protocol.h>
#include <efi/boot_services.h>
#include <efi/image_protocol.h>
#include <efi/time.h>
#include <efi/runtime_services.h>
#include <elf/elf.h>
#include <core/bytearray.h>

WChar16 buffer[64];
EfiSimpleTextOutputProtocol* efiOut;
EfiSimpleTextInputProtocol* efiIn;
EfiRuntimeServices* runtimeServices;
EfiBootServices* bootServices;

EfiStatus efi_log_full(WChar16* msg, Bool showTimestamp);
EfiStatus efi_announce(WChar16* msg);
EfiStatus efi_log(WChar16* msg);
EfiInputKey efi_pause();

EfiStatus efi_main(EfiHandle handle, EfiSystemTable* systemTable) {
    EfiStatus status;
    EfiInputKey key;

    efiOut = systemTable->ConOut;
    efiIn = systemTable->ConIn;
    runtimeServices = systemTable->RuntimeServices;
    bootServices = systemTable->BootServices;

    status = efiOut->ClearScreen(efiOut);
    if (EFI_ERROR(status)) return status;

    status = efi_announce(L"Boson Bootloader for Muon Kernel");
    if (EFI_ERROR(status)) return status;

    status = systemTable->ConIn->Reset(systemTable->ConIn, false);
    if (EFI_ERROR(status)) return status;
    
    EfiLoadedImageProtocol* loadedImage;
    EfiSimpleFileSystemProtocol* fileSystem;
    EfiFileProtocol* root, *file;

    status = bootServices->HandleProtocol(handle, &(EfiGUID)EFI_LOADED_IMAGE_PROTOCOL_GUID, (void**)&loadedImage);
    if (EFI_ERROR(status)) {
        efi_log(L"Error getting bootloader image information");
        return status;
    } 
    efi_log(L"Retrieved bootloader image information");

    status = bootServices->HandleProtocol(loadedImage->DeviceHandle, &(EfiGUID)EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_GUID, (void**)&fileSystem);
    if (EFI_ERROR(status)) {
        efi_log(L"Error getting device partitions");
        return status;
    }
    efi_log(L"Retrieved device partitions");

    status = fileSystem->OpenVolume(fileSystem, &root);
    if (EFI_ERROR(status)) {
        efi_log(L"Error getting file system root");
        return status;
    }
    efi_log(L"Retrieved file sytsem root");
    
    status = root->Open(root, &file, L"\\EFI\\BOOT\\muon.sys", EFI_FILE_MODE_READ, 0);
    if (EFI_ERROR(status)) {
        efi_log(L"muon.sys not found");
        return status;
    }
    efi_log(L"Loaded muon.sys");

    Elf64Header elfHeader;
    UINTN headerSize = sizeof(elfHeader);

    status = file->Read(file, &headerSize, &elfHeader);
    if (EFI_ERROR(status)) {
        efi_log(L"Cannot read file header");
        return status;
    }
    efi_log(L"Read muon.sys header");

    Int8Result res = IByteArray.compare_n(elfHeader.common.magic, ELF_MAGIC, 4);
    if (UNWRAP(RESULT) == 0) {
        efi_log(L"yippie");
    }

    efi_pause();

    return status;
}

EfiInputKey efi_pause() {
    EfiInputKey key;
    while (efiIn->ReadKeyStroke(efiIn, &key) == EFI_NOT_READY) {}
    return key;
}

EfiStatus efi_log_full(WChar16* msg, Bool showTimestamp) {
    EfiStatus status;
    
    if (showTimestamp) {
        EfiTime time; 
        EfiStatus timeStatus = runtimeServices->GetTime(&time, null);
        if (EFI_ERROR(timeStatus)) return timeStatus;

        Size offset = format_datetime(time, buffer, 64);

        status = efiOut->OutputString(efiOut, buffer);
        if (EFI_ERROR(status)) return status;
    }

    status = efiOut->OutputString(efiOut, msg);
    if (EFI_ERROR(status)) return status;
    status = efiOut->OutputString(efiOut, L"\r\n");
    return status;
}


EfiStatus efi_announce(WChar16* msg) {
    return efi_log_full(msg, false);
}

EfiStatus efi_log(WChar16* msg) {
    return efi_log_full(msg, true);
}
