module boson;

enum MemoryRegionType : const uint {
    BOOTLOADER,
    AVAILABLE,
    FIRMWARE,
    ACPI,
    MMIO,
    RESERVED,
}

struct BootloaderKernelStack {
    uint size;
    uptr base;
    uptr end;
}

struct MemoryRegion {
    MemoryRegionType type;
    uptr base;
    ulong size;
}

struct BootloaderPayload {
    uptr pageTablePtr;
    BootloaderKernelStack stack;
    MemoryRegion* memoryRegionMap;
    uint memoryRegionEntries;
    // vendor tables
    uptr rsdpAddr;
}
