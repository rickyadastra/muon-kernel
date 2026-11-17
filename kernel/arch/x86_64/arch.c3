module arch;

import muon;
import mem;
import dev;

fn void init(BootContext* ctx) {
    arch::cpu::disable_interrupts();

    // Foundations
    gdt::setup((uptr)ctx.stack.base);
    log::printn("GDT setup complete");

    gdt::install();
    log::printn("GDT install complete");

    idt::setup();
    log::printn("IDT setup complete");

    idt::install();
    log::printn("IDT install complete");

    muon::@wrap_panic(cpu::cpuid::enable());
    log::printn("CPUID enabled");

    muon::@wrap_panic(cpu::sse::enable());
    log::printn("SSE enabled");

    // Memory Management
    muon::@wrap_panic(mem::init(&ctx.memory));
    log::printn("Memory manager init complete");

    // Interrupts and Timing
    timing::pit::disable();

    muon::@wrap_panic(acpi::init(ctx.rsdpAddr));
    log::printn("ACPI init complete");

    muon::@wrap_panic(apic::init());
    log::printn("APIC init complete");

    muon::@wrap_panic(timing::hpet::init());

    interrupts::init();
    log::printn("Interrupts init complete");

    muon::@wrap_panic(timing::calibrate());
    log::printn("Timer calibration complete");
}

fn void panic() {
    cpu::disable_interrupts();
    cpu::idle();
}

alias PanicFn = fn void(String message, String file, String function, int line);
PanicFn panicfn = &log_and_panic;

fn void log_and_panic(String message, String file = "", String function = "", int line = 0) {
    log::panic(message, file: file, function: function, line: (uint)line);
    arch::panic();
}

fn void stack_check_fail() @noreturn @export @cname("__stack_chk_fail") => log_and_panic("stack smashing detected");
