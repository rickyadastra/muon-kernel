module muon::authority::handle;

import muon::authority::object;

faultdef INVALID, GEN_MISMATCH, SALT_MISMATCH, TYPE_MISMATCH, NO_PERMISSION;

bitstruct Handle : ulong {
    uint index : 0..23;
    uint generation : 24..47;
    ushort salt : 48..63;
}

macro Handle make(uint index, uint generation, ushort salt) {
    return {
        .index = index & 0xffffff,
        .generation = generation & 0xffffff,
        .salt = salt,
    };
}

macro bool check_rights(ObjectSlot slot, ObjectRights rights) {
    return slot.rights & rights == rights;
}

macro void? validate(ObjectSlot entry, Handle handle) {
    if (!entry.present()) return handle::INVALID?;
    if (entry.generation != handle.generation) return handle::GEN_MISMATCH?;
    if (entry.salt != handle.salt) return handle::SALT_MISMATCH?;
}

fn KernelObject? resolve(ObjectTable table, Handle handle, ObjectRights rights) {
    table.lock.acquire();
    defer table.lock.release();

    if (handle.index >= table.entries.len) return handle::INVALID?;
    ObjectSlot slot = table.entries[handle.index];

    validate(slot, handle)!;
    if (check_rights(slot, rights)) return slot.object;

    $$unreachable(); 
}
