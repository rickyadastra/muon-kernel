module arch::mem::paging;

import mem::pmm;

const usz TABLE_ENTRIES = pmm::FRAME_SIZE / TableEntry.sizeof;
const usz ENTRY_ADDRESS_LSB = 12;
const ulong ENTRY_ADDRESS_MASK = 0xffff_ffff_ffff_f000;

enum PagingMode : uint (usz virtAddrLen) {
    PAGING_MAP_LEVEL4 = 48,
    PAGING_MAP_LEVEL5 = 52,
}

bitstruct TableEntry : ulong {
    bool present : 0;
    bool readWrite : 1;
    bool userPage : 2;
    bool writeThrough : 3;
    bool cacheDisable : 4;
    bool accessed : 5;
    bool dirty : 6;
    bool huge : 7;                  // reserved on PML4 and PML5
    bool global : 8;
    char availLow : 9..11;
    ulong addr : 12..51;
    char availHigh : 52..58;
    char protectionKey : 59..62;
    bool executionDisable : 63;
}

typedef PageTable = inline TableEntry[];
