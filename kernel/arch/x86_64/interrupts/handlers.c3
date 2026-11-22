module arch::interrupts;

import muon::log, muon::debug;
import arch::mem @public;
import process::scheduler @public;
import arch::cpu;
import dev::interrupts::apic;

InterruptHandlerFn[IRQS] handlers @private;

macro InterruptHandlerFn @handler_wrapper(SimpleInterruptHandlerFn $fn) => fn (InterruptStack* stack) {
    $fn(stack.irq);
    return stack;
};

macro void @print_context(InterruptStack* #stack, KnownInterrupt intr) @private {
    log::printn("\nContext:");
    log::printn("  rax=%x  rbx=%x  rcx=%x  rdx=%x", #stack.rax, #stack.rbx, #stack.rcx, #stack.rdx);
    log::printn("  rsi=%x  rdi=%x  rbp=%x  rsp=%x", #stack.rsi, #stack.rdi, #stack.rbp, #stack.rsp);
    log::printn("  r8= %x  r9= %x  r10=%x  r11=%x", #stack.r8, #stack.r9, #stack.r10, #stack.r11);
    log::printn("  r12=%x  r13=%x  r14=%x  r15=%x", #stack.r12, #stack.r13, #stack.r14, #stack.r15);
    log::printn("  rip=%x  rflags=%x", #stack.rip, #stack.rflags);
    log::printn("  cs=%x (%s) ", (ushort)#stack.cs, gdt::@descriptor_of(#stack.cs).description);
    log::printn("  ss=%x (%s)", (ushort)#stack.ss, gdt::@descriptor_of(#stack.ss).description);
    log::newline();
    log::print("  Interrupt: %d (%s)", #stack.irq, intr.name, terminator: intr.has_error_code ? ' ' : '\n');
    if (intr.has_error_code) log::printn("with error code=%x", (ushort)#stack.error_code);

	if (scheduler::currentTask != null) {
		log::printn("  Current task: #%d (handles=%d, refs=%d)", 
			scheduler::currentTask.id, scheduler::currentTask.handles.bitmap.cardinality(), scheduler::currentTask.get_ref_count());
	}
}

fn InterruptStack* exception_handler(InterruptStack* stack) @private {
    KnownInterrupt intr = KnownInterrupt::from_ordinal(stack.irq);
    
    log::error("Exception %d of type %s (%s): %s", intr.num, intr.type.description, intr.mnmem, intr.name);

    switch (intr) {
        case KnownInterrupt.PAGE_FAULT:
            stack = mem::pagefault_handler(stack, intr);
        case KnownInterrupt.SIMD_FP_EXC:
            stack = sse::exception_handler(stack);
            muon::panic("sse exception");
        default:
            muon::@panic_with_extra("unhandled exception") {
				interrupts::@print_context(stack, intr);

				log::printp("\nBacktrace:\n");
				debug::print_backtrace_from(stack.rip, stack.rsp);
			};
    }

    return stack;
}

fn InterruptStack* interrupt_handler(InterruptStack* stack) @private {
    InterruptHandlerFn func = handlers[stack.irq];
    
    if (func != null) {
        stack = func(stack);
    } else {
        log::debug("unhandled interrupt %d", stack.irq);
    }

    apic::lapic_eoi();
    return stack;
}
