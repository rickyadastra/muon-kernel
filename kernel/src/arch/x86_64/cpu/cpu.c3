module arch::cpu;

macro void enable_interrupts() { asm("sti"); }
macro void disable_interrupts() { asm("cli"); }
macro void idle() { asm("hlt"); }
