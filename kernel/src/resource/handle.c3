module resource::handle;

import resource::table;

macro Handle init(uint index, uint generation, ushort salt) {
    return {
        .index = index & 0xffffff,
        .generation = generation & 0xffffff,
        .salt = salt,
    };
}

macro bool Handle.validate(Handle handle, HandleEntry* entry) {
    if (!entry.valid()) return handle::INVALID_HANDLE?;
    if (entry.generation != handle.generation) return handle::HANDLE_GEN_MISMATCH?;
    if (entry.salt != handle.salt) return handle::HANDLE_SALT_MISMATCH?;

    return true;
}

module resource::table;

import arch::mem;
import std::collections;
import resource::handle;

<*
    @require entriesSize < 0x2000 / HandleEntry.sizeof
*>
fn HandleTable? init(usz entriesSize) {
    HandleEntry[] entries = ((HandleEntry*)mem::alloc(HandleEntry.sizeof * entriesSize))[:entriesSize];
    void* bitmap = mem::alloc(entriesSize / ulong.sizeof);

    return {
        .entries = entries,
        .bitmap = bitmap::init(bitmap, entriesSize),
    };
}

macro HandleEntry.valid(&self) => self.resource != null;

<*
    @require self.resource == null
*>
macro HandleEntry.set(&self, usz idx, any resource, ushort salt, HandlePerms perms = 0) {
    self.resource = resource;
    self.salt = salt;
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
