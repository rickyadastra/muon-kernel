#pragma once

typedef UInt16 Port;

#define PORT_ONLY_METHODS(TYPE, SUPER, FUNC) \
    STATIC(TYPE, SUPER, FUNC, void, out8, Port port, UInt8 data) \
    STATIC(TYPE, SUPER, FUNC, void, out16, Port port, UInt16 data) \
    STATIC(TYPE, SUPER, FUNC, void, out32, Port port, UInt32 data) \
    STATIC(TYPE, SUPER, FUNC, UInt8, in8, Port port) \
    STATIC(TYPE, SUPER, FUNC, UInt16, in16, Port port) \
    STATIC(TYPE, SUPER, FUNC, UInt32, in32, Port port) \

#define PORT_METHODS(TYPE, SUPER, FUNC) \
    PORT_ONLY_METHODS(TYPE, SUPER, FUNC)

IFACEDEF(Port, PORT_METHODS)
ENDIFACEDEF(Port)

