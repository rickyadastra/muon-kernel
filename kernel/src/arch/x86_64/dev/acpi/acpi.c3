module dev::acpi;

bool initComplete @local = false;
XSDTable* xsdt @local = null;
usz entries @local = 0;

fn bool checksum(uptr ptr, usz size) @local {
    char sum = 0;
    for (usz i = 0; i < size; i++) {
        sum += ((char*)ptr)[i];
    }

    return sum == 0;
}

fn void? init(uptr ptr) {
    XSDPointer* tablePtr = (XSDPointer*) ptr;
    
    // only ACPI version 2 is supported
    if (tablePtr.revision != 2) return UNSUPPORTED_VERSION?;
    if (!checksum((uptr)tablePtr, XSDPointer.sizeof)) return CHECKSUM_FAIL?;

    // parse XSDT
    xsdt = (XSDTable*)tablePtr.xsdtAddr; 
    entries = (xsdt.length - $sizeof(xsdt.header)) / 8;

    initComplete = true;
}

fn ACPITable*? get_acpi_table(char[4] signature) {
    if (!initComplete) return NOT_READY?;
    if (!entries) return NOT_FOUND?;

    for (usz i = 0; i < entries; i++) {
        ACPITable* table = (ACPITable*) xsdt.otherSdtPtrs[i];
        if (signature == table.signature) {
            if (!checksum((uptr)table, table.length)) return CHECKSUM_FAIL?;

            return table;
        }
    }

    return NOT_FOUND?;
}
