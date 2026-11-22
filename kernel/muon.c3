module muon;

import arch;
import process;

fn void kmain(BootContext* ctx) {
	debug::init(ctx.debug)!!;

    arch::init(ctx);
	debug::load_symbols(ctx.modules);
    object::init();

    muon::@wrap_panic(scheduler::init());
    // muon::init();
    // scheduler::start();
	
    idle();
}

fn void init() {
    Handle handle = process::spawn((EntryPointFn)&test)!!;
    process::detach(handle)!!;

    //// Run tests (remove comments)
    // test::prepare_scheduler();
    // test::prepare_scheduler_fpu();

    log::info("Muon init complete");
}

fn void test(SpawnInfo* info) {
    log::info("task 2 says hello world");

    Handle child = process::create(process::@entry_void_to_int(&test2))!!;

    process::sleep_ms(2000)!!;
    log::info("task 2 will start task 3 and wait for it...");
    process::start(child)!!;
    int st = process::wait(child)!!;

    log::info("task 2 says goodbye (task 3 terminated with code %d)", st);
}

fn void test2(SpawnInfo* info) {
    log::info("task 3 greets y'all! i'm gonna take a nap");
    process::sleep_ms(3000)!!;

    log::info("task 3 woke up, gm and goodbye");
}

fn void idle() @local {
    while (true) arch::cpu::idle();
}

macro panic(String message, String file = $$FILE, String function = $$FUNC, int line = $$LINE, bool backtrace = true) {
	log::panic(message, file: file, function: function, line: (uint)line);
	if (backtrace) debug::print_backtrace();
	arch::panic();
}

macro @wrap_panic(#func) {
    if (catch ex = #func) {
        log::error("Got fault %s during %s. Cannot continue, goodbye, world.", ex.description, $$FUNC);
        panic("Init failed");
    }
}

// panicfn pointer definition for C3 builtin panic handler

alias PanicFn = fn void(String message, String file, String function, int line);
PanicFn panicfn = &panic_fn;

fn void panic_fn(String message, String file = "", String function = "", int line = 0) @local {
	panic(message, file, function, line);
}
