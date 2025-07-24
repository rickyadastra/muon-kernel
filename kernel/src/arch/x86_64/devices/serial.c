#include "devices/port.h"
#include <lepton/exception/invalid_parameter_exception.h>
#include <devices/serial.h>

ENUMPACKAGE(SerialPort, , SERIALPORT_MEMBERS)

INHERITCLASS(Serial, SERIAL_ONLY_METHODS, OBJECT_METHODS)

Bool Serial_setup(Serial *self, UInt16 port) {
    if (port != SerialPort.COM1 && port != SerialPort.COM2 &&
        port != SerialPort.COM3 && port != SerialPort.COM4 &&
        port != SerialPort.COM5 && port != SerialPort.COM6 &&
        port != SerialPort.COM7 && port != SerialPort.COM8) {
        THROW_EXCEPTION(InvalidParameterException, "The port is not a valid serial port");
        return false;
    }
    self->port = port;

    ISerial.set_interrupt_enable_reg(self, (SerialInterruptEnableReg){});

    ISerial.set_baud_rate_divisor(self, 3);

    ISerial.set_line_ctrl_reg(self, (SerialLineCtrlReg){
        .data_bits=SerialDataBits.EIGHT,
        .parity_bits=SerialParityBits.NONE,
        .break_enable_bit=0,
        .stop_bit=SerialStopBits.ONE
    });

    ISerial.set_fifo_ctrl_reg(self, (SerialFIFOCtrlReg){
        .fifo_enable=1,
        .clear_recv_fifo=1,
        .clear_transm_fifo=1,
        .interrupt_trigger_level=SerialInterruptTriggerBytes.FOURTEEN
    });

    //? Test port via loopback
    ISerial.set_modem_ctrl_reg(self, (SerialModemCtrlReg){
        .request_to_send=1,
        .out_2_irq=1,
        .out_1=1,
        .loop=1
    });

    // Send byte and check for return
    IPort.out8(self->port, 0xAE);
    if (IPort.in8(self->port) != 0xAE) {
        return false;
    }
    
    ISerial.set_modem_ctrl_reg(self, (SerialModemCtrlReg){
        .data_terminal_ready=1,
        .request_to_send=1,
        .out_2_irq=1,
        .out_1=1
    });

    return true;
}

SerialLineCtrlReg Serial_get_line_ctrl_reg(Serial *self) {
    SerialLineCtrlReg lineCtrlReg;
    lineCtrlReg.raw = IPort.in8(self->port + SerialPortRegister.LINE_CTRL);
    return lineCtrlReg;
}

void Serial_set_line_ctrl_reg(Serial *self, SerialLineCtrlReg value) {
    IPort.out8(self->port + SerialPortRegister.LINE_CTRL, value.raw);
}

SerialInterruptEnableReg Serial_get_interrupt_enable_reg(Serial *self) {
    SerialInterruptEnableReg intEnableReg;
    intEnableReg.raw = IPort.in8(self->port + SerialPortRegister.INTER_ENABLE);
    return intEnableReg;
}

void Serial_set_interrupt_enable_reg(Serial *self, SerialInterruptEnableReg value) {
    IPort.out8(self->port + SerialPortRegister.INTER_ENABLE, value.raw);
}

SerialFIFOCtrlReg Serial_get_fifo_ctrl_reg(Serial *self) {
    SerialFIFOCtrlReg fifoCtrlReg;
    fifoCtrlReg.raw = IPort.in8(self->port + SerialPortRegister.FIFO_CTRL);
    return fifoCtrlReg;
}

void Serial_set_fifo_ctrl_reg(Serial *self, SerialFIFOCtrlReg value) {
    IPort.out8(self->port + SerialPortRegister.FIFO_CTRL, value.raw);
}

SerialModemCtrlReg Serial_get_modem_ctrl_reg(Serial *self) {
    SerialModemCtrlReg modemCtrlReg;
    modemCtrlReg.raw = IPort.in8(self->port + SerialPortRegister.MODEM_CTRL);
    return modemCtrlReg;
}

void Serial_set_modem_ctrl_reg(Serial *self, SerialModemCtrlReg value) {
    IPort.out8(self->port + SerialPortRegister.MODEM_CTRL, value.raw);
}

SerialLineStatusReg Serial_get_line_status_reg(Serial *self) {
    SerialLineStatusReg lineStatusReg;
    lineStatusReg.raw = IPort.in8(self->port + SerialPortRegister.LINE_STATUS);
    return lineStatusReg;
}

void Serial_set_baud_rate_divisor(Serial *self, UInt16 divisor) {
    SerialLineCtrlReg lineCtrlReg = ISerial.get_line_ctrl_reg(self);
    
    // Enable DLAB (Divisor Latch Access Bit) in Line Control Register (bit 7)
    lineCtrlReg.divisor_latch_access_bit = true;
    ISerial.set_line_ctrl_reg(self, lineCtrlReg);

    // Send the LSB to BRDR_LSB and MSB to BRDR_MSB
    IPort.out8(self->port+SerialPortRegister.BRDR_LSB, (UInt8)divisor);
    IPort.out8(self->port+SerialPortRegister.BRDR_MSB, (UInt8)(divisor>>8));
    
    // Clear DLAB
    lineCtrlReg.divisor_latch_access_bit = false;
    ISerial.set_line_ctrl_reg(self, lineCtrlReg);
}

void Serial_put(Serial *self, char data) {
    while (!ISerial.can_write(self));
    IPort.out8(self->port, data);
}

void Serial_write(Serial *self, char* msg) {
    while (*msg != 0) 
        ISerial.put(self, *msg++);
}

UInt8 Serial_get(Serial *self) {
    while (!ISerial.can_read(self));
    return IPort.in8(self->port);
}

Bool Serial_can_write(Serial *self) {
    return ISerial.get_line_status_reg(self).can_send_data;
}

Bool Serial_can_read(Serial *self) {
    return ISerial.get_line_status_reg(self).data_ready;
}

PACKAGECLASS(Serial, Object, SERIAL_ONLY_METHODS, OBJECT_METHODS)
