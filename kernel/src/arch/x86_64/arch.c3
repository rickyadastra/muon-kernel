module arch;

import boson;
import muon;
import mem;
import dev;

fn void init(BootloaderPayload* payload) {
    uptr rsdpAddr = payload.rsdpAddr;

    arch::cpu::disable_interrupts();

    // Foundations
    gdt::setup(payload.stack.base);
    logging::printn("GDT setup complete");

    gdt::install();
    logging::printn("GDT install complete");

    idt::setup();
    logging::printn("IDT setup complete");

    idt::install();
    logging::printn("IDT install complete");

    muon::@wrap_panic(cpu::cpuid::enable());
    logging::printn("CPUID enabled");

    muon::@wrap_panic(cpu::sse::enable());
    logging::printn("SSE enabled");

    // Memory Management
    muon::@wrap_panic(mem::init(payload));
    logging::printn("Memory manager init complete");

    // Interrupts and Timing
    timing::pit::disable();

    muon::@wrap_panic(acpi::init(rsdpAddr));
    logging::printn("ACPI init complete");

    muon::@wrap_panic(apic::init());
    logging::printn("APIC init complete");

    muon::@wrap_panic(timing::hpet::init());

    interrupts::init();
    logging::printn("Interrupts init complete");

    muon::@wrap_panic(timing::calibrate());
    logging::printn("Timer calibration complete");
}

macro void panic() {
    cpu::disable_interrupts();
    cpu::idle();
}

alias PanicFn = fn void(String message, String file, String function, uint line);
PanicFn panicfn = &log_and_panic;

fn void log_and_panic(String message, String file = "", String function = "", uint line = 0) {
    logging::panic(message, file: file, function: function, line: line);
    arch::panic();
}

fn void stack_check_fail() @noreturn @export @extern("__stack_chk_fail") => log_and_panic("stack smashing detected");
