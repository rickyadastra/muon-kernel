module dev::interrupts::apic;

import dev::acpi;

enum RecordType : const char {
    LOCAL_APIC,
    IO_APIC,
    IO_APIC_ISO, // IO APIC interrupt source override
    IO_APIC_NMI, // IO APIC non maskable interrupt source
    LOCAL_APIC_NMI,
    LOCAL_APIC_ADDRESS_OVERRIDE,
    LOCAL_X2APIC = 9,
}

struct RecordHeader @packed {
    RecordType type;
    char length;
}

struct MADTable @packed {
    inline SDTHeader header;
    uint localApicAddr;
    bitstruct : uint {
        bool legacyPicPresent : 0;
    }
    RecordHeader firstRecord;
}

bitstruct LocalAPICRecordFlags : uint {
    bool processorEnabled : 0;
    bool onlineCapable : 1;
}

bitstruct InterruptFlags : ushort {
    bool activeOnLow : 1;
    bool triggerOnLevel : 3;
}

const InterruptFlags EDGE_HIGH  = { .activeOnLow = false, .triggerOnLevel = false };
const InterruptFlags EDGE_LOW   = { .activeOnLow = true, .triggerOnLevel = false };
const InterruptFlags LEVEL_HIGH = { .activeOnLow = false, .triggerOnLevel = true  };
const InterruptFlags LEVEL_LOW  = { .activeOnLow = true, .triggerOnLevel = true };

struct LocalAPICRecord @packed {
    inline RecordHeader header;
    char acpiProcessorId;
    char apicId;
    LocalAPICRecordFlags flags;
}

struct IOAPICRecord @packed {
    inline RecordHeader header;
    char ioApicId;
    char reserved;
    uint ioApicAddr;
    uint globalSystemInterruptBase;
}

struct IOAPICSourceOverrideRecord @packed {
    inline RecordHeader header;
    char busSource;
    char irqSource;
    uint globalSystemInterrupt;
    InterruptFlags flags;
}

struct IOAPICNonMaskableIntsRecord @packed {
    inline RecordHeader header;
    char nmiSource;
    char reserved;
    InterruptFlags flags;
    uint globalSystemInterrupt;
}

struct LocalAPICNonMaskableIntsRecord @packed {
    inline RecordHeader header;
    char acpiProcessorId;
    InterruptFlags flags;
    char lintNumber;
}

struct LocalAPICAddressOverrideRecord @packed {
    inline RecordHeader header;
    ushort reserved;
    ulong localApicphysAddr;
}

struct LocalX2APICRecord @packed {
    inline RecordHeader header;
    ushort reserved;
    uint x2ApicId;
    LocalAPICRecordFlags flags;
    uint acpiId;
}
