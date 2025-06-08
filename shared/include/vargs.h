#pragma once

typedef __builtin_va_list VAList;

#define VASTART(AP, LASTARG) __builtin_va_start(AP, LASTARG)
#define VAEND(AP) __builtin_va_end(AP)
#define VAARG(AP, TYPE) __builtin_va_arg(AP, TYPE)
