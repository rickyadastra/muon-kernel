if (NOT DEFINED BOOT_METHOD)
    message(STATUS "Boot method not defined, defaulting to UEFI")
    set(BOOT_METHOD uefi CACHE STRING "Boot method")
endif()

message(STATUS "Boot method: ${BOOT_METHOD}")

if (NOT DEFINED TARGET_ARCH)
    message(STATUS "Arch not defined, defaulting to x86_64")
    set(TARGET_ARCH x86_64 CACHE STRING "Target architecture")
endif()

message(STATUS "Target arch: ${TARGET_ARCH}")

if(TARGET_ARCH STREQUAL "x86_64")
    set(ARCH_SRC "src/arch/x86_64/")
    set(ARCH_FLAGS "-m64")
else()
    message(FATAL_ERROR "Unknown target architecture: ${TARGET_ARCH}")
endif()

add_subdirectory(src/boot/${BOOT_METHOD})

file(GLOB KERNEL_SOURCES
    "*.c"
    "arch/${ARCH_SRC}/*.c"
    "arch/${ARCH_SRC}/*.asm"
)

# add_library(kernel STATIC ${KERNEL_SOURCES})

# target_compile_options(kernel PRIVATE 
#     ${ARCH_FLAGS}
#     -ffreestanding
#     -nostdlib
#     -fno-builtin
#     -Wall
#     -Wextra
#     -mno-red-zone
# )

# target_include_directories(kernel PUBLIC
#     ${CMAKE_CURRENT_SOURCE_DIR}/include
#     ${CMAKE_CURRENT_SOURCE_DIR}/include/arch/${TARGET_ARCH}
# )
