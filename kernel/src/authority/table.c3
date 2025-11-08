module muon::authority::table;

import arch::mem;
import std::collections;
import muon::authority;
import random;
import muon;
import lang;

fn void? ObjectTable.init(&self, usz entriesSize) {
    ObjectSlot[] entries = ((ObjectSlot*)mem::alloc_pages(mem::pages(ObjectSlot.sizeof * entriesSize))!)[:entriesSize];
    void* bitmap = mem::alloc(entriesSize / ulong.sizeof);

    self.entries = entries;
    self.bitmap = bitmap::init(bitmap, entriesSize);
}

fn void? ObjectTable.destroy(&self) {
    usz entriesSize = self.bitmap.size;
    mem::free((void*)self.bitmap.data.ptr);
    mem::free_pages((uptr)self.entries.ptr, mem::pages(ObjectSlot.sizeof * entriesSize))!;
}

fn any? ObjectTable.resolve(&self, Handle handle, ObjectRights perms = {}) {
    usz idx = handle.index;
    if (idx > self.entries.len) return handle::INVALID_HANDLE?;

    ObjectSlot entry = self.entries[idx];

    if (handle.validate(entry)!) {
        if (entry.perms & perms != perms) return handle::HANDLE_NO_PERMISSION?;
        return any_make(entry.resource, entry.type.type);
    }

    $$unreachable();
}

fn Handle? ObjectTable.insert(&self, void* resource, ObjectType type, ObjectRights perms = {}) {
    Handle handle;
    usz idx = self.bitmap.find_free()!;
    ObjectSlot* entry = &self.entries[idx];

    handle = handle::make((uint)idx, entry.generation, (ushort)random::random()!);
    entry.set(idx, resource, type, handle.salt, perms);

    self.bitmap.set(idx);

    // logging::printn("insert ObjectSlot@%x[%d]{resource=%x (%s), gen=%d, salt=%d, perms=%x} -> %x", self, idx, entry.resource, entry.type.nameof, entry.generation, entry.salt, entry.perms, handle);

    return handle;
}

fn any? ObjectTable.remove(&self, Handle handle) {
    usz idx = handle.index;
    if (idx > self.entries.len) return handle::INVALID_HANDLE?;

    ObjectSlot entry = self.entries[idx];
    if (handle.validate(entry)!) {
        return any_make(entry.clear(), entry.type.type);
    }

    $$unreachable();
}

fn Handle? ObjectTable.copy_handle_to(&self, ObjectTable* dest, Handle handle, ObjectType type) {
    // self table fails to validate given handle
    if (catch excuse = self.resolve(handle)) return excuse?;

    // handle is valid, get entry and create handle
    ObjectSlot entry = self.entries[handle.index];
    if (type != entry.type) return handle::HANDLE_TYPE_MISMATCH?;

    return dest.insert(entry.resource, entry.type, entry.perms)!;
}

macro ObjectSlot.valid(&self) => self.resource != null;

<*
    @require self.resource == null
*>
macro ObjectSlot.set(&self, usz idx, void* resource, ObjectType type, ushort salt, ObjectRights perms = {}) {
    self.resource = resource;
    self.salt = salt;
    self.type = type;
    self.perms = perms;
}

<*
    @ensure return.resource == null
*>
macro any ObjectSlot.clear(&self) {
    ObjectType* resource = self.resource;

    self.resource = null;
    self.generation++;
    self.perms = 0;

    return resource;
}
