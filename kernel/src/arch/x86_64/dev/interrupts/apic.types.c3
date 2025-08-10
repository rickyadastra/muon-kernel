module dev::interrupts::apic;

import dev::acpi;

faultdef APIC_DISABLED;

const SDTSignature SIGNATURE @private = "APIC";

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

bitstruct APICBaseMSR : ulong {
    bool isBootstrapProcessor : 8;
    bool x2ApicEnable : 10;
    bool globalEnable : 11;
    ulong baseAddr : 12..35;
}

enum LAPICRegister : const uint {
    LAPIC_ID                    = 0x20,
    LAPIC_VERSION               = 0x30,
    TASK_PRIORITY               = 0x80,
    ARBITRATION_PRIORITY        = 0x90,
    PROCESSOR_PRIORITY          = 0Xa0,
    EOI                         = 0xb0,
    REMOTE_READ                 = 0xc0,
    LOGICAL_DESTINATION         = 0xd0,
    DESTINATION_FORMAT          = 0xe0,
    SPURIOUS_INTERR_VECTOR      = 0xf0,
    IN_SERVICE_BASE             = 0x100,
    TRIGGER_MODE_BASE           = 0x180,
    INTERRUPT_REQUEST_BASE      = 0x200,
    ERROR_STATUS                = 0x280,
    LVT_CORRECTED_MCI           = 0x2f0,
    INTERRUPT_COMMAND           = 0x300,
    LVT_TIMER                   = 0x320,
    LVT_THERMAL_SENSOR          = 0x330,
    LVT_PERFORMANCE_MONITOR     = 0x340,
    LVT_LINT0                   = 0x350,
    LVT_LINT1                   = 0x360,
    LVT_ERROR                   = 0x370,
    TIMER_INITIAL_COUNT         = 0x380,
    TIMER_CURRENT_COUNT         = 0x390,
    TIMER_DIVIDE_CONFIG         = 0x3e0,
}

enum IOAPICRegister : const uint {
    IOAPIC_ID                   = 0x00,
    IOAPIC_VER                  = 0x01,
    IOAPIC_ARBITRATION_ID       = 0x02,
}

const uint IOAPIC_REGSEL = 0x00;
const uint IOAPIC_DATA   = 0x10;

bitstruct IOAPICVerReg : uint {
    char ioApicVer : 0..7;
    char maxRedirectIndex : 16..23;
}
