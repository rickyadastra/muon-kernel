module arch;

import muon;
import mem;
import dev;

fn void init(BootContext* ctx) {
    arch::cpu::disable_interrupts();

    // Foundations
    gdt::setup((uptr)ctx.stack.base);
    log::debug("GDT setup complete");

    gdt::install();
    log::info("GDT install complete");

    idt::setup();
    log::debug("IDT setup complete");

    idt::install();
    log::info("IDT install complete");

    muon::@wrap_panic(cpu::cpuid::enable());
    log::debug("CPUID enabled");

    muon::@wrap_panic(cpu::sse::enable());
    log::debug("SSE enabled");

    // Memory Management
    muon::@wrap_panic(mem::init(&ctx.memory));
    log::info("Memory manager init complete");

    // Interrupts and Timing
    timing::pit::disable();

    muon::@wrap_panic(acpi::init(ctx.rsdpAddr));
    log::info("ACPI init complete");

    muon::@wrap_panic(apic::init());
    log::info("APIC init complete");

    muon::@wrap_panic(timing::hpet::init());

    interrupts::init();
    log::info("Interrupts init complete");

    muon::@wrap_panic(timing::calibrate());
    log::info("Timer calibration complete");
}

fn void panic() {
    cpu::disable_interrupts();
    cpu::idle();
}

fn void stack_check_fail() @noreturn @export @cname("__stack_chk_fail") => muon::panic("stack smashing detected");
