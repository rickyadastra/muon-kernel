import arch;
import muon::logging;

import boson;

fn void kstart(BootloaderPayload* payload) @export("kstart") {
    arch::cpu::disable_interrupts();

    logging::init();
    arch::init(payload);

    arch::cpu::enable_interrupts();
    
    while (true) {
        arch::cpu::idle();
    }
}
