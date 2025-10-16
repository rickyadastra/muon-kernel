module handle;

macro Handle init(uint index, uint generation, ushort salt) {
    return {
        .index = index & 0xffffff,
        .gen = generation & 0xffffff,
        .salt = salt,
    };
}

module handle::table{ResourceType};

fn bool HandleTableEntry.free(&self) => &self.data == null;
