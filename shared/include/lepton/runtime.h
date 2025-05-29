#pragma once

typedef void (*PrintfFunc)(const char*, ...);
typedef int (*SetJmpFunc)(void**);
typedef __attribute__((noreturn)) void (*LongJmpFunc)(void**, int);

extern PrintfFunc Lepton_print; 
extern SetJmpFunc Lepton_setjmp;
extern LongJmpFunc Lepton_longjmp;

#define LEPTON_RUNTIME_INIT(LONGJMP, SETJMP, PRINTF) \
    LongJmpFunc Lepton_longjmp = (LongJmpFunc) LONGJMP; \
    SetJmpFunc Lepton_setjmp = (SetJmpFunc) SETJMP; \
    PrintfFunc Lepton_print = (PrintfFunc) PRINTF;
