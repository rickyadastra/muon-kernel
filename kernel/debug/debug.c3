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
