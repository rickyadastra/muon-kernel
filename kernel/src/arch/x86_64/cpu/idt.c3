module arch::cpu::idt;

import arch::cpu::gdt;
import arch::interrupts;

const usz IDT_ENTRIES = 256;
GateDescriptor[IDT_ENTRIES] idt @private;

fn GateDescriptor construct_descriptor(uint irq, InterruptVoidFn handler, char ist = 0, GateType type,
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
    foreach (KnownInterrupt e : interrupts::KERNEL_HANDLED_INTS) {
        if (e == val) return true;
    }
    return false;
} 

fn void idt_load(IDTRegister* reg) {
    asm("lidt (%rdi)");
}

fn void setup() {
    for (uint i = 0; i < IDT_ENTRIES; i++) {
        char ist = (i < interrupts::EXCEPTIONS && is_kernel_handled(KnownInterrupt.from_ordinal(i))) ? 1 : 0;
        
        idt[i] = construct_descriptor(i, interrupts::irqs[i], ist: ist, type: GateType.INTERRUPT);
    }
}

fn void install() {
    IDTRegister idtr = {
        .offset = &idt,
        .size = (GateDescriptor.sizeof * IDT_ENTRIES) - 1
    };

    idt_load(&idtr);
}
