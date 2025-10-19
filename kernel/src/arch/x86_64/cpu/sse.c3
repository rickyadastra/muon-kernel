module arch::cpu::sse;

import arch::cpu;
import arch::interrupts;
import muon;

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

fn void save_context(char[FPU_CONTEXT_SIZE]* to) {
    asm("fxsave (%rdi)");
}

fn void restore_context(char[FPU_CONTEXT_SIZE]* from) {
    asm("fxrstor (%rdi)");
}

fn void init_context(char[FPU_CONTEXT_SIZE]* ctx) {
    (*ctx)[..] = 0;
    *(MXCSReg*)&((*ctx)[MXCSR_CTX_BYTE_OFFSET]) = sse::DEFAULT_MXCSR;
    *(FPUCtrlWord*)&((*ctx)[FCW_CTX_BYTE_OFFSET]) = sse::DEFAULT_FCW;
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
