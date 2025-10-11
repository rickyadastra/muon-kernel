module scheduler::task;

import muon;
import arch;

fn void TaskContext.init(&self, EntryPointFn entryPoint, uptr stackBase, uptr stackTop) @dynamic {
    // set cpuContext
    self.cpuContext = {
        .rip = (uptr)entryPoint,
        .rsp = stackTop - 8,
        .rbp = stackBase,
        .rflags = 0x202,
        .cs = gdt::@segment_selector_of(gdt::KnownDescriptor.KERNEL_CODE.ordinal),
        .ss = gdt::@segment_selector_of(gdt::KnownDescriptor.KERNEL_DATA.ordinal),
    };

    *(uptr*)self.cpuContext.rsp = (uptr)&scheduler::task::terminate;

    // set fpuContext
    self.fpuContext[..] = 0;
}

fn void TaskContext.save(&self, CpuContext* context) @dynamic {
    self.cpuContext = *context;
}

fn void TaskContext.load(&self, CpuContext* context) @dynamic {
    *context = self.cpuContext;
}
