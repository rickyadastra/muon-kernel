module dev::timing::apic_timer;

import muon::log;
import arch::cpu;
import arch::interrupts;
import arch::mem;
import dev::timing::tsc @public, dev::interrupts::apic @public, dev::timing::hpet @public;

import std::math, std::collections::linkedlist;

// ---------- APIC One Shot Timer definition ------------------

struct APICOneShotTimer (Timer) {
	double frequency;
}

fn void APICOneShotTimer.set(&self, KernelTime time) @dynamic {
	uint _time = (uint)math::min((ulong)uint::max, time);
	apic::@lapic_write(LAPICRegister.TIMER_INITIAL_COUNT, _time);
}

fn void APICOneShotTimer.cancel(&self) @dynamic {
	apic::@lapic_write(LAPICRegister.TIMER_INITIAL_COUNT, 0);
}

fn double APICOneShotTimer.get_frequency(&self) @dynamic {
	return self.frequency;
}

fn KernelTime APICOneShotTimer.get_current(&self) @dynamic {
	return apic::@lapic_read(LAPICRegister.TIMER_CURRENT_COUNT);
}

// ---------- TSC Deadline mode functions ---------------------

macro double get_apic_timer_frequency() {
	ulong hpetStart = hpet::hpetSource.read();
    ulong hpetDelta = hpet::@femto_to_ticks((usz)10e12);
    
	apic::@lapic_write(LAPICRegister.TIMER_INITIAL_COUNT, uint::max);

    while (hpet::hpetSource.read() <= hpetStart+hpetDelta) arch::cpu::pause();
    uint timerEnd = apic::@lapic_read(LAPICRegister.TIMER_CURRENT_COUNT);

    ulong delta = (ulong)(uint::max - timerEnd);
    double freq = (delta * hpet::hpetSource.frequency) / (double)hpetDelta;

	log::debug("Bus/Core frequency for LAPIC timer is %f (%d ticks elapsed)", freq, delta);

	return freq;
}

fn bool? calibrate_oneshot() {
	// set up apic timer in oneshot, masked
	apic::timer_enable(APICTimerMode.ONESHOT, true);
	apic::timer_set_divisor(TimerDivideConfig.DIVIDE_1);

	// set timer interface
	APICOneShotTimer* apicTimer = (APICOneShotTimer*)mem::alloc(APICOneShotTimer::size);
	apicTimer.frequency = get_apic_timer_frequency();
	timing::timer = (Timer)apicTimer;

	// reset timer and unmask
	apicTimer.cancel();
	apic::timer_enable(APICTimerMode.ONESHOT);
	return true;
}

// ---------- APIC TSC Timer definition -----------------------

struct APICTscTimer (Timer) {
    double frequency;
}

fn void APICTscTimer.set(&self, KernelTime time) @dynamic {
    cpu::write_msr(ModelSpecificRegister.TSC_DEADLINE, time);
}

fn void APICTscTimer.cancel(&self) @dynamic {
	// writing 0 disarms the local-APIC timer
    cpu::write_msr(ModelSpecificRegister.TSC_DEADLINE, 0); 
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

fn bool? calibrate_tsc_deadline() {
	if (!check_tsc_deadline_support()!) return false;
	if (tsc::tscSource == null) return false;

	// set up apic timer in tsc-deadline
	apic::timer_enable(APICTimerMode.TSC_DEADLINE);

	// set timer interface
	APICTscTimer* apicTimer = (APICTscTimer*)mem::alloc(APICTscTimer::size);
	apicTimer.frequency = tsc::tscSource.frequency;
	timing::timer = (Timer)apicTimer;

	return true;
}
