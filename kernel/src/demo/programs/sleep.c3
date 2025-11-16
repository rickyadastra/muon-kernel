module muon::demo::programs;

import muon;
import process;

faultdef INVALID_DURATION;

String[shell::MAX_TOKENS] tokens @local;

fn int sleep(SpawnInfo* info) {
    Handle termHandle = info.auxHandles[0];
    String[] args = shell::@get_args(info, tokens);

    logging::printn("Sleep program started");

    if (args.len == 1) {
        term::printn(termHandle, "Missing argument. Usage: sleep <time>")!!;
        return -1;
    }

    usz? seconds = parse_time_to_ms(args[1]);

    if (try seconds) {
        logging::printn("Sleeping for %d seconds", seconds);
        process::sleep_ms(seconds*1000)!!;

    } else {
        term::print(termHandle, "Invalid argument '")!!;
        term::print(termHandle, args[1])!!;
        term::printn(termHandle, "' for time.")!!;
        return -1;
    }

    logging::printn("Sleep program exited");
    return 0;
}

fn usz? parse_time_to_ms(String arg) {
    usz time = 0;

    foreach (char c : arg) {
        if (c >= '0' && c <= '9') {
            time *= 10;
            time += (usz)(c-'0');

        } else {
            return INVALID_DURATION?;
        }
    }

    return time;
}
