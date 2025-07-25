module dev::serial;

import dev::port;

enum SerialPort : ushort (Port value) {
    COM1 = 0x3f8,
    COM2 = 0x2f8,
    COM3 = 0x3e8,
    COM4 = 0x2e8,
    COM5 = 0x5f8,
    COM6 = 0x4f8,
    COM7 = 0x5e8,
    COM8 = 0x4e8,
}

enum SerialPortRegister : ushort (char offset) {
    RECEIVE_BUFFER = 0,
    TRANSMIT_BUFFER = 0,
    INTERRUPT_ENABLE = 1,
    BAUD_RATE_LSB = 0,
    BAUD_RATE_MSB = 1,
    INTERRUPT_ID = 2,
    FIFO_CTRL = 2,
    LINE_CTRL = 3,
    MODEM_CTRL = 4,
    LINE_STATUS = 5,
    MODEM_STATUS = 6,
    SCRATCH = 7, 
}

bitstruct LineStatusRegister : char {
    bool data_ready : 0;
    bool overrun_error : 1;
    bool parity_error : 2;
    bool framing_error : 3;
    bool break_indicator : 4;
    bool can_send_data : 5;
    bool transmitter_idle : 6;
    bool impending_error : 7;
}

struct Serial {
    Port port;
}

fn void Serial.setup(Serial* this, SerialPort port) {
    this.port = port.value;

    this.port.out8(SerialPortRegister.INTERRUPT_ENABLE.offset, 0x00);   // disable interrupts
    this.port.out8(SerialPortRegister.LINE_CTRL.offset, 0x80);          // enable DLAB
    this.port.out8(SerialPortRegister.BAUD_RATE_LSB.offset, 0x03);      // set divisor LSB to 3
    this.port.out8(SerialPortRegister.BAUD_RATE_MSB.offset, 0x00);      // set divisor MSB to 0
    this.port.out8(SerialPortRegister.LINE_CTRL.offset, 0x03);          // disable DLAB, 8 bits of data, no parity, one stop bit 
    this.port.out8(SerialPortRegister.FIFO_CTRL.offset, 0xc7);          // enable FIFO, clear buffers, interrupts every 14 byte
    this.port.out8(SerialPortRegister.MODEM_CTRL.offset, 0x0f);         // enable IRQs, enable RTS/DSR, enable out #1 & #2 ints
}

fn bool Serial.can_write(Serial* this) {
    return ((LineStatusRegister) this.port.in8(SerialPortRegister.LINE_STATUS.offset)).can_send_data;
}

fn void Serial.put(Serial* this, char c) {
    while (!this.can_write());
    this.port.out8(SerialPortRegister.TRANSMIT_BUFFER.offset, c);
}

fn void Serial.write(Serial* this, char[] s) {
    for (usz i = 0; i < s.len; i++) this.put(s[i]);
}
