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

fn void? calibrate() {
	if (apic_timer::calibrate_tsc_deadline()!) return;

	return TIMER_UNSUPPORTED~;
}

fn InterruptStack* timer_fired(InterruptStack* stack) @private {
    KernelTime curTime = timer.get_current();
    log::debug("Timer fired! %d events waiting. Time is %d", timerEvents.size, curTime);

    InterruptStack** stackPtr = &stack;
    serve_timer_events(curTime, stackPtr)!!;
    if (try event = timerEvents.first() && event.timestamp > curTime) timer.set(event.timestamp); 

    return *stackPtr;
}
