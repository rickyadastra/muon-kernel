module arch::interrupts;

import dev;
import dev::timing;
import dev::interrupts::apic @public;
import muon::logging;
import arch::mem;
import arch::cpu;

enum KnownInterrupt : uint (char num, String mnmem, InterruptType type, bool has_error_code, String name) {
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
    LEGACY_PIT              = {0x20, "", INTERRUPT, false, "Legacy PIT Interrupt"},
    SERIAL_COM2_COM4        = {0x23, "", INTERRUPT, false, "COM2/4 Interrupt"},
    SERIAL_COM1_COM3        = {0x24, "", INTERRUPT, false, "COM1/3 Interrupt"},
    CMOS_RTC                = {0x28, "", INTERRUPT, false, "CMOS RTC Interrupt"},
    APIC_TIMER              = {0x30, "", INTERRUPT, false, "APIC Timer Interrupt"},
    HPET_TIMER0             = {0x31, "", INTERRUPT, false, "HPET Timer #0 Interrupt"},
    SPURIOUS_INTERRUPT      = {0xff, "", INTERRUPT, false, "Spurious Interrupt"},
}

const uint EXCEPTIONS = KnownInterrupt.CONTROL_PROTECTION_EXC.ordinal+1;

const KnownInterrupt[*] KERNEL_HANDLED_INTS = { 
    DOUBLE_FAULT, PAGE_FAULT, GENERAL_PROTECTION, APIC_TIMER,
};

<*
    @require handler != null
*>
fn void add_interrupt_handler(KnownInterrupt inter, InterruptFlags flags, InterruptHandlerFn handler) {
    char irq = inter.num - apic::LEGACY_IRQ_BASE;
    uint gsi = apic::get_gsi_override(irq);

    apic::ioapic_set_redirect(gsi, irq, flags);
    handlers[inter.num] = handler;

    logging::debug("Registering new interrupt handler for %s, vector %d @ %x", inter.nameof, inter.num, handler);
}

fn void set_interrupt_mask(KnownInterrupt inter, bool val, bool cancelPending = false) {
    uint gsi = apic::get_gsi_override(inter.num - apic::LEGACY_IRQ_BASE);

    apic::ioapic_set_mask(gsi, val, cancelPending);

    logging::debug("%sasking interrupt line for %s, vector %d", val ? "M" : "Unm", inter.nameof, inter.num);
}

fn void init() {
    // LEGACY PIT: mask interrupts
    set_interrupt_mask(KnownInterrupt.LEGACY_PIT, true, cancelPending: true);

    // SERIAL COM1: enable rx interrupts, set rx buffer and add interrupt
    serial::of(SerialPort.COM1).set_rx_buffer((SerialBuffer*)mem::alloc(SerialBuffer.sizeof));
    serial::of(SerialPort.COM1).enable_rx();
    add_interrupt_handler(KnownInterrupt.SERIAL_COM1_COM3, apic::LEVEL_HIGH, @handler_wrapper(&serial::interrupt_handler));

    // RTC: enable update interrupt and set wallclock callback
    rtc::enable_update_interrupt();
    add_interrupt_handler(KnownInterrupt.CMOS_RTC, apic::EDGE_HIGH, @handler_wrapper(&timing::get_wallclock_callback));

    // HPET: set default handler for timer #0
    add_interrupt_handler(KnownInterrupt.HPET_TIMER0, apic::LEVEL_HIGH, @handler_wrapper(&timing::hpet::timer_fired));

    // enable interrupts
    arch::cpu::enable_interrupts();
}
