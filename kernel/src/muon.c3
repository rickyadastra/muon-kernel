module muon;

import arch;
import boson;
import process;
import dev;

fn void kmain(BootloaderPayload* payload) {
    logging::init();

    arch::init(payload);
    object::init();

    muon::@wrap_panic(scheduler::init());
    muon::init();
    scheduler::start();
    
    idle();
}

fn void init() {
    // Handle handle = process::spawn((EntryPointFn)&test)!!;
    // process::detach(handle)!!;

    Terminal* terminal = term::create(SerialPort.COM3);
    Handle termHandle = scheduler::get_current_task().handles.insert(terminal, {})!!;
    terminal.track_ref();

    Handle shellHandle = process::create(process::@entry_void_to_int(&shell::shell_main))!!;

    process::set_aux_handle(shellHandle, 0, termHandle)!!;

    process::start(shellHandle)!!;
    process::detach(shellHandle)!!;

    //// Run tests (remove comments)
    // test::prepare_scheduler();
    // test::prepare_scheduler_fpu();

    logging::printn("Muon init complete");
}

fn void test(SpawnInfo* info) {
    logging::printn("task 2 says hello world");

    Handle child = process::create(process::@entry_void_to_int(&test2))!!;

    process::sleep_ms(2000)!!;
    logging::printn("task 2 will start task 3 and wait for it...");
    process::start(child)!!;
    int st = process::wait(child)!!;

    logging::printn("task 2 says goodbye (task 3 terminated with code %d)", st);
}

fn void test2(SpawnInfo* info) {
    logging::printn("task 3 greets y'all! i'm gonna take a nap");
    process::sleep_ms(3000)!!;

    logging::printn("task 3 woke up, gm and goodbye");
}

fn void idle() @local {
    while (true) arch::cpu::idle();
}

macro panic(String message) => arch::log_and_panic(message, $$FILE, $$FUNC, $$LINE);

macro @wrap_panic(#func) {
    if (catch excuse = #func) {
        logging::printn("Got fault %s during %s. Cannot continue, goodbye, world.", excuse.nameof, $$FUNC);
        panic("Init failed");
    }
}
