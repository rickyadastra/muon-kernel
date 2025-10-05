module dev::timing;

import datetime;
import muon::logging;
import arch::cpu;
import arch::interrupts;
import arch::mem;
import dev::timing::hpet @public;
import dev::interrupts::apic @public;
import std::collections::linkedlist;

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

fn InterruptStack* timer_fired(InterruptStack* stack) @private {
    ulong curTime = cpu::read_tsc();
    logging::debug("Timer fired! %d events waiting. Time is %d", timerEvents.size, curTime);

    serve_timer_events(curTime)!!;
    if (try event = timerEvents.first() && event.timestamp > curTime) timer.set(event.timestamp); 

    return stack;
}
