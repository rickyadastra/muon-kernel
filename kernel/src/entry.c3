import arch;
import muon::logging;

import boson;

fn void kstart(BootloaderPayload* payload) @export("kstart") {
    logging::init();
    arch::init(payload);
    
    while (true) arch::cpu::idle();
}
