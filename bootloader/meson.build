boson_cc = meson.get_compiler('c')

efi_compile_args = [
    '-target', 'x86_64-unknown-windows-msvc',
    '-ffreestanding',
    '-fshort-wchar',
    '-mno-red-zone',
    '-fms-extensions',
    '-Wno-microsoft',
    '-nostdlib',
    '-DMS_ABI'
]

efi_link_args = [
    '-target', 'x86_64-unknown-windows-msvc',
    '-Wl,-entry:efi_main',
    '-Wl,-subsystem:efi_application',
    '-fuse-ld=lld-link',
    '-ffreestanding',
    '-fshort-wchar',
    '-mno-red-zone',
    '-fms-extensions',
    '-Wno-microsoft',
    '-nostdlib',
]

boson_sources = files(
    'boson/src/entry.c',
    'boson/src/console.c',
    'boson/src/bootloader.c',
    'boson/src/file.c',
    'boson/src/trampoline.s',
    'boson/src/efi/time.c',
    'boson/src/utils/string.c',
    'boson/src/utils/utils.c',
    'boson/src/exception/file_exception.c',
    'boson/src/exception/bootloader_exception.c',
    'boson/src/exception/console_exception.c',
) + libcore_sources + liblepton_sources

boson_inc = include_directories(
    'boson/include'
)

executable(
    'boson.efi',
    boson_sources,
    include_directories: [boson_inc, shared_inc],
    c_args: efi_compile_args,
    link_args: efi_link_args,
    install: false
)
