#include <elf/elf_parser.h>
#include <core/bytearray.h>
#include <elf/elf.h>
#include <base/int.h>
#include <lepton/exception/null_exception.h>
#include <lepton.h>
#include <lepton/result.h>

DECLAREMETHODS(ElfParser, ROOT, ELFPARSER_METHODS)

Bool ElfParser_check_header(UPtr buffer, ElfMode mode, ElfArch arch, ElfEndian endian) {
    if (buffer == 0) {
        THROW_EXCEPTION(NullException, "buffer is null")
        return false;
    }

    Elf64Header* elfHeader = (Elf64Header*) buffer;
    Int8Result res = IByteArray.compare_n(elfHeader->common.magic, ELF_MAGIC, 4);
    Int8 resData = UNWRAP(res);

    return (resData == 0 &&
        elfHeader->common.elf_mode == mode &&
        elfHeader->common.endian_type == endian &&
        elfHeader->elf_arch == arch);
}

UPtr ElfParser_get_entry_point(UPtr header) {
    if (header == 0) {
        THROW_EXCEPTION(NullException, "header is null")
        return false;
    }

    return ((Elf64Header*)header)->entry_point;
}

PACKAGEIFACE(ElfParser, ELFPARSER_METHODS)