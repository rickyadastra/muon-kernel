module dev::port;

alias Port = ushort;

extern fn void arch_out8(Port, char);
extern fn void arch_out16(Port, ushort);
extern fn void arch_out32(Port, uint);

extern fn char arch_in8(Port);
extern fn ushort arch_in16(Port);
extern fn uint arch_in32(Port);

fn void Port.out8(Port* port, ushort offset, char data) {
    arch_out8((*port) + offset, data);
}

fn void Port.out16(Port* port, ushort offset, ushort data) {
    arch_out16((*port) + offset, data);
}

fn void Port.out32(Port* port, ushort offset, uint data) {
    arch_out32((*port) + offset, data);
}

fn char Port.in8(Port* port, ushort offset) {
    return arch_in8((*port) + offset);
}

fn ushort Port.in16(Port* port, ushort offset) {
    return arch_in16((*port) + offset);
}

fn uint Port.in32(Port* port, ushort offset) {
    return arch_in32((*port) + offset);
}
