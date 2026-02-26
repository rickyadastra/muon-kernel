module muon::debug;

import arch;
import muon::debug::dwarf;
import muon::logging;
import muon::symbols;

faultdef UNWIND_FAIL;

uptr tableAddr @private;
usz tableSize @private;
UnwindVmState initState @local;
CieData kernelCie @local;

<*
	@param[&in] tablePtr
	@require tableSz > 0
*>
fn void? init(char* tablePtr, uptr tableSz) {
	tableAddr = (uptr)tablePtr;
	tableSize = tableSz;

	// Find CIE and initialize vm state
	kernelCie = dwarf::find_cie()!;
	initState.init(kernelCie)!;
}

fn void? print_backtrace(uptr ip, uptr sp, usz frames = 5) {
	SymbolResult res;
	uptr _ip = ip;
	uptr _sp = sp;

	cpu::disable_interrupts();
	defer cpu::enable_interrupts();

	do {
		res = symbols::resolve(_ip);
		logging::printn("  [%x] %s+%x", _ip, res.name, (ushort)res.offset);

		UnwindVmState vmState = initState;
		if (catch ex = vmState.unwind_one(_ip)) {
			return UNWIND_FAIL?;
		}

		vmState.resolve_frame(&_ip, &_sp)!;
		frames--;

	} while (_ip != 0 && frames != 0);
}
