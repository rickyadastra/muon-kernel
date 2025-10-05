module dev::timing;

import datetime;
import muon::logging;
import arch::cpu;
import arch::interrupts;
import arch::mem;
import dev::timing::hpet @public;
import dev::interrupts::apic @public;
import std::collections::linkedlist;

uint128? wallclock @local = WALLCLOCK_NOT_SET?;

// timer subsystem
Timer timer @local;
LinkedList{TimerEvent} timerEvents @local;

fn void get_wallclock_callback(ulong irq) {
    if (try utime = rtc::get_datetime().seconds_since_epoch()) {
        logging::debug("Wallclock set to %d", utime);
        wallclock = utime;
    }

    rtc::acknoledge_interrupt();
    rtc::disable_update_interrupt();
}

fn double get_tsc_frequency_with_hpet() @local {
    ulong hpetStart = hpet::get_counter();
    ulong hpetDelta = hpet::@femto_to_ticks((usz)10e12);
    
    ulong tscStart = cpu::read_tsc();
    while (hpet::get_counter() <= hpetStart+hpetDelta) arch::cpu::pause();
    ulong tscEnd = cpu::read_tsc();

    ulong tscDelta = tscEnd-tscStart;
    return (tscDelta * hpet::frequency) / (double)hpetDelta;
}

fn void setup_tsc_deadline_timer(double frequency) {
    // set up apic timer in tsc-deadline
    apic::timer_enable(APICTimerMode.TSC_DEADLINE);

    // set timer interface
    APICTscTimer* apicTimer = (APICTscTimer*)mem::alloc(APICTscTimer.sizeof);
    apicTimer.frequency = frequency;
    timer = (Timer)apicTimer;
    timerEvents = linkedlist::init{TimerEvent}(mem::get_allocator());
}

fn void? calibrate() {   
    if (!cpuid::query_tsc_deadline_support()!) return TIMER_UNSUPPORTED?;

    double tscFrequency = get_tsc_frequency_with_hpet();
    logging::debug("TSC frequency: %f GHz", tscFrequency / 1e9);

    setup_tsc_deadline_timer(tscFrequency);
}

fn void? add_timer_event(TimerEvent event) @private {
    if (timerEvents.is_empty()) {
        timerEvents.add(event);
    } else {
        usz i = 0;
        while (try e = timerEvents.get(i) && e.timestamp < event.timestamp) i++;
        timerEvents.insert_at(i, event)!;
    }
}

fn void? serve_timer_events(ulong currentTime) @private {
    while (try e = timerEvents.first() && e.timestamp <= currentTime) {
        timerEvents.remove_at(0)!!;
        e.callback(&timer);
    }
}

fn void schedule_nano(ulong nano, TimerCallbackFn callback) {
    ulong deltaTicks = (ulong) (nano * (timer.get_frequency() / 1e9));
    ulong time = cpu::read_tsc()+deltaTicks;

    add_timer_event({time, callback})!!;
    if (try event = timerEvents.first() && event.timestamp >= time) timer.set(time);
}

fn void schedule_micro(ulong micro, TimerCallbackFn callback) => schedule_nano(micro * 1_000, callback);
fn void schedule_milli(ulong milli, TimerCallbackFn callback) => schedule_nano(milli * 1_000_000, callback);

fn InterruptStack* timer_fired(InterruptStack* stack) @private {
    ulong curTime = cpu::read_tsc();
    logging::debug("Timer fired! %d events waiting. Time is %d", timerEvents.size, curTime);

    serve_timer_events(curTime)!!;
    if (try event = timerEvents.first() && event.timestamp > curTime) timer.set(event.timestamp); 

    return stack;
}
