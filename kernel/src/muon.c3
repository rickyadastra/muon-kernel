module muon;

import arch;
import boson;
import scheduler;

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
    task::spawn((EntryPointFn)&test)!!;

    //// Run tests (remove comments)
    // test::prepare_scheduler();
    // test::prepare_scheduler_fpu();

    // logging::printn("counter: %x, spawner: %x", counterHandle, spawnerHandle);

    logging::printn("Muon init complete");
}

fn void test(SpawnInfo* info) @local {
    logging::printn("task 2 says hello world! i got info @ %x", info);
    task::yield();
    logging::printn("task 2's handle is %x", info.taskHandle);
    task::spawn(&test2, {info.taskHandle, ResourceType.TASK})!!;

    logging::printn("task 2 says i wont crash no more");
}

fn void test2() @local {
    logging::printn("task 3 says hello world, again!");
    task::yield();
    logging::printn("task 3 will wake up in 3 seconds");
    task::sleep_ms(3000)!!;
    logging::printn("task 3 says gm world!");
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
