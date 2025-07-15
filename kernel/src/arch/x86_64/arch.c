#include "devices/port.h"
#include <base/int.h>

void kstart() {
    asm("cli");
    

    
    // IPort.out8(&com1, 4, 0x1e);
    // IPort.out8(&com1, 0, 0xae);

    char msg[] = "hello world\n";

    for (Size i=0; i<sizeof(msg); i++) {
        IPort.write(&com1, msg[i]);
    }

    for (;;) {}
}
