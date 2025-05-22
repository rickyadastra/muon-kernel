#include "lepton/class.h"
#include <bool.h>
#include <lepton/object.h>
#include <null.h>

DECLAREMETHODS(Object, ROOT, OBJECT_METHODS)

Class* Object_get_class(Object* self) {
    return self->classmeta;
}

Object Object_init() {
    return (Object){
        .classmeta = &_Object_classmeta,
    };
}

Class _Object_classmeta = {
    .name = "Object",
    .super_class = ((Class *)((void *)0)),
    .interface = &IObject
};

ObjectInterface IObject = {
    .get_class = Object_get_class,
    .init = Object_init,
};
