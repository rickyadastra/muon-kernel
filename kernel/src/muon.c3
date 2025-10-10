module muon;

import arch;
import boson;
import scheduler;

fn void kmain(BootloaderPayload* payload) {
    logging::init();

    arch::init(payload);

    scheduler::init();
    // init();
    scheduler::start();
    
    idle();
}

fn void idle() @local {
    while (true) arch::cpu::idle();
}

macro panic(String message) => arch::log_and_panic(message, $$FILE, $$FUNC, $$LINE);
