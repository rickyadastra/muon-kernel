#pragma once

#include <efi/time.h>
#include <int.h>
#include <efi/efi.h>
#include <wchar.h>

#define EFI_FILE_PROTOCOL_REVISION           0x00010000
#define EFI_FILE_PROTOCOL_REVISION2          0x00020000
#define EFI_FILE_PROTOCOL_LATEST_REVISION EFI_FILE_PROTOCOL_REVISION2

typedef struct _EfiFileProtocol_struct EfiFileProtocol;
typedef EfiStatus (*EfiFileOpen) (EfiFileProtocol* This, EfiFileProtocol** NewHandle, WChar16* FileName, UInt64 OpenMode, UInt64 Attributes);
typedef EfiStatus (*EfiFileClose) (EfiFileProtocol* This);
typedef EfiStatus (*EfiFileDelete) (EfiFileProtocol* This);
typedef EfiStatus (*EfiFileRead) (EfiFileProtocol* This, UINTN* BufferSize, void* Buffer);
typedef EfiStatus (*EfiFileWrite) (EfiFileProtocol* This, UINTN* BufferSize, void* Buffer);
typedef EfiStatus (*EfiFileGetPosition) (EfiFileProtocol* This, UInt64* Position);
typedef EfiStatus (*EfiFileSetPosition) (EfiFileProtocol* This, UInt64 Position);
typedef EfiStatus (*EfiFileGetInfo) (EfiFileProtocol* This, EfiGUID* InformationType, UINTN* BufferSize, void* Buffer);
typedef EfiStatus (*EfiFileSetInfo) (EfiFileProtocol* This, EfiGUID* InformationType, UINTN BufferSize, void* Buffer);
typedef EfiStatus (*EfiFileFlush) (EfiFileProtocol* This);

#define EFI_FILE_MODE_READ       0x0000000000000001
#define EFI_FILE_MODE_WRITE      0x0000000000000002
#define EFI_FILE_MODE_CREATE     0x8000000000000000

struct _EfiFileProtocol_struct {
  UInt64 Revision;
  EfiFileOpen Open;
  EfiFileClose Close;
  EfiFileDelete Delete;
  EfiFileRead Read;
  EfiFileWrite Write;
  EfiFileGetPosition GetPosition;
  EfiFileSetPosition SetPosition;
  EfiFileGetInfo GetInfo;
  EfiFileSetInfo SetInfo;
  EfiFileFlush Flush;
  void* OpenEx; // Added for revision 2
  void* ReadEx; // Added for revision 2
  void* WriteEx; // Added for revision 2
  void* FlushEx; // Added for revision 2
};

#define EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_GUID \
 {0x0964e5b22,0x6459,0x11d2, {0x8e,0x39,0x00,0xa0,0xc9,0x69,0x72,0x3b}}

#define EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_REVISION 0x00010000

typedef struct _EfiSimpleFileSystemProtocol_struct EfiSimpleFileSystemProtocol;
typedef EfiStatus (*EfiSimpleFileSystemProtocolOpenVolume) (EfiSimpleFileSystemProtocol* This,EfiFileProtocol** Root);

struct _EfiSimpleFileSystemProtocol_struct {
    UInt64 Revision;
    EfiSimpleFileSystemProtocolOpenVolume OpenVolume;
};

#define EFI_FILE_INFO_GUID \
 {0x09576e92,0x6d3f,0x11d2, {0x8e,0x39,0x00,0xa0,0xc9,0x69,0x72,0x3b}}

typedef struct _EfiFileInfo_struct {
  UInt64 Size;
  UInt64 FileSize;
  UInt64 PhysicalSize;
  EfiTime CreateTime;
  EfiTime LastAccessTime;
  EfiTime ModificationTime;
  UInt64 Attribute;
  WChar16 FileName[];
} EfiFileInfo;
