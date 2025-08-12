module arch;

import boson;
import muon::logging;
import dev;

fn void init(BootloaderPayload* payload) {
    gdt::setup(payload.stack.base);
    logging::printn("GDT setup complete");

    gdt::install();
    logging::printn("GDT install complete");

    interrupts::setup();
    logging::printn("IDT setup complete");

    interrupts::install();
    logging::printn("IDT install complete");

    logging::@catch_or_log(acpi::init(payload.rsdpAddr), "ACPI init complete");

    logging::@catch_or_log(apic::init(), "APIC init complete");

    // logging::@catch_or_log(hpet::init(), "HPET init complete");
}

macro void panic() {
    cpu::disable_interrupts();
    cpu::idle();
}

fn void log_and_panic(String message) {
    logging::panic(message);
    arch::panic();
}

fn void stack_check_fail() @noreturn @export @extern("__stack_chk_fail") => log_and_panic("stack smashing detected");
