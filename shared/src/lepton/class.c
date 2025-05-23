#include <null.h>
#include <lepton/class.h>
#include <lepton/object.h>

int inline subclassof(Class* objClass, Class* classmeta) {
    if (objClass == classmeta) return 1;

    Class* superMeta = objClass->super_class;
    while (superMeta != null) {
        if (superMeta == classmeta) return 1;
        superMeta = superMeta->super_class;
    }

    return 0;
}
