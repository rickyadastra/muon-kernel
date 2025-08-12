module arch::cpu::tss;

import arch::cpu::gdt;

TaskStateSegment tss @private;

const usz IST_SIZE = 4; // in pages
char[IST_SIZE*0x1000] ist1 @local;

fn TSSDescriptor construct_descriptor(uptr base, uint limit, SegmentAccess access, SegmentType type) {
    return {
        .segment = gdt::construct_descriptor(base, limit, access, type),
        .base_higher = (base >> 32) & 0xffffffff,
        .reserved = 0
    };
}

fn void setup(TSSDescriptor* tssd, uptr kernelStack) {
    tss.iopb = TaskStateSegment.sizeof;
    tss.rsp0 = kernelStack;
    tss.ist1 = (uptr)&ist1 + (IST_SIZE*0x1000); // stack is top-down
    
    *tssd = construct_descriptor(
        (uptr)&tss, (uint)(uptr)&tss + TaskStateSegment.sizeof,
        gdt::segment_access_of(sysType: TSS_64_AVAIL, type: SYSTEM, privilege_level: KERNEL, present: true),
        SegmentType.TSS
    );
}

fn void install() @inline {
    tss_load();
}

fn void tss_load() {
    asm {
        movw $ax, (gdt::@segment_selector_of(gdt::GDT_ENTRIES));
    }
    asm("ltr %ax");
}
