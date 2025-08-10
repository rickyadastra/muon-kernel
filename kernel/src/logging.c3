module muon::logging;

import dev::serial;
import string::formatting;

Serial serial @private;
const SerialPort LOG_PORT = SerialPort.COM1;

macro void @throw_excuse(#excuse, #msg) @private {
    serial.write("Fault ");
    serial.write(#excuse.nameof);
    serial.write("!: \"");
    serial.write(#msg);
    serial.write("\"\n");
}

fn void print(String format, args..., char terminator = '\0') {
    Formatter formatter;
    String? f = formatter.format(format, ...args);

    if (catch e = f) {
        @throw_excuse(e, format);
        return;
    }

    serial.write(f);
    serial.put(terminator);
}

macro void printn(String format, args...) => print(format, ...args, terminator: '\n');
macro void newline() => print("", terminator: '\n');

fn void panic(String reason) {
    serial.write("MUON PANIC: ");
    serial.write(reason);
    serial.put('\n');
}

fn void init() {
    serial.setup(SerialPort.COM1);
    printn("Serial port setup complete");
}

macro void @catch_or_log(#action, #message) {
    if (catch e = #action) {
        logging::printn("Error during init: %s", e.nameof);
    } else {
        logging::printn(#message);
    }
}
