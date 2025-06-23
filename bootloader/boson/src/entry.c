#include "bootloader.h"
#include "console.h"
#include "efi/memory.h"
#include <elf/elf_parser.h>
#include "lepton/exception/exception.h"
#include "memory_manager.h"
#include <lepton/core.h>
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

#define APIC_BASE 0xFEE00000
#define KERNEL_STACK_PAGES 4
#define KERNEL_FILENAME L"\\EFI\\BOOT\\muon.sys"

extern __attribute__((noreturn)) void start_kernel(UPtr stack, UPtr pml4, UPtr entry);
extern UInt8 trampolineStart, trampolineEnd;

void virtual_map(UPtr paddr, UPtr vaddr, UInt64* pml4);

EfiStatus efi_main(EfiHandle handle, EfiSystemTable* systemTable) {
    efiOut = systemTable->ConOut;
    efiIn = systemTable->ConIn;
    runtimeServices = systemTable->RuntimeServices;
    bootServices = systemTable->BootServices;

    Console console = IConsole.init();
    MemoryManager memManager = IMemoryManager.init();
    Bootloader bootloader = IBootloader.init();
    
    TRY {
        IConsole.set_efi_table(&console, systemTable);
        IConsole.set_mode_and_clear(&console, 2);
        IConsole.announce(&console, L"Boson Bootloader for Muon Kernel");

        IMemoryManager.set_efi_table(&memManager, systemTable);
        IConsole.log(&console, L"Memory manager initiliased");

        IBootloader.set_handle(&bootloader, handle);
        IBootloader.set_efi_table(&bootloader, systemTable);
        IBootloader.set_memory_manager(&bootloader, &memManager);
        IConsole.logf(&console, "Bootloader information loaded, trampoline @ %x", &trampolineStart);

        IBootloader.open_volume(&bootloader);
        UPtr kernelBuf = IBootloader.load_kernel(&bootloader, KERNEL_FILENAME);
        IConsole.log(&console, L"Opened kernel file");

        if (!IElfParser.check_header(kernelBuf, ELF_64BIT, ELF_x86_64, ELF_LITTLE_ENDIAN)) {
            THROW_EXCEPTION(Exception, "Kernel is not a valid ELF file")
        }

        IMemoryManager.virtual_map(&memManager, bootloader.kernelPageTable, (UPtr)&trampolineStart, 
            (UPtr)&trampolineStart, EFI_SIZE_TO_PAGES(&trampolineEnd - &trampolineStart));
        IConsole.logf(&console, "Kernel entry point at %x", IElfParser.get_entry_point(kernelBuf));
        
        IBootloader.prepare_kernel_stack(&bootloader, KERNEL_STACK_PAGES*EFI_PAGE_SIZE);
        IConsole.log(&console, L"Kernel stack allocated and mapped");
        
        IMemoryManager.virtual_map_huge(&memManager, bootloader.kernelPageTable, 0x0, 0x0, 1);
        IConsole.log(&console, L"Lower 2MB identity mapped");

        IMemoryManager.virtual_map_huge(&memManager, bootloader.kernelPageTable, APIC_BASE, APIC_BASE, 1);
        IConsole.log(&console, L"APIC identity mapped");

        IBootloader.prepare_kernel_programs(&bootloader);
        IConsole.log(&console, L"Kernel programs loaded and mapped");

        // Size descriptorSize = 0, size;
        // EfiMemoryDescriptor* d = (IMemoryManager.get_memory_map(&memManager, &size, &descriptorSize));

        
        // for (Size i=0; i<(size/descriptorSize); i++) {
            //     efi_logf("attribute: %u, pages: %u, %x -> %x (%d)", d->Attribute, d->NumberOfPages, d->PhysicalStart, d->VirtualStart, d->Type);
            //     d = (EfiMemoryDescriptor*)((UInt8*)d + descriptorSize);
            // } 
        
        IConsole.log(&console, L"Launching kernel...");
        IBootloader.exit_bootloader(&bootloader);
        
        start_kernel(bootloader.kernelStack.end, (UPtr)bootloader.kernelPageTable, IElfParser.get_entry_point(kernelBuf));


    } CATCH(Exception, e) {
        IConsole.logf(&console, "%s (%s:%u): %s", IException.get_class(e)->name, e->file, e->line, e->message);
        IConsole.output(&console, L"\nPress any key to return to UEFI shell", false);

        IConsole.pause(&console);

    } ENDTRY

    return EFIERR(EFI_LOAD_ERROR);
}

void virtual_map(UPtr paddr, UPtr vaddr, UInt64* pml4) {
    paddr = (UInt64)paddr & ~((UInt64)0xfff);
    vaddr = (UInt64)vaddr & ~((UInt64)0xfff);

    UPtr pml4e = (vaddr >> 39) & 0x1ff;
    UPtr pdpte = (vaddr >> 30) & 0x1ff;
    UPtr pde   = (vaddr >> 21) & 0x1ff;
    UPtr pte   = (vaddr >> 12) & 0x1ff;
    efi_logf("pml4e: %u > pdpte: %u > pde: %u > pte: %u: %x ==> %x", pml4e, pdpte, pde, pte, vaddr, paddr);

    efi_pause();

    UInt64 *thisPml4 = pml4, *thisPdpt = 0, *thisPd = 0, *thisPt = 0;
    if (!(thisPml4[pml4e] & EFI_PAGE_PRESENT)) {
        efi_alloc_pages(EFI_PAGE_SIZE, (UPtr*)&thisPdpt);
        thisPml4[pml4e] = (UInt64)thisPdpt | EFI_PAGE_PRESENT | EFI_PAGE_RW;
    } else
    thisPdpt = (UInt64*)((UInt64)thisPml4[pml4e] & ~((UInt64)0xfff));
    efi_logf("pdpt %x", thisPdpt);

    if (!(thisPdpt[pdpte] & EFI_PAGE_PRESENT)) {
        efi_alloc_pages(EFI_PAGE_SIZE, (UPtr*)&thisPd);
        thisPdpt[pdpte] = (UInt64)thisPd | EFI_PAGE_PRESENT | EFI_PAGE_RW;
    } else
    thisPd = (UInt64*)((UInt64)thisPdpt[pdpte] & ~((UInt64)0xfff));
    efi_logf("pd %x", thisPd);

    if (!(thisPd[pde] & EFI_PAGE_PRESENT)) {
        efi_alloc_pages(EFI_PAGE_SIZE, (UPtr*)&thisPt);
        thisPd[pde] = (UInt64)thisPt | EFI_PAGE_PRESENT | EFI_PAGE_RW;
    } else
    thisPt = (UInt64*)((UInt64)thisPd[pde] & ~((UInt64)0xfff));
    efi_logf("pt %x", thisPt);

    if (!(thisPt[pte] & EFI_PAGE_PRESENT)) {
        thisPt[pte] = paddr | EFI_PAGE_PRESENT | EFI_PAGE_RW;
    }
}