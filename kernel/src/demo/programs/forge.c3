module muon::demo::programs;

import muon;
import process;
import random;
import string;

faultdef INVALID;

String[shell::MAX_TOKENS] tokens @local;

fn int forge(SpawnInfo* info) {
    Handle termHandle = info.auxHandles[0];
    String[] args = shell::@get_args(info, tokens);

    logging::printn("Forge program started");

    if (args.len < 3) {
        term::printn(termHandle, "Missing argument/s. Usage: forge <id> <gen>")!!;
        return -1;
    }

	uint id, gen;
	ushort salt = (ushort)random::random()!!;
	
	if (try pid = parse_int(args[1])) {
		id = (uint)pid;
	} else {
		term::print(termHandle, "Invalid argument '")!!;
		term::print(termHandle, args[1])!!;
		term::printn(termHandle, "' for id.")!!;
		return -1;
	}

	if (try pgen = parse_int(args[2])) {
		gen = (uint)pgen;
	} else {
		term::print(termHandle, "Invalid argument '")!!;
		term::print(termHandle, args[1])!!;
		term::printn(termHandle, "' for gen.")!!;
		return -1;
	}

	Handle forged = {id, gen, salt};

	Formatter formatter;
	String s = formatter.format("Attempting term::printn() with forged Handle=%x", forged)!!;
    term::printn(termHandle, s)!!;

    if (catch excuse = term::printn(forged, "Forged Handle got through!")) {
		s = formatter.format("Invalid Handle. Reason: %s", excuse.nameof)!!;
		term::printn(termHandle, s)!!;

	} else {
		$$unreachable();
	}

    logging::printn("Forge program exited");
    return 0;
}

fn usz? parse_int(String arg) {
    usz val = 0;

    foreach (char c : arg) {
        if (c >= '0' && c <= '9') {
            val *= 10;
            val += (usz)(c-'0');

        } else {
            return INVALID?;
        }
    }

    return val;
}
