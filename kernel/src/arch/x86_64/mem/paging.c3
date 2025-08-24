module arch::mem::paging;

import mem::pmm @public;
import mem::vmm;
import muon::logging;

ulong addressMask @private = ENTRY_ADDRESS_MASK;
PagingMode pagingMode @private = PAGING_MAP_LEVEL4;

<*
    @require i < TABLE_ENTRIES
*>
fn void PageTable.set(PageTable* self, usz i, TableEntry entry) => (*self)[i] = entry;

macro @table_ptr(PageTable #table) @private => (uptr)&(TableEntry)#table[0];
macro uptr @canonical(uptr #addr) @private => (uptr)((long)(#addr << ((ulong.sizeof*8)-vmm::virtual_address_length())) >> ((ulong.sizeof*8)-vmm::virtual_address_length()));
macro uptr @path_addr(PagingPath #path) @private => 0ul | (#path.pml4e << pagingMode.pml4Shift) | (#path.pdpte << pagingMode.pdptShift) | (#path.pde << pagingMode.pdShift) | (#path.pte << pagingMode.ptShift);

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

fn PageTable? create_table() @private {
    uptr ptr = pmm::alloc()!;
    return (PageTable)((TableEntry*)ptr)[:TABLE_ENTRIES];
}

fn PageTable? create_root() @private {
    PageTable table = create_table()!;

    // map self
    table.set(KnownTableEntry.SELF.idx, construct_entry(present: true, readWrite: true, addr: @table_ptr(table)));

    return table;
}
