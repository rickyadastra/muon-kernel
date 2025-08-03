import arch;
import muon::logging;

fn void kstart() @export("kstart") {
    logging::init();
    arch::init();
    
    arch::idle();
}
