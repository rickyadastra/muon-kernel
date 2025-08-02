module arch::interrupts;

enum InterruptType : char {
    FAULT,
    TRAP,
    ABORT,
    INTERRUPT,
}

enum GateType : char (char flags) {
    INTERRUPT   = 0xe,
    TRAP        = 0xf,
}

bitstruct SegmentSelector : ushort {
    PrivilegeLevel privilege_req : 0..1;
    bool use_ldt : 2;
    ushort index : 3..15;
}

struct GateDescriptor {
    ushort offset_low;              // offset[0:15]
    SegmentSelector selector;
    bitstruct : ushort {
        char ist_offset : 0..2;
        // bits 3..7 are reserved
        char type : 8..11;
        // bit 12 is always 0
        PrivilegeLevel privilege_level : 13..14;
        bool present : 15;
    }
    ushort offset_mid;              // offset[16:31]
    uint offset_high;               // offset[32:63]
    uint __reserved;
}

struct IDTRegister @packed {
    ushort size;
    GateDescriptor* offset;
}

struct InterruptStack @packed {
    Register r15;
    Register r14;
    Register r13;
    Register r12;
    Register r11;
    Register r10;
    Register r9;
    Register r8;
    Register rbp;
    Register rdi;
    Register rsi;
    Register rdx;
    Register rcx;
    Register rbx;
    Register rax;

    ulong irq;
    ulong error_code;
    
    Register rip;
    Register cs;
    Register rflags;
    Register rsp;
    Register ss;
}
