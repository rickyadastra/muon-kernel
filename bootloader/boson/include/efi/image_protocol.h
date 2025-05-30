#pragma once

#include "efi/memory_type.h"
#include <int.h>
#include <efi/efi.h>

#define EFI_LOADED_IMAGE_PROTOCOL_GUID \
  {0x5B1B31A1,0x9562,0x11d2, {0x8E,0x3F,0x00,0xA0,0xC9,0x69,0x72,0x3B}}

#define EFI_LOADED_IMAGE_PROTOCOL_REVISION 0x1000

typedef struct {
   UInt32 Revision;
   EfiHandle ParentHandle;
   EfiSystemTable* SystemTable;

   // Source location of the image
   EfiHandle DeviceHandle;
   void* FilePath;
   void* Reserved;

   // Image’s load options
   UInt32 LoadOptionsSize;
   void* LoadOptions;

   // Location where image was loaded
   void* ImageBase;
   UInt64 ImageSize;
   EfiMemoryType ImageCodeType;
   EfiMemoryType ImageDataType;
   void* Unload;
} EfiLoadedImageProtocol;