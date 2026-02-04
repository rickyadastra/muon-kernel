module muon::demo::programs;

import muon;
import process;
import string;

const usz MAX_COUNT = 50;
const usz ITERATIONS = 1_000_000_000;

String[shell::MAX_TOKENS] tokens @local;

fn int spawner(SpawnInfo* info) {
    Handle termHandle = info.auxHandles[0];
    String[] args = shell::@get_args(info, tokens);

    logging::printn("Spawner program started");

    if (args.len == 1) {
        term::printn(termHandle, "Missing argument. Usage: spawner <count>")!!;
        return -1;
    }

    ulong? count = parse_integer(args[1]);

    if (try count && count > 0 && count <= MAX_COUNT) {
        logging::printn("Spawning %d programs", count);

        Handle[MAX_COUNT] handles;
	    TaskAccountingLog[MAX_COUNT] logs;

        for (usz i=0; i<count; i++) {
            Handle procHandle = process::create((EntryPointFn)&spawner_child)!!;
            handles[i] = procHandle;

            process::set_aux_handle(procHandle, 0, termHandle)!!;
            process::set_command_line(procHandle, info.commandLine)!!;
            process::start(procHandle)!!;
        }

        for (usz i=0; i<count; i++) {
            process::wait(handles[i], &logs[i])!!;

			logging::printn("Child #%d terminated. Stats: turnaround=%fms, response=%fms, wait=%fms, burst=%fms", 
							i, logs[i].turnaroundTime, logs[i].responseTime, logs[i].waitTime, logs[i].turnaroundTime-logs[i].waitTime);
        }

    } else {
        term::print(termHandle, "Invalid argument '")!!;
        term::print(termHandle, args[1])!!;
        term::printn(termHandle, "' for count.")!!;
        return -1;
    }

    logging::printn("Spawner program exited");
    return 0;
}

fn int spawner_child(SpawnInfo* info) {
    Handle termHandle = info.auxHandles[0];
    term::printn(termHandle, "Child started")!!;

	for (usz i=0; i<ITERATIONS; i++) {}

    term::printn(termHandle, "Child ended")!!;
    return 0;
}
