module dev::serial;

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
