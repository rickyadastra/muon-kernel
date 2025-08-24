module dev::timing::hpet;

import dev::acpi;

const SDTSignature SIGNATURE @private = "HPET";

enum PageProtectionCapability : const char {
    NO_GUARANTEE,
    PROTECTED_4KB,
    PROTECTED_64KB,
}

struct HPETTable @packed {
    inline SDTHeader header;
    bitstruct : uint {
        char hardwareRevisionId : 0..7;
        char comparatorCount : 8..12;
        char counterSize : 13..13;
        // bit 14 is reserved
        char legacyReplacement : 15..15;
        ushort pciVendorId : 16..31;
    }
    AddressSpaceID address;
    char hpetNumber;
    ushort minimumPeriodicClockTick;
    bitstruct : char {
        PageProtectionCapability pageProtection : 0..3;
        char oemAttributes : 4..7;
    }
}
