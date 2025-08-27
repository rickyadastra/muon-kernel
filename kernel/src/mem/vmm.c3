module mem::vmm;

import arch::cpu;
import arch::mem::paging @public;
import muon::logging;
import std::math;

faultdef PAGING_INIT_FAIL;

AddressLength addrLen @local;
AddressSpace kernelAddrSpace @local;

macro usz physical_address_length() => addrLen.physicalLength;
macro usz virtual_address_length() => addrLen.virtualLength;
macro usz @physmap_pages(usz #bytes) => (#bytes + (paging::HugePage.HUGE_1G.size - 1ul)) / paging::HugePage.HUGE_1G.size;

fn void? map_physmap(usz len) @local {
    logging::printn("%d -> mapping %dx 1GB pages", len, @physmap_pages(len));
    
    for (usz i = 0; i < math::min(@physmap_pages(len), PHYSMAP_MAX); i++) {
        uptr paddr = (uptr)(HugePage.HUGE_1G.size * i);
        uptr vaddr = paging::@path_addr(KnownPagingPath.PHYSMAP.path, pdpteModifier: i);

        paging::map(kernelAddrSpace.pageTable, paddr, vaddr, hugePage: HUGE_1G)!;
    }
}

fn void? map(uptr paddr, uptr vaddr, usz len) {
    // for ... map all required pages
    paging::map(kernelAddrSpace.pageTable, paddr, vaddr)!;
}

fn void unmap(uptr vaddr, usz len) {

}

fn uptr translate(uptr vaddr) {
    return 0;
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


}

fn void activate(AddressSpace* space) {
    // install page table in CR3 etc.
}
