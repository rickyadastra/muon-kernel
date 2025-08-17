module arch::mem;

import boson;
import mem;
import muon::logging;

const uptr LEGACY_BIOS_LIMIT = 0x9ffff;

faultdef MEMORY_UNAVAILABLE;

fn uptr? find_bitmap_region(MemoryRegion[] memoryRegions, usz byteSize) @local {
    foreach (usz i, MemoryRegion reg : memoryRegions) {
        if (reg.type == AVAILABLE && reg.base > LEGACY_BIOS_LIMIT && reg.size >= byteSize) return reg.base;
    }

    return MEMORY_UNAVAILABLE?;
}

fn void? init(BootloaderPayload* payload) {
    MemoryRegion[] regions = payload.memoryRegionMap[:payload.memoryRegionEntries];
    usz bitmapAllocSize = pmm::bitmap_alloc_size_of(payload.totalMemoryBytes);
    uptr bitmap = find_bitmap_region(regions, bitmapAllocSize)!;
    
    logging::printn("bitmap size will be %d B", bitmapAllocSize);

    pmm::setup(bitmap, payload.totalMemoryBytes)!;

    foreach (usz i, MemoryRegion reg : regions) {
        if (reg.type != AVAILABLE) {
            logging::printn("%d:\t[%x-%x] %d B (type: %s)", i, reg.base, reg.base+reg.size-1, reg.size, reg.type.nameof);

            // sanitize size: some uefi memory regions are MMIO outside of physical RAM
            usz size = reg.size;
            if (reg.base + reg.size >= payload.totalMemoryBytes) {
                size = payload.totalMemoryBytes - reg.base;
            }

            pmm::mark_region_used(reg.base, size)!;
        }
    }
}
