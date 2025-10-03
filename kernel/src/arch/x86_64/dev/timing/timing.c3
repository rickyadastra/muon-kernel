module dev::timing;

import datetime;
import muon::logging;
import arch::cpu;
import dev::timing::hpet @public;

uint128? wallclock @local = WALLCLOCK_NOT_SET?;
double tscFrequency @local;

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

fn void? calibrate() {
    tscFrequency = get_tsc_frequency_with_hpet();
    logging::printn("TSC freq: %f GHz", tscFrequency / 1e9);

    if (cpuid::query_tsc_deadline_support()!) {
        logging::printn("supported");
    }
}