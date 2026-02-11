module muon::demo::programs;

import muon;
import process;
import arch;

const usz SPINS = 1000;

fn int spinner(SpawnInfo* info) {
    logging::printn("Spinner program started");

	for (usz i=0; i<SPINS; i++) arch::cpu::idle();

    logging::printn("Spinner program exited");
    return 0;
}
