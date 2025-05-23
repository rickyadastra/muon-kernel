#pragma once

typedef struct _Class_struct Class;
struct _Class_struct {
    const char* name;
    Class* super_class;
    void* interface;
};

#define VIRTUALDEF(SUPER, CLASS, RET, NAME, ...) RET (*NAME)(__VA_ARGS__);
#define METHODDECL(SUPER, CLASS, RET, NAME, ...) RET CLASS##_##NAME(__VA_ARGS__);
#define WEAKMETHODDECL(SUPER, CLASS, RET, NAME, ...) __attribute__((weak)) RET CLASS##_##NAME(__VA_ARGS__);
#define IFACEMETHOD(SUPER, CLASS, RET, METHOD, ...) ((CLASS##Interface*)(_##SUPER##_classmeta.interface))->METHOD
#define IFACEASSIGN(CLASS, SUPER, RET, METHOD, ...) .METHOD = CLASS##_##METHOD,
#define IFACEOVERRIDE(CLASS, SUPER, RET, METHOD, ...) .METHOD = CLASS##_##METHOD ? CLASS##_##METHOD : IFACEMETHOD(SUPER, CLASS, RET, METHOD, ##__VA_ARGS__),

#define _ROOT_classmeta ((Class*)null)

int subclassof(Class*, Class*);
#define INSTANCEOF(OBJECT, CLASS) subclassof((OBJECT)->classmeta, &_##CLASS##_classmeta)

// HEADER FILE MACROS --------------- 

#define IFACEDEF(NAME, METHODS) \
    struct _##NAME##_interface { \
        METHODS(NAME, ROOT, VIRTUALDEF) \
    }; \

#define BASECLASSDEF(NAME, METHODS) \
    typedef struct _##NAME##_interface NAME##Interface; \
    typedef struct _##NAME##_struct NAME; \
    IFACEDEF(NAME, METHODS) \
    METHODS(NAME, ROOT, METHODDECL) \
    \
    struct _##NAME##_struct { \
        Class* classmeta; \

#define CLASSDEF(NAME, SUPER, METHODS) \
    typedef struct _##NAME##_interface NAME##Interface; \
    typedef struct _##NAME##_struct NAME; \
    IFACEDEF(NAME, METHODS) \
    METHODS(NAME, SUPER, METHODDECL) \
    \
    struct _##NAME##_struct { \
        union { \
            SUPER super; \
            SUPER; \
        }; \

#define ENDCLASSDEF(NAME) \
    }; \
    extern Class _##NAME##_classmeta; \
    extern NAME##Interface I##NAME; 

#define ENDIFACEDEF(NAME) \
    typedef struct _##NAME##_interface NAME##Interface; \
    extern NAME##Interface I##NAME; 

// SOURCE FILE MACROS --------------- 

#define DECLAREMETHODS(NAME, SUPER, METHODS) \
    NAME##Interface I##NAME; \
    METHODS(NAME, NAME, METHODDECL)

#define PACKAGECLASS(CLASS, SUPER, METHODS, SUPER_METHODS) \
    CLASSMETADEF(CLASS, SUPER, METHODS, SUPER_METHODS) \
    INITIALIZERDEF(CLASS, SUPER, METHODS, SUPER_METHODS)

#define CLASSMETADEF(NAME, SUPER, METHODS, SUPER_METHODS) \
    Class _##NAME##_classmeta = { \
        .name = #NAME, \
        .super_class = &_##SUPER##_classmeta, \
        .interface = &I##NAME \
    }; 

#define INITIALIZERDEF(NAME, SUPER, METHODS, SUPER_METHODS) \
    int _##NAME##_lazy_initialized = 0; \
    \
    void _##NAME##_iface_init_lazy() { \
        I##NAME = (NAME##Interface) { \
            SUPER_METHODS(NAME, SUPER, IFACEOVERRIDE) \
            METHODS(NAME, SUPER, IFACEASSIGN) \
        }; \
        _##NAME##_lazy_initialized = 1; \
    } \
    NAME NAME##_init() { \
        if (_##NAME##_lazy_initialized == 0) _##NAME##_iface_init_lazy(); \
        return (NAME) {.classmeta = &_##NAME##_classmeta}; \
    } \

#define INHERITCLASS(NAME, SUPER_METHODS, METHODS) \
    SUPER_METHODS(NAME, NAME, WEAKMETHODDECL) \
    METHODS(NAME, NAME, METHODDECL) \
    NAME##Interface I##NAME = { \
        .init = NAME##_init, \
    };

#define PACKAGEIFACE(NAME, METHODS) \
    NAME##Interface I##NAME = (NAME##Interface) { \
        METHODS(NAME, ROOT, IFACEASSIGN) \
    };
