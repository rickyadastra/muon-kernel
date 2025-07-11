#include <efi/efi.h>
#include <efi/time.h>
#include <boson/wchar.h>

WChar16 format_digit(UInt8 digit, Size scale) {
    return L'0' + ((digit/scale)%10);
}

WChar16 format_digit_16(UInt16 digit, Size scale) {
    return L'0' + ((digit/scale)%10);
}

Size format_datetime(EfiTime time, WChar16* buffer, Size bufferSize) {
    // todo: assert bufferSize > 23
    WChar16* tempPtr = buffer;

    *(tempPtr++) = L'[';
    *(tempPtr++) = format_digit_16(time.Year, 1000);
    *(tempPtr++) = format_digit_16(time.Year, 100);
    *(tempPtr++) = format_digit_16(time.Year, 10);
    *(tempPtr++) = format_digit_16(time.Year, 1);
    *(tempPtr++) = L'-';
    *(tempPtr++) = format_digit(time.Month, 10);
    *(tempPtr++) = format_digit(time.Month, 1);
    *(tempPtr++) = L'-';
    *(tempPtr++) = format_digit(time.Day, 10);
    *(tempPtr++) = format_digit(time.Day, 1);
    *(tempPtr++) = L' ';
    *(tempPtr++) = format_digit(time.Hour, 10);
    *(tempPtr++) = format_digit(time.Hour, 1);
    *(tempPtr++) = L':';
    *(tempPtr++) = format_digit(time.Minute, 10);
    *(tempPtr++) = format_digit(time.Minute, 1);
    *(tempPtr++) = L':';
    *(tempPtr++) = format_digit(time.Second, 10);
    *(tempPtr++) = format_digit(time.Second, 1);
    *(tempPtr++) = L']';
    *(tempPtr++) = L'\t';
    *tempPtr = 0;

    return 23;
}
