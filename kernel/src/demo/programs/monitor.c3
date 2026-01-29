module muon::demo::programs;

import muon;
import process;
import string;
import datetime;
import dev;

const String SPACER = "            ";

fn int monitor(SpawnInfo* info) {
    Handle termHandle = info.auxHandles[0];
    Handle monitorHandle = info.auxHandles[1];
    logging::printn("Monitor program started");
    
	Formatter formatter;
    TaskSnapshot[10] snap;
	TaskSnapshot[] res = monitor::fetch(monitorHandle, &&snap[..])!!;

	@print_header(termHandle, formatter);

	foreach (i, r : res) {
		@print_int(termHandle, formatter, r.id);
		@print_string(termHandle, formatter, r.state.nameof);

		if (r.state == RUNNING) {
			@print_double_ast(termHandle, formatter, timing::ticks_to_milli(timing::get_ticks() - r.timeOfLastSchedule));
		} else {
			@print_double(termHandle, formatter, timing::ticks_to_milli(r.timeTotalBurst));
		}

		@print_int(termHandle, formatter, r.references);
		@print_bool(termHandle, formatter, r.hasPendingEvent);
		@print_bool(termHandle, formatter, r.hasAwaitingTask);
		term::printn(termHandle, r.command)!!;
	}

    logging::printn("Monitor program exited");
    return 0;
}

macro @print_header(#termHandle, #formatter) {
    @print_string(#termHandle, #formatter, "ID");
    @print_string(#termHandle, #formatter, "State");
    @print_string(#termHandle, #formatter, "Time (ms)");
    @print_string(#termHandle, #formatter, "References");
    @print_string(#termHandle, #formatter, "Event?");
    @print_string(#termHandle, #formatter, "Awaited?");
    @print_string(#termHandle, #formatter, "Command");
	term::print_newline(#termHandle)!!;
}

macro @print_int(#termHandle, #formatter, #field) => @print_field(#termHandle, #formatter, "%d", #field);
macro @print_double_ast(#termHandle, #formatter, double #field) => @print_field(#termHandle, #formatter, "%f*", #field);
macro @print_double(#termHandle, #formatter, double #field) => @print_field(#termHandle, #formatter, "%f", #field);
macro @print_bool(#termHandle, #formatter, bool #field) => @print_field(#termHandle, #formatter, "%s", (#field) ? "yes" : "no");
macro @print_string(#termHandle, #formatter, String #field) => @print_field(#termHandle, #formatter, "%s", #field);

macro @print_field(#termHandle, #formatter, #format, #field) {
	String s = #formatter.format(#format, #field)!!;
	term::print(#termHandle, s)!!;
	term::print(#termHandle, SPACER[:SPACER.len-s.len])!!;
}
