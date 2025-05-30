#pragma once

#include <int.h>
#include <efi/efi.h>
#include <efi/time.h>

#define EFI_RUNTIME_SERVICES_SIGNATURE 0x56524553544e5552
#define EFI_RUNTIME_SERVICES_REVISION EFI_SPECIFICATION_VERSION
typedef struct {
    EfiTableHeader    Hdr;

    // Time Services
    EfiGetTime GetTime;
    void*      SetTime;
    void*      GetWakeupTime;
    void*      SetWakeupTime;

    // Virtual Memory Services
    void*      SetVirtualAddressMap;
    void*      ConvertPointer;

    // Variable Services
    void*      GetVariable;
    void*      GetNextVariableName;
    void*      SetVariable;

    // Miscellaneous Services
    void*      GetNextHighMonotonicCount;
    void*      ResetSystem;

    // UEFI 2.0 Capsule Services
    void*      UpdateCapsule;
    void*      QueryCapsuleCapabilities;

    // Miscellaneous UEFI 2.0 Service
    void*      QueryVariableInfo;
} EfiRuntimeServices;
