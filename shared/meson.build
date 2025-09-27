shared_inc = include_directories(
    'include',
    'src/lepton/exception'
)

libshared_sources = files(
    'src/elf/elf_parser.c'
)

libcore_sources = files(
    'src/core/bytearray.c',
)

liblepton_sources = files(
    'src/lepton/runtime.c',
    'src/lepton/throwable.c',
    'src/lepton/core/class.c',
    'src/lepton/core/object.c',
    'src/lepton/exception/exception.c',
    'src/lepton/exception/null_exception.c',
    'src/lepton/exception/result_exception.c',
    'src/lepton/exception/no_such_enum_member_exception.c',
    'src/lepton/exception/invalid_parameter_exception.c',
    'src/lepton/exception/exception_runtime_@0@_@1@.s'.format(arch, abi)
)

libsharedc3_sources = files(
    f'libs/boson.c3i',
    f'libs/formatting.c3',
    f'libs/lang.c3',
    f'libs/math.c3',

    f'libs/mem/allocator.c3i',
    f'libs/mem/buddy_allocator.c3',
    
    f'libs/io/ringbuffer.c3',
    f'libs/io/stream.c3i',

    f'libs/collections/bitmap.c3',
)
