module muon::debug::dwarf;

const char CODE_ALIGN @private = 1;
const ichar DATA_ALIGN @private = -8;
const RegId RETURN_ADDR @private = RegId.RIP;
const String AUGS @private = "zR";
const ushort AUG_DATA @private = 0x011b;

const usz MAX_DWARF_REG = 17;

enum RegId : const inline char {
    RBP = 6,
    RSP = 7,
    RIP = 16,
}

fn void? UnwindVmState.resolve_frame(&state, uptr* ip, uptr* sp) {
	ulong cfa;

	switch {
		case state.cfa.reg == RegId.RSP: cfa = *sp;
		case state.cfa.reg == RegId.RIP: cfa = *ip;
		default: return UNKNOWN_CFA?;
	}

	cfa += state.cfa.offset;
	*sp = cfa;
	
	if (state.regs[RegId.RIP].kind == RegRuleKind.OFFSET) {
		*ip = *(ulong*)(cfa + state.regs[RegId.RIP].offset);
	} else {
		return UNKNOWN_RULE?;
	}
}
