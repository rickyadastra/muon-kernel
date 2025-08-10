module arch::cpu;

macro void enable_interrupts() { asm("sti"); }
macro void disable_interrupts() { asm("cli"); }
macro void idle() { asm("hlt"); }

enum ModelSpecificRegister : const uint {
    APIC =              0x1b,
    EFER =              0xC0000080,
    STAR =              0xC0000081,
    LSTAR =             0xC0000082,
    COMPAT_STAR =       0xC0000083,
    SYSCALL_FLAG_MASK = 0xC0000084,
    FS_BASE =           0xC0000100,
    GS_BASE =           0xC0000101,
    KERN_GS_BASE =      0xc0000102,
}

fn void write_msr(ModelSpecificRegister reg, ulong value) @export {
    asm {
        movl $eax, ((uint)(value & 0xffffffff));
        movl $edx, ((uint)(value >> 32));
        movl $ecx, reg;
    }
    asm("wrmsr");
}

fn ulong read_msr(ModelSpecificRegister reg) @export {
    uint dataLow, dataHigh;
    asm {
        movl $ecx, reg;
    }
    asm("rdmsr");
    asm {
        movl dataLow, $eax;
        movl dataHigh, $edx;
    }

    return (((ulong)dataHigh) << 32) | dataLow;
}
