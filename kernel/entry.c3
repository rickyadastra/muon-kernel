import arch;
import muon;
import boson;
import lang;

fn void kstart(BootInfoBlock* bib) @export("kstart") {
    lang::init_runtime();

    muon::kmain(bib);
    
    muon::panic("muon::kmain() returned");
}
