module arch::interrupts;

import muon::logging;
import arch::mem @public;
import arch::cpu::gdt;
import dev::interrupts::apic;

InterruptHandlerFn[IRQS] handlers @private;

macro InterruptHandlerFn @handler_wrapper($fn) => fn (InterruptStack* stack) {
    $fn();
    return stack;
};

macro void @print_stack(InterruptStack* #stack, KnownInterrupt intr) @private {
    logging::printn("—————————————————————————————————————— INTERRUPT STACK DUMP ————————————————————————————————————————");
    logging::printn(" rax: %x  rbx: %x  rcx: %x  rdx: %x", #stack.rax, #stack.rbx, #stack.rcx, #stack.rdx);
    logging::printn(" rsi: %x  rdi: %x  rbp: %x  rsp: %x", #stack.rsi, #stack.rdi, #stack.rbp, #stack.rsp);
    logging::printn(" r8:  %x  r9:  %x  r10: %x  r11: %x", #stack.r8, #stack.r9, #stack.r10, #stack.r11);
    logging::printn(" r12: %x  r13: %x  r14: %x  r15: %x", #stack.r12, #stack.r13, #stack.r14, #stack.r15);
    logging::newline();
    logging::print(" IRQ %d (%x)", #stack.irq, (uint)#stack.irq, terminator: intr.has_error_code ? ' ' : '\n');
    if (intr.has_error_code) logging::printn("with error code: %x", #stack.error_code);
    logging::print(" rip: %x  cs:  %x (%s) ", #stack.rip, (ushort)#stack.cs, gdt::@descriptor_of(#stack.cs).nameof);
    logging::printn(" ss:  %x (%s)", (ushort)#stack.ss, gdt::@descriptor_of(#stack.ss).nameof);
    logging::printn(" rflags: %x", #stack.rflags);
    logging::printn("—————————————————————————————————— END OF INTERRUPT STACK DUMP —————————————————————————————————————");
}

fn InterruptStack* exception_handler(InterruptStack* stack) @private {
    KnownInterrupt intr = KnownInterrupt.from_ordinal(stack.irq);
    
    logging::printn("Exception %d of type %s (%s): %s", intr.num, intr.type.nameof, intr.mnmem, intr.name);
    
    if (intr == KnownInterrupt.PAGE_FAULT) {
        stack = mem::pagefault_handler(stack, intr);
    } else {
        @print_stack(stack, intr);
        arch::panic();
    }

    return stack;
}

fn InterruptStack* interrupt_handler(InterruptStack* stack) @private {
    InterruptHandlerFn func = handlers[stack.irq];
    
    if (func != null) {
        stack = func(stack);
    } else {
        logging::debug("interrupt %d", stack.irq);
    }

    apic::lapic_eoi();
    return stack;
}
