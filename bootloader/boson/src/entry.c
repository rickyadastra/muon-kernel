#include <lepton/result.h>
#include <lepton/core.h>
#include <int.h>
#include <bool.h>
#include <null.h>
#include <efi/efi.h>
#include <efi/file_protocol.h>
#include <efi/boot_services.h>
#include <efi/image_protocol.h>
#include <efi/time.h>
#include <efi/runtime_services.h>
#include <elf/elf.h>
#include <core/bytearray.h>
#include <utils/log.h>

EfiStatus efi_main(EfiHandle handle, EfiSystemTable* systemTable) {
    EfiStatus status;

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
    UINTN headerSize = sizeof(Elf64Header);

    status = file->Read(file, &headerSize, &elfHeader);
    if (EFI_ERROR(status)) {
        efi_log(L"Cannot read file header");
        return status;
    }
    efi_log(L"Read muon.sys header");

    Int8Result res = IByteArray.compare_n(elfHeader.common.magic, ELF_MAGIC, 4);
    if (UNWRAP(RESULT) == 0 && 
            elfHeader.common.elf_mode == ELF_64BIT && 
            elfHeader.common.endian_type == ELF_LITTLE_ENDIAN) {

        efi_logf("entry point: %x", elfHeader.entry_point);
    }

    efi_pause();

    return status;
}
