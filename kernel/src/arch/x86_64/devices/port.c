#include "lepton/core/class.h"
#include <devices/port.h>

DECLAREMETHODS(Port, OBJECT_METHODS, PORT_METHODS)

void Port_out8(Port port, UInt8 data) {
    asm volatile("out %%al, %%dx" : : "a" (data), "d" (port));
}

void Port_out16(Port port, UInt16 data) {
    asm volatile("out %%ax, %%dx" : : "a" (data), "d" (port));
}

void Port_out32(Port port, UInt32 data) {
    asm volatile("out %%eax, %%dx" : : "a" (data), "d" (port));
}

UInt8 Port_in8(Port port) {
    UInt8 data;
    asm volatile("in %%dx, %%al" : "=a" (data) : "d" (port));
    return data;
}

UInt16 Port_in16(Port port) {
    UInt16 data;
    asm volatile("in %%dx, %%ax" : "=a" (data) : "d" (port));
    return data;
}

UInt32 Port_in32(Port port) {
    UInt32 data;
    asm volatile("in %%dx, %%eax" : "=a" (data) : "d" (port));
    return data;
}

PACKAGEIFACE(Port, PORT_METHODS)
