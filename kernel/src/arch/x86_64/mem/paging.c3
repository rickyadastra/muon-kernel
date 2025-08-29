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
<*
    @require i < TABLE_ENTRIES
*>
fn TableEntry PageTable.get(PageTable* self, usz i) => (*self)[i];

fn uptr PageTable.get_ptr(PageTable* self) => (uptr)&(TableEntry)(*self)[0];

macro PageTable @as_table(uptr #ptr) => (PageTable)((TableEntry*)#ptr)[:TABLE_ENTRIES];
macro uptr @canonical(uptr #addr) @private => (uptr)((long)(#addr << ((ulong.sizeof * 8) - vmm::virtual_address_length())) >> ((ulong.sizeof * 8) - vmm::virtual_address_length()));
macro bool @has_recursion(PagingPath #path) @private => (#path.pml4e == KnownTableEntry.SELF.idx) || (#path.pml4e == KnownTableEntry.OTHER.idx);
macro uptr @mask_addr(#addr, #bits) @private => #addr & ~((1ul << (#bits)) - 1);

macro uptr @path_addr(PagingPath #path, usz pdpteModifier = 0, usz pdeModifier = 0, usz pteModifier = 0) @private {
    return @canonical(0ul | 
           (#path.pml4e << pagingMode.pml4Shift) |
           ((#path.pdpte + pdpteModifier) << pagingMode.pdptShift) |
           ((#path.pde + pdeModifier) << pagingMode.pdShift) |
           ((#path.pte + pteModifier) << pagingMode.ptShift));
}

macro PagingPath @addr_path(uptr #addr) @private {
    return (PagingPath) {
        .pml4e = (#addr >> pagingMode.pml4Shift) & 0x1ff,
        .pdpte = (#addr >> pagingMode.pdptShift) & 0x1ff,
        .pde = (#addr >> pagingMode.pdShift) & 0x1ff,
        .pte = (#addr >> pagingMode.ptShift) & 0x1ff,
    };
}

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
    logging::printn("new table @ %x", ptr);
    return @as_table(ptr);
}

fn PageTable? create_root() @private {
    PageTable table = create_table()!;

    // map self
    table.set(KnownTableEntry.SELF.idx, construct_entry(present: true, readWrite: true, addr: table.get_ptr()));

    return table;
}

fn PageTable? ensure_table(PageTable parent, usz entry, bool useVirtAddr = true) @local {
    uptr tablePtr;
    if (parent.get(entry).present) {
        // get table
        tablePtr = (parent.get(entry).addr << ENTRY_ADDRESS_LSB);
    } else {
        // create table, set in parent, get table
        PageTable table = create_table()!;
        parent.set(entry, construct_entry(present: true, readWrite: true, addr: table.get_ptr()));
        tablePtr = table.get_ptr();
    }

    return @as_table(useVirtAddr ? 0 + tablePtr : tablePtr);
}

fn void? map(PageTable root, uptr paddr, uptr vaddr, PageSize hugePage = NORMAL) @private {
    PagingPath path = @addr_path(vaddr);
    logging::printn("mapping paddr: %x to vaddr: %x (%d %d %d %d)", paddr, vaddr, path.pml4e, path.pdpte, path.pde, path.pte);

    if (@has_recursion(path)) {
        logging::printn("recursion not yet supported!");
    } else {
        PageTable pdpt = ensure_table(root, path.pml4e, useVirtAddr: false)!;
        if (hugePage == HUGE_1G) {
            pdpt.set(path.pdpte, construct_entry(present: true, readWrite: true, huge: true, addr: @mask_addr(paddr, pagingMode.pdptShift)));
        } else {
            PageTable pd = ensure_table(pdpt, path.pdpte, useVirtAddr: false)!;
            if (hugePage == HUGE_2M) {
                pd.set(path.pde, construct_entry(present: true, readWrite: true, huge: true, addr: @mask_addr(paddr, pagingMode.pdShift)));
            } else {
                PageTable pt = ensure_table(pd, path.pde, useVirtAddr: false)!;
                pt.set(path.pte, construct_entry(present: true, readWrite: true, addr: paddr));
            }
        }
    }
}
