#include <lepton/throwable.h>
#include <lepton/core/class.h>
#include <base.h>

ThrowableContext* currentExcContext = null;

INHERITCLASS(Throwable, _THROWABLE_METHODS, OBJECT_METHODS)

void inline Throwable_set(Throwable* self, const char* message, const char* file, int line) {
    self->message = message;
    self->file = file;
    self->line = line;
}

PACKAGECLASS(Throwable, Object, _THROWABLE_METHODS, OBJECT_METHODS)