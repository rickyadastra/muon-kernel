#include "devices/serial.h"

void kstart() {
    asm("cli");
    
    Serial logSerial = ISerial.init();
    ISerial.setup(&logSerial, SerialPort.COM1);

    ISerial.write(&logSerial, "hello world\n");

    for (;;) {}
}
