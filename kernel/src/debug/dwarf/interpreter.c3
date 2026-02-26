module muon::debug::dwarf;

faultdef UNKNOWN_INSTRUCTION, UNKNOWN_RULE, UNKNOWN_CFA;

fn ulong decode_uleb128(char** ptr) @private {
    ulong result;
    uint shift;

    while (true) {
        char byte = **ptr;
        (*ptr)++;
        result |= (ulong)(byte & 0x7F) << shift;
        if ((byte & 0x80) == 0) break;
        shift += 7;
    }

    return result;
}

fn long decode_sleb128(char** ptr) @private {
    long result;
    uint shift;
    char byte;

    while (true) {
        byte = **ptr;
        (*ptr)++;
        result |= (ulong)(byte & 0x7F) << shift;
        shift += 7;
        if ((byte & 0x80) == 0) break;
    }

    if (shift < 64 && (byte & 0x40)) result |= (long)-(1 << shift);
    
    return result;
}

macro bool @dwarf_cfa_advance_loc1(UnwindVmState* #state, OpCode #op, char* #p, ulong #ip) @local {
	return @dwarf_cfa_advance_loc_internal(#state, #ip, *#p++);
}

macro bool @dwarf_cfa_advance_loc2(UnwindVmState* #state, OpCode #op, char* #p, ulong #ip) @local {
	char low = *#p++;
	char high = *#p++;
	ushort off = ((ushort)high << 8) | low;

	return @dwarf_cfa_advance_loc_internal(#state, #ip, off);
}

macro @dwarf_def_cfa_offset(UnwindVmState* #state, OpCode #op, char* #p) @local {
	long operand = decode_uleb128(&#p);
	#state.cfa.offset = operand;
}

macro bool @dwarf_cfa_advance_loc(UnwindVmState* #state, OpCode #op, char* #p, ulong #ip) @local {
	return @dwarf_cfa_advance_loc_internal(#state, #ip, #op.low);
}
 
macro bool @dwarf_cfa_advance_loc_internal(UnwindVmState* #state, ulong #ip, #off) @local {
	if (#ip != 0 && #state.loc + (uptr)#off*CODE_ALIGN > #ip) return false;
	#state.loc += (uptr)#off*CODE_ALIGN;
	return true;
}

macro @dwarf_cfa_offset(UnwindVmState* #state, OpCode #op, char* #p) @local {
	RegId reg = (RegId)#op.low;
	char off = *#p++;

	#state.regs[reg].kind = RegRuleKind.OFFSET;
	#state.regs[reg].offset = off*(-8);
}

macro @dwarf_def_cfa(UnwindVmState* #state, OpCode #op, char* #p) @local {
	#state.cfa.reg = (RegId)*#p++;
	#state.cfa.offset = *#p++;
}

<*
	@param[&in] program
*>
fn void? UnwindVmState.execute(&state, char* program, usz programLen, uptr targetIp) @private {
	char* p = program;
	char* end = program+programLen;

	// If targetIp is null, execute all instructions
	while LOOP: (p < end && (targetIp == 0 || state.loc < targetIp)) {
		OpCode op = (OpCode)*p++;

		switch OUTER: {
			case op == Instruction.NO_OP.opcode:
				break; 

			case op.primary == Instruction.CFA_OFFSET.opcode.primary:
				@dwarf_cfa_offset(state, op, p);

			case op.primary == Instruction.CFA_ADVANCE_LOC.opcode.primary:
				if (!@dwarf_cfa_advance_loc(state, op, p, targetIp)) break LOOP;

			default:
				switch (op) {
					case Instruction.DEF_CFA.opcode:
						@dwarf_def_cfa(state, op, p);

					case Instruction.DEF_CFA_OFFSET.opcode:
						@dwarf_def_cfa_offset(state, op, p);

					case Instruction.CFA_ADVANCE_LOC1.opcode:
						if (!@dwarf_cfa_advance_loc1(state, op, p, targetIp)) break LOOP;

					case Instruction.CFA_ADVANCE_LOC2.opcode:
						if (!@dwarf_cfa_advance_loc2(state, op, p, targetIp)) break LOOP;

					default:
						return UNKNOWN_INSTRUCTION?;
				}
		}
	}
}

<*
	@require state.initialised == false
*>
fn void? UnwindVmState.init(&state, CieData data) {
	state.execute(data.instructions, data.instructionsLen, 0)!;
	state.initialised = true;
}

<*
	@require state.initialised == true
*>
fn void? UnwindVmState.unwind_one(&state, uptr ip) {
	FdeData data = dwarf::find_fde(ip)!;
	state.loc = data.initialLocation;
	state.execute(data.instructions, data.instructionsLen, ip)!;
}
