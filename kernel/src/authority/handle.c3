module muon::authority::handle;

import muon::authority::object;

macro Handle make(uint index, uint generation, ushort salt) {
    return {
        .index = index & 0xffffff,
        .generation = generation & 0xffffff,
        .salt = salt,
    };
}

macro bool? Handle.validate(&self, ObjectSlot entry) {
    if (!entry.valid()) return handle::INVALID_HANDLE?;
    if (entry.generation != self.generation) return handle::HANDLE_GEN_MISMATCH?;
    if (entry.salt != self.salt) return handle::HANDLE_SALT_MISMATCH?;

    return true;
}
