import dev::serial;
import arch;

fn void kstart() @export("kstart") {
    Serial log;
    log.setup(SerialPort.COM1);
    log.write("Serial port setup complete\n");

    arch::init();
    
    arch::idle();
}
