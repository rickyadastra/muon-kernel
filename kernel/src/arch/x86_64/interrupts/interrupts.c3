module arch::interrupts;

// extern fn void idt_load(IDTRegister*);

const usz IDT_ENTRIES = 256;
GateDescriptor[IDT_ENTRIES] idt @private;

enum KnownInterrupt : uint (usz num, String mnmem, InterruptType type, bool has_error_code, String name) {
    DIVISION_ERROR          = {0, "#DE", FAULT, false, "Divide error"},
    DEBUG                   = {1, "#DB", TRAP, false, "Debug Exception"},
    NONMASKABLE_INTERRUPT   = {2, "NMI", INTERRUPT, false, "NMI Interrupt"},
    BREAKPOINT              = {3, "#BP", TRAP, false, "Breakpoint"},
    OVERFLOW                = {4, "#OF", TRAP, false, "Overflow"},
    BOUND_RANGE_EXCEEDED    = {5, "#BR", FAULT, false, "BOUND Range Exceeded"},
    INVALID_OPCODE          = {6, "#UD", FAULT, false, "Invalid Opcode"},
    DEVICE_NOT_AVAIL        = {7, "#NM", FAULT, false, "Device Not Available"},
    DOUBLE_FAULT            = {8, "#DF", ABORT, true, "Double Fault"},
    COPROC_SEGMENT_OVERRUN  = {9, "N/A", FAULT, false, "Coprocessor Segment Overrun"},
    INVALID_TSS             = {10, "#TS", FAULT, true, "Invalid TSS"},
    SEGMENT_NOT_PRESENT     = {11, "#NP", FAULT, true, "Segment Not Present"},
    STACK_SEGMENT_FAULT     = {12, "#SS", FAULT, true, "Stack-Segment Fault"},
    GENERAL_PROTECTION      = {13, "#GP", FAULT, true, "General Protection Fault"},
    PAGE_FAULT              = {14, "#PF", FAULT, true, "Page Fault"},
    INTERRUPT_15            = {15, "N/A", FAULT, false, "Intel Reserved"},
    FPU_ERROR               = {16, "#MF", FAULT, false, "x87 FPU Floating-Point Error"},
    ALIGNMENT_ERROR         = {17, "#AC", FAULT, true, "Alignment Check"},
    MACHINE_CHECK           = {18, "#MC", ABORT, false, "Machine Check"},
    SIMD_FP_EXC             = {19, "#XM", FAULT, false, "SIMD Floating-Point Exception"},
    VIRTUALIZATION_EXC      = {20, "#VE", FAULT, false, "Virtualization Exception"},
    CONTROL_PROTECTION_EXC  = {21, "#CP", FAULT, true, "Control Protection Exception"},
    // 22..31 reserved
}
