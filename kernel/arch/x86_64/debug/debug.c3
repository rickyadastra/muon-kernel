module muon::debug;

macro @capture_frame(uptr #pc, uptr #sp) {
	uptr pc, sp;
	asm("leaq 0(%rip), %rax");
	asm {
		movq pc, $rax;
		movq sp, $rsp;
	}

	if (#pc == 0) #pc = pc;
	if (#sp == 0) #sp = sp;
}

module muon::debug::dwarf;

const char EXPECTED_CODE_ALIGN = 1;
const ichar EXPECTED_DATA_ALIGN = -8;
const RegId EXPECTED_RETURN_ADDR = RegId.RIP;
const String EXPECTED_AUGS = "zR";
const ushort EXPECTED_AUG_DATA = 0x011b;

constset RegId : inline char {
    RBP = 6,
    RSP = 7,
    RIP = 16,
}

const RegId REGISTER_PC = RegId.RIP;
const RegId REGISTER_SP = RegId.RSP;
