module arch::cpu;

enum PrivilegeLevel : char {
    KERNEL,
    LEVEL_1,
    LEVEL_2,
    USER,
}

alias Register = ulong;

macro void enable_interrupts() { asm("sti"); }
macro void disable_interrupts() { asm("cli"); }
macro void idle() { asm("hlt"); }
macro void pause() { asm("pause"); }

enum ModelSpecificRegister : const uint {
    APIC =              0x1b,
    TSC_DEADLINE =      0x6e0,
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

bitstruct RFLAGSRegister : ulong {
    bool carry : 0;
    bool parity : 2;
    bool auxCarry : 4;
    bool zero : 6;
    bool sign : 7;
    bool trap : 8;
    bool interruptEnable : 9;
    bool direction : 10;
    bool overflow : 11;
    PrivilegeLevel ioPrivilege : 12..13;
    bool nestedTask : 14;
    bool resume : 16;
    bool virtual8086 : 17;
    bool alignmentCheck : 18;
    bool virtualInterrupt : 19;
    bool virtualInterruptPending : 20;
    bool id : 21;
}

fn RFLAGSRegister read_rflags() {
    ulong data;
    asm("pushf");
    asm {
        popq data;
    }

    return (RFLAGSRegister)data;
}

fn void write_rflags(RFLAGSRegister reg) {
    asm {
        pushq ((ulong)reg);
    }
    asm("popf");
}

fn void write_cr3(uptr pageTablePtr) {
    asm {
        movq $rax, ((ulong) pageTablePtr);
    }
    asm("mov %rax, %cr3");
}

fn uptr read_cr3() {
    ulong reg;
    asm("mov %cr3, %rax");
    asm {
        movq reg, $rax;
    }

    return (uptr)reg;
}

fn uptr read_cr2() {
    ulong reg;
    asm("mov %cr2, %rax");
    asm {
        movq reg, $rax;
    }

    return (uptr)reg;
}

fn Register read_cr0() {
    ulong reg;
    asm("mov %cr0, %rax");
    asm {
        movq reg, $rax;
    }

    return (uptr)reg;
}

fn void write_cr0(Register reg) {
    asm {
        movq $rax, ((ulong) reg);
    }
    asm("mov %rax, %cr0");
}

fn Register read_cr4() {
    ulong reg;
    asm("mov %cr4, %rax");
    asm {
        movq reg, $rax;
    }

    return (uptr)reg;
}

fn void write_cr4(Register reg) {
    asm {
        movq $rax, ((ulong) reg);
    }
    asm("mov %rax, %cr4");
}

fn ulong read_tsc() {
    uint dataLow, dataHigh;
    asm("rdtsc");
    asm {
        movl dataLow, $eax;
        movl dataHigh, $edx;
    }

    return (((ulong)dataHigh) << 32) | dataLow;
}
