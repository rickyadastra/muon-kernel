module resource::handle;

import resource::table;

macro Handle init(uint index, uint generation, ushort salt) {
    return {
        .index = index & 0xffffff,
        .generation = generation & 0xffffff,
        .salt = salt,
    };
}

macro bool? Handle.validate(Handle handle, HandleEntry entry) {
    if (!entry.valid()) return handle::INVALID_HANDLE?;
    if (entry.generation != handle.generation) return handle::HANDLE_GEN_MISMATCH?;
    if (entry.salt != handle.salt) return handle::HANDLE_SALT_MISMATCH?;

    return true;
}

module resource::table;

import arch::mem;
import std::collections;
import resource::handle;
import random;
import muon;

fn void? HandleTable.init(&self, usz entriesSize) {
    HandleEntry[] entries = ((HandleEntry*)mem::alloc_pages(mem::pages(HandleEntry.sizeof * entriesSize))!)[:entriesSize];
    void* bitmap = mem::alloc(entriesSize / ulong.sizeof);

    self.entries = entries;
    self.bitmap = bitmap::init(bitmap, entriesSize);
}

fn void? HandleTable.destroy(&self) {
    usz entriesSize = self.bitmap.size;
    mem::free((void*)self.bitmap.data.ptr);
    mem::free_pages((uptr)self.entries.ptr, mem::pages(HandleEntry.sizeof * entriesSize))!;
}

macro bool? HandleTable.validate_handle(&self, Handle handle) {
    usz idx = handle.index;
    if (idx > self.entries.len) return handle::INVALID_HANDLE?;

    return handle.validate(self.entries[idx]);
}

fn Handle? HandleTable.insert(&self, void* resource, ResourceType type, HandlePerms perms = {}) {
    Handle handle;
    usz idx = self.bitmap.find_free()!;
    HandleEntry* entry = &self.entries[idx];

    handle = handle::init((uint)idx, entry.generation, (ushort)random::random()!);
    entry.set(idx, resource, type, handle.salt, perms);

    self.bitmap.set(idx);

    logging::printn("insert HandleEntry[%d]{resource=%x (%s), gen=%d, salt=%d, perms=%x} -> %x", idx, entry.resource, entry.type.nameof, entry.generation, entry.salt, entry.perms, handle);

    return handle;
}

fn Handle? HandleTable.copy_handle_to(&self, HandleTable dest, Handle handle, ResourceType type) {
    // self table fails to validate given handle
    if (catch excuse = self.validate_handle(handle)) return excuse?;

    // handle is valid, get entry and create handle
    HandleEntry entry = self.entries[handle.index];
    if (type != entry.type) return handle::HANDLE_TYPE_MISMATCH?;

    return dest.insert(entry.resource, entry.type, entry.perms)!;
}

macro HandleEntry.valid(&self) => self.resource != null;

<*
    @require self.resource == null
*>
macro HandleEntry.set(&self, usz idx, void* resource, ResourceType type, ushort salt, HandlePerms perms = {}) {
    self.resource = resource;
    self.salt = salt;
    self.type = type;
    self.perms = perms;
}

<*
    @ensure return.resource == null
*>
macro any HandleEntry.clear(&self) {
    ResourceType* resource = self.resource;

    self.resource = null;
    self.generation++;
    self.perms = 0;

    return resource;
}
