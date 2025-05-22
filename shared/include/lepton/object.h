#pragma once

#include "class.h"

#define OBJECT_METHODS(S, M, T) \
    M(T, S, T, init) \
    M(T, S, Class*, get_class, T* self)

BASECLASSDEF(Object, OBJECT_METHODS)

ENDCLASSDEF(Object)
