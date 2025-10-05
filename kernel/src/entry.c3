import arch;
import muon;
import boson;
import lang;

fn void kstart(BootloaderPayload* payload) @export("kstart") {
    lang::init_runtime();

    muon::kmain(payload);
    
    muon::panic("muon::kmain() returned");
    while (true) arch::cpu::idle();
}
