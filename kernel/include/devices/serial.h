#pragma once

#include "port.h"

#define SERIAL_ONLY_METHODS(TYPE, SUPER, FUNC) \
    METHOD(TYPE, SUPER, FUNC, void, setup, UInt16 port) \
    METHOD(TYPE, SUPER, FUNC, void, set_interrupt_enable, Bool enable) \
    METHOD(TYPE, SUPER, FUNC, void, set_baud_rate_divisor, UInt16 divisor) \

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
#define INTER_OFFSET        1
#define BRDR_LSB_OFFSET     0
#define BRDR_MSB_OFFSET     1
#define INTER_ID_OFFSET     2
#define FIFO_CTRL_OFFSET    2
#define LINE_CTRL_OFFSET    3
#define MODEM_CTRL_OFFSET   4
#define LINE_STATUS_OFFSET  5
#define MODEM_STATUS_OFFSET 6
#define SCRATCH_REG_OFFSET  7
