module muon::demo::programs;

import muon;
import process;
import random;
import string;

faultdef INVALID_NUMBER;

String[shell::MAX_TOKENS] tokens @local;

fn int random(SpawnInfo* info) {
    Handle termHandle = info.auxHandles[0];
    String[] args = shell::@get_args(info, tokens);

    ulong min = ulong.min;
    ulong max = ulong.max;

    // parse min
    if (args.len >= 2) {
        if (try pmin = parse_integer(args[1])) {
            min = pmin;
        } else {
            term::print(termHandle, "Invalid argument '")!!;
            term::print(termHandle, args[1])!!;
            term::printn(termHandle, "' for min.")!!;
            return -1;
        }
    } 

    // parse max
    if (args.len >= 3) {
        if (try pmax = parse_integer(args[2]) && pmax > min && pmax != 0) {
            max = pmax + 1;
        } else {
            term::print(termHandle, "Invalid argument '")!!;
            term::print(termHandle, args[2])!!;
            term::printn(termHandle, "' for max.")!!;
            return -1;
        }
    } 

    logging::printn("Random program started");
    logging::printn("Generating random number between %d and %d", min, max-1);

    ulong rand = (random::random()!! % max) + min;
    Formatter formatter;
    String s = formatter.format("Generated random: %d", rand)!!;

    term::printn(termHandle, s)!!;

    logging::printn("Random program exited");
    return 0;
}

fn ulong? parse_integer(String arg) {
    ulong num = 0;

    foreach (char c : arg) {
        if (c >= '0' && c <= '9') {
            num *= 10;
            num += (ulong)(c-'0');

        } else {
            return INVALID_NUMBER?;
        }
    }

    return num;
}
