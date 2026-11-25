module dev::timing::apic_timer;

import muon::log;
import arch::cpu;
import arch::interrupts;
import arch::mem;
import dev::timing::tsc @public;
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
	if (tsc::tscSource == null) return false;

    setup_tsc_deadline_timer(tsc::tscSource.frequency);

	return true;
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
