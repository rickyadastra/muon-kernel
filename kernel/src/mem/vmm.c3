module mem::vmm;

import arch::cpu;
import arch::mem::paging @public;

faultdef PAGING_INIT_FAIL;

AddressLength addrLen @local;
AddressSpace kernelAddrSpace @local;

macro usz physical_address_length() => addrLen.physicalLength;
macro usz virtual_address_length() => addrLen.virtualLength;

fn void map(uptr paddr, uptr vaddr, usz length) {

}

fn void? init() {
    if (try len = cpuid::query_address_length()) {
        addrLen = len;
        paging::addressMask = ((1ul << (len.physicalLength - paging::ENTRY_ADDRESS_LSB)) - 1);
    } else {
        addrLen = {0, 0};
    }

    kernelAddrSpace.pageTable = paging::create_root()!;
}

fn void swap(AddressSpace* space) {
    // install page table in CR3 etc.
}
