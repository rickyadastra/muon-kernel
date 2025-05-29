#pragma once

#include <lepton/core/object.h>
#include <lepton/runtime.h>

#define _THROWABLE_METHODS(TYPE, SUPER, FUNC) \
    FUNC(TYPE, SUPER, void, set, TYPE* self, const char* message, const char* file, int line)

#define THROWABLE_METHODS(TYPE, SUPER, FUNC) \
    OBJECT_METHODS(TYPE, SUPER, FUNC) \
    _THROWABLE_METHODS(TYPE, SUPER, FUNC)

CLASSDEF(Throwable, Object, THROWABLE_METHODS)
    const char* message;
    const char* file;
    unsigned int line;
ENDCLASSDEF(Throwable)

typedef void* JumpContext[10];
typedef struct _ThrowableContext_struct ThrowableContext; 

struct _ThrowableContext_struct {
    JumpContext context;
    Throwable* throwable;
    ThrowableContext* prev;
};

extern ThrowableContext* currentExcContext;

#define TRY \
    do { \
        ThrowableContext ctx; \
        ctx.prev = currentExcContext; \
        currentExcContext = &ctx; \
        if (Lepton_setjmp((void**)&ctx.context) == 0)

#define CATCH(T, e) \
    else if (INSTANCEOF(ctx.throwable, T)) { \
        T* e = (T*)ctx.throwable; \
        currentExcContext = ctx.prev;

#define ORCATCH(T, e) \
    } else if (INSTANCEOF(ctx.throwable, T)) { \
        T* e = (T*)ctx.throwable; \
        currentExcContext = ctx.prev;

#define ENDTRY \
    } } while (0); 

#define FINALLY \
    if (currentExcContext != null) currentExcContext = ctx.prev;


#define THROW(T) \
    if (!currentExcContext) { \
        Lepton_print("Uncaught throwable"); \
    } \
    currentExcContext->throwable = (Throwable*)&T; \
    Lepton_longjmp((void**)&currentExcContext->context, 1)
