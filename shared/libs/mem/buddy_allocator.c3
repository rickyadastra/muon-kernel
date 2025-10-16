module mem::allocator::buddy;

const usz MAX_ORDER = 13; // 8192B block
const usz MIN_ORDER = 3;  // 8B block, minimum to accomodate BuddyBlockHeader
const float FREE_THRESHOLD = 0.25f;
const usz SYS_BLOCK_SIZE = 0x1000;

alias AllocPageFn = fn uptr?(usz pages);
alias FreePageFn = fn void?(uptr ptr, usz pages);

struct BuddyBlockHeader {
    union {
        BuddyBlockHeader* next;
        usz size;
    }
    ulong _padding;
}

struct BuddyAllocator (Allocator) {
    AllocPageFn allocFn;
    FreePageFn freeFn;

    BuddyBlockHeader*[MAX_ORDER - MIN_ORDER + 1] freelist;
    usz totalMemory;
    usz usedMemory;
}

fn BuddyAllocator? init(AllocPageFn allocFn, FreePageFn freeFn) {
    return {
        .allocFn = allocFn,
        .freeFn = freeFn,
        .totalMemory = 0,
        .usedMemory = 0,
    };
}

<*
    @require i <= MAX_ORDER - MIN_ORDER
    @require block.next == null
*>
fn void BuddyAllocator.freelist_add(&self, usz i, BuddyBlockHeader* block) @local {
    block.next = self.freelist[i];
    self.freelist[i] = block;
}

<*
    @require i <= MAX_ORDER - MIN_ORDER
    @ensure return.next == null
*>
fn BuddyBlockHeader* BuddyAllocator.freelist_remove(&self, usz i) @local {
    BuddyBlockHeader* block = self.freelist[i];
    self.freelist[i] = block.next;
    block.next = null;
    return block;
}

fn BuddyBlockHeader*[2] split(BuddyBlockHeader* block, usz order) @local => { block, (BuddyBlockHeader*)((uptr)block+(allocator::@order_size(order)/2)) };

fn BuddyBlockHeader*? BuddyAllocator.get_from_parent_block(&self, int idx) @local {
    BuddyBlockHeader*[2] splits;

    if (idx >= self.freelist.len) {      // get a new block from alloc
        if (try block = self.allocFn(allocator::@order_size(MAX_ORDER) / SYS_BLOCK_SIZE)) {
            self.totalMemory += allocator::@order_size(MAX_ORDER);
            return (BuddyBlockHeader*)block;
        } else {
            return allocator::OUT_OF_MEMORY?;
        }

    } else if (self.freelist[idx] != null) {
        splits = split(self.freelist_remove(idx), idx+MIN_ORDER);
    } else {
        splits = split(self.get_from_parent_block(idx+1), idx+MIN_ORDER)!;
    }

    self.freelist_add(idx-1ul, splits[1]);
    return splits[0];
}

fn void*? BuddyAllocator.acquire(&self, usz size) @dynamic {
    if (size > allocator::@order_size(MAX_ORDER) - BuddyBlockHeader.sizeof) return allocator::INVALID_ALLOC_SIZE?;

    usz order = $$max(allocator::@order_of(size+BuddyBlockHeader.sizeof), MIN_ORDER);

    int idx = (int)order - MIN_ORDER;
    assert(idx >= 0);

    BuddyBlockHeader* block;

    if (self.freelist[idx] != null) {
        block = self.freelist_remove(idx);
        block.size = allocator::@order_size(order);

        self.usedMemory += allocator::@order_size(order);

    } else {
        // find a bigger block to split
        block = self.get_from_parent_block(idx+1)!;
        block.size = allocator::@order_size(order);

        self.usedMemory += allocator::@order_size(order);
    }

    char[] data = ((char*)block + BuddyBlockHeader.sizeof)[:allocator::@order_size(order) - BuddyBlockHeader.sizeof];
    data[..] = 0;

    return (void*)data.ptr;
}

fn void? BuddyAllocator.release(&self, void* ptr) @dynamic {
    if (ptr == null) return allocator::INVALID_FREE?;

    BuddyBlockHeader* header = (BuddyBlockHeader*)(ptr - BuddyBlockHeader.sizeof);

    usz order = allocator::@order_of(header.size)-1;
    usz size = header.size;
    int idx = (int)order - MIN_ORDER;

    self.usedMemory -= size;

    while (order < MAX_ORDER) {
        BuddyBlockHeader* buddy = (BuddyBlockHeader*)((uptr)header ^ size);

        BuddyBlockHeader* prev = null;
        BuddyBlockHeader* iterator = self.freelist[idx];
        while (iterator != null && iterator != buddy) {
            prev = iterator;
            iterator = iterator.next;
        }

        if (iterator == buddy) {
            if (prev != null) {     // not the first element
                prev.next = iterator.next;
            } else {                // the first element in the list
                self.freelist[idx] = iterator.next;
            }

            if (buddy < header) header = buddy;
            
            order++;
            idx++;
            size <<= 1;
        } else {
            break;
        }
    }

    float usage = (float)self.usedMemory / self.totalMemory;

    if (order == MAX_ORDER && usage < FREE_THRESHOLD) {
        self.freeFn((uptr)header, 1)!;
    } else {
        header.next = null;
        self.freelist_add(idx, header);
    }
}
