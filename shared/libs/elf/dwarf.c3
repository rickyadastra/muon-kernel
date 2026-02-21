module elf::dwarf;

import muon::logging;

macro Unwinder create_unwinder(uptr tableAddr, usz tableSize) => (Unwinder){tableAddr, tableSize};

macro bool Header.is_cie(self) => self.cieId == 0; 

fn UnwindedFrame? Unwinder.unwind_one(self, ulong ip, ulong sp) {
	Header* hdr = (Header*)self.table;
	UnwindState state;

	// logging::printn("Looking for IP: %x", ip);

	for (usz i=0; (uptr)hdr < self.table+self.tableSize; i++) {
		if (hdr.is_cie()) {
			CommonInfoEntry* entry = (CommonInfoEntry*)hdr;

			usz len;
			for (len=0; entry.augmentation[len]!='\0'; len++);
			String aug = (String)entry.augmentation[:len];

			char codeAlignFactor = (char)decode_uleb128(&&(char*)((uptr)entry + CommonInfoEntry.sizeof + aug.len + 1));
			ichar dataAlignFactor = (ichar)decode_sleb128(&&(char*)((uptr)entry + CommonInfoEntry.sizeof + aug.len + 2));
			RegId returnAddrReg = (RegId)decode_uleb128(&&(char*)((uptr)entry + CommonInfoEntry.sizeof + aug.len + 3));
			ushort augData = (((ushort)*(char*)((uptr)entry + CommonInfoEntry.sizeof + aug.len + 4)) << 8) |
				*(char*)((uptr)entry + CommonInfoEntry.sizeof + aug.len + 5);
			char* instructions = (char*)((uptr)entry + CommonInfoEntry.sizeof + aug.len + 6);
			usz instructionsLen = hdr.length - (instructions-(char*)entry) + 4;

			assert(codeAlignFactor == CODE_ALIGN);
			assert(dataAlignFactor == DATA_ALIGN);
			assert(returnAddrReg == RETURN_ADDR);
			assert(aug == AUGS);
			assert(augData == AUG_DATA);

			// logging::printn("CIE: {len: %d, id: %d, ver: %d, aug: \"%s\", codeAlign: %d, dataAlign: %d, retAddrReg: %x, augData: %x}", 
			// 	entry.length, entry.cieId, entry.version, aug, codeAlignFactor, dataAlignFactor, returnAddrReg, augData);
			
			init_vm(&state, instructions, instructionsLen);

		} else {
			FrameDescriptionEntry* entry = (FrameDescriptionEntry*)hdr;
			uptr initialLocation = (uptr)&entry.initialLocation + (int)entry.initialLocation;
			char* instructions = (char*)((uptr)entry + FrameDescriptionEntry.sizeof);
			usz instructionsLen = hdr.length - (instructions-(char*)entry) + 4;

			if (ip >= initialLocation && ip < initialLocation + entry.addrRange) {
				// logging::printn("FDE@%x: {len: %d, offset: %d, begin: %x, range: %x}", 
				// 	entry, entry.length, entry.cieOffset, initialLocation, entry.addrRange);
			
				run_vm(&state, instructions, instructionsLen, initialLocation, ip, sp);
				
				ulong cfa, nextIp, nextSp;

				switch {
					case state.cfa.reg == RegId.RSP: cfa = sp;
					case state.cfa.reg == RegId.RIP: cfa = ip;
					default: logging::panic("Unexpected CFA");
				}

				cfa += state.cfa.offset;
				nextSp = cfa;
				
				if (state.regs[RegId.RIP].kind == RegRuleKind.OFFSET) {
					nextIp = *(ulong*)(cfa + state.regs[RegId.RIP].offset);
				} else {
					logging::panic("Unexpected Kind for RIP register rule");
				}

				// logging::printn("Unwinded frame: IP: %x, SP: %x", nextIp, nextSp);
				return (UnwindedFrame){ nextIp, nextSp };
			}

		}

		hdr = (Header*)((uptr)hdr + hdr.length + Header.length.sizeof);
	}

	return UNWIND_FAIL?;
}

fn void Unwinder.unwind(self, ulong ip, ulong sp, usz frames = 5) {
	ulong _ip = ip;
	ulong _sp = sp;
	
	logging::printn("[%x] SP: %x", _ip, _sp);

	while (_ip != 0 && frames != 0) {
		UnwindedFrame? frame = self.unwind_one(_ip, _sp);
		if (catch ex = frame) {
			logging::printn("Error during unwind: %s", ex.nameof);
			return;
		} 

		_ip = frame.ip;
		_sp = frame.sp;

		logging::printn("  [%x] SP: %x", _ip, _sp);
	}
}

<*
	@param[&inout] state
	@param[&in] instr
	@require state.initialised == false
*>
fn void init_vm(UnwindState* state, char* instr, usz instrLen) @local {
	char* p = instr;
	char* end = instr+instrLen;

	// @print_debug_state(state);

	while (p < end) {
		OpCode op = (OpCode)*p++;

		switch {
			case op == Instruction.NO_OP.opcode:
				break; 

			case op.primary == Instruction.CFA_OFFSET.opcode.primary:
				@dwarf_cfa_offset(state, op, p);

			default:
				switch (op) {
					case Instruction.DEF_CFA.opcode:
						@dwarf_def_cfa(state, op, p);
					
					default:
						logging::printn("Unexpected instruction %d", op);
						break;
				}
		}
	}

	// @print_debug_state(state);

	state.initialised = true;
}

<*
	@param[&inout] state
	@param[&in] instr
	@require state.initialised == true
*>
fn void run_vm(UnwindState* state, char* instr, usz instrLen, uptr initialLoc, ulong ip, ulong sp) @local {
	char* p = instr;
	char* end = instr+instrLen;

	state.loc = initialLoc;

	// @print_debug_state(state);

	while LOOP: (p < end && state.loc < ip) {
		OpCode op = (OpCode)*p++;

		switch OUTER: {
			case op == Instruction.NO_OP.opcode:
				break; 

			case op.primary == Instruction.CFA_OFFSET.opcode.primary:
				@dwarf_cfa_offset(state, op, p);

			case op.primary == Instruction.CFA_ADVANCE_LOC.opcode.primary:
				if (!@dwarf_cfa_advance_loc(state, op, p, ip)) break LOOP;

			default:
				switch (op) {
					case Instruction.DEF_CFA.opcode:
						@dwarf_def_cfa(state, op, p);

					case Instruction.DEF_CFA_OFFSET.opcode:
						@dwarf_def_cfa_offset(state, op, p);

					case Instruction.CFA_ADVANCE_LOC1.opcode:
						if (!@dwarf_cfa_advance_loc1(state, op, p, ip)) break LOOP;

					case Instruction.CFA_ADVANCE_LOC2.opcode:
						if (!@dwarf_cfa_advance_loc2(state, op, p, ip)) break LOOP;

					default:
						logging::printn("Unexpected instruction %x", op);
						break OUTER;
				}
		}
	}

	// @print_debug_state(state);
}

macro bool @dwarf_cfa_advance_loc1(UnwindState* #state, OpCode #op, char* #p, ulong #ip) @local {
	return @dwarf_cfa_advance_loc_internal(#state, #ip, *#p++);
}

macro bool @dwarf_cfa_advance_loc2(UnwindState* #state, OpCode #op, char* #p, ulong #ip) @local {
	char low = *#p++;
	char high = *#p++;
	ushort off = ((ushort)high << 8) | low;

	return @dwarf_cfa_advance_loc_internal(#state, #ip, off);
}

macro @dwarf_def_cfa_offset(UnwindState* #state, OpCode #op, char* #p) @local {
	long operand = decode_uleb128(&#p);
	#state.cfa.offset = operand;
}

macro bool @dwarf_cfa_advance_loc(UnwindState* #state, OpCode #op, char* #p, ulong #ip) @local {
	return @dwarf_cfa_advance_loc_internal(#state, #ip, #op.low);
}
 
macro bool @dwarf_cfa_advance_loc_internal(UnwindState* #state, ulong #ip, #off) @local {
	if (#state.loc + (uptr)#off*CODE_ALIGN > #ip) return false;
	#state.loc += (uptr)#off*CODE_ALIGN;
	return true;
}

macro @dwarf_cfa_offset(UnwindState* #state, OpCode #op, char* #p) @local {
	RegId reg = (RegId)#op.low;
	char off = *#p++;

	#state.regs[reg].kind = RegRuleKind.OFFSET;
	#state.regs[reg].offset = off*(-8);
}

macro @dwarf_def_cfa(UnwindState* #state, OpCode #op, char* #p) @local {
	#state.cfa.reg = (RegId)*#p++;
	#state.cfa.offset = *#p++;
}

macro @print_debug_state(UnwindState* #state) {
	logging::printn("UnwindState@%x", #state);
	logging::printn("  LOC: %x", #state.loc);
	logging::printn("  CFA: reg=%d, offset=%d", #state.cfa.reg, #state.cfa.offset);
	logging::printn("  RSP: kind=%d, offset=%d", #state.regs[RegId.RSP].kind, #state.regs[RegId.RSP].offset);
	logging::printn("  RIP: kind=%d, offset=%d", #state.regs[RegId.RIP].kind, #state.regs[RegId.RIP].offset);
	logging::newline();
}
