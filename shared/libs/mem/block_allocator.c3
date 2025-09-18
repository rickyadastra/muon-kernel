<*
    @require POOL_SIZE % BLOCK_SIZE == 0
*>
module mem::allocator::block {BLOCK_SIZE};

import std::collections::bitmap;

const BLOCKS = POOL_SIZE / BLOCK_SIZE;

struct BlockAllocator (Allocator) {
    BitMap{BLOCKS} map;
    char[*] data;
}

fn BlockAllocator init(void* data, void* map) {
    return {
        .map = bitmap::init{BLOCKS}(map),
        .data = ((char*)data)[:POOL_SIZE],
    };
}
