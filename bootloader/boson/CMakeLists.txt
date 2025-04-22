set(ENTRY_POINT "efi_main")
set(LINKER_SCRIPT ${CMAKE_BINARY_DIR}/${BOOTLOADER}.ld)

configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/scripts/linkerscript.ld.in
    ${LINKER_SCRIPT}
    @ONLY
)

include_directories(boson PRIVATE ${CMAKE_SOURCE_DIR}/shared/include)

file(GLOB BOSON_SOURCES
    "src/*.c"
)

add_library(${BOOTLOADER} STATIC ${BOSON_SOURCES})

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_C_COMPILER "clang")

target_compile_options(${BOOTLOADER} PRIVATE
    -target x86_64-unknown-windows 
    -ffreestanding 
    -fshort-wchar 
    -mno-red-zone
)

target_include_directories(${BOOTLOADER} PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

set(UEFI_APP_OUT ${CMAKE_BINARY_DIR}/bootloader/BOOTX64.EFI)
set(UEFI_EXPORT ${UEFI_APP_OUT} PARENT_SCOPE)

add_custom_command(
    OUTPUT ${UEFI_APP_OUT}
    COMMAND clang
        -target x86_64-unknown-windows 
        -nostdlib 
        -Wl,-entry:${ENTRY_POINT}
        -Wl,-subsystem:efi_application 
        -fuse-ld=lld-link
        $<TARGET_FILE:${BOOTLOADER}>
        -o ${UEFI_APP_OUT}
    DEPENDS ${BOOTLOADER}
    COMMENT "[boson] Linking executable ${UEFI_APP_OUT}"
)

add_custom_target(uefi-app ALL
    DEPENDS ${UEFI_APP_OUT}
)
