module arch::cpu::cpuid;

import arch::cpu;

faultdef CPUID_UNSUPPORTED, LEAF_UNAVAILABLE;

bool supportsCpuid @local = false;
Register maxBasicLeaf, maxExtLeaf @local;

Register scratch @local;

enum CPUIDLeaf : usz (Register a, Register c) @local {
    BASIC_FUNCTION_INFO     {0x0, 0},
    FEATURE_INFORMATION     {0x01, 0},
	EXTENDED_FUNCTION_INFO	{0x80000000, 0},
	INVARIANT_TSC_AVAILABLE	{0x80000007, 0},
    PHYSICAL_ADDRESS_SIZE   {0x80000008, 0},
}

constset CPUFeature : char {
    // 0-31 are RCX (see https://www.felixcloutier.com/x86/cpuid#input-eax-=-01h--returns-feature-information-in-ecx-and-edx)
    TSC_DEADLINE_SUPPORT = 24,
    RDRAND_SUPPORT = 30,
    // 32-63 are RDX
    FPU_PRESENT = 32,
    FXSR_SUPPORT = 56,
    SSE_SUPPORT = 57,
    SSE2_SUPPORT = 58,
}

bitstruct AddressLength : ushort {
    char physicalLength : 0..7;
    char virtualLength : 8..15;
}

macro bool supported() => supportsCpuid;

fn void? execute_raw(Register* a, Register* b, Register* c, Register* d) {
    if (!supported()) return CPUID_UNSUPPORTED~;

    Register _a, _b, _c, _d;

    _a = *a;
    _c = *c;

    asm {
        movq $rax, _a;
        movq $rcx, _c;
        
        cpuid;
        
        movq [a], $rax;
        movq [b], $rbx;
        movq [c], $rcx;
        movq [d], $rdx;
    }
}

fn void? query_leaf(CPUIDLeaf leaf, Register* a, Register* b, Register* c, Register* d) @inline {
    *a = leaf.a;
    *c = leaf.c;
    execute_raw(a, b, c, d)!;
}

fn void? enable() {
    RFLAGSRegister rflags = cpu::read_rflags();
    rflags.id = true;
    cpu::write_rflags(rflags);

    // test is ID bit has changed, if not raise CPUID_UNSUPPORTED
    if (!cpu::read_rflags().id) return CPUID_UNSUPPORTED~;
    supportsCpuid = true;

	// get max supported basic and extended leaves
	query_leaf(BASIC_FUNCTION_INFO, &maxBasicLeaf, &scratch, &scratch, &scratch)!!;
	query_leaf(EXTENDED_FUNCTION_INFO, &maxExtLeaf, &scratch, &scratch, &scratch)!!;
} 

macro bool check_leaf_availability(CPUIDLeaf leaf) {

}

macro AddressLength? query_address_length() {
    usz len;
    query_leaf(PHYSICAL_ADDRESS_SIZE, &(Register)len, &scratch, &scratch, &scratch)!;
    return (AddressLength)(ushort)(len & 0xffff);
}

macro bool? query_feature(CPUFeature feature) {
    Register rcx, rdx;
    query_leaf(FEATURE_INFORMATION, &scratch, &scratch, &rcx, &rdx)!;

    if (feature < FPU_PRESENT) {
        return (bool)((rcx >> (char)(feature)) & 1);
    } else {
        return (bool)((rdx >> (char)(feature-CPUFeature.FPU_PRESENT)) & 1);
    }
}

macro bool? query_invariant_tsc() {
	if (maxExtLeaf < CPUIDLeaf.INVARIANT_TSC_AVAILABLE.a) return LEAF_UNAVAILABLE~;

	Register edx;
	query_leaf(INVARIANT_TSC_AVAILABLE, &scratch, &scratch, &scratch, &edx)!;
	return ((edx >> 8) & 0b1) == 1;
}
