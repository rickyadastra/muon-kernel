module arch;

import boson;
import muon::logging;
import mem;
import dev;

fn void init(BootloaderPayload* payload) {
    uptr rsdpAddr = payload.rsdpAddr;

    gdt::setup(payload.stack.base);
    logging::printn("GDT setup complete");

    gdt::install();
    logging::printn("GDT install complete");

    interrupts::setup();
    logging::printn("IDT setup complete");

    interrupts::install();
    logging::printn("IDT install complete");

    cpu::cpuid::enable()!!;
    logging::printn("CPUID enabled");

    mem::init(payload)!!;
    logging::printn("Memory manager init complete");

    acpi::init(rsdpAddr)!!;
    logging::printn("ACPI init complete");

    apic::init()!!;
    logging::printn("APIC init complete");

    // logging::@catch_or_log(hpet::init(), "HPET init complete");
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
