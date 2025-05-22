/**
 * @file class.h
 * @brief Defines the class structure and related macros for the Lepton object system.
 *
 * This file provides the foundation for creating and managing classes,
 * supporting inheritance and virtual methods through a vtable-based interface.
 *
 * The core concept is the `Class` structure, which holds metadata about a class,
 * including its name, superclass, and interface (vtable).  Macros are provided
 * to simplify the definition of classes, their interfaces, and their methods.
 *
 * Key macros:
 *   - `BASECLASSDEF`: Defines a base class with its interface and structure.
 *   - `CLASSDEF`: Defines a class inheriting from a superclass.
 *   - `ENDCLASSDEF`: Completes the class definition and declares the class metadata and interface.
 *   - `VIRTUALDEF`: Defines a virtual method within an interface.
 *   - `METHODDECL`: Declares a method implementation for a class.
 *   - `DECLAREMETHODS`: Declares the interface and method implementations for a class.
 */
#pragma once

#include <null.h>

typedef struct _Class_struct Class;
struct _Class_struct {
    const char* name;
    Class* super_class;
    void* interface;
};

#define VIRTUALDEF(SUPER, CLASS, RET, NAME, ...) RET (*NAME)(__VA_ARGS__);
#define METHODDECL(SUPER, CLASS, RET, NAME, ...) RET CLASS##_##NAME(__VA_ARGS__);
#define IFACEMETHOD(SUPER, CLASS, RET, METHOD, ...) ((I##CLASS*)(_##SUPER##_classmeta.interface))->METHOD
#define IFACEASSIGN(SUPER, CLASS, RET, METHOD, ...) .METHOD = CLASS##_##METHOD ? CLASS##_##METHOD : IFACEMETHOD(SUPER, CLASS, RET, METHOD, ##__VA_ARGS__),

#define _ROOT_classmeta ((Class*)null)

// HEADER FILE MACROS --------------- 

#define BASECLASSDEF(NAME, METHODS) \
    typedef struct _##NAME##_interface NAME##Interface; \
    typedef struct _##NAME##_struct NAME; \
    \
    struct _##NAME##_interface { \
        METHODS(ROOT, VIRTUALDEF, NAME) \
    }; \
    \
    METHODS(ROOT, METHODDECL, NAME) \
    \
    struct _##NAME##_struct { \
        Class* classmeta; \

#define CLASSDEF(NAME, SUPER, METHODS) \
    typedef struct _##NAME##_interface NAME##Interface; \
    typedef struct _##NAME##_struct NAME; \
    \
    struct _##NAME##_interface { \
        METHODS(VIRTUALDEF, NAME) \
    }; \
    \
    METHODS(METHODDECL, NAME) \
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
    METHODS(SUPER, METHODDECL, NAME)

#define PACKAGECLASS(CLASS, SUPER, METHODS, SUPER_METHODS) \
    CLASSMETADEF(CLASS, SUPER, METHODS, SUPER_METHODS) \
    INITIALIZERDEF(CLASS, SUPER, METHODS, SUPER_METHODS)

#define CLASSMETADEF(NAME, SUPER, METHODS, SUPER_METHODS) \
    Class _##NAME##_classmeta = { \
        .name = #NAME, \
        .super_class = _##SUPER##_classmeta, \
        .interface = &I##NAME \
    }; 

#define INITIALIZERDEF(NAME, SUPER, METHODS, SUPER_METHODS) \
    Bool _##NAME##_lazy_initialized = false; \
    \
    void _##NAME##_lazy() { \
        I##NAME = (I##NAME) { \
            METHODS(SUPER, IFACEASSIGN, NAME) \
        }; \
    }
