module muon::demo::programs;

import muon;
import process;
import string;
import std::math;

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
	double sumTurnaround, sumWait, sumResponse, sumBurst;

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

			sumTurnaround += logs[i].turnaroundTime;
			sumResponse += logs[i].responseTime;
			sumWait += logs[i].waitTime;
			sumBurst += logs[i].turnaroundTime-logs[i].waitTime;

			logging::printn("Child #%d terminated. Stats: turnaround=%fms, response=%fms, wait=%fms, burst=%fms", 
							i, logs[i].turnaroundTime, logs[i].responseTime, logs[i].waitTime, logs[i].turnaroundTime-logs[i].waitTime);
        }

		double avgTurnaround = sumTurnaround / count;
		double avgResponse = sumResponse / count;
		double avgWait = sumWait / count;
		double avgBurst = sumBurst / count;

		double sumBurstSquares;
		double ssdTurnaround, ssdWait, ssdResponse, ssdBurst;

		foreach (TaskAccountingLog log : logs[:count]) {
			double burstTime = (log.turnaroundTime - log.waitTime);

			ssdTurnaround += @pow2(log.turnaroundTime - avgTurnaround);
			ssdWait += @pow2(log.waitTime - avgWait);
			ssdResponse += @pow2(log.responseTime - avgResponse);
			ssdBurst += @pow2(burstTime - avgBurst);
			sumBurstSquares += @pow2(burstTime);
		}

		double jainIndex = @pow2(sumBurst) / (count*sumBurstSquares);

		term::print_newline(termHandle)!!;
		term::printn(termHandle, "Spawner program complete.")!!;

		@print_average(termHandle, "turnaround time", avgTurnaround, @sd(ssdTurnaround, count));
		@print_average(termHandle, "response time", avgResponse, @sd(ssdResponse, count));
		@print_average(termHandle, "wait time", avgWait, @sd(ssdWait, count));
		@print_average(termHandle, "burst time", avgBurst, @sd(ssdBurst, count));
		@printf(termHandle, "Jain's fairness index: %f", jainIndex);

    } else {
        term::print(termHandle, "Invalid argument '")!!;
        term::print(termHandle, args[1])!!;
        term::printn(termHandle, "' for count.")!!;
        return -1;
    }

    logging::printn("Spawner program exited");
    return 0;
}

macro @pow2(#val) @local => (#val)*(#val);
macro @sd(#ssd, #n) @local => math::sqrt(#ssd / (double)(#n-1));
macro @se(#ssd, #n) @local => math::sqrt(#ssd / (double)(#n*(#n-1)));

macro @printf(#termHandle, String #format, args...) {
	Formatter formatter;
	String s = formatter.format(#format, ...args)!!;
	term::printn(#termHandle, s)!!;
}

macro @print_average(#termHandle, String #text, double #avg, double #se) {
	@printf(#termHandle, "Average %s: %fms +/- %fms", #text, #avg, #se);
}

fn int spawner_child(SpawnInfo* info) {
    Handle termHandle = info.auxHandles[0];
    term::printn(termHandle, "Child started")!!;

	for (usz i=0; i<ITERATIONS; i++) {}

    term::printn(termHandle, "Child ended")!!;
    return 0;
}
