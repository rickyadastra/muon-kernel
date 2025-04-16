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

file(GLOB KERNEL_SOURCES
    "*.c"
    "arch/${ARCH_SRC}/*.c"
    "arch/${ARCH_SRC}/*.asm"
)

# add_library(kernel STATIC ${KERNEL_SOURCES})

# target_include_directories(kernel PRIVATE ${CMAKE_SOURCE_DIR}/shared/include)

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
