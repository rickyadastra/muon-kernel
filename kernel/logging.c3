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

macro @out(#serial, ...) @local {
	$for var $i = 0; $i < $vaarg.len; $i++:
        #serial.write($vaarg[$i]);
    $endfor
}

fn void print(String format, args..., char terminator = '\0') {
    Formatter formatter;
	String? f = formatter.format(format, ...args);

	// fault during formatting pass
    if (catch e = f) {
		@out(serial, "\n\t*** Fault while formatting string \"", format, "\" : ", e.description, "\n");
        return;
    }

    serial.write(f);
    serial.put(terminator);
}

fn void log(String format, args..., LogLevel level = INFO, String callee = "?", char terminator = '\0') {
    Formatter formatter;

	$if !$feat(NO_ANSI_COLORS): 
	serial.write(level.ansiColor); 
	$endif

	// print log time
	String? f = formatter.format("%4d.%06d", 0, 0);
	@out(serial, "[", f!!, "] ");

	// print log level label
	f = formatter.format("%-5s", level.label);
	@out(serial, "[", f!!, "] ");

	// print callee module
	if (callee != "") @out(serial, "[", callee, "] ");

	// print message
    f = formatter.format(format, ...args);

	// fault during formatting pass
    if (catch e = f) {
		@out(serial, "\n\t*** Fault while formatting string \"", format, "\" : ", e.description, "\n");
        return;
    }

    serial.write(f);
    serial.put(terminator);

	$if !$feat(NO_ANSI_COLORS): 
	serial.write(ANSI_RESET); 
	$endif
}

macro trace(String format, args..., char terminator = '\n') @weak {}
macro debug(String format, args..., char terminator = '\n') @weak {}

macro trace(String format, args..., char terminator = '\n') @feat(LOG_TRACE) 
	=> log(format, ...args, level: LogLevel.TRACE, callee: $$MODULE, terminator: terminator);
macro debug(String format, args..., char terminator = '\n') @feat(LOG_DEBUG | LOG_TRACE) 
	=> log(format, ...args, level: LogLevel.DEBUG, callee: $$MODULE, terminator: terminator);
macro info(String format, args..., char terminator = '\n') 
	=> log(format, ...args, level: LogLevel.INFO, callee: $$MODULE, terminator: terminator);
macro warn(String format, args..., char terminator = '\n') 
	=> log(format, ...args, level: LogLevel.WARN, callee: $$MODULE, terminator: terminator);
macro error(String format, args..., char terminator = '\n') 
	=> log(format, ...args, level: LogLevel.ERROR, callee: $$MODULE, terminator: terminator);

macro void printn(String format, args...) => print(format, ...args, terminator: '\n');
macro void newline() => serial.put('\n');

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
    log::info("Serial port setup complete");
}
