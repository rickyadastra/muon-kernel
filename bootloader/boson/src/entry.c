#include "base/int.h"
#include "bootloader.h"
#include "boson/boson.h"
#include "console.h"
#include "efi/configuration_table.h"
#include "efi/memory.h"
#include "memory_manager.h"
#include "lepton/exception/exception.h"
#include <efi/efi.h>
#include <efi/status.h>
#include <elf/elf_parser.h>
#include <elf/elf.h>
#include <elf/program.h>
#include <lepton.h>
#include <lepton/result.h>
#include <utils/utils.h>

#define APIC_BASE 0xFEE00000
#define KERNEL_STACK_PAGES 4
#define KERNEL_FILENAME L"\\EFI\\BOOT\\muon.sys"

extern __attribute__((noreturn)) void start_kernel(UPtr stack, UPtr pml4, UPtr entry, BootloaderPayload* payload);
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

        IMemoryManager.virtual_self_map(&memManager, bootloader.kernelPageTable, 510);

        IBootloader.prepare_kernel_programs(&bootloader);
        IConsole.log(&console, L"Kernel programs loaded and mapped");

        BootloaderPayload* payload = (BootloaderPayload*) IMemoryManager.alloc_pages(&memManager, sizeof(BootloaderPayload), true);
        IMemoryManager.virtual_map(&memManager, bootloader.kernelPageTable, (UPtr)payload, (UPtr)payload, EFI_SIZE_TO_PAGES(sizeof(BootloaderPayload)));
        payload->stack = bootloader.kernelStack;
        payload->pageTablePaddr = (UPtr)bootloader.kernelPageTable;

        // ? Find ACPI table address
        for (Size i = 0; i < systemTable->NumberOfTableEntries; i++) {
            EfiConfigurationTable table = systemTable->ConfigurationTable[i];
            if (compare_guid(&table.VendorGuid, &(EfiGUID)EFI_ACPI_20_TABLE_GUID)) {
                IConsole.logf(&console, "Found ACPI 2.0 table at %x", table.VendorTable);
                payload->rsdpAddr = (UPtr)table.VendorTable;
            }
        }
        
        Size descriptorSize = 0, size;
        EfiMemoryDescriptor* memoryMap = (IMemoryManager.get_memory_map(&memManager, &size, &descriptorSize, null));

        // ? Identity map ACPI tables 
        EfiMemoryDescriptor* d = memoryMap;
        for (Size i=0; i<(size/descriptorSize); i++) {
            if (d->Type == EFI_ACPI_RECLAIM_MEMORY)
                IMemoryManager.virtual_map(&memManager, bootloader.kernelPageTable, d->PhysicalStart, d->PhysicalStart, d->NumberOfPages);

            d = (EfiMemoryDescriptor*)((UInt8*)d + descriptorSize);
        }

        memoryMap = (IMemoryManager.get_memory_map(&memManager, &size, &descriptorSize, null));
        MemoryRegion* regions = (MemoryRegion*) IMemoryManager.alloc_pages(&memManager, EFI_PAGE_SIZE, true);
        IMemoryManager.virtual_map(&memManager, bootloader.kernelPageTable, (UPtr)regions, (UPtr)regions, 1);

        BigSize usable = 0;
        Size entries = 0;
    
        IMemoryManager.process_memory_map(memoryMap, descriptorSize, size, regions, &usable, &entries);
        IConsole.logf(&console, "%d memory entries. Total usable memory: %d KB ", entries, usable*EFI_PAGE_SIZE/1024);
        payload->memoryRegionEntries = entries;
        payload->memoryRegionMap = regions;
        
        IConsole.log(&console, L"Launching kernel...");
        IBootloader.exit_bootloader(&bootloader);
        
        start_kernel(bootloader.kernelStack.end, (UPtr)bootloader.kernelPageTable, IElfParser.get_entry_point(kernelBuf), payload);

    } CATCH(Exception, e) {
        IConsole.logf(&console, "%s (%s:%u): %s", IException.get_class(e)->name, e->file, e->line, e->message);
        IConsole.output(&console, L"\nPress any key to return to UEFI shell", false);

        IConsole.pause(&console);

    } ENDTRY

    return EFIERR(EFI_LOAD_ERROR);
}
