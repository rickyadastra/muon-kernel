#pragma once

#include "port.h"

typedef union _SerialLineCtrlReg_struct {
    UInt8 raw;
    struct {
        UInt8 data_bits : 2;
        Bool stop_bit : 1;
        UInt8 parity_bits : 3;
        Bool break_enable_bit : 1;
        Bool divisor_latch_access_bit : 1;
    };
} SerialLineCtrlReg;

typedef union _SerialInterruptEnableReg_struct {
    UInt8 raw;
    struct {
        Bool recv_data_avail : 1;
        Bool transm_reg_empty : 1;
        UInt8 recv_line_status : 1;
        UInt8 modem_status : 1;
    };
} SerialInterruptEnableReg;

typedef union _SerialFIFOCtrlReg_struct {
    UInt8 raw;
    struct {
        Bool fifo_enable : 1;
        Bool clear_recv_fifo : 1;
        Bool clear_transm_fifo : 1;
        UInt8 dma_mode_select : 1;
        UInt8 __reserved : 2;
        UInt8 interrupt_trigger_level : 2;
    };
} SerialFIFOCtrlReg;

typedef union _SerialInterruptIdentificationReg_struct {
    UInt8 raw;
    struct {
        Bool no_interrupts : 1;
        UInt8 interrupt_state : 2;
        Bool timeout_interrupt_pending : 1;
        UInt8 __reserved : 2;
        UInt8 fifo_buffer_state : 2;
    };
} SerialInterruptIdentificationReg;

typedef union _SerialModemCtrlReg_struct {
    UInt8 raw;
    struct {
        Bool data_terminal_ready : 1;
        Bool request_to_send : 1;
        Bool out_1 : 1;
        Bool out_2_irq : 1;
        Bool loop : 1;
    };
} SerialModemCtrlReg;

typedef union _SerialLineStatusReg_struct {
    UInt8 raw;
    struct {
        Bool data_ready : 1;
        Bool overrun_error : 1;
        Bool parity_error : 1;
        Bool framing_error : 1;
        Bool break_indicator : 1;
        Bool can_send_data : 1;
        Bool transmitter_idle : 1;
        Bool impending_error : 1;
    };
} SerialLineStatusReg;

typedef union _SerialModemStatusReg_struct {
    UInt8 raw;
    struct {
        Bool delta_cts : 1; // Clear To Send changed
        Bool delta_dsr : 1; // Data Set Ready changeed
        Bool teri : 1; // Trailing Edge of Ring Indicator
        Bool delta_dcd : 1; // Data Carrier Detect changed
        Bool cts : 1;
        Bool dsr : 1;
        Bool ri : 1;
        Bool dcd : 1;
    };
} SerialModemStatusReg;

#define SERIAL_ONLY_METHODS(TYPE, SUPER, FUNC) \
    METHOD(TYPE, SUPER, FUNC, Bool, setup, UInt16 port) \
    METHOD(TYPE, SUPER, FUNC, void, set_baud_rate_divisor, UInt16 divisor) \
    METHOD(TYPE, SUPER, FUNC, SerialLineCtrlReg, get_line_ctrl_reg) \
    METHOD(TYPE, SUPER, FUNC, void, set_line_ctrl_reg, SerialLineCtrlReg value) \
    METHOD(TYPE, SUPER, FUNC, SerialInterruptEnableReg, get_interrupt_enable_reg) \
    METHOD(TYPE, SUPER, FUNC, void, set_interrupt_enable_reg, SerialInterruptEnableReg value) \
    METHOD(TYPE, SUPER, FUNC, SerialFIFOCtrlReg, get_fifo_ctrl_reg) \
    METHOD(TYPE, SUPER, FUNC, void, set_fifo_ctrl_reg, SerialFIFOCtrlReg value) \
    METHOD(TYPE, SUPER, FUNC, SerialModemCtrlReg, get_modem_ctrl_reg) \
    METHOD(TYPE, SUPER, FUNC, void, set_modem_ctrl_reg, SerialModemCtrlReg value) \
    METHOD(TYPE, SUPER, FUNC, SerialLineStatusReg, get_line_status_reg) \
    METHOD(TYPE, SUPER, FUNC, void, put, char data) \
    METHOD(TYPE, SUPER, FUNC, void, write, char* msg) \
    METHOD(TYPE, SUPER, FUNC, Bool, can_write) \
    METHOD(TYPE, SUPER, FUNC, Bool, can_read) \
    METHOD(TYPE, SUPER, FUNC, UInt8, get) \

#define SERIAL_METHODS(TYPE, SUPER, FUNC) \
    OBJECT_METHODS(TYPE, SUPER, FUNC) \
    SERIAL_ONLY_METHODS(TYPE, SUPER, FUNC)

CLASSDEF(Serial, Object, SERIAL_METHODS)
    Port port;
ENDCLASSDEF(Serial)

#define COM1 0x3f8
#define COM2 0x2f8
#define COM3 0x3e8
#define COM4 0x2e8
#define COM5 0x5f8
#define COM6 0x4f8
#define COM7 0x5e8
#define COM8 0x4e8

#define RECV_BUFFER_OFFSET  0
#define WRIT_BUFFER_OFFSET  0
#define INTER_ENABLE_OFFSET 1
#define BRDR_LSB_OFFSET     0
#define BRDR_MSB_OFFSET     1
#define INTER_ID_OFFSET     2
#define FIFO_CTRL_OFFSET    2
#define LINE_CTRL_OFFSET    3
#define MODEM_CTRL_OFFSET   4
#define LINE_STATUS_OFFSET  5
#define MODEM_STATUS_OFFSET 6
#define SCRATCH_REG_OFFSET  7

#define DATA_BITS_5 0b00
#define DATA_BITS_6 0b01
#define DATA_BITS_7 0b10
#define DATA_BITS_8 0b11

#define STOP_BITS_1 0b0
#define STOP_BITS_2 0b1

#define PARITY_BITS_NONE    0b000
#define PARITY_BITS_ODD     0b001
#define PARITY_BITS_EVEN    0b011
#define PARITY_BITS_MARK    0b101
#define PARITY_BITS_SPACE   0b111

#define INT_TRIGGER_BYTES_1   0b00
#define INT_TRIGGER_BYTES_4   0b01
#define INT_TRIGGER_BYTES_8   0b10
#define INT_TRIGGER_BYTES_14  0b11
