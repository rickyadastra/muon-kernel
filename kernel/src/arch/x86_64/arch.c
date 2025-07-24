#include "devices/serial.h"
#include "x86_64/gdt.h"

void kstart() {
    asm("cli");
    
    Serial logSerial = ISerial.init();
    ISerial.setup(&logSerial, SerialPort.COM1);
    ISerial.write(&logSerial, "COM1 serial logging setup complete\n");

    GDTManager gdtManager = IGDTManager.init();
    IGDTManager.setup(&gdtManager);
    ISerial.write(&logSerial, "GDT setup complete\n");
    IGDTManager.install(&gdtManager);
    ISerial.write(&logSerial, "GDT install complete\n");

    for (;;) {}
}
