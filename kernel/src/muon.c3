module muon;

import arch;
import boson;
import process;

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
    Handle handle = process::spawn((EntryPointFn)&test)!!;
    process::detach(handle)!!;

    //// Run tests (remove comments)
    // test::prepare_scheduler();
    // test::prepare_scheduler_fpu();

    logging::printn("Muon init complete");
}

fn void test(SpawnInfo* info) {
    logging::printn("task 2 says hello world");

    Handle child = process::create((EntryPointFn)&test2)!!;

    process::sleep_ms(2000)!!;
    logging::printn("task 2 will start task 3 and wait for it...");
    process::start(child)!!;
    process::wait(child)!!;

    logging::printn("task 2 says goodbye");
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
