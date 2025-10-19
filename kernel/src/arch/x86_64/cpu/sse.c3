module arch::cpu::sse;

import arch::cpu;
import arch::interrupts;
import muon;

faultdef SSE_UNSUPPORTED, SSE2_UNSUPPORTED;

const CR0_EM = 2;
const CR0_MP = 1;
const CR4_OSFXSR = 9;
const CR4_OSXMMEXCPT = 10;

const MXCSReg DEFAULT_MXCSR = {
    .invalidOperationMasked = true,
    .denormOperandMasked = true,
    .zeroDivMasked = true,
    .numOverflowMasked = true,
    .numUnderflowMasked = true,
    .inexactResMasked = true,
};

const FPUCtrlWord DEFAULT_FCW = {
    .invalidOperationMasked = true,
    .denormOperandMasked = true,
    .zeroDivMasked = true,
    .overflowMasked = true,
    .underflowMasked = true,
    .precisionMasked = true,
    .precisionControl = EXTENDED,
    .roundingControl = TO_NEAREST,
};

bitstruct MXCSReg : uint {
    // Exceptions
    bool invalidOperationExcpt : 0;
    bool denormOperandExcpt : 1;
    bool zeroDivExcpt : 2;
    bool numOverflowExcpt : 3;
    bool numUnderflowExcpt : 4;
    bool inexactResExcpt : 5;
    // Masks
    bool invalidOperationMasked : 7;
    bool denormOperandMasked : 8;
    bool zeroDivMasked : 9;
    bool numOverflowMasked : 10;
    bool numUnderflowMasked : 11;
    bool inexactResMasked : 12;
}

enum PrecisionControl : const char {
    SINGLE = 0b00,
    DOUBLE = 0b10,
    EXTENDED = 0b11, 
}

enum RoundingControl : const char {
    TO_NEAREST = 0b00,
    DOWN = 0b01,
    UP = 0b10,
    TO_ZERO = 0b11,
}

bitstruct FPUCtrlWord : ushort {
    // Exception masks
    bool invalidOperationMasked : 0;
    bool denormOperandMasked : 1;
    bool zeroDivMasked : 2;
    bool overflowMasked : 3;
    bool underflowMasked : 4;
    bool precisionMasked : 5;
    // Configs
    PrecisionControl precisionControl : 8..9;
    RoundingControl roundingControl : 10..11;
}

<*
    clear the CR0.EM bit (bit 2)
    set the CR0.MP bit (bit 1)
*>
macro cr0_disable_emulation_enable_monitor() @local {
    Register cr0 = cpu::read_cr0();

    cr0 &= ~(1 << CR0_EM);
    cr0 |= (1 << CR0_MP);

    cpu::write_cr0(cr0);
}

<*
    set the CR4.OSFXSR bit (bit 9)
    set the CR4.OSXMMEXCPT bit (bit 10)
*>
macro cr4_enable_osfxsr_xmmexcpt() @local {
    Register cr4 = cpu::read_cr4();

    cr4 |= (1 << CR4_OSFXSR);
    cr4 |= (1 << CR4_OSXMMEXCPT);

    cpu::write_cr4(cr4);
}

fn void? enable() {
    if (!cpuid::query_feature(SSE_SUPPORT)!) return SSE_UNSUPPORTED?;
    if (!cpuid::query_feature(SSE2_SUPPORT)!) return SSE2_UNSUPPORTED?;

    cr0_disable_emulation_enable_monitor();
    cr4_enable_osfxsr_xmmexcpt();

    load_mxcsr(&DEFAULT_MXCSR);
    load_fcw(&DEFAULT_FCW);
}

fn void save_context(char* to) {
    asm("fxsave (%rdi)");
}

fn void restore_context(char* from) {
    asm("fxrstor (%rdi)");
}

fn void store_mxcsr(MXCSReg* to) @private {
    asm("stmxcsr (%rdi)");
}

fn void load_mxcsr(MXCSReg* from) @private {
    asm("ldmxcsr (%rdi)");
}

fn void store_fcw(FPUCtrlWord* to) @private {
    asm("fstcw (%rdi)");
}

fn void load_fcw(FPUCtrlWord* from) @private {
    asm("fldcw (%rdi)");
}

macro @clear_exception_flags(MXCSReg #reg) {
    #reg.invalidOperationExcpt = false;
    #reg.denormOperandExcpt = false;
    #reg.zeroDivExcpt = false;
    #reg.numOverflowExcpt = false;
    #reg.numUnderflowExcpt = false;
    #reg.inexactResExcpt = false;
}

fn InterruptStack* exception_handler(InterruptStack* stack) {
    MXCSReg reg;
    store_mxcsr(&reg);

    logging::print("MXCSR: %x, Exception: ", reg);
    switch {
        case reg.invalidOperationExcpt:
            logging::printn("invalidOperation");
        case reg.denormOperandExcpt:
            logging::printn("denormOperand");
        case reg.zeroDivExcpt:
            logging::printn("zeroDiv");
        case reg.numOverflowExcpt:
            logging::printn("numOverflow");
        case reg.numUnderflowExcpt:
            logging::printn("numUnderflow");
        case reg.inexactResExcpt:
            logging::printn("inexactRes");
    }

    @clear_exception_flags(reg);
    load_mxcsr(&reg);

    return stack;
}
