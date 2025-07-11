#pragma once

#include <base.h>
#include <elf/elf.h>
#include <lepton.h>
    
#define ELFPARSER_METHODS(T, S, M) \
    STATIC(T, S, M, Bool, check_header, UPtr buffer, UInt8 mode, UInt16 arch, UInt8 endian) \
    STATIC(T, S, M, UPtr, get_entry_point, UPtr header)

IFACEDEF(ElfParser, ELFPARSER_METHODS)
ENDIFACEDEF(ElfParser)