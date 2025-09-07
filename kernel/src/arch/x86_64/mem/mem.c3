module arch::mem;

import boson;
import mem @public;
import muon::logging;

const uptr LEGACY_BIOS_BASE = 0x0;
const uptr LEGACY_BIOS_LIMIT = 0xfffff;

faultdef MEMORY_UNAVAILABLE;

fn uptr? find_bitmap_region(MemoryRegion[] memoryRegions, usz byteSize) @local {
    foreach (usz i, MemoryRegion reg : memoryRegions) {
        if (reg.type == AVAILABLE && reg.base > LEGACY_BIOS_LIMIT && reg.size >= byteSize) return reg.base;
    }

    return MEMORY_UNAVAILABLE?;
}

fn void? mark_memory_regions(MemoryRegion[] regions) @local {
    // mark legacy bios region, should never be used
    pmm::mark_region_used(LEGACY_BIOS_BASE, LEGACY_BIOS_LIMIT)!;

    foreach (usz i, MemoryRegion reg : regions) {
            logging::printn("%d:\t[%x-%x] -> %x, %d B (type: %s)", i, reg.base, reg.base+reg.size-1, reg.baseVirt, reg.size, reg.type.nameof);
        if (reg.type != AVAILABLE) {

            // sanitize size: some uefi memory regions are MMIO outside of physical RAM
            usz size = reg.size;
            if (reg.base + reg.size >= pmm::physTotal) {
                size = pmm::physTotal - reg.base;
            }

            pmm::mark_region_used(reg.base, size)!;
        }
    }
}

fn void? map_memory_regions(MemoryRegion[] regions) @local {
    foreach (usz i, MemoryRegion reg : regions) {
        if (reg.type != AVAILABLE && reg.baseVirt != 0) {
            vmm::map(reg.base, reg.baseVirt, reg.size)!;
            
        } else if (reg.type == ACPI) {
            vmm::map(reg.base, vmm::@acpi(reg.base), reg.size)!;
        }
    }
}

fn void? init(BootloaderPayload* payload) {
    MemoryRegion[] regions = payload.memoryRegionMap[:payload.memoryRegionEntries];
    usz bitmapAllocSize = pmm::bitmap_alloc_size_of(payload.totalMemoryBytes);
    uptr bitmap = find_bitmap_region(regions, bitmapAllocSize)!;
    
    // create physmem bitmap, mark default regions
    pmm::init(bitmap, payload.totalMemoryBytes)!;
    // mark memory regions
    mark_memory_regions(regions)!;

    // create kernel address space with self map, pmm and physmap region
    vmm::init(payload.totalMemoryBytes)!;
    // map memory regions
    map_memory_regions(regions)!;

    // set new bitmap address
    pmm::set_bitmap(vmm::bitmap_virt_base());

    // activate kernel address space
    vmm::activate(&vmm::kernelAddrSpace);
    vmm::initialized = true;

    // initialize block allocator for alloc_pages
}

fn uptr alloc_pages(usz pages) {
    // find a "pages" long extent and get its vaddr
    // alloc "pages" frames via pmm and map to vaddr via vmm
    // return vaddr
    return (uptr)null;
}

fn void free_pages(uptr addr) {

}
