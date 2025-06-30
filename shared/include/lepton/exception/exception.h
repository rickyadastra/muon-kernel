#pragma once

#include <lepton/core/object.h>
#include <lepton/throwable.h>

#define _EXCEPTION_METHODS(TYPE, SUPER, FUNC)

#define EXCEPTION_METHODS(TYPE, SUPER, FUNC) \
    THROWABLE_METHODS(TYPE, SUPER, FUNC) \
    _EXCEPTION_METHODS(TYPE, SUPER, FUNC)

CLASSDEF(Exception, Throwable, EXCEPTION_METHODS)
ENDCLASSDEF(Exception)

#define THROW_EXCEPTION(TYPE, MESSAGE) \
    TYPE e = I##TYPE.init(); \
    I##TYPE.set(&e, MESSAGE, __FILE__, __LINE__); \
    THROW(e);
