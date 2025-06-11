#include "efi/memory.h"
#include <efi/status.h>
#include <elf/program.h>
#include <size.h>
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
#include <utils/utils.h>

extern __attribute__((noreturn)) void start_kernel(UPtr stack, UPtr pml4);
extern UInt8 trampolineStart, trampolineEnd;

EfiStatus efi_main(EfiHandle handle, EfiSystemTable* systemTable) {
    EfiStatus status;    

    efiOut = systemTable->ConOut;
    efiIn = systemTable->ConIn;
    runtimeServices = systemTable->RuntimeServices;
    bootServices = systemTable->BootServices;

    EFI_ASSERT(efiOut->SetMode(efiOut, 2));
    EFI_ASSERT(efiOut->ClearScreen(efiOut));

    EFI_ASSERT(efi_announce(L"Boson Bootloader for Muon Kernel"));

    EFI_ASSERT(systemTable->ConIn->Reset(systemTable->ConIn, false));
    
    
    EfiLoadedImageProtocol* loadedImage;
    EFI_ASSERT_THEN(bootServices->HandleProtocol(handle, &(EfiGUID)EFI_LOADED_IMAGE_PROTOCOL_GUID, (void**)&loadedImage), {
        efi_log(L"Error getting bootloader image information");
    });
    
    EFI_ASSERT(efi_log(L"Retrieved bootloader image information"));
    
    EfiSimpleFileSystemProtocol* fileSystem;
    EFI_ASSERT_THEN(bootServices->HandleProtocol(loadedImage->DeviceHandle, &(EfiGUID)EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_GUID, (void**)&fileSystem), {
        efi_log(L"Error getting device partitions");
    });
    
    EFI_ASSERT(efi_log(L"Retrieved device partitions"));
    
    EfiFileProtocol *root, *file;
    EFI_ASSERT_THEN(fileSystem->OpenVolume(fileSystem, &root), {
        efi_log(L"Error getting file system root");
    });

    EFI_ASSERT(efi_log(L"Retrieved file sytsem root"));

    EFI_ASSERT_THEN(root->Open(root, &file, L"\\EFI\\BOOT\\muon.sys", EFI_FILE_MODE_READ, 0), {
        efi_log(L"muon.sys not found");
    });

    efi_log(L"Loaded muon.sys");

    EfiFileInfo* kernelInfo = null;
    UINTN infoSize = 0;

    status = file->GetInfo(file, &(EfiGUID)EFI_FILE_INFO_GUID, &infoSize, null);
    if (status == EFIERR(EFI_BUFFER_TOO_SMALL)) {
        efi_logf("Allocating %u bytes for info structure...", infoSize);
        status = efi_alloc(infoSize, (void**)kernelInfo);
    } else {
        efi_logf("Cannot read file info, reason: %s (%u bytes)", status == EFI_UNSUPPORTED ? "unsupported" : "buffer_too_small", infoSize);
        efi_pause();
        return status;
    }

    status = file->GetInfo(file, &(EfiGUID)EFI_FILE_INFO_GUID, &infoSize, kernelInfo);
    if (EFI_ERROR(status)) {
        efi_logf("CRITICAL: cannot read file info, reason: %s (%u bytes)", status == EFI_UNSUPPORTED ? "unsupported" : "buffer_too_small", infoSize);
        efi_pause();
        return status;
    }

    efi_pause();

    UPtr fileBuffer;
    Elf64Header* elfHeader;
    UINTN fileSize = kernelInfo->FileSize;

    efi_logf("File '%w' is %u bytes, allocating...", kernelInfo->FileName, fileSize);
    status = efi_alloc(fileSize, (void**)&fileBuffer);
    if (EFI_ERROR(status)) {
        efi_log(L"Cannot allocate file buffer");
        return status;
    }

    efi_logf("Allocated buffer of %u bytes", fileSize);

    status = file->Read(file, &fileSize, (void*)fileBuffer);
    if (EFI_ERROR(status)) {
        efi_log(L"Cannot read from file");
        return status;
    }
    efi_logf("Read %u bytes from file", fileSize);

    elfHeader = (Elf64Header*)fileBuffer;
    Int8Result res = IByteArray.compare_n(elfHeader->common.magic, ELF_MAGIC, 4);

    if (UNWRAP(res) == 0 && 
            elfHeader->common.elf_mode == ELF_64BIT && 
            elfHeader->common.endian_type == ELF_LITTLE_ENDIAN) {

        efi_logf("Kernel entry point at %x", elfHeader->entry_point);

        UInt64 *pml4, *pdpt, *identityPdpt, *identityPd, *pd, *pt;
        efi_alloc_pages(EFI_PAGE_SIZE, (UPtr*)&pml4);
        efi_alloc_pages(EFI_PAGE_SIZE, (UPtr*)&pdpt);
        efi_alloc_pages(EFI_PAGE_SIZE, (UPtr*)&identityPdpt);
        efi_alloc_pages(EFI_PAGE_SIZE, (UPtr*)&identityPd);
        efi_alloc_pages(EFI_PAGE_SIZE, (UPtr*)&pd);
        efi_alloc_pages(EFI_PAGE_SIZE, (UPtr*)&pt);

        // todo più pagine!!
        UPtr stack;
        efi_alloc_pages(2*EFI_PAGE_SIZE, &stack);

        efi_pause();

        UPtr apicAddr = 0xFEE00000;

        pml4[0] = (UInt64)identityPdpt | EFI_PAGE_PRESENT | EFI_PAGE_RW;
        pml4[511] = (UInt64)pdpt | EFI_PAGE_PRESENT | EFI_PAGE_RW;
        pdpt[0] = (UInt64)pd | EFI_PAGE_PRESENT | EFI_PAGE_RW;
        pd[0] = (UInt64)pt | EFI_PAGE_PRESENT | EFI_PAGE_RW;

        identityPdpt[0] = (UInt64)0x0 | EFI_PAGE_PRESENT | EFI_PAGE_RW | EFI_PAGE_HUGE;
        identityPdpt[(apicAddr>>30) & 0x1ff] = (UInt64)identityPd | EFI_PAGE_PRESENT | EFI_PAGE_RW;

        identityPd[(apicAddr>>21) & 0x1ff] = (UInt64)apicAddr | EFI_PAGE_PRESENT | EFI_PAGE_RW | EFI_PAGE_HUGE;

        {
            UPtr addr = (UPtr)stack;
            UPtr physAddr = ((UInt64)addr & ~((UInt64)0xfff));
            UPtr pml4e = (addr >> 39) & 0x1ff;
            UPtr pdpte = (addr >> 30) & 0x1ff;
            UPtr pde   = (addr >> 21) & 0x1ff;
            UPtr pte   = (addr >> 12) & 0x1ff;
            efi_logf("pml4e: %u > pdpte: %u > pde: %u > pte: %u: %x == %x", pml4e, pdpte, pde, pte, addr, physAddr);

            efi_pause();

            UInt64 *thisPml4 = pml4, *thisPdpt = pdpt, *thisPd = 0, *thisPt = 0;
            if (!(thisPml4[pml4e] & EFI_PAGE_PRESENT)) {
                efi_alloc_pages(EFI_PAGE_SIZE, (UPtr*)&thisPdpt);
                thisPml4[pml4e] = (UInt64)thisPdpt | EFI_PAGE_PRESENT | EFI_PAGE_RW;
            }

            if (!(thisPdpt[pdpte] & EFI_PAGE_PRESENT)) {
                efi_alloc_pages(EFI_PAGE_SIZE, (UPtr*)&thisPd);
                thisPdpt[pdpte] = (UInt64)thisPd | EFI_PAGE_PRESENT | EFI_PAGE_RW;
            }

            if (!(thisPd[pde] & EFI_PAGE_PRESENT)) {
                efi_alloc_pages(EFI_PAGE_SIZE, (UPtr*)&thisPt);
                thisPd[pde] = (UInt64)thisPt | EFI_PAGE_PRESENT | EFI_PAGE_RW;
            }

            if (!(thisPt[pte] & EFI_PAGE_PRESENT)) {
                thisPt[pte] = physAddr | EFI_PAGE_PRESENT | EFI_PAGE_RW;
            }
        }

        {
            UPtr addr = (UPtr)&trampolineStart;
            UPtr physAddr = ((UInt64)addr & ~((UInt64)0xfff));
            UPtr pml4e = (addr >> 39) & 0x1ff;
            UPtr pdpte = (addr >> 30) & 0x1ff;
            UPtr pde   = (addr >> 21) & 0x1ff;
            UPtr pte   = (addr >> 12) & 0x1ff;
            efi_logf("pml4e: %u > pdpte: %u > pde: %u > pte: %u: %x == %x", pml4e, pdpte, pde, pte, addr, physAddr);

            efi_pause();

            UInt64 *thisPml4 = pml4, *thisPdpt = pdpt, *thisPd = 0, *thisPt = 0;
            if (!(thisPml4[pml4e] & EFI_PAGE_PRESENT)) {
                efi_alloc_pages(EFI_PAGE_SIZE, (UPtr*)&thisPdpt);
                thisPml4[pml4e] = (UInt64)thisPdpt | EFI_PAGE_PRESENT | EFI_PAGE_RW;
            }

            if (!(thisPdpt[pdpte] & EFI_PAGE_PRESENT)) {
                efi_alloc_pages(EFI_PAGE_SIZE, (UPtr*)&thisPd);
                thisPdpt[pdpte] = (UInt64)thisPd | EFI_PAGE_PRESENT | EFI_PAGE_RW;
            }

            if (!(thisPd[pde] & EFI_PAGE_PRESENT)) {
                efi_alloc_pages(EFI_PAGE_SIZE, (UPtr*)&thisPt);
                thisPd[pde] = (UInt64)thisPt | EFI_PAGE_PRESENT | EFI_PAGE_RW;
            }

            if (!(thisPt[pte] & EFI_PAGE_PRESENT)) {
                thisPt[pte] = physAddr | EFI_PAGE_PRESENT | EFI_PAGE_RW;
            }
        }

        Elf64ProgramHeader* programHeader = (Elf64ProgramHeader*)((UPtr)elfHeader + elfHeader->program_offset);
        for (Size i=0; i<elfHeader->programs_count; i++) {
            if (programHeader->type == SEGMENT_TYPE_LOAD) {
                UPtr addr = 0;
                status = efi_alloc_pages(programHeader->mem_size, &addr);
                efi_logf("Allocated %u pages for segment at %x", EFI_SIZE_TO_PAGES(programHeader->mem_size), addr);

                efi_mem_copy((const char*)(fileBuffer + programHeader->file_offset), (char*)addr, programHeader->mem_size);

                Size fillZero = programHeader->mem_size - programHeader->file_size;
                if (fillZero > 0) {
                    efi_logf("Zeroing %u bytes...", fillZero);
                    efi_mem_set((char*)addr, programHeader->mem_size, 0);
                }
            }

            programHeader = (Elf64ProgramHeader*)((UPtr)programHeader + elfHeader->programs_size);
        }

        efi_logf("Press any key to load CR3");
        efi_pause();

        /* EfiMemoryDescriptor* d = *map;
        for (Size i=0; i<(size/descriptorSize); i++) {
            efi_logf("attribute: %u, pages: %u, %x -> %x (%d)", d->Attribute, d->NumberOfPages, d->PhysicalStart, d->VirtualStart, d->Type);
            d = (EfiMemoryDescriptor*)((UInt8*)d + descriptorSize);
        } */

        efi_logf("trampoline: %x - %x %d", &trampolineStart, &trampolineEnd, &trampolineEnd-&trampolineStart);

                UINTN mapKey, descriptorSize, size = 0;
        UInt32 ver;
        EfiMemoryDescriptor** map = null;
        
        status = bootServices->GetMemoryMap(&size, null, &mapKey, &descriptorSize, &ver);
        if (status == EFIERR(EFI_BUFFER_TOO_SMALL)) {
            efi_logf("Allocating %u for memory map...", size);
            status = efi_alloc(size, (void**)map);

        } else {
            efi_logf("Error getting memory map %x %u", status, size);
            efi_pause();
            return status;
        } 

        EFI_ASSERT_THEN(bootServices->GetMemoryMap(&size, *map, &mapKey, &descriptorSize, &ver), {
            efi_logf("error memory map %x", status);
            efi_pause();
        })
        EFI_ASSERT_THEN(bootServices->ExitBootServices(handle, mapKey), {
            efi_logf("error exit boot services %x", status);
            efi_pause();
        })

        start_kernel(stack, (UPtr)pml4);

        __asm__ volatile (
            "mov %0, %%cr3"
            :
            : "r"(pml4)
            : "memory"
        );

        return status;

        efi_logf("CR3 loaded");

        efi_pause();
    }

    return status;
}
