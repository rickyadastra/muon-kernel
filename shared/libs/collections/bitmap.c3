module std::collections;

faultdef BITMAP_FULL;

module std::collections::bitmap;

const BITS = ulong.sizeof * 8;

struct BitMap {
    ulong[] data;
    usz size;
    usz hint;
}

macro @row(#i) @local => #i / BITS;
macro @bit(#i) @local => #i % BITS;
macro @first_free(#row) @local => $$ctz(~#row);
macro @sz(#size) @local => (#size + BITS - 1) / BITS;

<*
    @require ptr != null
    @require size >= BITS : "Size is too small (< 64)"
*>
fn BitMap init(void* ptr, usz size) {
    return {
        .data = ((ulong*)ptr)[:@sz(size)],
        .size = size,
        .hint = 0
    };
}

macro usz BitMap.data_size(&self) => self.data.len * ulong.sizeof;
fn usz BitMap.len(&self) @operator(len) => self.size;

<*
    @require i < self.size
*>
fn void BitMap.set(BitMap* self, usz i) {
    self.data[@row(i)] |= 1ul << @bit(i);
}

<*
    @require i < self.size
*>
fn void BitMap.set_bool(BitMap* self, usz i, bool val) @operator([]=) {
    if (val) self.set(i);
    self.clear(i);
}

<*
    @require i < self.size
*>
fn void BitMap.clear(BitMap* self, usz i) {
    self.data[@row(i)] &= ~(1ul << @bit(i));
}

<*
    @require i < self.size
*>
fn bool BitMap.get_bool(BitMap* self, usz i) @operator([]) {
    return self.data[@row(i)] & (1ul << @bit(i)) != 0; 
}

<*
    @require i < self.size
*>
fn bool* BitMap.get_ptr(BitMap* self, usz i) @operator(&[]) {
    return (bool*)&(self.data[@row(i)]); 
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