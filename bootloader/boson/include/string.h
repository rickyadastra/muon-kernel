#pragma once

#include <int.h>
#include <vargs.h>
#include <wchar.h>

WChar16* vstrf(const char* istr, WChar16* buffer, VAList args);
