module scheduler::task;

import muon;
import arch;

fn void TaskContext.init(&self, EntryPointFn entryPoint, uptr stackBase, uptr stackTop) @dynamic {
    // set exit return address
    *(uptr*)(stackTop-8) = (uptr)&scheduler::task::terminate;
    self.cpuContext = (CpuContext*)(stackTop-8-CpuContext.sizeof);

    // set initial cpuContext
    *self.cpuContext = {
        .rip = (uptr)entryPoint,
        .rsp = stackTop-8,
        .rbp = stackTop,
        .rflags = 0x202,
        .cs = gdt::@segment_selector_of(gdt::KnownDescriptor.KERNEL_CODE.ordinal),
        .ss = gdt::@segment_selector_of(gdt::KnownDescriptor.KERNEL_DATA.ordinal),
    };

    // set fpuContext
    self.fpuContext[..] = 0;
}

fn void TaskContext.save_from(&self, CpuContext* context) @dynamic {
    self.cpuContext = context;
    // TODO: add fpu state save and restore
}

fn void TaskContext.load_to(&self, CpuContext** context) @dynamic {
    *context = self.cpuContext;
    // TODO: add fpu state save and restore
}

macro prepare_yielding() {
    asm {
        pushq $rsp;
    }
    asm("pushfq");
    asm {
        subq $rsp, 0x8;
    }
    asm("mov %cs, (%rsp)");
    asm {
        subq $rsp, 0x18;
        pushq $rax;
        pushq $rbx;
        pushq $rcx;
        pushq $rdx;
        pushq $rsi;
        pushq $rdi;
        pushq $rbp;
        pushq $r8;
        pushq $r9;
        pushq $r10;
        pushq $r11;
        pushq $r12;
        pushq $r13;
        pushq $r14;
        pushq $r15;
        movq $rax, [$rsp + 0xa8];
        movq [$rsp + 0x88], $rax;
        addq [$rsp + 0xa0], 8;
        xorq $rax, $rax;
    };
    asm("mov %ss, %rax");
    asm {
        movq [$rsp + 0xa8], $rax;
        pushq $rsp;
        movq $rdi, $rsp;
    };
}

macro complete_yielding() {
    asm {
        popq $rsp;
        popq $r15;
        popq $r14;
        popq $r13;
        popq $r12;
        popq $r11;
        popq $r10;
        popq $r9;
        popq $r8;
        popq $rbp;
    };
}

macro exit_yielding() {
    asm { 
        popq $rdi;
        popq $rsi;
        popq $rdx;
        popq $rcx;
        popq $rbx;
        popq $rax;
        addq $rsp, 16;
        iretq;
    };
}
