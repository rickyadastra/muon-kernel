module muon;

import arch;

macro panic(String message, String file = $$FILE, String function = $$FUNC, int line = $$LINE, bool backtrace = true) {
	@panic_with_extra(message, file: file, function: function, line: (uint)line) {
		if (backtrace) {
			log::printp("\nBacktrace:\n");
			debug::print_backtrace();
		}
	};
}

macro @panic_with_extra(String message, String file = $$FILE, String function = $$FUNC, int line = $$LINE; @body()) {
	log::panic(message, file: file, function: function, line: (uint)line);
	@body();
	log::end_panic();
	arch::panic();
}

macro @wrap_panic(#func) {
    if (catch ex = #func) {
        log::error("Got fault %s during %s. Cannot continue, goodbye, world.", ex.description, $$FUNC);
        panic("init failed");
    }
}

// panicfn pointer definition for C3 builtin panic handler

alias PanicFn = fn void(String message, String file, String function, int line);
PanicFn panicfn = &panic_fn;

fn void panic_fn(String message, String file = "", String function = "", int line = 0) @local {
	panic(message, file, function, line);
}
