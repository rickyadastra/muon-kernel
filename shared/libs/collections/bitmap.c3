<*
    @require SIZE > 0
*>
module std::collections;

faultdef BITMAP_FULL;

module std::collections::bitmap {SIZE};

const BITS = ulong.sizeof * 8;
const SZ = (SIZE + BITS - 1) / BITS;

struct BitMap {
    ulong[SZ] data;
    usz hint;
}

macro @row(#i) @local => #i / BITS;
macro @bit(#i) @local => #i % BITS;
macro @first_free(#row) @local => $$ctz(~#row);

<*
    @require ptr != null 
*>
fn BitMap init(void* ptr) {
    return {
        .data = ((ulong*)ptr)[:SZ],
        .hint = 0
    };
}

macro usz alloc_size() => SIZE / char.sizeof;

<*
    @require i < SIZE
*>
fn void BitMap.set(BitMap* self, usz i) {
    self.data[@row(i)] |= 1ul << @bit(i);
}

<*
    @require i < SIZE
*>
fn void BitMap.set_bool(BitMap* self, usz i, bool val) {
    if (val) self.set(i);
    self.clear(i);
}

<*
    @require i < SIZE
*>
fn void BitMap.clear(BitMap* self, usz i) {
    self.data[@row(i)] &= ~(1ul << @bit(i));
}

<*
    @require i < SIZE
*>
fn bool BitMap.get(BitMap* self, usz i) @operator([]) {
    return self.data[@row(i)] & (1ul << @bit(i)) != 0; 
}

fn usz? BitMap.find_free(BitMap* self) {
    for (usz i=self.hint; i<self.hint + self.data.len; i++) {
        usz rowIdx = i % self.data.len;
        ulong row = self.data[rowIdx];
        if (row == ulong.max) continue; // skip row if all bits are set

        usz pos = @first_free(row);
        ulong mask = 1ul << pos;

        if ((row & mask) == 0) {
            usz bitIdx = rowIdx*BITS + pos;

            self.hint = i;
            return bitIdx;
        }
    }

    return collections::BITMAP_FULL?;
}

fn usz BitMap.cardinality(BitMap* self) {
    usz n = 0;
    foreach (ulong row : self.data) {
        n += $$popcount(row);
    }
    return n;
}