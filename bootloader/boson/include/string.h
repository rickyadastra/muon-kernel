#pragma once

#include <int.h>
#include <vargs.h>
#include <wchar.h>

unsigned int strlen(const char* str);
char* ltoa(UInt64 i, unsigned base, char* buf);
void ltoa_s(Int64 i, unsigned base, char* buf);
WChar16* vstrf(const char* istr, WChar16* buffer, VAList args);
