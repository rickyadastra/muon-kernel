#pragma once

#include <lepton/core/class.h>

#define OBJECT_METHODS(TYPE, SUPER, FUNC) \
    STATIC(TYPE, SUPER, FUNC, TYPE, init) \
    METHOD(TYPE, SUPER, FUNC, Class*, get_class)

BASECLASSDEF(Object, OBJECT_METHODS)

ENDCLASSDEF(Object)
