#pragma once

#include <base/int.h>

typedef enum {
    MEMORY_REGION_BOOTLOADER,
    MEMORY_REGION_AVAILABLE,
    MEMORY_REGION_FIRMWARE,
    MEMORY_REGION_ACPI,
    MEMORY_REGION_MMIO,
    MEMORY_REGION_RESERVED
} MemoryRegionType;

typedef struct _Bootloader_Kernel_Stack_struct {
    Size size;
    UPtr base;
    UPtr end;
} BootloaderKernelStack;

typedef struct _Memory_Region_struct {
    MemoryRegionType type;
    UPtr base;
    BigSize size;
} MemoryRegion;

typedef struct _Bootloader_Payload_struct {
    UPtr pageTablePaddr;
    BootloaderKernelStack stack;
    MemoryRegion* memoryRegionMap;
    Size memoryRegionEntries;
} BootloaderPayload;

