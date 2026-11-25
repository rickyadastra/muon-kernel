module dev::timing;

import muon::log;
import arch::mem, arch::interrupts;

import std::collections::linkedlist;

fn void get_wallclock_callback(ulong irq) {
    if (try utime = rtc::get_datetime().seconds_since_epoch()) {
        log::debug("Wallclock set to %d", utime);
        wallclock = utime;
    }

    timing::schedule_milli(1000, &increment_time_sources);

    rtc::acknoledge_interrupt();
    rtc::disable_update_interrupt();
}

fn void increment_time_sources(TimerEvent* event) @local {
    if (try wallclock) log::debug("Wallclock updated to %d", (ulong)++wallclock);
    timing::schedule_milli(1000, &increment_time_sources, since: event.timestamp);
}

fn void? init_timesource() @local {
	if (tsc::init_tsc_timesource()) return;
	return NO_SUPPORTED_TIMESOURCE~;
}

fn void? calibrate_timer() @local {
	if (apic_timer::calibrate_tsc_deadline()!) return;
	if (apic_timer::calibrate_oneshot()!) return;
	return NO_SUPPORTED_TIMER~;
}

<*
@ensure timeSource != null
@ensure bootTime != 0
@ensure timer != null
*>
fn void? init() {
	init_timesource()!;
	calibrate_timer()!;

	// init timer events list
	timing::timerEvents = linkedlist::init{TimerEvent*}(mem::get_allocator());
}

fn InterruptStack* timer_fired(InterruptStack* stack) @private {
    KernelTime curTime = timeSource.read();
    log::debug("Timer fired! %d events waiting. Time is %d", timerEvents.size, curTime);

    InterruptStack** stackPtr = &stack;
    serve_timer_events(curTime, stackPtr)!!;
    if (try event = timerEvents.first() && event.timestamp > curTime) timer.set(event.timestamp, timeSource); 

    return *stackPtr;
}
