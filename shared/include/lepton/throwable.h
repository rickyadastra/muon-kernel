#pragma once

#include "lepton/class.h"
#include "lepton/object.h"

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

typedef void* JumpContext[5];
typedef struct _ThrowableContext_struct ThrowableContext; 

struct _ThrowableContext_struct {
    JumpContext context;
    Throwable* throwable;
    ThrowableContext* prev;
};

#define SAVE_EXC_CONTEXT __builtin_setjmp
#define LOAD_EXC_CONTEXT __builtin_longjmp

extern ThrowableContext* currentExcContext;

#define TRY \
    do { \
        ThrowableContext ctx; \
        ctx.prev = currentExcContext; \
        currentExcContext = &ctx; \
        if (SAVE_EXC_CONTEXT((void**)&ctx.context) == 0)

#define CATCH(T, e) \
    else if (INSTANCEOF(ctx.throwable, T)) { \
        Throwable* t = ctx.throwable; \
        currentExcContext = ctx.prev;

#define ORCATCH(T, e) \
    } else if (INSTANCEOF(ctx.throwable, T)) { \
        Throwable* t = ctx.throwable; \
        currentExcContext = ctx.prev;

#define ENDTRY \
    } } while (0); 

#define FINALLY \
    if (currentExcContext != null) currentExcContext = ctx.prev;


// TODO: non usare printf
#define THROW(T) \
    if (!currentExcContext) { \
        printf("Uncaught throwable"); \
    } \
    currentExcContext->throwable = (Throwable*)&T; \
    LOAD_EXC_CONTEXT((void**)&currentExcContext->context, 1)
