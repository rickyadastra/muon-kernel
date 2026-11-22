module muon::debug;

import muon::boot, muon::log, muon::debug::dwarf;

const sz MAX_UNWIND_FRAMES = 32;

struct FrameUnwindInfo {
	uptr pc;
	uptr sp;
}

char[] ehFrame @local;
CieData cieData @local;

fn void? init(DebugInfoContext debugCtx) {
	ehFrame = ((char*)(uptr)debugCtx.unwindTable)[:debugCtx.unwindTableSize];
	cieData = dwarf::find_cie(ehFrame)!;

	log::debug("CIE found: codeAlign=%d, dataAlign=%d, raReg=%d, aug=\"%s\", augData=%x",
		cieData.codeAlignFactor, cieData.dataAlignFactor, cieData.returnAddrReg, 
		cieData.aug, cieData.augData);
	
	dwarf::validate_cie(cieData);
	log::debug("CIE validation passed");
}

macro usz? @unwind_frames(FrameUnwindInfo[MAX_UNWIND_FRAMES] #frameUnwindInfo, uptr pc, uptr sp) @private {
	if (cieData.instructions.ptr == null) {
		log::error("Debug info not found/not initialized, cannot unwind stack!!");
		return 0;
	}

	usz frames = 0;

	do {
		#frameUnwindInfo[frames++] = { pc, sp };

		// find FDE for pc
		log::trace("Searching FDE for PC %x", pc);
		FdeData? fdeData = dwarf::find_fde(ehFrame, pc);
		if (catch fdeData) break; // abort on no FDE found

		log::debug("FDE found for %x: range=%x:%x, instrs=%d",
			pc, fdeData.initialLocation, fdeData.initialLocation+fdeData.locationRange, fdeData.instructions.len);

		// init frame state with CIE and FDE's initial loc
		FrameState state;
		state.curPc = fdeData.initialLocation;
		state.execute(cieData.instructions)!;
		state.execute(fdeData.instructions, pc)!;

		log::debug("Frame state is cfaReg=%d, cfaOffset=%x, loc=%x", 
			state.cfaReg, state.cfaOffset, state.curPc);
		
		// update pc to new frame
		state.update_to_next_frame(&pc, &sp)!;
		log::debug("Next frame is PC=%x, SP=%x", pc, sp);

		if (pc == 0) break; // abort on entry point reached
		pc -= 1;
	} while (frames < MAX_UNWIND_FRAMES);

	return frames;
}

fn void print_backtrace_from(uptr pc, uptr sp) {
	FrameUnwindInfo[MAX_UNWIND_FRAMES] frameUnwindInfo;
	usz frames = @unwind_frames(frameUnwindInfo, pc, sp)!!;

	foreach (sz i, FrameUnwindInfo fui : frameUnwindInfo[:frames]) {
		SymbolResult res = resolve_symbol(fui.pc);

		log::printn("  #%d: [%x] %s+%d", i, fui.pc, res.name, res.offset);
	}
}

macro void print_backtrace(uptr pc = 0, uptr sp = 0) {
	$if $defined(@capture_frame):
		if (pc == 0 || sp == 0) @capture_frame(pc, sp);
	$endif

	print_backtrace_from(pc, sp);
}
