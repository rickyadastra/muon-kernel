module muon::demo::programs;

import muon;
import process;

fn int sleep5(SpawnInfo* info) {
    Handle termHandle = info.auxHandles[0];
    logging::printn("Sleep5 program started");

    term::print(termHandle, "Sleeping for 5 seconds... ")!!;
    process::sleep_ms(5000)!!;
    term::printn(termHandle, "Bye.")!!;

    logging::printn("Sleep5 program exited");
    return 0;
}
