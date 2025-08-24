module arch::cpu::tss;

import arch::cpu::gdt;

struct TaskStateSegment @packed {
    uint reserved0;
    Register rsp0;
    Register rsp1;
    Register rsp2;
    ulong reserved1;
    ulong ist1;
    ulong ist2;
    ulong ist3;
    ulong ist4;
    ulong ist5;
    ulong ist6;
    ulong ist7;
    ulong reserved2;
    ushort reserved3;
    ushort iopb;
}

struct TSSDescriptor {
    inline SegmentDescriptor segment;
    bitstruct : ulong {
        ulong base_higher : 0..31;
        ulong reserved : 32..63;
    }
}
