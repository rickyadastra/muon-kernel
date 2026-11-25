module dev::timing::apic_timer;

import muon::log;
import arch::cpu;
import arch::interrupts;
import arch::mem;
import dev::timing::hpet @public;
import dev::interrupts::apic @public;
import std::collections::linkedlist;

// ---------- APIC TSC Timer definition -----------------------

struct APICTscTimer (Timer) {
    double frequency;
}

fn void APICTscTimer.set(&self, KernelTime time) @dynamic {
    cpu::write_msr(ModelSpecificRegister.TSC_DEADLINE, time);
}

fn void APICTscTimer.cancel(&self) @dynamic {
    cpu::write_msr(ModelSpecificRegister.TSC_DEADLINE, 0); // writing 0 disarms the local-APIC timer
}

fn double APICTscTimer.get_frequency(&self) @dynamic {
    return self.frequency;
}

fn KernelTime APICTscTimer.get_current(&self) @dynamic @inline {
    return cpu::read_tsc();
}

// ---------- TSC Deadline mode functions ---------------------

macro bool? check_tsc_deadline_support() @local {
	bool b = cpuid::query_feature(CPUFeature.TSC_DEADLINE_SUPPORT)!;
	if (!b) log::warn("TSC Deadline mode is unsupported!");
	return b;
}

macro bool? calibrate_tsc_deadline() {
	if (!check_tsc_deadline_support()!) return false;

	double tscFrequency = get_tsc_frequency_with_hpet();
    log::debug("TSC frequency: %f GHz", tscFrequency / 1e9);

    setup_tsc_deadline_timer(tscFrequency);
	timing::bootTime = cpu::read_tsc();

	return true;
}

fn double get_tsc_frequency_with_hpet() {
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
    APICTscTimer* apicTimer = (APICTscTimer*)mem::alloc(APICTscTimer::size);
    apicTimer.frequency = frequency;
    timing::timer = (Timer)apicTimer;
    timing::timerEvents = linkedlist::init{TimerEvent*}(mem::get_allocator());
}
