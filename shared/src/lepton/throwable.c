#include <lepton/throwable.h>
#include <lepton/class.h>
#include <null.h>

ThrowableContext* currentExcContext = null;

INHERITCLASS(Throwable, _THROWABLE_METHODS, OBJECT_METHODS)

PACKAGECLASS(Throwable, Object, _THROWABLE_METHODS, OBJECT_METHODS)