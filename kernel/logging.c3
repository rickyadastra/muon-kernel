module muon::log;

import muon::debug;
import dev::serial, dev::timing;
import string::formatting;

enum LogLevel : int (String label, String ansiColor) {
	TRACE { "TRACE", "\e[36m" },
	DEBUG { "DEBUG", "\e[30m" },
	INFO  { "INFO", "\e[0m" },
	WARN  { "WARN", "\e[33m" },
	ERROR { "ERROR", "\e[31m" },
	PANIC { "PANIC", "\e[35m" },
}

const SerialPort LOG_PORT = SerialPort.COM1;
const ANSI_RESET = "\e[0m";

const String[] PANIC_SPLASH_MESSAGES = {
	"Muon encountered a fatal error and panicked.",
	"Whoops, the muon decayed too fast!",
	"Have you tried turning the emulator off and on again?",
	"This is fine. Everything is fine.",
	"Pointer went on vacation without telling the VMM.",
	"Damn you, pointer arithmetic!",
	"Kernel panic! At least it wasn't written in C.",
	"Triple fault avoided (barely).",
	"Undefined behavior? In MY C3 kernel?!",
};

Serial* serial @private;

macro @out(Serial* #serial, ...) @local {
	$for var $i = 0; $i < $vaarg.len; $i++:
		$switch $Typeof($vaarg[$i]):
			$case char[]: 
			$case String: 
				#serial.write($vaarg[$i]);
			$case char: 
				#serial.put($vaarg[$i]);
			$default: $error("Unknown type for @out macro");
		$endswitch

    $endfor
}

macro @set_ansi_color(#color) @local {
	$if !$feat(ANSI_COLORS_NO): 
		serial.write(#color); 
	$endif
}

macro @reset_ansi_color() @local {
	$if !$feat(ANSI_COLORS_NO): 
		serial.write(ANSI_RESET); 
	$endif
}

fn void printp(String s) {
	serial.write(s);
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

	@set_ansi_color(level.ansiColor);

	// print log time
	ulong totalUs = timing::get_uptime_us();
	ulong seconds = totalUs / 1_000_000;
	ulong microseconds = totalUs % 1_000_000;
	String? f = formatter.format("%4d.%06d", seconds, microseconds);
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

	@reset_ansi_color();
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
	newline();
	@set_ansi_color(LogLevel.PANIC.ansiColor);

	var $idx = (usz)($$rnd() * PANIC_SPLASH_MESSAGES.len); 
	var $splash = PANIC_SPLASH_MESSAGES[$idx];
	@out(serial, "[" +++ LogLevel.PANIC.label +++ "] " +++ $splash +++ "\n");

	@out(serial, "  panic reason: \"", reason, "\"\n");

    if (function.len > 0) {
		// print panicked function
		@out(serial, "  in function ", function);

        if (file.len > 0) {
            char[16] tempBuf;
			usz? len = formatting::format_any_to_decimal(&line, &tempBuf);
			// print file name and line
            if (try len) @out(serial, " (", file, ':', tempBuf[:len], ")\n");
        }
    }
}

macro void end_panic() {
	newline();
	@reset_ansi_color();
}

fn void init() {
    serial = serial::of(SerialPort.COM1);
    serial.setup(SerialPort.COM1);
    log::info("Serial port setup complete");
}
