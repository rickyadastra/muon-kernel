module arch::mem;

import boson;
import mem @public;
import muon::logging;

import mem::allocator::buddy;
import std::lock;

const uptr LEGACY_BIOS_BASE = 0x0;
const uptr LEGACY_BIOS_LIMIT = 0xfffff;

BuddyAllocator kAllocator @local;
Spinlock lock, plock @local;
fn Allocator get_allocator() => &kAllocator;

faultdef MEMORY_UNAVAILABLE;

fn uptr? find_bitmap_entry(MemoryEntry[] memoryEntries, usz byteSize) @local {
    foreach (usz i, MemoryEntry me : memoryEntries) {
        if (me.type == AVAILABLE && me.base > LEGACY_BIOS_LIMIT && me.length >= byteSize) return me.base;
    }

    return MEMORY_UNAVAILABLE~;
}

fn void? mark_memory_entries(MemoryEntry[] entries) @local {
    // mark legacy bios entry, should never be used
    pmm::mark_region_used(LEGACY_BIOS_BASE, LEGACY_BIOS_LIMIT)!;

    foreach (usz i, MemoryEntry me : entries) {
            logging::debug("%d:\t[%x-%x] -> %x, %d B (type: %s)", i, me.base, me.base+me.length-1, me.baseVirt, me.length, me.type.description);
		if (me.base >= pmm::physTotal) continue;
        if (me.type != AVAILABLE) {

            // sanitize size: some uefi memory entries are MMIO outside of physical RAM
            usz size = me.length;
            if (me.base + me.length >= pmm::physTotal) {
                size = pmm::physTotal - me.base;
            }

            pmm::mark_region_used(me.base, size)!;
        }
    }
}

fn void? map_memory_entries(MemoryEntry[] entries) @local {
    foreach (usz i, MemoryEntry me : entries) {
        if (me.type != AVAILABLE && me.baseVirt != 0) {
            vmm::map(me.base, me.baseVirt, me.length)!;
            
        } else if (me.type == ACPI) {
            vmm::map(me.base, vmm::@acpi(me.base), me.length)!;
        }
    }
}

fn void? init(TagMemoryMap* memoryMap) {
    MemoryEntry[] entries = memoryMap.entries[:memoryMap.numOfEntries];
    usz bitmapAllocSize = pmm::bitmap_alloc_size_of(memoryMap.totalBytes);
    uptr bitmap = find_bitmap_entry(entries, bitmapAllocSize)!;
    
    // create physmem bitmap, mark default entries
    pmm::init(bitmap, memoryMap.totalBytes)!;
    // mark memory entries
    mark_memory_entries(entries)!;

    // create kernel address space with self map, pmm and physmap entry
    vmm::init(memoryMap.totalBytes)!;
    // map memory entries
    map_memory_entries(entries)!;

    // set new bitmap address
    pmm::set_bitmap(vmm::bitmap_virt_base());

    // activate kernel address space
    vmm::activate(&vmm::kernelAddrSpace);
    vmm::initialized = true;

    // initialize kernel buddy allocator
    kAllocator = buddy::init(&alloc_pages, &free_pages)!;
}

macro usz page_size() => pmm::FRAME_SIZE;
macro usz pages(bytes) => vmm::@pages(bytes);

fn uptr? alloc_pages(usz pages, bool clear = false) {
	plock.acquire();
    defer plock.release();

	uptr addr = vmm::@phys((uptr)pmm::alloc(pages)!);

	if (clear) $$memset((char*)addr, (char)0, pages*pmm::FRAME_SIZE, false, (usz)1);
	return addr;
}

fn void? free_pages(uptr addr, usz pages) {
	plock.acquire();
    defer plock.release();
    pmm::free((PhysAddr)(addr - vmm::@phys(0)), pages)!;
}

fn void* alloc(usz bytes) {
    lock.acquire();
    defer lock.release();

    void* ptr = (void*)kAllocator.acquire(bytes)!!;
    logging::debug("KERNEL ALLOCATOR - NEW ALLOCATION of %d bytes at %x (usage %d%)", bytes, ptr, ((double)kAllocator.usedMemory / kAllocator.totalMemory)*100);
    return ptr;
}

fn void free(void* ptr) {
    lock.acquire();
    defer lock.release();

    if (catch kAllocator.release(ptr)) {
        logging::printn("Attempted free on null pointer.");
    } else {
        logging::debug("KERNEL ALLOCATOR - FREED %x (usage %d%)", ptr, ((double)kAllocator.usedMemory / kAllocator.totalMemory)*100);
    }
}
