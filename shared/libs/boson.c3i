module boson;

enum MemoryRegionType : uint {
    BOOTLOADER,
    AVAILABLE,
    FIRMWARE,
    ACPI,
    MMIO,
    RESERVED,
    KERNEL,
}

struct BootloaderKernelStack {
    uint size;
    uptr base;
    uptr end;
}

struct MemoryRegion {
    MemoryRegionType type;
    uptr base;
    uptr baseVirt;
    ulong size;
}

struct BootloaderPayload {
    uptr pageTablePtr;
    BootloaderKernelStack stack;
    MemoryRegion* memoryRegionMap;
    uint memoryRegionEntries;
    ulong totalMemoryBytes;
    // vendor tables
    uptr rsdpAddr;
}
