#include "devices/port.h"
#include <devices/serial.h>

INHERITCLASS(Serial, SERIAL_ONLY_METHODS, OBJECT_METHODS)

void Serial_setup(Serial *self, UInt16 port) {
    self->port = port;

    IPort.out8(self->port+INTER_OFFSET, 0x00);
    IPort.out8(self->port+LINE_CTRL_OFFSET, 0x80);
    IPort.out8(self->port+BRDR_LSB_OFFSET, 0x03);
    IPort.out8(self->port+BRDR_MSB_OFFSET, 0x00);
    IPort.out8(self->port+LINE_CTRL_OFFSET, 0x03);
    IPort.out8(self->port+FIFO_CTRL_OFFSET, 0xC7);
    IPort.out8(self->port+MODEM_CTRL_OFFSET, 0x0b);
}

void Serial_set_interrupt_enable(Serial *self, Bool enable) {
    IPort.out8(self->port+INTER_OFFSET, enable);
}

void Serial_set_baud_rate_divisor(Serial *self, UInt16 divisor);

PACKAGECLASS(Serial, Object, SERIAL_ONLY_METHODS, OBJECT_METHODS)
