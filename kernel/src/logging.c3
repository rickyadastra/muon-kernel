module muon::logging;

import dev::serial;
import string::formatting;

Serial* serial @private;
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

macro void debug(String format, args..., char terminator = '\n') {
    $if muon::DEBUG:
        print("[%s] ", $$MODULE);
        print(format, ...args, terminator: terminator);
    $endif
}

macro void printn(String format, args...) => print(format, ...args, terminator: '\n');
macro void newline() => print("", terminator: '\n');

fn void panic(String reason, String file = "", String function = "", uint line = 0) {
    serial.write("\nMUON PANIC! ");
    serial.write(reason);

    if (function.len > 0) {
        serial.write(" @ ");
        serial.write(function);

        if (file.len > 0) {
            serial.write(" (");
            serial.write(file);

            char[16] tempBuf;
            if (try fmtLen = formatting::format_any_to_decimal(&line, &tempBuf)) {
                serial.put(':');
                serial.write(tempBuf[:fmtLen]);
            }
            serial.write(")\n");
        }
    }
}

fn void init() {
    serial = serial::of(SerialPort.COM1);
    serial.setup(SerialPort.COM1);
    printn("Serial port setup complete");
}
