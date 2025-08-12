module arch::cpu::gdt;

enum DescriptorType : char {
    SYSTEM,
    DATA_OR_CODE
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
