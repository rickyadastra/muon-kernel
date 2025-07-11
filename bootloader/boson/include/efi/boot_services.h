#pragma once

#include <efi/memory.h>
#include <efi/efi.h>

#define EFI_BOOT_SERVICES_SIGNATURE 0x56524553544f4f42
#define EFI_BOOT_SERVICES_REVISION EFI_SPECIFICATION_VERSION

typedef EfiStatus(*EfiHandleProtocol)(EfiHandle Handle, EfiGUID* Protocol, void** Interface);
typedef EfiStatus(*EfiAllocatePages)(EfiAllocateType Type, EfiMemoryType MemoryType, UINTN Pages, UPtr* PhysicalAddress);
typedef EfiStatus(*EfiAllocatePool) (EfiMemoryType PoolType, UINTN Size, void** Buffer);
typedef EfiStatus(*EfiFreePool) (void* Buffer);
typedef EfiStatus(*EfiFreePages) (UPtr Memory, UINTN Pages);
typedef EfiStatus(*EfiGetMemoryMap) (UINTN* MemoryMapSize, EfiMemoryDescriptor* MemoryMap, UINTN* MapKey, UINTN* DescriptorSize, UInt32* DescriptorVersion);
typedef EfiStatus(*EfiExitBootServices) (EfiHandle ImageHandle, UINTN MapKey);

typedef struct {
    EfiTableHeader     Hdr;

    //
    // Task Priority Services
    //
    void*   RaiseTPL;       // EFI 1.0+
    void*   RestoreTPL;     // EFI 1.0+

    //
    // Memory Services
    //
    EfiAllocatePages   AllocatePages;  // EFI 1.0+
    EfiFreePages   FreePages;      // EFI 1.0+
    EfiGetMemoryMap   GetMemoryMap;   // EFI 1.0+
    EfiAllocatePool   AllocatePool;   // EFI 1.0+
    EfiFreePool   FreePool;       // EFI 1.0+

    //
    // Event & Timer Services
    //
    void*   CreateEvent;    // EFI 1.0+
    void*   SetTimer;       // EFI 1.0+
    void*   WaitForEvent;   // EFI 1.0+
    void*   SignalEvent;    // EFI 1.0+
    void*   CloseEvent;     // EFI 1.0+
    void*   CheckEvent;     // EFI 1.0+

    //
    // Protocol Handler Services
    //
    void*   InstallProtocolInterface;            // EFI 1.0+
    void*   ReinstallProtocolInterface;          // EFI 1.0+
    void*   UninstallProtocolInterface;          // EFI 1.0+
    EfiHandleProtocol   HandleProtocol;                      // EFI 1.0+
    void*   Reserved;    // EFI 1.0+
    void*   RegisterProtocolNotify;              // EFI  1.0+
    void*   LocateHandle;                        // EFI 1.0+
    void*   LocateDevicePath;                    // EFI 1.0+
    void*   InstallConfigurationTable;           // EFI 1.0+

    //
    // Image Services
    //
    void*   LoadImage;        // EFI 1.0+
    void*   StartImage;       // EFI 1.0+
    void*   Exit;             // EFI 1.0+
    void*   UnloadImage;      // EFI 1.0+
    EfiExitBootServices   ExitBootServices; // EFI 1.0+

    //
    // Miscellaneous Services
    //
    void*   GetNextMonotonicCount; // EFI 1.0+
    void*   Stall;                 // EFI 1.0+
    void*   SetWatchdogTimer;      // EFI 1.0+

    //
    // DriverSupport Services
    //
    void*   ConnectController;     // EFI 1.1
    void*   DisconnectController;  // EFI 1.1+

    //
    // Open and Close Protocol Services
    //
    void*   OpenProtocol;           // EFI 1.1+
    void*   CloseProtocol;          // EFI 1.1+
    void*   OpenProtocolInformation;// EFI 1.1+

    //
    // Library Services
    //
    void*   ProtocolsPerHandle;     // EFI 1.1+
    void*   LocateHandleBuffer;     // EFI 1.1+
    void*   LocateProtocol;         // EFI 1.1+
    void*   InstallMultipleProtocolInterfaces;    // EFI 1.1+
    void*   UninstallMultipleProtocolInterfaces;   // EFI 1.1+*

    //
    // 32-bit CRC Services
    //
    void*   CalculateCrc32;     // EFI 1.1+

    //
    // Miscellaneous Services
    //
    void*   CopyMem;        // EFI 1.1+
    void*   SetMem;         // EFI 1.1+
    void*   CreateEventEx;  // UEFI 2.0+
} EfiBootServices;
