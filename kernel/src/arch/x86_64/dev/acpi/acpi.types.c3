module dev::acpi;

faultdef UNSUPPORTED_VERSION, CHECKSUM_FAIL, NOT_READY, NOT_FOUND;

alias SDTSignature = char[4];

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
    SDTSignature signature;
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

enum AddressSpaceID : const char {
    SYSTEM_MEMORY,
    SYSTEM_IO,
}

struct GenericAddress @packed {
    AddressSpaceID addressSpaceId;
    char registerBitWidth;
    char registerBitOffset;
    char reserved;
    ulong address;
}
