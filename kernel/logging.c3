module muon::log;

import dev::serial;
import string::formatting;

enum LogLevel : int (String label, String ansiColor) {
	TRACE { "TRACE", "\e[36m" },
	DEBUG { "DEBUG", "\e[30m" },
	INFO  { "INFO", "\e[0m" },
	WARN  { "WARN", "\e[33m" },
	ERROR { "ERROR", "\e[31m" },
}

Serial* serial @private;
const SerialPort LOG_PORT = SerialPort.COM1;

const ANSI_RESET = "\e[0m";

// macro void @throw_excuse(#excuse, #msg) @private {
//     serial.write("Fault ");
//     serial.write(#excuse.description);
//     serial.write("!: \"");
//     serial.write(#msg);
//     serial.write("\"\n");
// }

fn void print(String format, args..., LogLevel level = INFO, String callee = "?", char terminator = '\0') {
    Formatter formatter;

	$if !$feat(NO_ANSI_COLORS): 
	serial.write(level.ansiColor); 
	$endif

	// print log time
	String? f = formatter.format("%4d.%06d", 0, 0);
	serial.write("[");
	serial.write(f!!);
	serial.write("] ");

	// print log level label
	f = formatter.format("%-5s", level.label);
	serial.write("[");
	serial.write(f!!);
	serial.write("] ");

	// print callee module
	if (callee != "") {
		serial.write("[");
		serial.write(callee);
		serial.write("] ");
	}

    f = formatter.format(format, ...args);

	// fault during formatting pass
    if (catch e = f) {
		serial.write("\n\t*** Fault while formatting string \"");
        serial.write(format);
        serial.write("\" : ");
		serial.write(e.description);
		serial.write("\n");
        return;
    }

    serial.write(f);
    serial.put(terminator);

	$if !$feat(NO_ANSI_COLORS): 
	serial.write(ANSI_RESET); 
	$endif
}

macro void debug(String format, args..., char terminator = '\n') {
    $if muon::DEBUG:
        print("[%s] ", $$MODULE);
        print(format, ...args, terminator: terminator);
    $endif
}

macro void printn(String format, args...) => print(format, ...args, callee: $$MODULE, terminator: '\n');
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
