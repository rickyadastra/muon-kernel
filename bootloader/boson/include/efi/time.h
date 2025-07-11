#include <efi/efi.h>

#pragma once

typedef struct {
    UInt16    Year;              // 1900 - 9999
    UInt8     Month;             // 1 - 12
    UInt8     Day;               // 1 - 31
    UInt8     Hour;              // 0 - 23
    UInt8     Minute;            // 0 - 59
    UInt8     Second;            // 0 - 59
    UInt8     Pad1;
    UInt32    Nanosecond;        // 0 - 999,999,999
    Int16     TimeZone;          // —1440 to 1440 or 2047
    UInt8     Daylight;
    UInt8     Pad2;
} EfiTime;

#define EFI_TIME_ADJUST_DAYLIGHT   0x01
#define EFI_TIME_IN_DAYLIGHT       0x02

#define EFI_UNSPECIFIED_TIMEZONE   0x07FF

typedef EfiStatus (*EfiGetTime)(void *This, const WChar16 *String);



Size format_datetime(EfiTime time, WChar16* buffer, Size bufferSize);
