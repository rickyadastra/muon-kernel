import dev::serial;
import arch;

fn void kstart() @export("kstart") {
    Serial log;
    log.setup(SerialPort.COM1);
    gdt::setup();
    log.write("GDT setup complete\n");

    gdt::install();
    log.write("GDT install complete\n");
    
    asm("hlt");
}
