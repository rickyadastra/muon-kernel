#pragma once

#include <lepton/core/class.h>

#define LEPTON_RUNTIME_METHODS(T, S, M) \
    M(T, S, void, print, const char*, ...) \

IFACEDEF(LeptonRuntime, LEPTON_RUNTIME_METHODS)

typedef struct _LeptonRuntime_interface LeptonRuntimeInterface;
__attribute__((weak)) extern LeptonRuntimeInterface ILeptonRuntime;

typedef void* JumpContext[10];

#if __STDC_HOSTED__
    #define LEPTON_SETJMP __builtin_setjmp
    #define LEPTON_LONGJMP __builtin_longjmp
#else
    extern int lepton_setjmp(JumpContext*);
    extern void lepton_longjmp(JumpContext*, int);

    #if defined (__x86_64__) && (defined (MS_ABI) || defined (SYSV_ABI))
        #define LEPTON_SETJMP lepton_setjmp
        #define LEPTON_LONGJMP lepton_longjmp
    #else
        #error "Unsupported freestanding architecture"
    #endif
#endif
