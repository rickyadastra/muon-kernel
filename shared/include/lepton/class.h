/**
 * @file class.h
 * @brief This file defines macros for declaring and defining classes and interfaces in C.
 *
 * The macros provided in this file simplify the creation of class-like structures with inheritance and virtual methods.
 * It includes macros for defining base classes, derived classes, interfaces, and methods, as well as macros for initializing class metadata and interfaces.
 *
 * @defgroup Class Definition Macros
 * @{
 * @def BASECLASSDEF(NAME, METHODS) Defines a base class with an interface and methods.
 * @def CLASSDEF(NAME, SUPER, METHODS) Defines a class inheriting from a superclass, with its own interface and methods.
 * @def ENDCLASSDEF(NAME) Completes the class definition and declares the class metadata and interface.
 * @def DECLAREMETHODS(NAME, SUPER, METHODS) Declares the interface and methods for a class.
 * @def PACKAGECLASS(CLASS, SUPER, METHODS, SUPER_METHODS) Packages the class by defining its metadata and initializer.
 * @def CLASSMETADEF(NAME, SUPER, METHODS, SUPER_METHODS) Defines the class metadata structure.
 * @def INITIALIZERDEF(NAME, SUPER, METHODS, SUPER_METHODS) Defines the initializer function for the class.
 * @def INHERITCLASS(NAME, SUPER_METHODS, METHODS) Inherits methods from a superclass and defines new methods for the class.
 * @def VIRTUALDEF(SUPER, CLASS, RET, NAME, ...) Defines a virtual method in the interface.
 * @def METHODDECL(SUPER, CLASS, RET, NAME, ...) Declares a method for a class.
 * @def WEAKMETHODDECL(SUPER, CLASS, RET, NAME, ...) Declares a weak method for a class.
 * @def IFACEMETHOD(SUPER, CLASS, RET, METHOD, ...) Accesses a method from the superclass's interface.
 * @def IFACEASSIGN(CLASS, SUPER, RET, METHOD, ...) Assigns a method to the interface.
 * @def IFACEOVERRIDE(CLASS, SUPER, RET, METHOD, ...) Overrides a method in the interface, falling back to the superclass's implementation if not defined.
 * @def _ROOT_classmeta The classmeta of the root class.
 * @}
 */
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
#define IFACEASSIGN(CLASS, SUPER, RET, METHOD, ...) .METHOD = CLASS##_##METHOD
#define IFACEOVERRIDE(CLASS, SUPER, RET, METHOD, ...) .METHOD = CLASS##_##METHOD ? CLASS##_##METHOD : IFACEMETHOD(SUPER, CLASS, RET, METHOD, ##__VA_ARGS__),

#define _ROOT_classmeta ((Class*)null)

// HEADER FILE MACROS --------------- 

#define BASECLASSDEF(NAME, METHODS) \
    typedef struct _##NAME##_interface NAME##Interface; \
    typedef struct _##NAME##_struct NAME; \
    \
    struct _##NAME##_interface { \
        METHODS(NAME, ROOT, VIRTUALDEF) \
    }; \
    \
    METHODS(NAME, ROOT, METHODDECL) \
    \
    struct _##NAME##_struct { \
        Class* classmeta; \

#define CLASSDEF(NAME, SUPER, METHODS) \
    typedef struct _##NAME##_interface NAME##Interface; \
    typedef struct _##NAME##_struct NAME; \
    \
    struct _##NAME##_interface { \
        METHODS(NAME, SUPER, VIRTUALDEF) \
    }; \
    \
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
