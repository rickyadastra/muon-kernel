module muon::authority::table;

import arch::mem;
import std::collections;
import muon::authority;
import random;
import muon;
import lang;

<*
    Init a new ObjectTable
    @param entriesSize : "number of entries in the table"
*>
fn void? ObjectTable.init(&self, usz entriesSize) {
    ObjectSlot[] entries = ((ObjectSlot*)mem::alloc_pages(mem::pages(ObjectSlot.sizeof * entriesSize))!)[:entriesSize];
    void* bitmap = mem::alloc(entriesSize / ulong.sizeof);

    self.entries = entries;
    self.bitmap = bitmap::init(bitmap, entriesSize);
}

<*
    Destroy a ObjectTable
*>
fn void? ObjectTable.destroy(&self) {
    usz entriesSize = self.bitmap.size;
    mem::free((void*)self.bitmap.data.ptr);
    mem::free_pages((uptr)self.entries.ptr, mem::pages(ObjectSlot.sizeof * entriesSize))!;
}

<*
    @require handle.index < self.entries.len
*>
fn ObjectSlot* ObjectTable.get(&self, Handle handle) {
    self.lock.acquire();
    defer self.lock.release();

    usz idx = handle.index;
    return &self.entries[handle.index];
}

fn Handle? ObjectTable.insert(&self, KernelObject object, ObjectRights rights = {}) {
    self.lock.acquire();
    defer self.lock.release();
    
    usz idx = self.bitmap.find_free()!;
    ObjectSlot* entry = &self.entries[idx];

    ushort salt = (ushort)random::random()!;
    entry.set(idx, object, salt, rights);
    self.bitmap.set(idx);

    return handle::make((uint)idx, entry.generation, salt);
}

<*
    @require handle.index < self.entries.len
*>
fn KernelObject ObjectTable.remove(&self, Handle handle) {    
    KernelObject obj = self.get(handle).clear();
    obj.drop_ref();
    return obj;
}

fn void ObjectTable.remove_all(&self) {
    self.lock.acquire();
    defer self.lock.release();
    
    foreach (ObjectSlot* &entry : self.entries) {
        if (entry.present()) {
            KernelObject obj = entry.clear();
            obj.drop_ref();
        }
    }
}

macro ObjectSlot.present(&self) => self.object != null;

<*
    @require self.object == null
*>
macro ObjectSlot.set(&self, usz idx, KernelObject object, ushort salt, ObjectRights rights = {}) {
    self.object = object;
    self.salt = salt;
    self.rights = rights;
}

<*
    @ensure return != null
*>
macro KernelObject ObjectSlot.clear(&self) {
    KernelObject object = self.object;

    self.object = null;
    self.generation++;
    self.rights = 0;

    return object;
}
