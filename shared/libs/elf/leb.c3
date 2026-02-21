module elf::dwarf;

fn ulong decode_uleb128(char** ptr) {
    ulong result;
    uint shift;

    while (true) {
        char byte = **ptr;
        (*ptr)++;
        result |= (ulong)(byte & 0x7F) << shift;
        if ((byte & 0x80) == 0) break;
        shift += 7;
    }

    return result;
}

fn long decode_sleb128(char** ptr) {
    long result;
    uint shift;
    char byte;

    while (true) {
        byte = **ptr;
        (*ptr)++;
        result |= (ulong)(byte & 0x7F) << shift;
        shift += 7;
        if ((byte & 0x80) == 0) break;
    }

    if (shift < 64 && (byte & 0x40)) result |= (long)-(1 << shift);
    
    return result;
}