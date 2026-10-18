module dev::mmio;

alias MemIO = uptr;

macro @mmio_write($Type, #mmio, #reg, #data) @local => *($Type*)(#mmio + #reg) = #data;
macro @mmio_read($Type, #mmio, #reg) @local => *($Type*)(#mmio + #reg);

fn void MemIO.write8(MemIO* mmio, ulong reg, char data) => @mmio_write(char, *mmio, reg, data);
fn void MemIO.write16(MemIO* mmio, ulong reg, ushort data) => @mmio_write(ushort, *mmio, reg, data);
fn void MemIO.write32(MemIO* mmio, ulong reg, uint data) => @mmio_write(uint, *mmio, reg, data);
fn void MemIO.write64(MemIO* mmio, ulong reg, ulong data) => @mmio_write(ulong, *mmio, reg, data);

fn char MemIO.read8(MemIO* mmio, ulong reg) => @mmio_read(char, *mmio, reg);
fn ushort MemIO.read16(MemIO* mmio, ulong reg) => @mmio_read(ushort, *mmio, reg);
fn uint MemIO.read32(MemIO* mmio, ulong reg) => @mmio_read(uint, *mmio, reg);
fn ulong MemIO.read64(MemIO* mmio, ulong reg) => @mmio_read(ulong, *mmio, reg);
