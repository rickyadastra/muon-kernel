#include "devices/port.h"
#include <lepton/exception/invalid_parameter_exception.h>
#include <devices/serial.h>

INHERITCLASS(Serial, SERIAL_ONLY_METHODS, OBJECT_METHODS)

Bool Serial_setup(Serial *self, UInt16 port) {
    if (port != COM1 && port != COM2 && port != COM3 && port != COM4 &&
        port != COM5 && port != COM6 && port != COM7 && port != COM8) {
        THROW_EXCEPTION(InvalidParameterException, "The port is not a valid serial port");
        return false;
    }
    self->port = port;

    ISerial.set_interrupt_enable_reg(self, (SerialInterruptEnableReg){});

    ISerial.set_baud_rate_divisor(self, 3);

    ISerial.set_line_ctrl_reg(self, (SerialLineCtrlReg){
        .data_bits=DATA_BITS_8,
        .parity_bits=PARITY_BITS_NONE,
        .break_enable_bit=0,
        .stop_bit=STOP_BITS_1
    });

    ISerial.set_fifo_ctrl_reg(self, (SerialFIFOCtrlReg){
        .fifo_enable=1,
        .clear_recv_fifo=1,
        .clear_transm_fifo=1,
        .interrupt_trigger_level=INT_TRIGGER_BYTES_14
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
    lineCtrlReg.raw = IPort.in8(self->port + LINE_CTRL_OFFSET);
    return lineCtrlReg;
}

void Serial_set_line_ctrl_reg(Serial *self, SerialLineCtrlReg value) {
    IPort.out8(self->port + LINE_CTRL_OFFSET, value.raw);
}

SerialInterruptEnableReg Serial_get_interrupt_enable_reg(Serial *self) {
    SerialInterruptEnableReg intEnableReg;
    intEnableReg.raw = IPort.in8(self->port + INTER_ENABLE_OFFSET);
    return intEnableReg;
}

void Serial_set_interrupt_enable_reg(Serial *self, SerialInterruptEnableReg value) {
    IPort.out8(self->port + INTER_ENABLE_OFFSET, value.raw);
}

SerialFIFOCtrlReg Serial_get_fifo_ctrl_reg(Serial *self) {
    SerialFIFOCtrlReg fifoCtrlReg;
    fifoCtrlReg.raw = IPort.in8(self->port + FIFO_CTRL_OFFSET);
    return fifoCtrlReg;
}

void Serial_set_fifo_ctrl_reg(Serial *self, SerialFIFOCtrlReg value) {
    IPort.out8(self->port + FIFO_CTRL_OFFSET, value.raw);
}

SerialModemCtrlReg Serial_get_modem_ctrl_reg(Serial *self) {
    SerialModemCtrlReg modemCtrlReg;
    modemCtrlReg.raw = IPort.in8(self->port + MODEM_CTRL_OFFSET);
    return modemCtrlReg;
}

void Serial_set_modem_ctrl_reg(Serial *self, SerialModemCtrlReg value) {
    IPort.out8(self->port + MODEM_CTRL_OFFSET, value.raw);
}

void Serial_set_baud_rate_divisor(Serial *self, UInt16 divisor) {
    SerialLineCtrlReg lineCtrlReg = ISerial.get_line_ctrl_reg(self);
    
    // Enable DLAB (Divisor Latch Access Bit) in Line Control Register (bit 7)
    lineCtrlReg.divisor_latch_access_bit = true;
    ISerial.set_line_ctrl_reg(self, lineCtrlReg);

    // Send the LSB to BRDR_LSB and MSB to BRDR_MSB
    IPort.out8(self->port+BRDR_LSB_OFFSET, (UInt8)divisor);
    IPort.out8(self->port+BRDR_MSB_OFFSET, (UInt8)(divisor>>8));
    
    // Clear DLAB
    lineCtrlReg.divisor_latch_access_bit = false;
    ISerial.set_line_ctrl_reg(self, lineCtrlReg);
}

PACKAGECLASS(Serial, Object, SERIAL_ONLY_METHODS, OBJECT_METHODS)
