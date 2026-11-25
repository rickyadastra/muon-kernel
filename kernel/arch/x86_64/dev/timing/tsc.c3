module dev::timing::tsc;

import arch::cpu, arch::mem;
import dev::timing @public, dev::timing::hpet @public;
import muon::log;

struct TscTimeSource (TimeSource) {
	double frequency;
}

fn KernelTime TscTimeSource.read(&self) @dynamic => cpu::read_tsc();

TscTimeSource* tscSource @private;

fn double get_tsc_frequency_with_hpet() {
    ulong hpetStart = hpet::hpetSource.read();
    ulong hpetDelta = hpet::@femto_to_ticks((usz)10e12);
    
    ulong tscStart = cpu::read_tsc();
    while (hpet::hpetSource.read() <= hpetStart+hpetDelta) arch::cpu::pause();
    ulong tscEnd = cpu::read_tsc();

    ulong tscDelta = tscEnd-tscStart;
    return (tscDelta * hpet::hpetSource.frequency) / (double)hpetDelta;
}

fn bool init_tsc_timesource() {
	tscSource = (TscTimeSource*)mem::alloc(TscTimeSource::size);
	tscSource.frequency = get_tsc_frequency_with_hpet();
    log::debug("TSC frequency: %f GHz", tscSource.frequency / 1e9);

	timing::timeSource = tscSource;
	timing::bootTime = tscSource.read();

	return true;
}
