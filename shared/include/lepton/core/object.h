#pragma once

#include "class.h"

#define OBJECT_METHODS(TYPE, SUPER, FUNC) \
    FUNC(TYPE, SUPER, TYPE, init) \
    FUNC(TYPE, SUPER, Class*, get_class, TYPE* self)

BASECLASSDEF(Object, OBJECT_METHODS)

ENDCLASSDEF(Object)
