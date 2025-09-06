module mem::vmm;

import arch::cpu;
import arch::mem::paging @public;
import mem::pmm @public;
import muon::logging;
import std::math;

faultdef PAGING_INIT_FAIL;

AddressLength addrLen @local;
AddressSpace kernelAddrSpace @private;
bool initialized @private = false;

macro uptr bitmap_virt_base() => paging::@path_addr(KnownPagingPath.PMM_BITMAP.path);
macro uptr @phys(#addr) => paging::@path_addr(KnownPagingPath.PHYSMAP.path) + #addr;
macro uptr @acpi(#addr) => paging::@path_addr(KnownPagingPath.ACPI.path) + #addr;
macro uptr @mmio(#addr) => paging::@path_addr(KnownPagingPath.MMIO.path) + #addr;

macro usz physical_address_length() => addrLen.physicalLength;
macro usz virtual_address_length() => addrLen.virtualLength;

macro uptr @align_addr(uptr #addr, usz #pageSize = paging::PageSize.NORMAL.size) => #addr & ~(#pageSize - 1);
macro usz @pages(usz #bytes, usz #pageSize = paging::PageSize.NORMAL.size) => (#bytes + (#pageSize - 1ul)) / #pageSize;
macro usz @physmap_pages(usz #bytes) => @pages(#bytes, paging::PageSize.HUGE_1G.size);

fn void? map_physmap(usz len) @local {
    logging::printn("%d -> mapping %dx 1GB pages", len, @physmap_pages(len));
    
    for (usz i = 0; i < math::min(@physmap_pages(len), PHYSMAP_MAX); i++) {
        uptr paddr = (uptr)(PageSize.HUGE_1G.size * i);
        uptr vaddr = paging::@path_addr(KnownPagingPath.PHYSMAP.path, pdpteModifier: i);

        paging::map(kernelAddrSpace.pageTable, paddr, vaddr, hugePage: HUGE_1G)!;
    }
}

fn void? map_pmap() @local {
    map((uptr)&(pmm::pmap[0]), paging::@path_addr(KnownPagingPath.PMM_BITMAP.path), pmm::pmap.len * BitmapRow.sizeof)!;
}

fn void? map(uptr paddr, uptr vaddr, usz len = paging::PageSize.NORMAL.size, PageTable table = kernelAddrSpace.pageTable) {
    for (usz i = 0; i < @pages(len); i++) {
        uptr memPaddr = @align_addr(paddr) + (paging::PageSize.NORMAL.size * i);
        uptr memVaddr = @align_addr(vaddr) + (paging::PageSize.NORMAL.size * i);

        paging::map(table, memPaddr, memVaddr)!;
    }
}

fn void? unmap(uptr vaddr, usz len = paging::PageSize.NORMAL.size, PageTable table = kernelAddrSpace.pageTable) {
    usz unmappedBytes = 0;

    while (unmappedBytes < len) {
        unmappedBytes += paging::unmap(table, vaddr)!;
    }
}

fn uptr? map_mmio(uptr addr, usz len = paging::PageSize.NORMAL.size, PageTable table = kernelAddrSpace.pageTable) {
    uptr vaddr = @mmio(addr);

    for (usz i = 0; i < @pages(len); i++) {
        uptr memPaddr = @align_addr(addr) + (paging::PageSize.NORMAL.size * i);
        uptr memVaddr = @align_addr(vaddr) + (paging::PageSize.NORMAL.size * i);

        paging::map(table, memPaddr, memVaddr, props: paging::PageProperties.MMIO)!;
    }

    return vaddr;
}

fn void? init(usz totalMemoryBytes) {
    if (try len = cpuid::query_address_length()) {
        addrLen = len;
        paging::addressMask = ((1ul << (len.physicalLength - paging::ENTRY_ADDRESS_LSB)) - 1);
    } else {
        addrLen = {0, 0};
    }

    //create root table
    kernelAddrSpace.pageTable = paging::create_root()!;
    // create physmap region
    map_physmap(totalMemoryBytes)!;
    // create pmap region
    map_pmap()!;
}

fn void activate(AddressSpace* space) {
    paging::set_table(space.pageTable);
}
