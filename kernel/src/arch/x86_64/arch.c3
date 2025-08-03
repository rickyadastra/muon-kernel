module arch;

import dev::serial;
import muon::logging;

fn void init() {
    gdt::setup();
    logging::printn("GDT setup complete");

    gdt::install();
    logging::printn("GDT install complete");

    interrupts::setup();
    logging::printn("IDT setup complete");

    interrupts::install();
    logging::printn("IDT install complete");

    asm("int $$32");
    @log(log, "IDT install complete\n");
}

fn void idle() {
    asm("hlt");
}
