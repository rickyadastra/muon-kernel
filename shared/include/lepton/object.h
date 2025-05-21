#pragma once

#include "class.h"

#define OBJECT_METHODS(M, T) \
    M(T, Class*, get_class, T* self)

BASECLASSDEF(Object, OBJECT_METHODS)

ENDCLASSDEF(Object)
