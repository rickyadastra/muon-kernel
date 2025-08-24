module arch::mem::paging;

import mem::pmm @public;
import mem::vmm;
import muon::logging;

ulong addressMask @local = ENTRY_ADDRESS_MASK;

enum KnownTableEntry : uint (usz idx) {
    KERNEL = 511,
    SELF = 510,
    EDIT = 509,
}

<*
    @require i < TABLE_ENTRIES
*>
fn void PageTable.set(PageTable* self, usz i, TableEntry entry) => (*self)[i] = entry;

macro @table_ptr(PageTable #table) @local => (uptr)&(TableEntry)#table[0];

fn TableEntry construct_entry(bool present = false, bool readWrite = false, bool userPage = false,
                              bool writeThrough = false, bool cacheDisable = false, bool huge = false,
                              bool global = false, uptr addr, bool executionDisable = false) @local {    
    return (TableEntry) {
        .present = present,
        .readWrite = readWrite,
        .userPage = userPage,
        .writeThrough = writeThrough,
        .cacheDisable = cacheDisable,
        .huge = huge,
        .global = global,
        .addr = (ulong)(addr >> ENTRY_ADDRESS_LSB) & addressMask,
        .executionDisable = executionDisable,
    };
}

fn PageTable? create_table() @local {
    uptr ptr = pmm::alloc()!;
    return (PageTable)((TableEntry*)ptr)[:TABLE_ENTRIES];
}

fn PageTable? create_root() @local {
    PageTable root = create_table()!;

    // map self
    root.set(KnownTableEntry.SELF.idx, construct_entry(present: true, readWrite: true, addr: @table_ptr(root)));

    return root;
}

fn void? init() {
    usz physAddrLen = vmm::physical_address_length();
    if (physAddrLen != 0) addressMask = ((1ul << (physAddrLen - ENTRY_ADDRESS_LSB)) - 1);

    PageTable root = create_root()!;
}
