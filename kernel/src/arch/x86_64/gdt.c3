module arch::gdt;

extern fn void gdt_load(GDTRegister*);

const usz GDT_ENTRIES = 5;
SegmentDescriptor[GDT_ENTRIES] gdt @private;

macro @segment_selector_of(#segment) {
    return #segment * SegmentDescriptor.sizeof;
}

/*
    Default segment access is: 0 00 1 0 0 0 0
                               P PL S E D W A
 */
fn SegmentAccess segment_access_of(bool accessed = false, bool writable = false, bool readable = false,
                                    Direction direction = GROW_UP, Conforming conforming = SAME_PRIVILEGE,
                                    bool executable = false, DescriptorType type = DATA_OR_CODE, 
                                    PrivilegeLevel privilege_level = KERNEL, bool present = false) @private {
    SegmentAccess ret = {
        .accessed = accessed,
        .executable = executable,
        .type = type,
        .privilege_level = privilege_level,
        .present = present
    };

    if (ret.executable) {
        ret.readable = readable;
        ret.conforming = conforming;
    } else {
        ret.writable = writable;
        ret.direction = direction;
    }

    return ret;    
}

fn SegmentDescriptor construct_descriptor(uptr base, uint limit, SegmentAccess access, SegmentType type) @private {
    return {
        .limit_low = (ushort)(limit & 0xffff),
        .limit_high = (char)((limit >> 16) & 0x0f),
        .base_low = (ushort)(base & 0xffff),
        .base_mid = (char)((base >> 16) & 0xff),
        .base_high = (char)((base >> 24) & 0xff),
        .access = access,
        .flags = type.flags & 0x0f
    };
}

enum KnownDescriptor : uint {
    NULL,
    KERNEL_CODE,
    KERNEL_DATA,
    USER_CODE,
    USER_DATA
}

fn void setup() {
    gdt[KnownDescriptor.NULL.ordinal] = construct_descriptor(
        0, 0,
        segment_access_of(),
        SegmentType.NULL
    );

    gdt[KnownDescriptor.KERNEL_CODE.ordinal] = construct_descriptor(
        0, 0xfffff, 
        segment_access_of(readable: true, executable: true, present: true),
        SegmentType.CODE_64
    );

    gdt[KnownDescriptor.KERNEL_DATA.ordinal] = construct_descriptor(
        0, 0xfffff,
        segment_access_of(writable: true, present: true),
        SegmentType.DATA_64
    );
    
    gdt[KnownDescriptor.USER_CODE.ordinal] = construct_descriptor(
        0, 0xfffff,
        segment_access_of(readable: true, executable: true, privilege_level: USER, present: true),
        SegmentType.CODE_64
    );

    gdt[KnownDescriptor.USER_DATA.ordinal] = construct_descriptor(
        0, 0xfffff,
        segment_access_of(writable: true, privilege_level: USER, present: true),
        SegmentType.DATA_64
    );
}

fn void install() {
    GDTRegister gdtr = {
        .offset = &gdt,
        .size = (SegmentDescriptor.sizeof * GDT_ENTRIES) - 1
    };

    gdt_load(&gdtr);
}
