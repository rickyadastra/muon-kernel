import dev::serial;

fn void kstart() @export("kstart") {
    Serial log;
    log.setup(SerialPort.COM1);

    log.write("hello world\n");
    
    asm("hlt");
}
