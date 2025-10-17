module resource::handle;


macro Handle init(uint index, uint generation, ushort salt) {
    return {
        .index = index & 0xffffff,
        .generation = generation & 0xffffff,
        .salt = salt,
    };
}

macro bool Handle.validate(Handle handle, GenericHandleEntry* entry) {
    if (!entry.valid) return handle::INVALID_HANDLE?;
    if (entry.generation != handle.generation) return handle::HANDLE_GEN_MISMATCH?;
    if (entry.salt != handle.salt) return handle::HANDLE_SALT_MISMATCH?;

    return true;
}

module resource::handletable{ResourceType};

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

macro HandleEntry.set(&self, usz idx, ResourceType* data, ResourceType* parent, ushort salt, HandlePerms perms = 0) {
    self.data = data;
    self.parent = parent;
    self.salt = salt;
    self.perms = perms;
    self.valid = true;
}

macro ResourceType* HandleEntry.clear(&self, ResourceType* parent = null) {
    ResourceType* data = self.data;
    if (parent != null) parent = self.parent;

    self.valid = false;
    self.generation++;
    self.perms = 0;

    return data;
}
