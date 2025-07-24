#include "devices/serial.h"

void kstart() {
    asm("cli");
    
    Serial logSerial = ISerial.init();
    ISerial.setup(&logSerial, COM1);

    ISerial.write(&logSerial, "hello world\n");

    for (;;) {}
}
