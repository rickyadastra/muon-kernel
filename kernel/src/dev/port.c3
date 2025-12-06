module dev::port;

alias Port = ushort;

fn void Port.out8(Port* port, ushort offset, char data) {
    out8(*port + offset, data);
}

fn void Port.out16(Port* port, ushort offset, ushort data) {
    out16(*port + offset, data);
}

fn void Port.out32(Port* port, ushort offset, uint data) {
    out32(*port + offset, data);
}

fn char Port.in8(Port* port, ushort offset) {
    return in8(*port + offset);
}

fn ushort Port.in16(Port* port, ushort offset) {
    return in16(*port + offset);
}

fn uint Port.in32(Port* port, ushort offset) {
    return in32(*port + offset);
}
