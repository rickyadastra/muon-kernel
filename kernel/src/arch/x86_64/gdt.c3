module arch::gdt;

enum DescriptorType : char {
    SYSTEM,
    DATA_OR_CODE
}

enum PrivilegeLevel : char {
    KERNEL,
    LEVEL_1,
    LEVEL_2,
    USER,
}

enum Direction : char {
    GROW_UP,
    GROW_DOWN,
}

enum Conforming : char {
    SAME_PRIVILEGE,
    SAME_OR_LOWER_PRIVILEGE
}

bitstruct SegmentAccess : char @overlap {
    bool accessed : 0;
    bool writable : 1;              // data segments only
    bool readable : 1;              // code segments only
    Direction direction : 2..2;     // data segments only
    Conforming conforming : 2..2;   // code segments only
    bool executable : 3;
    DescriptorType type : 4..4;
    PrivilegeLevel privilege_level : 5..6;
    bool present : 7;
}

enum SegmentType : ushort (char flags) {
    NULL    = 0b0000,
    DATA_64 = 0b1000,
    CODE_64 = 0b1010,
    DATA_32 = 0b1100,
    CODE_32 = 0b1100,
    TSS     = 0b0000,
}

struct SegmentDescriptor {
    ushort limit_low;                   // limit[0:15]
    ushort base_low;                    // base[0:15]
    char base_mid;                      // base[16:23]
    SegmentAccess access;
    bitstruct : char {
        char limit_high : 0..3;         // limit[16:19]
        char flags : 4..7;
    }
    char base_high;                     // base[24:31]
}

struct GDTRegister @packed {
    ushort size;
    SegmentDescriptor* offset;
}

extern fn void gdt_load(GDTRegister*);

const usz GDT_ENTRIES = 5;
SegmentDescriptor[GDT_ENTRIES] gdt;

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

fn void setup() {
    gdt[0] = construct_descriptor(0, 0, segment_access_of(), SegmentType.NULL);

    gdt[1] = construct_descriptor(0, 0xfffff, segment_access_of(readable: true, executable: true, present: true), SegmentType.CODE_64);
    gdt[2] = construct_descriptor(0, 0xfffff, segment_access_of(writable: true, present: true), SegmentType.DATA_64);
    
    gdt[3] = construct_descriptor(0, 0xfffff, segment_access_of(readable: true, executable: true, privilege_level: USER, present: true), SegmentType.CODE_64);
    gdt[4] = construct_descriptor(0, 0xfffff, segment_access_of(writable: true, privilege_level: USER, present: true), SegmentType.DATA_64);
}

fn void install() {
    GDTRegister gdtr = {
        .offset = &gdt,
        .size = SegmentDescriptor.sizeof * GDT_ENTRIES
    };

    gdt_load(&gdtr);
}
