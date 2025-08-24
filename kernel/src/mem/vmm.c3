module mem::vmm;

import arch::cpu;
import arch::mem::paging;

faultdef PAGING_INIT_FAIL;

AddressLength addrLen @local;

macro usz physical_address_length() => addrLen.physicalLength;
macro usz virtual_address_length() => addrLen.virtualLength;

fn void init_address_length() @inline @local {
    if (try len = cpuid::query_address_length()) {
        addrLen = len;
    } else {
        addrLen = {0, 0};
    }
}

fn void? init() {
    init_address_length();

    if (catch paging::init()) return PAGING_INIT_FAIL?;
}
