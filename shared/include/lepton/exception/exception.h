#pragma once

#include <lepton/core.h>
#include <lepton/throwable.h>

#define _EXCEPTION_METHODS(TYPE, SUPER, FUNC)

#define EXCEPTION_METHODS(TYPE, SUPER, FUNC) \
    THROWABLE_METHODS(TYPE, SUPER, FUNC) \
    _EXCEPTION_METHODS(TYPE, SUPER, FUNC)

CLASSDEF(Exception, Throwable, EXCEPTION_METHODS)
ENDCLASSDEF(Exception)
