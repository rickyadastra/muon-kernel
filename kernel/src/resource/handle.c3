module resource::handle;

macro Handle init(uint index, uint generation, ushort salt) {
    return {
        .index = index & 0xffffff,
        .generation = generation & 0xffffff,
        .salt = salt,
    };
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
}

macro HandleEntry.clear(&self) {
    self.data = null;
    self.parent = null;
    self.salt = 0;
    self.perms = 0;
    self.generation++;
}
