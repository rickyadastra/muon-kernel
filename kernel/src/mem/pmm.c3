module mem::pmm;

import muon::logging;

alias BitmapRow = ulong;
typedef PhysAddr = inline uptr;

enum FrameState : ulong {
    FREE,
    USED,
}

faultdef OUT_OF_MEMORY, INVALID_FRAME_INDEX;

const usz FRAME_SIZE = 0x1000;
const usz BITMAP_FRAMES_PER_ROW = (BitmapRow.sizeof * 8);

BitmapRow[] pmap @local;
usz pmapSize @local = 0;
usz physTotal @local = 0;
usz frameTotal @local = 0;
usz frameFree @local = 0;

usz allocHint @local = 0;

macro @align_frame(#val) => #val / FRAME_SIZE; 
macro @bytes_to_frames(#bytes) @local => @align_frame(#bytes);
macro @frames_to_rows(#frames) @local => ((#frames + BITMAP_FRAMES_PER_ROW-1) / BITMAP_FRAMES_PER_ROW);
macro usz bitmap_alloc_size_of(usz bytes) => @frames_to_rows(@bytes_to_frames(bytes)) * BitmapRow.sizeof;

macro @frame_row(#i) @local => #i / BITMAP_FRAMES_PER_ROW;
macro @frame_bit(#i) @local => #i % BITMAP_FRAMES_PER_ROW;
macro @frame_changed(#old, #new) @local => #old != #new;
macro @frame_of(#addr) => @align_frame(#addr);
macro @row_first_free(#row) => $$ctz(~#row);

<*
  @require amount <= frameTotal
  @ensure frameFree >= 0
*>
macro update_stats(FrameState newState, usz amount) {
    frameFree += ((newState == USED) ? -1 : 1) * amount;
}

fn FrameState? get(usz frameId) @inline {
    if (frameId >= frameTotal) return INVALID_FRAME_INDEX?;
    return FrameState.from_ordinal((char)((pmap[@frame_row(frameId)] & (1ul << @frame_bit(frameId))) >> @frame_bit(frameId)));
}

<*
  @require state != FREE || (frameTotal - frameFree) >= 1
  @require state == FREE || state == USED : "Invalid frame state (pmm)"
*>
fn void? mark(usz frameId, FrameState state) @private {
    if (frameId >= frameTotal) return INVALID_FRAME_INDEX?;
    if (state == USED && frameFree == 0) return OUT_OF_MEMORY?;

    FrameState old = get(frameId)!; 
    if (state == USED) {
        pmap[@frame_row(frameId)] |= (BitmapRow)(state.ordinal << @frame_bit(frameId));
    } else {
        pmap[@frame_row(frameId)] &= ~(BitmapRow)(state.ordinal << @frame_bit(frameId));
    }
    
    if (@frame_changed(old, state)) update_stats(state, 1);
}

fn void? mark_used(usz frameId) @inline @private => mark(frameId, USED);
fn void? mark_free(usz frameId) @inline @private => mark(frameId, FREE);

fn void? mark_region(uptr base, usz size, FrameState state) {
    if (size == 0) return;
    usz from = @align_frame(base);

    for (usz frames=@bytes_to_frames(size + FRAME_SIZE - 1); frames > 0; frames--) {        
        mark(from++, state)!;
    }
}

fn void? mark_region_used(uptr base, usz size) @inline => mark_region(base, size, USED);
fn void? mark_region_free(uptr base, usz size) @inline => mark_region(base, size, FREE);

fn PhysAddr? alloc() {
    for (usz i=allocHint; i<allocHint+pmap.len; i++) {
        usz rowIdx = i % pmap.len;

        BitmapRow row = pmap[rowIdx];
        if (row == ulong.max) continue;

        usz pos = @row_first_free(row);
        ulong mask = 1ul << pos;

        if ((row & mask) == 0) {
            usz frameIdx = rowIdx*BITMAP_FRAMES_PER_ROW + pos;

            allocHint = i;
            mark_used(frameIdx)!;
            return (PhysAddr)(frameIdx * FRAME_SIZE);
        }
    }

    return OUT_OF_MEMORY?;
}

fn void? free(PhysAddr addr) {
    usz frame = @frame_of(addr);

    if (get(frame)! == USED) {
        mark_free(frame)!;

    } else {
        logging::printn("Double pmm::free of %x", addr);
    }
}
 
fn void? init(uptr bitmap, usz totalMemoryBytes) {
    frameTotal = frameFree = @bytes_to_frames(totalMemoryBytes);
    physTotal = totalMemoryBytes;

    usz rowCount = @frames_to_rows(frameTotal);
    pmapSize = rowCount * BitmapRow.sizeof;
    pmap = ((BitmapRow*)bitmap)[:rowCount];

    pmap[..] = 0;   // initialize bitmap
    mark_used(0)!;   // mark frame 0 as used, address 0x0 should never be used

    // self mark pmap
    mark_region_used(bitmap, pmapSize)!;  
}
