module dev::acpi;

faultdef UNSUPPORTED_VERSION, CHECKSUM_FAIL, NOT_READY, NOT_FOUND;

struct RSDPointer @packed {
    char[8] signature;
    char checksum;
    char[6] oemId;
    char revision;
    uint rsdtAddr;
}

struct XSDPointer @packed {
    inline RSDPointer rsdp;    
    uint length;
    ulong xsdtAddr;
    char extendedChecksum;
    char[3] reserved;
}

struct SDTHeader @packed {
    char[4] signature;
    uint length;
    char revision;
    char checksum;
    char[6] oemId;
    char[8] oemTableId;
    uint oemRevision;
    uint creatorId;
    uint creatorRevision;
}

struct ACPITable @packed {
    inline SDTHeader header;
    char[*] data;
}

struct XSDTable @packed {
    inline SDTHeader header;
    ulong[*] otherSdtPtrs;
}
