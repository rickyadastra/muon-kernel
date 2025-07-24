#pragma once

#include <lepton/core/class.h>

#define MEMBERDECL(TYPE, NAME, VAL) TYPE NAME;
#define MEMBERDEF(TYPE, NAME, VAL) .NAME = VAL,
#define MEMBERATTRDECL(TYPE, NAME, VALUE) {.label=#NAME},

#define ENUMPACKAGE(NAME, ATTRIBUTES, MEMBERS) \
    static const struct NAME##Member { \
        const char* label; \
        ATTRIBUTES; \
    } NAME##Members[] = { \
        MEMBERS(NAME, MEMBERATTRDECL) \
    }; \
    NAME##EnumInterface I##NAME##Enum; \
    const char* NAME##Enum_get_label(const NAME##EnumType* enumMember) { \
        Size index = ((UPtr)enumMember - (UPtr)&NAME) / sizeof(NAME##EnumType); \
        if (index < 0 || index >= I##NAME##Enum.size) { \
            THROW_EXCEPTION(NoSuchEnumMemberException, "Invalid enum access in " #NAME) \
        } \
        return NAME##Members[index].label; \
    } \
    \
    NAME##EnumInterface I##NAME##Enum = \
        (NAME##EnumInterface){ \
            .size = sizeof(NAME) / sizeof(NAME##EnumType), \
            .get_label = NAME##Enum_get_label \
        }; \

#define ENUMDEF(NAME, TYPE, MEMBERS, METHODS) \
    typedef TYPE NAME##EnumType; \
    static const struct _##NAME##_enum { \
        MEMBERS(TYPE, MEMBERDECL) \
    } NAME = { \
        MEMBERS(TYPE, MEMBERDEF)\
    }; \
    struct _##NAME##Enum_interface { \
        Size size; \
        const char* (*get_label)(const BaudRateEnumType* enumMember); \
        METHODS(NAME, ROOT, VIRTUALDEF) \
    }; \
    ENDIFACEDEF(NAME##Enum)
