module muon::debug::dwarf;

import muon::log;

faultdef UNKNOWN_INSTRUCTION;

fn void? FrameState.execute(&state, char[] instrs, ulong stopAt = 0) {
	char* cur = instrs.ptr;
	while LOOP: (cur < instrs.ptr + instrs.len) {
		char* p = cur;
		OpCode op = (OpCode)*cur++;

		switch OUTER: {
			case op == Op.NOP.code:
				log::trace("Executed NOP (%x) @ %x", (char)op, p);
				break;

			case op.high == Op.OFFSET.code.high:
				ulong reg = (ulong)op.low;
				ulong off = read_uleb128(&cur);
				log::trace("Executed OFFSET (%x) @ %x, reg=%d, off=%d", (char)op, p, reg, off);
				state.regOffset[reg] = off * EXPECTED_DATA_ALIGN;
				state.savedMask |= (1ul << reg);

			case op.high == Op.ADVANCE_LOC.code.high:
				char delta = op.low;
				log::trace("Executed ADVANCE_LOC (%x) @ %x, delta=%d", (char)op, p, delta);
				state.curPc += (uptr)(delta * EXPECTED_CODE_ALIGN);

			case op == Op.DEF_CFA.code:
				ulong reg = read_uleb128(&cur);
				ulong off = read_uleb128(&cur);
				log::trace("Executed DEF_CFA (%x) @ %x, reg=%d, off=%d", (char)op, p, reg, off);
				state.cfaReg = reg;
				state.cfaOffset = off;

			case op == Op.DEF_CFA_OFFSET.code:
				ulong off = read_uleb128(&cur);
				log::trace("Executed DEF_CFA_OFFSET (%x) @ %x, off=%d", (char)op, p, off);
				state.cfaOffset = off;

			case op == Op.ADVANCE_LOC1.code:
				char delta = (char)*cur++;
				log::trace("Executed ADVANCE_LOC1 (%x) @ %x, delta=%d", (char)op, p, delta);
				state.curPc += (uptr)(delta * EXPECTED_CODE_ALIGN);

			case op == Op.ADVANCE_LOC2.code:
				char l = *cur++;
				char h = *cur++;
				ushort delta = ((ushort)h << 8) | l;
				log::trace("Executed ADVANCE_LOC2 (%x) @ %x, delta=%d", (char)op, p, delta);
				state.curPc += (uptr)(delta * EXPECTED_CODE_ALIGN);

			default:
				log::trace("Unknown op '%x' @ %x", (char)op, p);
				return UNKNOWN_INSTRUCTION~;
		}
	}
}
