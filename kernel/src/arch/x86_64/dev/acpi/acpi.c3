module dev::acpi;

import muon::logging;

XSDTable* xsdt @local = null;

fn bool checksum(XSDPointer* ptr, usz size) @local {
    char sum = 0;
    for (usz i = 0; i < size; i++) {
        sum += ((char*)ptr)[i];
    }

    return sum == 0;
}

fn void? setup(uptr ptr) {
    XSDPointer* tablePtr = (XSDPointer*) ptr;
    
    // only ACPI version 2 is supported
    if (tablePtr.revision != 2) return UNSUPPORTED_VERSION?;
    if (!checksum(tablePtr, XSDPointer.sizeof)) return CHECKSUM_FAIL?;

    // parse XSDT
    xsdt = (XSDTable*)tablePtr.xsdtAddr; 

}
