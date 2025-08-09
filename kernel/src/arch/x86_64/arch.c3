module arch;

import boson;
import muon::logging;
import dev::acpi;

fn void init(BootloaderPayload* payload) {
    gdt::setup();
    logging::printn("GDT setup complete");

    gdt::install();
    logging::printn("GDT install complete");

    interrupts::setup();
    logging::printn("IDT setup complete");

    interrupts::install();
    logging::printn("IDT install complete");

    if (catch e = acpi::setup(payload.rsdpAddr)) {
        logging::printn("Error during ACPI setup: %s", e.nameof);
    }
}

fn void set_interrupts(bool val) @inline {
    if (val) {
        asm("sti");
    } else {
        asm("cli");
    }
}

fn void idle() @inline {
    asm("hlt");
}

macro void panic() {
    arch::set_interrupts(false);
    arch::idle();
}

fn void log_and_panic(String message) {
    logging::panic(message);
    arch::panic();
}

fn void stack_check_fail() @noreturn @export @extern("__stack_chk_fail") => log_and_panic("stack smashing detected");
