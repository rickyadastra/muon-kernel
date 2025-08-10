module arch::interrupts;

import arch::gdt;

const usz IDT_ENTRIES = 256;
GateDescriptor[IDT_ENTRIES] idt @private;

enum KnownInterrupt : uint (usz num, String mnmem, InterruptType type, bool has_error_code, String name) {
    DIVISION_ERROR          = {0x0, "#DE", FAULT, false, "Divide error"},
    DEBUG                   = {0x1, "#DB", TRAP, false, "Debug Exception"},
    NONMASKABLE_INTERRUPT   = {0x2, "NMI", INTERRUPT, false, "NMI Interrupt"},
    BREAKPOINT              = {0x3, "#BP", TRAP, false, "Breakpoint"},
    OVERFLOW                = {0x4, "#OF", TRAP, false, "Overflow"},
    BOUND_RANGE_EXCEEDED    = {0x5, "#BR", FAULT, false, "BOUND Range Exceeded"},
    INVALID_OPCODE          = {0x6, "#UD", FAULT, false, "Invalid Opcode"},
    DEVICE_NOT_AVAIL        = {0x7, "#NM", FAULT, false, "Device Not Available"},
    DOUBLE_FAULT            = {0x8, "#DF", ABORT, true, "Double Fault"},
    COPROC_SEGMENT_OVERRUN  = {0x9, "N/A", FAULT, false, "Coprocessor Segment Overrun"},
    INVALID_TSS             = {0xa, "#TS", FAULT, true, "Invalid TSS"},
    SEGMENT_NOT_PRESENT     = {0xb, "#NP", FAULT, true, "Segment Not Present"},
    STACK_SEGMENT_FAULT     = {0xc, "#SS", FAULT, true, "Stack-Segment Fault"},
    GENERAL_PROTECTION      = {0xd, "#GP", FAULT, true, "General Protection Fault"},
    PAGE_FAULT              = {0xe, "#PF", FAULT, true, "Page Fault"},
    INTERRUPT_15            = {0xf, "N/A", FAULT, false, "Intel Reserved"},
    FPU_ERROR               = {0x10, "#MF", FAULT, false, "x87 FPU Floating-Point Error"},
    ALIGNMENT_ERROR         = {0x11, "#AC", FAULT, true, "Alignment Check"},
    MACHINE_CHECK           = {0x12, "#MC", ABORT, false, "Machine Check"},
    SIMD_FP_EXC             = {0x13, "#XM", FAULT, false, "SIMD Floating-Point Exception"},
    VIRTUALIZATION_EXC      = {0x14, "#VE", FAULT, false, "Virtualization Exception"},
    CONTROL_PROTECTION_EXC  = {0x15, "#CP", FAULT, true, "Control Protection Exception"},
    // 22..31 reserved
    APIC_TIMER              = {0x20, "N/A", INTERRUPT, false, "APIC Timer Interrupt"},
    SPURIOUS_INTERRUPT      = {0xff, "N/A", INTERRUPT, false, "Spurious Interrupt"},
}

const uint EXCEPTIONS = KnownInterrupt.CONTROL_PROTECTION_EXC.ordinal+1;

const KnownInterrupt[*] KERNEL_HANDLED_INTS = { 
    DOUBLE_FAULT, PAGE_FAULT, GENERAL_PROTECTION, APIC_TIMER,
};

fn GateDescriptor construct_descriptor(uint irq, InterruptHandler handler, char ist = 0, GateType type,
                                       PrivilegeLevel privilege_level = KERNEL, bool present = true) @private {
    return {
        .offset_low = (ushort)((uptr)handler & 0xffff),
        .selector = {
            .privilege_req = PrivilegeLevel.KERNEL,
            .use_ldt = false,
            .index = (ushort)KnownDescriptor.KERNEL_CODE.ordinal
        },
        .ist_offset = ist & 0x3, // trunc to lower 2 bits
        .type = type.flags,
        .privilege_level = privilege_level,
        .present = present,
        .offset_mid = (ushort)(((uptr)handler >> 16) & 0xffff),
        .offset_high = (uint)(((uptr)handler >> 32) & 0xffffffff),
    };
}

fn bool is_kernel_handled(KnownInterrupt val) @local @inline {
    foreach (KnownInterrupt e : KERNEL_HANDLED_INTS) {
        if (e == val) return true;
    }
    return false;
} 

fn void setup() {
    for (uint i = 0; i < IRQS; i++) {
        char ist = (i < EXCEPTIONS && is_kernel_handled(KnownInterrupt.from_ordinal(i))) ? 1 : 0;
        
        idt[i] = construct_descriptor(i, irqs[i], ist: ist, type: GateType.INTERRUPT);
    }
}

fn void install() {
    IDTRegister idtr = {
        .offset = &idt,
        .size = (GateDescriptor.sizeof * IDT_ENTRIES) - 1
    };

    idt_load(&idtr);
}
