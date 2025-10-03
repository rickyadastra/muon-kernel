import arch;
import muon::logging;

import boson;
import lang;

fn void kstart(BootloaderPayload* payload) @export("kstart") {
    lang::init_runtime();

    logging::init();
    arch::init(payload);
    
    while (true) arch::cpu::idle();
}
