#include "bootloader.h"
#include "console.h"
#include "efi/memory.h"
#include "memory_manager.h"
#include "lepton/exception/exception.h"
#include <efi/efi.h>
#include <efi/status.h>
#include <elf/elf_parser.h>
#include <elf/elf.h>
#include <elf/program.h>
#include <lepton/core.h>
#include <lepton/result.h>
#include <size.h>
#include <int.h>
#include <bool.h>
#include <null.h>

#define APIC_BASE 0xFEE00000
#define KERNEL_STACK_PAGES 4
#define KERNEL_FILENAME L"\\EFI\\BOOT\\muon.sys"

extern __attribute__((noreturn)) void start_kernel(UPtr stack, UPtr pml4, UPtr entry);
extern UInt8 trampolineStart, trampolineEnd;

EfiStatus efi_main(EfiHandle handle, EfiSystemTable* systemTable) {
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
