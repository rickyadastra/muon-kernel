module arch::mem::paging;

import arch::cpu;
import mem::pmm @public;
import mem::vmm @public;
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
<*

*>
fn void PageTable.clear(PageTable* self, usz i) => (*self)[i] = (TableEntry){};

macro PageTable @as_table(uptr #ptr) => (PageTable)((TableEntry*)#ptr)[:TABLE_ENTRIES];
macro uptr @canonical(uptr #addr) @private => (uptr)((long)(#addr << ((ulong.sizeof * 8) - vmm::virtual_address_length())) >> ((ulong.sizeof * 8) - vmm::virtual_address_length()));
macro uptr @mask_addr(#addr, #bits) @private => #addr & ~((1ul << (#bits)) - 1);

macro @assert_entry(TableEntry #entry) @local {
    if (!#entry.present) return NOT_MAPPED?;
}

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
    logging::debug("new table @ %x", ptr);
    return @as_table(ptr);
}

fn bool? free_table(PageTable table, uptr tablePhysPtr = (uptr)table.ptr) @local {
    for (usz i = 0; i < TABLE_ENTRIES; i++) {
        if (table.get(i) != (TableEntry){}) return false;
    }

    logging::debug("delete table @ %x", tablePhysPtr);
    pmm::free((PhysAddr)tablePhysPtr)!;
    return true;
}

fn PageTable? create_root() @private {
    PageTable table = create_table()!;

    // map self
    table.set(KnownTableEntry.SELF.idx, construct_entry(present: true, readWrite: true, addr: (uptr)table.ptr));

    return table;
}

fn PageTable? ensure_table(PageTable parent, usz entry, PageProperties props = DEFAULT) @local {
    uptr tablePtr;
    if (parent.get(entry).present) {
        // get table
        tablePtr = (parent.get(entry).addr << ENTRY_ADDRESS_LSB);
    } else {
        // create table, set in parent, get table
        PageTable table = create_table()!;
        parent.set(entry, construct_entry(
                present: props.present, readWrite: props.readWrite, userPage: props.user, writeThrough: props.writeThrough,
                cacheDisable: props.cacheDisable, addr: (uptr)table.ptr
        ));
        tablePtr = (uptr)table.ptr;
    }

    return @as_table(vmm::initialized ? vmm::@phys(tablePtr) : tablePtr);
}

fn PageTable? check_table(PageTable parent, usz entry) @local {
    if (parent.get(entry).present) {
        uptr tablePtr = (parent.get(entry).addr << ENTRY_ADDRESS_LSB);
        return @as_table(vmm::initialized ? vmm::@phys(tablePtr) : tablePtr);
    }

    return NOT_MAPPED?;
}

fn void? map_impl_with_recurse(PagingPath path, uptr paddr, PageSize hugePage = NORMAL, PageProperties props = DEFAULT) @local {
    PageTable pml4Recurse = @as_table(@path_addr(KnownPagingPath.RECURSE_PML4.path));
    PageTable pdpt = ensure_table(pml4Recurse, path.pml4e)!;

    if (hugePage == HUGE_1G) {
        pdpt.set(path.pdpte, construct_entry(
            present: props.present, readWrite: props.readWrite, userPage: props.user, writeThrough: props.writeThrough,
            cacheDisable: props.cacheDisable, huge: true, addr: @mask_addr(paddr, pagingMode.pdptShift)
        ));

    } else {
        PageTable pdptRecurse = @as_table(@path_addr(KnownPagingPath.RECURSE_PDPT.path, pteModifier: path.pml4e));
        PageTable pd = ensure_table(pdptRecurse, path.pdpte)!;

        if (hugePage == HUGE_2M) {
            pd.set(path.pde, construct_entry(
                present: props.present, readWrite: props.readWrite, userPage: props.user, writeThrough: props.writeThrough,
                cacheDisable: props.cacheDisable, huge: true, addr: @mask_addr(paddr, pagingMode.pdShift)
            ));
            
        } else {
            PageTable pdRecurse = @as_table(@path_addr(KnownPagingPath.RECURSE_PD.path, pdeModifier: path.pml4e, pteModifier: path.pdpte));
            PageTable pt = ensure_table(pdRecurse, path.pde)!;

            pt.set(path.pte, construct_entry(
                present: props.present, readWrite: props.readWrite, userPage: props.user, writeThrough: props.writeThrough,
                cacheDisable: props.cacheDisable, addr: paddr
            ));
        }
    }
}

fn void? map_impl_direct(PagingPath path, PageTable table, uptr paddr, PageSize hugePage = NORMAL, PageProperties props = DEFAULT) @local {
    PageTable pdpt = ensure_table(table, path.pml4e)!;

    if (hugePage == HUGE_1G) {
        pdpt.set(path.pdpte, construct_entry(
            present: props.present, readWrite: props.readWrite, userPage: props.user, writeThrough: props.writeThrough,
            cacheDisable: props.cacheDisable, huge: true, addr: @mask_addr(paddr, pagingMode.pdptShift)
        ));

    } else {
        PageTable pd = ensure_table(pdpt, path.pdpte)!;

        if (hugePage == HUGE_2M) {
            pd.set(path.pde, construct_entry(
                present: props.present, readWrite: props.readWrite, userPage: props.user, writeThrough: props.writeThrough,
                cacheDisable: props.cacheDisable, huge: true, addr: @mask_addr(paddr, pagingMode.pdShift)
            ));

        } else {
            PageTable pt = ensure_table(pd, path.pde)!;

            pt.set(path.pte, construct_entry(
                present: props.present, readWrite: props.readWrite, userPage: props.user, writeThrough: props.writeThrough,
                cacheDisable: props.cacheDisable, addr: paddr
            ));
        }
    }
}

fn void? map(PageTable table, uptr paddr, uptr vaddr, PageSize hugePage = NORMAL, PageProperties props = DEFAULT) @private {
    PagingPath path = @addr_path(vaddr);
    // logging::debug("mapping paddr: %x to vaddr: %x (%d %d %d %d)", paddr, vaddr, path.pml4e, path.pdpte, path.pde, path.pte);

    // should we use table recursion?
    if (cpu::read_cr3() == (uptr)table.ptr) {
        map_impl_with_recurse(path, paddr, hugePage, props)!;
    } else {
        map_impl_direct(path, table, paddr, hugePage, props)!;
    }
}

fn usz? unmap_impl_with_recurse(PagingPath path, PhysAddr* physFrame) @local {
    uptr physFrameAddr = 0;
    usz bytes = 0;

    PageTable pml4Recurse = @as_table(@path_addr(KnownPagingPath.RECURSE_PML4.path));
    PageTable pdpt = check_table(pml4Recurse, path.pml4e)!;
    TableEntry pdpte = pdpt.get(path.pdpte);
    @assert_entry(pdpte)!;

    if (pdpte.huge) {
        physFrameAddr = pdpte.addr;
        bytes = PageSize.HUGE_1G.size;
        pdpt.clear(path.pdpte);

    } else {
        PageTable pdptRecurse = @as_table(@path_addr(KnownPagingPath.RECURSE_PDPT.path, pteModifier: path.pml4e));
        PageTable pd = check_table(pdptRecurse, path.pdpte)!;
        TableEntry pde = pd.get(path.pde);
        @assert_entry(pde)!;

        if (pde.huge) {
            physFrameAddr = pde.addr;
            bytes = PageSize.HUGE_2M.size;
            pd.clear(path.pde);

        } else {
            PageTable pdRecurse = @as_table(@path_addr(KnownPagingPath.RECURSE_PD.path, pdeModifier: path.pml4e, pteModifier: path.pdpte));
            PageTable pt = check_table(pdRecurse, path.pde)!;
            TableEntry pte = pt.get(path.pte);
            @assert_entry(pte)!;

            physFrameAddr = pte.addr;
            bytes = PageSize.NORMAL.size;
            pt.clear(path.pte);

            if (free_table(pt, tablePhysPtr: pde.addr << ENTRY_ADDRESS_LSB)!) {
                pd.clear(path.pde);
                if (free_table(pd, tablePhysPtr: pdpte.addr << ENTRY_ADDRESS_LSB)!) {
                    pdpt.clear(path.pdpte);
                    if (free_table(pdpt, tablePhysPtr: pml4Recurse.get(path.pml4e).addr << ENTRY_ADDRESS_LSB)!) {
                        pml4Recurse.clear(path.pml4e);
                    }
                }
                flush();
            }
        }
    }

    *physFrame = (PhysAddr)(physFrameAddr << ENTRY_ADDRESS_LSB);
    return bytes;
}

fn usz? unmap_impl_direct(PagingPath path, PageTable table, PhysAddr* physFrame) @local {
    uptr physFrameAddr = 0;
    usz bytes = 0;
    
    PageTable pdpt = check_table(table, path.pml4e)!;
    TableEntry pdpte = pdpt.get(path.pdpte);
    @assert_entry(pdpte)!;

    if (pdpte.huge) {
        physFrameAddr = pdpte.addr;
        bytes = PageSize.HUGE_1G.size;
        pdpt.clear(path.pdpte);

    } else {
        PageTable pd = check_table(pdpt, path.pdpte)!;
        TableEntry pde = pd.get(path.pde);
        @assert_entry(pde)!;

        if (pde.huge) {
            physFrameAddr = pde.addr;
            bytes = PageSize.HUGE_2M.size;
            pd.clear(path.pde);

        } else {
            PageTable pt = check_table(pd, path.pde)!;
            TableEntry pte = pt.get(path.pte);
            @assert_entry(pte)!;

            physFrameAddr = pte.addr;
            bytes = PageSize.NORMAL.size;
            pt.clear(path.pte);

            if (free_table(pt)!) {
                pd.clear(path.pde);
                if (free_table(pd)!) {
                    pdpt.clear(path.pdpte);
                    if (free_table(pdpt)!) {
                        table.clear(path.pml4e);
                    }
                }
                flush();
            }
        }
    }

    *physFrame = (PhysAddr)(physFrameAddr << ENTRY_ADDRESS_LSB);
    return bytes;
}

fn usz? unmap(PageTable table, uptr vaddr) @private {
    PagingPath path = @addr_path(vaddr);
    logging::debug("unmapping vaddr: %x (%d %d %d %d)", vaddr, path.pml4e, path.pdpte, path.pde, path.pte);

    PhysAddr physFrameAddr = 0;
    usz bytes = 0;

    if (cpu::read_cr3() == (uptr)table.ptr) {
        bytes = unmap_impl_with_recurse(path, &physFrameAddr)!;
    } else {
        bytes = unmap_impl_direct(path, table, &physFrameAddr)!;
    }

    invalidate(vaddr);

    return bytes;
}

fn void set_table(PageTable table) {
    cpu::write_cr3((uptr)table.ptr);
}

fn void invalidate(uptr addr) @local {
    asm {
        movq $rax, ((ulong) addr);
    }
    asm("invlpg %rax");   
}

fn void flush() @local {
    asm("mov %cr3, %rax");
    asm("mov %rax, %cr3");
}
