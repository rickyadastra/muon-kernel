module muon::debug;

import muon::boot, muon::log, muon::debug::dwarf;

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

fn void? unwind_from(uptr pc, uptr sp) {
	if (cieData.instructions.ptr == null) {
		log::error("Debug info not found/not initialized, cannot unwind stack!!");
		return;
	}

	log::trace("Searching FDE for PC %x", pc);
	FdeData fdeData = dwarf::find_fde(ehFrame, pc)!;

	log::debug("FDE found for %x: range=%x:%x, instrs=%d",
		pc, fdeData.initialLocation, fdeData.initialLocation+fdeData.locationRange, fdeData.instructions.len);
	
	FrameState state;
	state.curPc = fdeData.initialLocation;

	state.execute(cieData.instructions)!;
	state.execute(fdeData.instructions, pc)!;

	log::debug("Frame state is cfaReg=%d, cfaOffset=%x, loc=%x", 
		state.cfaReg, state.cfaOffset, state.curPc);
	
	state.update_to_next_frame(&pc, &sp)!;
	log::debug("Next frame is PC=%x, SP=%x", pc, sp);
}
