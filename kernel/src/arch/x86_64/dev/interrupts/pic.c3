module dev::interrupts::pic;

import dev::port;

enum PortOffset : const inline ushort {
    COMMAND = 0x0000,
    DATA    = 0x0001,
}

const Port MASTER_PIC = 0x0020;
const Port SLAVE_PIC = 0x00a0;

const char CASCADE_IRQ = 2;
const ushort INT_MASK_DISABLE = 0xff;

const char ICW1 = 0x10 | 0x01;  // 0x10: init word, 0x01: use ICW4
const char ICW4 = 0x01;         // 0x01: 8086 mode

fn void remap(char masterOffset = 0x20, char slaveOffset = 0x28) {
    MASTER_PIC.out8(PortOffset.COMMAND, ICW1);
    SLAVE_PIC.out8(PortOffset.COMMAND, ICW1);

    MASTER_PIC.out8(PortOffset.DATA, masterOffset);
    SLAVE_PIC.out8(PortOffset.DATA, slaveOffset);

    MASTER_PIC.out8(PortOffset.DATA, 1 << CASCADE_IRQ);
    SLAVE_PIC.out8(PortOffset.DATA, CASCADE_IRQ);

    MASTER_PIC.out8(PortOffset.DATA, ICW4);
    SLAVE_PIC.out8(PortOffset.DATA, ICW4);
}

macro @mask(#pic, #mask) @local => #pic.out8(PortOffset.DATA, #mask);
fn void mask_master(char mask) => @mask(MASTER_PIC, mask);
fn void mask_slave(char mask) => @mask(SLAVE_PIC, mask);

macro void disable() {
    mask_master(INT_MASK_DISABLE);
    mask_slave(INT_MASK_DISABLE);
}
