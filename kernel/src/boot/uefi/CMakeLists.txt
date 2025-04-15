set(ENTRY_POINT "efi_main")
set(LINKER_SCRIPT ${CMAKE_BINARY_DIR}/${BOOT_METHOD}-${TARGET_ARCH}.ld)

file(READ ${CMAKE_SOURCE_DIR}/kernel/scripts/common.ld.in COMMON_CONTENT)
file(READ ${CMAKE_SOURCE_DIR}/kernel/scripts/boot/uefi.ld.in BOOT_CONTENT)
file(READ ${CMAKE_SOURCE_DIR}/kernel/scripts/arch/${TARGET_ARCH}.ld.in ARCH_CONTENT)

configure_file(
    ${CMAKE_SOURCE_DIR}/kernel/scripts/compose.ld.in
    ${LINKER_SCRIPT}
    @ONLY
)

add_library(boot_uefi STATIC entry.c)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_C_COMPILER "clang")

target_compile_options(boot_uefi PRIVATE
    -target x86_64-unknown-windows 
    -ffreestanding 
    -fshort-wchar 
    -mno-red-zone
)

target_include_directories(boot_uefi PUBLIC
    ${CMAKE_SOURCE_DIR}/kernel/include
)
