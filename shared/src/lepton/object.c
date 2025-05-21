#include <bool.h>
#include <lepton/object.h>
#include <null.h>

DECLAREMETHODS(Object, OBJECT_METHODS)

Class* Object_get_class(Object* self) {
    return self->classmeta;
}

#define PACKAGECLASS(CLASS, SUPER) \
    CLASSMETADEF(CLASS, SUPER) \
    INITIALIZERDEF(CLASS)

#define INITIALIZERDEF(CLASS) \
    Bool _##CLASS##_lazy_initialized = false; \
    \
    void _##CLASS##_lazy() { \
        I##NAME = (I##NAME) { \
            
        }; \
    }

Object _Object_init() {
    if (!_Object_)
    return (Object) {
        .classmeta = &_Object_classmeta
    };
}

PACKAGECLASS(Object, ROOT)