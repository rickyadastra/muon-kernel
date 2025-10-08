module muon;

import arch;
import boson;

fn void kmain(BootloaderPayload* payload) {
    logging::init();

    arch::init(payload);

    // scheduler::init();
    // scheduler::spawn_bootstrap()

    // muon::init()
    idle();
}

fn void idle() @local {
    while (true) arch::cpu::idle();
}

macro panic(String message) => arch::log_and_panic(message, $$FILE, $$FUNC, $$LINE);
